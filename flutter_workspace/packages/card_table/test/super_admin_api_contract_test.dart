import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/super_admin_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Credentials;

const digest = '098F6BCD4621D373CADE4E832627B4F6';

void main() {
  test(
    'integral numeric business code remains compatible with Vue equality',
    () async {
      expect(
        (await _make(_Adapter({'code': 1.0, 'data': 'token'}))
                .login(md5Password: digest))
            .valueOrNull
            ?.token,
        'token',
      );
      expect(
        (await _make(_Adapter({'code': 1.5, 'data': 'token'}))
                .login(md5Password: digest))
            .failureOrNull,
        isNotNull,
      );
    },
  );
  for (final operation in [
    'login',
    'logout',
    'password',
    'list',
    'station',
    'grant',
    'revoke',
    'reset',
    'enable',
    'disable',
    'register',
  ]) {
    test(
      '$operation rejects server business failure rather than HTTP success',
      () async {
        final adapter = _Adapter({
          'code': 2,
          'data': {'auth_mode': 8},
          'msg': 'server-private',
        });
        final api = _make(adapter);
        final result = await switch (operation) {
          'login' => api.login(md5Password: digest),
          'logout' => api.logout(),
          'password' => api.changePassword(
            oldPassword: 'test',
            newPassword: 'abc',
          ),
          'list' => api.loadEmps(),
          'station' => api.setStationEnable(1),
          'grant' => api.grantStationAdmin(1),
          'revoke' => api.revokeStationAdmin(1),
          'reset' => api.resetEmpPassword(1),
          'enable' => api.setEmpEnable(1),
          'disable' => api.setEmpDisable(1),
          _ => api.registerTerminal(authCode: 'code', machineCode: 'machine'),
        };
        expect(result.failureOrNull, isNotNull);
        expect(
          result.failureOrNull!.safeMessage,
          isNot(contains('server-private')),
        );
      },
    );
  }
  test(
    'password change hashes original strings once using source field names',
    () async {
      final adapter = _Adapter({'code': 1});
      expect(
        (await _make(adapter).changePassword(
          oldPassword: 'test',
          newPassword: 'abc',
        )).failureOrNull,
        isNull,
      );
      expect(adapter.requests.single.uri.path, '/smgr/chgpwd');
      expect(adapter.requests.single.data, {
        'old_password': digest,
        'new_password': '900150983CD24FB0D6963F7D28E17F72',
      });
    },
  );
  test('source password change permits either nonempty input and hashes empty once', () async {
    final adapter = _Adapter({'code': 1});
    final api = _make(adapter);
    expect(
      (await api.changePassword(
        oldPassword: '',
        newPassword: '',
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
    expect(
      (await api.changePassword(
        oldPassword: '',
        newPassword: 'abc',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.single.data, {
      'old_password': 'D41D8CD98F00B204E9800998ECF8427E',
      'new_password': '900150983CD24FB0D6963F7D28E17F72',
    });
  });
  test('list selection sends numeric station id and preserves initialization contract', () async {
    final adapter = _Adapter({
      'code': 1,
      'data': {'depts': [], 'stations': [], 'station_emps': []},
    });
    expect(
      (await _make(adapter).loadEmps(
        isInit: 1,
        deptId: 4,
        stationId: '23',
        name: '张三',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.single.data, {
      'is_init': 1,
      'dept_id': 4,
      'station_id': 23,
      'name': '张三',
    });
  });
  test('invalid selections and mutation IDs never send a request', () async {
    final adapter = _Adapter({'code': 1});
    final api = _make(adapter);
    for (final station in ['0', '-1', 'x', '1.5', ' 1']) {
      expect((await api.loadEmps(stationId: station)).failureOrNull, isNotNull);
    }
    expect((await api.loadEmps(isInit: 0)).failureOrNull, isNotNull);
    expect((await api.loadEmps(deptId: -1)).failureOrNull, isNotNull);
    expect((await api.setStationEnable(0)).failureOrNull, isNotNull);
    expect((await api.grantStationAdmin(-1)).failureOrNull, isNotNull);
    expect((await api.revokeStationAdmin(0)).failureOrNull, isNotNull);
    expect((await api.resetEmpPassword(0)).failureOrNull, isNotNull);
    expect((await api.setEmpEnable(-1)).failureOrNull, isNotNull);
    expect((await api.setEmpDisable(0)).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });
  test(
    'login accepts only nonempty real token data; malformed envelopes fail',
    () async {
      for (final data in [null, '', ' ', {}, [], 123]) {
        final result = await _make(_Adapter({'code': 1, 'data': data}))
            .login(md5Password: digest);
        expect(result.failureOrNull, isNotNull);
      }
      for (final code in [null, true, {}, 'wrong']) {
        expect(
          (await _make(_Adapter({'code': code, 'data': 'token'}))
                  .login(md5Password: digest))
              .failureOrNull,
          isNotNull,
        );
      }
      expect(
        (await _make(_Adapter({'code': 1, 'data': 'token'}))
                .login(md5Password: digest))
            .valueOrNull!
            .token,
        'token',
      );
    },
  );
  test(
    'malformed employee identity cannot become actionable id zero',
    () async {
      for (final data in [
        [],
        {
          'station_emps': [false],
        },
        {
          'station_emps': [
            {'id': 0, 'n': '岗位', 'c': 1, 's': '有效', 'a': 1},
          ],
        },
        {
          'station_emps': [
            {
              'id': 1,
              'n': '岗位',
              'c': 1,
              's': '有效',
              'a': 1,
              'es': [
                {'n': '无ID'},
              ],
            },
          ],
        },
        {
          'stations': {'id': 1},
        },
      ]) {
        expect(
          (await _make(
            _Adapter({'code': 1, 'data': data}),
          ).loadEmps()).failureOrNull,
          isNotNull,
        );
      }
    },
  );
  test('registration validates mode and inputs without assuming a mode on malformed data', () async {
    for (final mode in [null, false, -1, 1.5, 'wrong']) {
      expect(
        (await _make(
              _Adapter({
                'code': 1,
                'data': {'auth_mode': mode},
              }),
            ).registerTerminal(authCode: 'code', machineCode: 'machine'))
            .failureOrNull,
        isNotNull,
      );
    }
    final adapter = _Adapter({
      'code': 1,
      'data': {'auth_mode': 8},
    });
    final api = _make(adapter);
    expect(
      (await api.registerTerminal(
        authCode: '',
        machineCode: 'machine',
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
    expect(
      (await api.registerTerminal(
        authCode: 'code',
        machineCode: 'machine',
      )).valueOrNull!.authMode,
      8,
    );
    expect(adapter.requests.single.data, {
      'auth_code': 'code',
      'machine_code': 'machine',
      'remark': '',
    });
  });
}

ProtocolSuperAdminApi _make(_Adapter adapter) {
  var tick = DateTime(2026);
  return ProtocolSuperAdminApi(
    client: ProtocolClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: ApiConfig(
        apiBase: Uri.parse('https://api.test'),
        onlineBase: Uri.parse('https://online.test'),
        websocketBase: Uri.parse('wss://api.test'),
      ),
      credentialStore: Credentials(),
      requestGate: RequestGate(
        clock: () => tick = tick.add(const Duration(milliseconds: 2)),
      ),
    ),
  );
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.response);
  final Map<String, Object?> response;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    if (stream != null) await stream.drain<void>();
    return ResponseBody.fromString(jsonEncode(response), 200);
  }

  @override
  void close({bool force = false}) {}
}
