import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/account_passwords.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

void main() {
  for (final flag in [null, 2, 'unexpected']) {
    test('unknown auth-password flag $flag is not a disabled state', () async {
      final result = await ProtocolAccountPasswordApi(
        client: _client(
          _Adapter([
            _ok({'enabled': flag}),
          ]),
        ),
      ).authPasswordEnabled(ClientKind.order);
      expect(result.failureOrNull?.code, 'protocol.account_password_shape');
    });
  }
  test(
    'changes login password with uppercase md5 and never leaks secrets',
    () async {
      final adapter = _Adapter([_ok(<String, Object?>{})]);
      final result = await ProtocolAccountPasswordApi(client: _client(adapter))
          .changePassword(
            ClientKind.order,
            oldPassword: '123456',
            newPassword: '654321',
          );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.uri.path, '/server/emp/chg_pwd');
      expect(adapter.requests.single.data, {
        'old_password': md5
            .convert(utf8.encode('123456'))
            .toString()
            .toUpperCase(),
        'new_password': md5
            .convert(utf8.encode('654321'))
            .toString()
            .toUpperCase(),
      });
      expect(result.toString(), isNot(contains('123456')));
      expect(result.toString(), isNot(contains('654321')));
    },
  );

  test('rejects a private change-password body', () async {
    final failure =
        (await ProtocolAccountPasswordApi(
              client: _client(
                _Adapter([
                  {'code': 2, 'msg': 'private old password 123456'},
                ]),
              ),
            ).changePassword(
              ClientKind.order,
              oldPassword: '123456',
              newPassword: '654321',
            ))
            .failureOrNull!;
    expect(failure.kind, FailureKind.business);
    expect(failure.safeMessage, isNot(contains('123456')));
    expect(failure.safeMessage, isNot(contains('private')));
  });

  test('loads auth-password enabled flag without a body', () async {
    final adapter = _Adapter([
      _ok({'enabled': 1}),
    ]);
    final enabled = (await ProtocolAccountPasswordApi(
      client: _client(adapter),
    ).authPasswordEnabled(ClientKind.order)).valueOrNull!;
    expect(adapter.requests.single.method, 'POST');
    expect(
      adapter.requests.single.uri.path,
      '/server/emp/get_auth_pwd_enabled',
    );
    expect(adapter.requests.single.data, isNull);
    expect(enabled, isTrue);
  });

  test('saves auth password hashes or empty strings when disabled', () async {
    final adapter = _Adapter([
      _ok(<String, Object?>{}),
      _ok(<String, Object?>{}),
    ]);
    final api = ProtocolAccountPasswordApi(client: _client(adapter));
    await api.changeAuthPassword(
      ClientKind.order,
      enabled: true,
      loginPassword: '123456',
      authPassword: '111111',
    );
    await api.changeAuthPassword(
      ClientKind.order,
      enabled: false,
      loginPassword: '123456',
      authPassword: '111111',
    );
    expect(adapter.requests[0].uri.path, '/server/emp/chg_auth_pwd');
    expect(adapter.requests[0].data, {
      'login_password': md5
          .convert(utf8.encode('123456'))
          .toString()
          .toUpperCase(),
      'auth_password': md5
          .convert(utf8.encode('111111'))
          .toString()
          .toUpperCase(),
    });
    expect(adapter.requests[1].data, {
      'login_password': '',
      'auth_password': '',
    });
  });
}

Map<String, Object?> _ok(Map<String, Object?> data) => {
  'code': 1,
  'data': data,
};

ProtocolClient _client(_Adapter adapter) {
  var now = DateTime.utc(2026, 9, 8);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.example.test/server'),
      onlineBase: Uri.parse('https://online.example.test/server'),
      websocketBase: Uri.parse('wss://socket.example.test/server'),
    ),
    credentialStore: _CredentialStore(),
    requestGate: RequestGate(
      clock: () {
        now = now.add(const Duration(milliseconds: 101));
        return now;
      },
    ),
  );
}

final class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);
  final List<Object?> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(
      jsonEncode(responses.removeAt(0)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _CredentialStore implements CredentialStore {
  @override
  Future<void> clearStk() async {}
  @override
  Future<void> clearStkIfMatches(String? expected) async {}
  @override
  Future<void> clearTk() async {}
  @override
  Future<void> clearTkIfMatches(String? expected) async {}
  @override
  Future<String?> readStk() async => null;
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 'test-tk', stk: null);
  @override
  Future<String?> readTk() async => 'test-tk';
  @override
  Future<void> writeStk(String value) async {}
  @override
  Future<void> writeTk(String value) async {}
}
