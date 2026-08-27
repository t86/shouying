import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:session/src/credential_transaction_coordinator.dart';

CredentialTransactionCoordinator createCredentialTransactionCoordinator() =>
    IoCredentialTransactionCoordinator(
      lockDirectoryProvider:
          const ApplicationSupportNativeLockDirectoryProvider(),
    );

abstract interface class NativeLockDirectoryProvider {
  Future<Directory> getLockDirectory();
}

final class ApplicationSupportNativeLockDirectoryProvider
    implements NativeLockDirectoryProvider {
  const ApplicationSupportNativeLockDirectoryProvider();

  @override
  Future<Directory> getLockDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(
      '${support.path}${Platform.pathSeparator}credential-transaction-locks',
    );
  }
}

final class FixedNativeLockDirectoryProvider
    implements NativeLockDirectoryProvider {
  const FixedNativeLockDirectoryProvider(this.directory);

  final Directory directory;

  @override
  Future<Directory> getLockDirectory() async => directory;
}

final class IoCredentialTransactionCoordinator
    implements CredentialTransactionCoordinator {
  const IoCredentialTransactionCoordinator({
    required this.lockDirectoryProvider,
  });

  final NativeLockDirectoryProvider lockDirectoryProvider;

  static final Map<String, Future<void>> _isolateTransactionTails =
      <String, Future<void>>{};

  @override
  Future<T> synchronized<T>(String namespace, Future<T> Function() operation) =>
      _withIsolateQueue(namespace, () => _withFileLock(namespace, operation));

  Future<T> _withIsolateQueue<T>(
    String namespace,
    Future<T> Function() operation,
  ) async {
    final preceding =
        _isolateTransactionTails[namespace] ?? Future<void>.value();
    final release = Completer<void>();
    final tail = release.future;
    _isolateTransactionTails[namespace] = tail;
    await preceding;
    try {
      return await operation();
    } finally {
      release.complete();
      if (identical(_isolateTransactionTails[namespace], tail)) {
        unawaited(_isolateTransactionTails.remove(namespace));
      }
    }
  }

  Future<T> _withFileLock<T>(
    String namespace,
    Future<T> Function() operation,
  ) async {
    File? processGuard;
    RandomAccessFile? lockFile;
    var locked = false;
    try {
      final directory = await lockDirectoryProvider.getLockDirectory();
      await directory.create(recursive: true);
      final namespaceHash = sha256.convert(utf8.encode(namespace)).toString();
      processGuard = File(
        '${directory.path}${Platform.pathSeparator}$namespaceHash.$pid.guard',
      );
      await _acquireProcessGuard(processGuard);
      final file = File(
        '${directory.path}${Platform.pathSeparator}$namespaceHash.lock',
      );
      lockFile = await file.open(mode: FileMode.append);
      await lockFile.lock(FileLock.blockingExclusive);
      locked = true;
    } on Object {
      if (lockFile != null) {
        try {
          await lockFile.close();
        } on Object {
          // The stable unavailable failure below remains authoritative.
        }
      }
      if (processGuard != null && await processGuard.exists()) {
        try {
          await processGuard.delete();
        } on Object {
          // The stable unavailable failure below remains authoritative.
        }
      }
      throw const CredentialTransactionUnavailableException();
    }

    try {
      return await operation();
    } finally {
      try {
        if (locked) await lockFile.unlock();
        await lockFile.close();
        await processGuard.delete();
      } on Object {
        throw const CredentialTransactionUnavailableException();
      }
    }
  }

  Future<void> _acquireProcessGuard(File guard) async {
    while (true) {
      try {
        await guard.create(exclusive: true);
        return;
      } on FileSystemException {
        if (!await guard.exists()) {
          throw const CredentialTransactionUnavailableException();
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }
  }
}
