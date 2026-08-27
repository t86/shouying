import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:session/src/credential_transaction_coordinator.dart';
import 'package:web/web.dart' as web;

CredentialTransactionCoordinator createCredentialTransactionCoordinator() =>
    BrowserCredentialTransactionCoordinator(
      requester: const NavigatorWebLockRequester(),
    );

abstract interface class WebLockRequester {
  bool get isAvailable;

  Future<void> requestExclusive(String name, Future<void> Function() operation);
}

final class NavigatorWebLockRequester implements WebLockRequester {
  const NavigatorWebLockRequester();

  JSObject? get _lockManager {
    if (!globalContext.hasProperty('navigator'.toJS).toDart) return null;
    final navigator = globalContext.getProperty<JSObject>('navigator'.toJS);
    if (!navigator.hasProperty('locks'.toJS).toDart) return null;
    final locks = navigator.getProperty<JSObject>('locks'.toJS);
    return locks.hasProperty('request'.toJS).toDart ? locks : null;
  }

  @override
  bool get isAvailable => _lockManager != null;

  @override
  Future<void> requestExclusive(
    String name,
    Future<void> Function() operation,
  ) async {
    final lockManager = _lockManager;
    if (lockManager == null) {
      throw const CredentialTransactionUnavailableException();
    }
    JSAny? callback(JSAny? lock) => operation().toJS;
    await lockManager
        .callMethod<JSPromise<JSAny?>>(
          'request'.toJS,
          name.toJS,
          web.LockOptions(mode: 'exclusive'),
          callback.toJS,
        )
        .toDart;
  }
}

final class BrowserCredentialTransactionCoordinator
    implements CredentialTransactionCoordinator {
  const BrowserCredentialTransactionCoordinator({required this.requester});

  final WebLockRequester requester;

  @override
  Future<T> synchronized<T>(
    String namespace,
    Future<T> Function() operation,
  ) async {
    if (!requester.isAvailable) {
      throw const CredentialTransactionUnavailableException();
    }
    late T result;
    var completed = false;
    Object? operationError;
    StackTrace? operationStackTrace;
    try {
      await requester.requestExclusive(namespace, () async {
        try {
          result = await operation();
          completed = true;
        } on Object catch (error, stackTrace) {
          operationError = error;
          operationStackTrace = stackTrace;
        }
      });
    } on Object {
      throw const CredentialTransactionUnavailableException();
    }
    if (operationError case final error?) {
      Error.throwWithStackTrace(error, operationStackTrace!);
    }
    if (!completed) {
      throw const CredentialTransactionUnavailableException();
    }
    return result;
  }
}
