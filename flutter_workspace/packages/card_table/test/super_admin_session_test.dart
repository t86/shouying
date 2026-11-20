import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/super_admin_api.dart';
import 'package:card_table/src/super_admin_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

const _digest = '098F6BCD4621D373CADE4E832627B4F6';

void main() {
  test('login persists the actual stk without touching ordinary tk', () async {
    final store = _Credentials();
    final adapter = _Adapter();
    final loader = ProtocolSuperAdminLoader(
      api: _api(store, adapter),
      credentials: store,
      session: SessionRepository(
        api: SessionApi(client: _api(store, adapter).client),
        credentialStore: store,
      ),
    );
    expect((await loader.login(md5Password: _digest)).failureOrNull, isNull);
    expect(store.stk, 'admin-token');
    expect(store.tk, 'ordinary-token');
  });
  test('ordinary session does not permit administrator writes', () async {
    final store = _Credentials();
    final adapter = _Adapter();
    final loader = ProtocolSuperAdminLoader(
      api: _api(store, adapter),
      credentials: store,
      session: SessionRepository(
        api: SessionApi(client: _api(store, adapter).client),
        credentialStore: store,
      ),
    );
    expect((await loader.resetEmpPassword(7)).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });

  test(
    'restore authorizes only after online validation; offline never authorizes',
    () async {
      final store = _Credentials()..stk = 'stored-admin';
      final adapter = _Adapter()..hold = Completer<void>();
      final loader = _loader(store, adapter);
      final restoring = loader.restore();
      await _flush();
      expect(loader.isAuthenticated, isFalse);
      adapter.hold!.complete();
      expect((await restoring).failureOrNull, isNull);
      expect(loader.isAuthenticated, isTrue);
      expect(adapter.requests.single.uri.path, '/smgr/emps');
      expect(adapter.requests.single.headers['stk'], 'stored-admin');
      adapter.fail = true;
      expect((await loader.restore()).failureOrNull, isNotNull);
      expect(loader.isAuthenticated, isFalse);
      expect(store.tk, 'ordinary-token');
    },
  );

  test(
    'logout clears local admin token even when remote logout rejects',
    () async {
      final store = _Credentials();
      final adapter = _Adapter();
      final loader = _loader(store, adapter);
      await loader.login(md5Password: _digest);
      final revision = loader.sessionRevision;
      adapter.code = 2;
      expect((await loader.logout()).failureOrNull, isNotNull);
      expect(loader.isAuthenticated, isFalse);
      expect(loader.sessionRevision, revision + 1);
      expect(store.stk, isNull);
      expect(store.tk, 'ordinary-token');
    },
  );

  test(
    'stk expiry invalidates matching admin session and not ordinary tk',
    () async {
      final store = _Credentials();
      final adapter = _Adapter();
      final loader = _loader(store, adapter);
      await loader.login(md5Password: _digest);
      var notifications = 0;
      loader.addListener(() => notifications++);
      adapter.code = 14;
      expect(
        (await loader.loadEmps()).failureOrNull?.code,
        'authentication.stk_expired',
      );
      expect(loader.isAuthenticated, isFalse);
      expect(notifications, greaterThan(0));
      expect(store.stk, isNull);
      expect(store.tk, 'ordinary-token');
    },
  );

  test(
    'logout clears an unverified stored candidate after failed restore',
    () async {
      final store = _Credentials()..stk = 'stored-admin';
      final adapter = _Adapter()..fail = true;
      final loader = _loader(store, adapter);
      expect((await loader.restore()).failureOrNull, isNotNull);
      expect(loader.isAuthenticated, isFalse);
      expect(store.stk, 'stored-admin');
      expect((await loader.logout()).failureOrNull, isNull);
      expect(store.stk, isNull);
      expect(store.tk, 'ordinary-token');
    },
  );

  test('old expired response cannot invalidate a newer admin login', () async {
    final store = _Credentials();
    final adapter = _Adapter();
    final loader = _loader(store, adapter);
    await loader.login(md5Password: _digest);
    adapter
      ..code = 14
      ..hold = Completer<void>()
      ..holdPath = '/smgr/emps';
    final old = loader.loadEmps();
    await _flush();
    adapter
      ..code = 1
      ..loginToken = 'new-admin-token';
    expect((await loader.login(md5Password: _digest)).failureOrNull, isNull);
    adapter.hold!.complete();
    expect((await old).failureOrNull, isNotNull);
    expect(loader.isAuthenticated, isTrue);
    expect(store.stk, 'new-admin-token');
    expect(store.tk, 'ordinary-token');
  });

  test(
    'page closure blocks delayed credential reads before actual transport',
    () async {
      final store = _Credentials();
      final adapter = _Adapter();
      final loader = _loader(store, adapter);
      await loader.login(md5Password: _digest);
      adapter.requests.clear();
      store.holdSnapshot = Completer<void>();
      var open = true;
      final write = loader.resetEmpPassword(7, canDispatch: () => open);
      await _flush();
      open = false;
      store.holdSnapshot!.complete();
      expect((await write).failureOrNull, isNotNull);
      expect(adapter.requests, isEmpty);
      expect(loader.isAuthenticated, isTrue);
    },
  );

  test('relogin blocks old writes waiting for credential headers', () async {
    final store = _Credentials();
    final adapter = _Adapter();
    final loader = _loader(store, adapter);
    await loader.login(md5Password: _digest);
    adapter.requests.clear();
    store.holdSnapshot = Completer<void>();
    final write = loader.toggleStationAdmin(7, true);
    await _flush();
    final login = loader.login(md5Password: _digest);
    store.holdSnapshot!.complete();
    expect((await write).failureOrNull, isNotNull);
    expect((await login).failureOrNull, isNull);
    expect(adapter.requests.map((request) => request.uri.path), [
      '/sauth/login',
    ]);
  });

  test(
    'closing a page during secure persistence removes only its delayed token',
    () async {
      final store = _Credentials()..holdWrite = Completer<void>();
      final adapter = _Adapter();
      final loader = _loader(store, adapter);
      var open = true;
      final login = loader.login(md5Password: _digest, canDispatch: () => open);
      await _flush();
      open = false;
      store.holdWrite!.complete();
      expect((await login).failureOrNull, isNotNull);
      expect(loader.isAuthenticated, isFalse);
      expect(store.stk, isNull);
      expect(store.tk, 'ordinary-token');
    },
  );

  test('disposed loader blocks a delayed write before transport', () async {
    final store = _Credentials();
    final adapter = _Adapter();
    final loader = _loader(store, adapter);
    await loader.login(md5Password: _digest);
    adapter.requests.clear();
    store.holdSnapshot = Completer<void>();
    final write = loader.toggleEmpStatus(7, false);
    await _flush();
    loader.dispose();
    store.holdSnapshot!.complete();
    expect((await write).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });

  test(
    'terminal registration is public and respects page dispatch guard',
    () async {
      final store = _Credentials();
      final adapter = _Adapter();
      final loader = _loader(store, adapter);
      expect(
        (await loader.registerTerminal(
          authCode: 'code',
          machineCode: 'machine',
        )).valueOrNull?.authMode,
        8,
      );
      expect(loader.isAuthenticated, isFalse);
      expect(store.stk, isNull);
      adapter.requests.clear();
      expect(
        (await loader.registerTerminal(
          authCode: 'code',
          machineCode: 'machine',
          canDispatch: () => false,
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
    },
  );
}

Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProtocolSuperAdminLoader _loader(_Credentials store, _Adapter adapter) =>
    ProtocolSuperAdminLoader(api: _api(store, adapter), credentials: store);

class _Credentials implements CredentialStore {
  String? tk = 'ordinary-token';
  String? stk;
  Completer<void>? holdSnapshot;
  Completer<void>? holdWrite;
  int snapshotReads = 0;
  @override
  Future<CredentialSnapshot> readSnapshot() async {
    snapshotReads++;
    await holdSnapshot?.future;
    return CredentialSnapshot(tk: tk, stk: stk);
  }

  @override
  Future<String?> readTk() async => tk;
  @override
  Future<String?> readStk() async => stk;
  @override
  Future<void> writeTk(String value) async => tk = value;
  @override
  Future<void> writeStk(String value) async {
    await holdWrite?.future;
    stk = value;
  }

  @override
  Future<void> clearTk() async => tk = null;
  @override
  Future<void> clearStk() async => stk = null;
  @override
  Future<void> clearTkIfMatches(String? expected) async {
    if (tk == expected) tk = null;
  }

  @override
  Future<void> clearStkIfMatches(String? expected) async {
    if (stk == expected) stk = null;
  }
}

ProtocolSuperAdminApi _api(_Credentials store, _Adapter adapter) {
  var tick = DateTime(2026);
  return ProtocolSuperAdminApi(
    client: ProtocolClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: ApiConfig(
        apiBase: Uri.parse('https://api.test'),
        onlineBase: Uri.parse('https://online.test'),
        websocketBase: Uri.parse('wss://api.test'),
      ),
      credentialStore: store,
      requestGate: RequestGate(
        clock: () => tick = tick.add(const Duration(milliseconds: 2)),
      ),
    ),
  );
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int code = 1;
  bool fail = false;
  String loginToken = 'admin-token';
  Completer<void>? hold;
  String? holdPath;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final responseCode = code;
    final token = loginToken;
    if (holdPath == null || options.uri.path == holdPath) await hold?.future;
    if (fail) throw DioException(requestOptions: options);
    return ResponseBody.fromString(
      jsonEncode({
        'code': responseCode,
        'data': options.uri.path == '/sauth/login'
            ? token
            : options.uri.path == '/register/machine'
            ? {'auth_mode': 8}
            : {'depts': [], 'stations': [], 'station_emps': []},
      }),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
