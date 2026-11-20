import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:card_table/src/wine_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_inventory_views.dart';
import 'package:card_table/src/wine_borrow_return_views.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

void main() {
  for (final kind in ['expired', 'grid', 'borrow', 'details']) {
    test(
      '$kind export cannot dispatch after reconnect during credentials',
      () async {
        final sessionAdapter = _Adapter();
        final session = SessionRepository(
          api: SessionApi(client: _client(sessionAdapter)),
          credentialStore: _Store(),
        );
        await session.authorizeMachine('machine');
        await session.login(
          account: 'employee',
          password: 'synthetic',
          type: EmployeeLoginType.account,
        );
        final adapter = _Adapter();
        final credentials = _DeferredStore();
        var epoch = 0, saves = 0;
        final loader = SessionBoundWineLoader(
          session: session,
          api: ProtocolWineApi(client: _client(adapter, store: credentials)),
          generation: () => epoch,
          isOnline: () => true,
          saveExport: (_, {bool Function()? canSave}) async {
            saves++;
            return const Success('not written');
          },
        );
        final pending = switch (kind) {
          'expired' => loader.exportWineInvtExpired(),
          'grid' => loader.exportExcelOfGridReport(),
          'borrow' => loader.exportUnreturnedWineList(),
          _ => loader.exportWineDetailList(),
        };
        await credentials.started.future;
        epoch++;
        credentials.ready.complete(
          const CredentialSnapshot(tk: 'synthetic', stk: null),
        );
        expect((await pending).failureOrNull, isNotNull);
        expect(adapter.calls, 0);
        expect(saves, 0);
      },
    );
  }
  for (final invalid in ['wrong system', 'closed session']) {
    test('$invalid blocks Wine export before network or save', () async {
      final adapter = _Adapter()
        ..machineMode = invalid == 'wrong system' ? 4 : 256;
      final client = _client(adapter);
      final session = SessionRepository(
        api: SessionApi(client: client),
        credentialStore: _Store(),
      );
      await session.authorizeMachine('machine');
      await session.login(
        account: 'employee',
        password: 'synthetic',
        type: EmployeeLoginType.account,
      );
      if (invalid == 'closed session') await session.close();
      final before = adapter.calls;
      var saved = false;
      final loader = SessionBoundWineLoader(
        session: session,
        api: ProtocolWineApi(client: client),
        isOnline: () => true,
        generation: () => 0,
        saveExport: (_, {bool Function()? canSave}) async {
          saved = true;
          return const Success('saved');
        },
      );
      final result = await loader.exportWineInvtExpired();
      expect(result.failureOrNull?.code, 'wine.session_required');
      expect(adapter.calls, before);
      expect(saved, isFalse);
    });
  }
  test('reconnected stale export is never saved or acknowledged', () async {
    final adapter = _Adapter();
    final client = _client(adapter);
    final session = SessionRepository(
      api: SessionApi(client: client),
      credentialStore: _Store(),
    );
    await session.authorizeMachine('machine');
    await session.login(
      account: 'employee',
      password: 'synthetic',
      type: EmployeeLoginType.account,
    );
    var epoch = 0;
    var saves = 0;
    final loader = SessionBoundWineLoader(
      session: session,
      api: ProtocolWineApi(client: client),
      generation: () => epoch,
      isOnline: () => true,
      saveExport: (file, {bool Function()? canSave}) async {
        saves++;
        return const Success('saved');
      },
    );
    adapter.binaryGate = Completer<void>();
    final pending = loader.exportWineInvtExpired();
    await Future<void>.delayed(Duration.zero);
    epoch++;
    adapter.binaryGate!.complete();
    expect((await pending).failureOrNull?.code, 'wine.session_changed');
    expect(saves, 0);
    expect(loader.lastExportLocation, isNull);
  });
  test(
    'loader gates offline/session and only succeeds after file saving',
    () async {
      final adapter = _Adapter();
      final client = _client(adapter);
      final session = SessionRepository(
        api: SessionApi(client: client),
        credentialStore: _Store(),
      );
      var online = true;
      var saveFails = true;
      var saves = 0;
      final loader = SessionBoundWineLoader(
        session: session,
        api: ProtocolWineApi(client: client),
        isOnline: () => online,
        saveExport: (file, {bool Function()? canSave}) async {
          saves++;
          expect(file.bytes, [80, 75, 3, 4, 1]);
          return saveFails
              ? const FailureResult(
                  AppFailure(
                    kind: FailureKind.unknown,
                    code: 'save_failed',
                    safeMessage: '保存失败',
                  ),
                )
              : const Success('/downloads/过期.xlsx');
        },
      );
      expect(
        (await loader.exportWineInvtExpired()).failureOrNull?.code,
        'wine.session_required',
      );
      expect(adapter.calls, 0);
      await session.authorizeMachine('machine');
      await session.login(
        account: 'employee',
        password: 'synthetic',
        type: EmployeeLoginType.account,
      );
      online = false;
      final before = adapter.calls;
      expect(
        (await loader.exportWineInvtExpired()).failureOrNull?.code,
        'wine.offline',
      );
      expect(adapter.calls, before);
      expect(saves, 0);
      online = true;
      expect(
        (await loader.exportWineInvtExpired()).failureOrNull?.code,
        'save_failed',
      );
      expect(loader.lastExportLocation, isNull);
      saveFails = false;
      expect((await loader.exportWineInvtExpired()).failureOrNull, isNull);
      expect(loader.lastExportLocation, '/downloads/过期.xlsx');
      expect(saves, 2);
    },
  );
  test(
    'expired export returns binary XLSX with server filename and Wine headers',
    () async {
      final adapter = _Adapter();
      final result = await ProtocolWineApi(client: _client(adapter))
          .exportWineInvtExpired(ClientKind.wine, keyword: '酒', ordType: 2);
      expect(
        adapter.request.uri.path,
        '/server/wine/rpt/exp_wine_invt_expired',
      );
      expect(adapter.request.data, {'key': '酒', 'ord_type': 2});
      expect(adapter.request.responseType, ResponseType.bytes);
      expect(adapter.request.headers['tk'], 'test-tk');
      expect(
        adapter.request.headers['tt'],
        ClientKind.wine.termType.toString(),
      );
      expect(result.failureOrNull, isNull);
      expect((result as dynamic).value.bytes, [80, 75, 3, 4, 1]);
      expect((result as dynamic).value.fileName, '过期.xlsx');
    },
  );
  test('JSON authentication error is not delivered as a spreadsheet', () async {
    final adapter = _Adapter()..jsonError = true;
    final store = _Store();
    final result = await ProtocolWineApi(client: _client(adapter, store: store))
        .exportWineInvtExpired(ClientKind.wine);
    expect(result.failureOrNull?.code, 'authentication.tk_expired');
    expect(store.clearedTk, 'test-tk');
  });
  test('binary responses retain response-size budget', () async {
    final adapter = _Adapter()
      ..payload = List<int>.filled(
        ProtocolResponseLimits.defaultMaxRawResponseBytes + 1,
        80,
      );
    final result = await _client(adapter)
        .postBinary('/wine/export', client: ClientKind.wine);
    expect(result.failureOrNull?.code, 'protocol.response_too_large');
  });
  test('unsafe binary request path is rejected before sending', () async {
    final adapter = _Adapter();
    final result = await _client(adapter)
        .postBinary('https://evil.example/export', client: ClientKind.wine);
    expect(result.failureOrNull?.code, 'protocol.invalid_path');
    expect(adapter.calls, 0);
  });
  test('all four legacy exports use exact paths and request bodies', () async {
    final cases =
        <
          (
            String,
            Map<String, Object?>,
            Future<Object?> Function(ProtocolWineApi),
          )
        >[
          (
            '/wine/exp_wine_invt_grid',
            {'key': ''},
            (api) => api.exportExcelOfGridReport(
              ClientKind.wine,
              keyword: 'ignored',
            ),
          ),
          (
            '/wine/rpt/exp_wine_invt',
            {
              'start_bef_in_day': '2026-01-01',
              'end_bef_in_day': '2026-01-02',
              'expired_day': 3,
              'key': '酒',
            },
            (api) => api.exportWineDetailList(
              ClientKind.wine,
              startTime: '2026-01-01',
              endTime: '2026-01-02',
              daysLeft: 3,
              keyword: '酒',
            ),
          ),
          (
            '/wine/rpt/exp_unreturned_wine_list',
            {'key': '酒'},
            (api) =>
                api.exportUnreturnedWineList(ClientKind.wine, keyword: '酒'),
          ),
          (
            '/wine/exp_wine_borrow_invt_list',
            {},
            (api) => api.exportWineBorrowInvtList(ClientKind.wine),
          ),
        ];
    for (final (path, body, invoke) in cases) {
      final adapter = _Adapter();
      await invoke(ProtocolWineApi(client: _client(adapter)));
      expect(adapter.request.uri.path, '/server$path');
      expect(adapter.request.data, body);
      expect(adapter.request.responseType, ResponseType.bytes);
    }
  });
  test('filename is decoded and cannot traverse download directory', () async {
    final adapter = _Adapter()
      ..disposition = "attachment; filename*=UTF-8''..%2F%E9%85%92.xlsx";
    final result = await _client(adapter)
        .postBinary('/wine/export', client: ClientKind.wine);
    expect(result.valueOrNull!.fileName, '酒.xlsx');
  });
  test('JSON success ack cannot masquerade as a file', () async {
    final adapter = _Adapter()
      ..payload = utf8.encode('{"code":1,"msg":"private"}');
    final result = await _client(adapter)
        .postBinary('/wine/export', client: ClientKind.wine);
    expect(result.failureOrNull?.code, 'protocol.export_rejected');
    expect(result.failureOrNull?.safeMessage, isNot(contains('private')));
  });
  for (final page in ['expired', 'grid', 'unreturned']) {
    for (final failed in [false, true]) {
      testWidgets(
        '$page shows ${failed ? 'save failure' : 'delivery success'} not request acknowledgement',
        (tester) async {
          tester.view.physicalSize = const Size(1800, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final loader = _ScreenLoader(failed);
          final screen = switch (page) {
            'expired' => WinePassTimeView(loader: loader),
            'grid' => WineSaveLibAllDataView(loader: loader),
            _ => WineUnreturnedView(loader: loader),
          };
          await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
          await tester.pumpAndSettle();
          await tester.tap(find.text('导出'));
          await tester.pumpAndSettle();
          expect(loader.exports, 1);
          expect(find.text(failed ? '导出失败: 文件保存失败' : '导出完成'), findsOneWidget);
          expect(find.text('导出指令已下发'), findsNothing);
        },
      );
    }
  }
}

class _ScreenLoader implements WineLoader {
  _ScreenLoader(this.failed);
  final bool failed;
  int exports = 0;
  Future<Result<void>> _export() async {
    exports++;
    return failed
        ? const FailureResult(
            AppFailure(
              kind: FailureKind.unknown,
              code: 'save',
              safeMessage: '文件保存失败',
            ),
          )
        : const Success(null);
  }

  @override
  Future<Result<void>> exportWineInvtExpired({
    String keyword = '',
    int ordType = 1,
  }) => _export();
  @override
  Future<Result<void>> exportExcelOfGridReport({String keyword = ''}) =>
      _export();
  @override
  Future<Result<void>> exportUnreturnedWineList({String keyword = ''}) =>
      _export();
  @override
  Future<Result<List<WineInventoryItem>>> loadPassTimeNeedToLib({
    String keyword = '',
  }) async => const Success([]);
  @override
  Future<Result<List<WineGridItem>>> loadSaveLibGrid({
    String keyword = '',
  }) async => const Success([]);
  @override
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowInvtList({
    String keyword = '',
  }) async => const Success([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProtocolClient _client(_Adapter adapter, {_Store? store}) {
  var now = DateTime.utc(2026);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.example.test/server'),
      onlineBase: Uri.parse('https://online.example.test/server'),
      websocketBase: Uri.parse('wss://socket.example.test/server'),
    ),
    credentialStore: store ?? _Store(),
    requestGate: RequestGate(
      clock: () => now = now.add(const Duration(seconds: 1)),
    ),
  );
}

class _Adapter implements HttpClientAdapter {
  int machineMode = 256;
  Completer<void>? binaryGate;
  late RequestOptions request;
  bool jsonError = false;
  List<int>? payload;
  String disposition = 'attachment; filename=%E8%BF%87%E6%9C%9F.xlsx';
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    calls++;
    if (stream != null) await stream.drain<void>();
    if (options.uri.path.endsWith('/term/auth') ||
        options.uri.path.endsWith('/auth/login')) {
      return ResponseBody.fromString(
        jsonEncode({
          'code': 1,
          'data': options.uri.path.endsWith('/term/auth')
              ? {
                  'id': 'machine',
                  'n': 'Wine',
                  'am': machineMode,
                  'tk': 'test-tk',
                }
              : {'emp_id': 'employee', 'name': 'Test', 'station_id': 'station'},
        }),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    await binaryGate?.future;
    return ResponseBody.fromBytes(
      payload ??
          (jsonError
              ? utf8.encode('{"code":11,"msg":"private"}')
              : [80, 75, 3, 4, 1]),
      200,
      headers: {
        'content-type': [
          jsonError ? 'application/json' : 'application/octet-stream',
        ],
        'content-disposition': [disposition],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _DeferredStore extends _Store {
  final started = Completer<void>();
  final ready = Completer<CredentialSnapshot>();
  @override
  Future<CredentialSnapshot> readSnapshot() {
    if (!started.isCompleted) started.complete();
    return ready.future;
  }
}

class _Store implements CredentialStore {
  String? clearedTk;
  @override
  Future<void> clearStk() async {}
  @override
  Future<void> clearStkIfMatches(String? expected) async {}
  @override
  Future<void> clearTk() async {}
  @override
  Future<void> clearTkIfMatches(String? expected) async {
    clearedTk = expected;
  }

  @override
  Future<String?> readStk() async => null;
  @override
  Future<String?> readTk() async => 'test-tk';
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 'test-tk', stk: null);
  @override
  Future<void> writeStk(String value) async {}
  @override
  Future<void> writeTk(String value) async {}
}
