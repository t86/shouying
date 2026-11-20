import 'dart:io';
import 'dart:async';

import 'package:card_table/src/wine_export_saver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final stage in ['directory', 'write']) {
    test(
      'invalidated export cleans its own artifact after delayed $stage',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'export-boundary-test-',
        );
        addTearDown(() => root.delete(recursive: true));
        const channel = MethodChannel('plugins.flutter.io/path_provider');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (_) async => root.path);
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null),
        );
        final entered = Completer<void>(), release = Completer<void>();
        final real = _NativeIO();
        var allowed = true;
        final pending = IOOverrides.runZoned(
          () => saveWineExport(
            ProtocolBinaryFile(bytes: [80, 75, 3, 4], fileName: 'test.xlsx'),
            canSave: () => allowed,
          ),
          createDirectory: (path) => stage == 'directory'
              ? _DelayedDirectory(real.createDirectory(path), entered, release)
              : real.createDirectory(path),
          createFile: (path) => stage == 'write'
              ? _DelayedFile(real.createFile(path), entered, release)
              : real.createFile(path),
        );
        await entered.future;
        allowed = false;
        release.complete();
        expect((await pending).failureOrNull?.code, 'export.context_changed');
        expect(await root.list(recursive: true).toList(), isEmpty);
      },
    );
  }
  test(
    'session change while locating downloads never writes an old export',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'export-scope-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final entered = Completer<void>(), release = Completer<String>();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) {
            entered.complete();
            return release.future;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      var allowed = true;
      final pending = saveWineExport(
        ProtocolBinaryFile(bytes: [80, 75, 3, 4, 1], fileName: '旧账号报表.xlsx'),
        canSave: () => allowed,
      );
      await entered.future;
      allowed = false;
      release.complete(directory.path);
      expect((await pending).failureOrNull, isNotNull);
      expect(await directory.list(recursive: true).toList(), isEmpty);
    },
  );
  test(
    'native delivery writes bytes and preserves previous same-name export',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'wine-export-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => directory.path);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final file = ProtocolBinaryFile(
        bytes: [80, 75, 3, 4, 1],
        fileName: '库存.xlsx',
      );
      final first = await saveWineExport(file);
      final second = await saveWineExport(file);
      expect(first.failureOrNull, isNull);
      expect(second.failureOrNull, isNull);
      expect(first.valueOrNull, isNot(second.valueOrNull));
      expect(await File(first.valueOrNull!).readAsBytes(), file.bytes);
      expect(await File(second.valueOrNull!).readAsBytes(), file.bytes);
    },
  );
  test('unavailable native downloads returns safe save error', () async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final result = await saveWineExport(
      ProtocolBinaryFile(bytes: [80, 75, 3, 4], fileName: '库存.xlsx'),
    );
    expect(result.failureOrNull?.code, 'wine.export_save_failed');
  });
}

final class _NativeIO extends IOOverrides {}

class _DelayedDirectory implements Directory {
  _DelayedDirectory(this.delegate, this.entered, this.release);
  final Directory delegate;
  final Completer<void> entered, release;
  @override
  String get path => delegate.path;
  @override
  Future<Directory> create({bool recursive = false}) =>
      delegate.create(recursive: recursive);
  @override
  Future<Directory> createTemp([String? prefix]) async {
    final result = await delegate.createTemp(prefix);
    entered.complete();
    await release.future;
    return result;
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      delegate.delete(recursive: recursive);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected directory operation');
}

class _DelayedFile implements File {
  _DelayedFile(this.delegate, this.entered, this.release);
  final File delegate;
  final Completer<void> entered, release;
  @override
  String get path => delegate.path;
  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    final result = await delegate.writeAsBytes(bytes, mode: mode, flush: flush);
    entered.complete();
    await release.future;
    return result;
  }

  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      delegate.delete(recursive: recursive);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected file operation');
}
