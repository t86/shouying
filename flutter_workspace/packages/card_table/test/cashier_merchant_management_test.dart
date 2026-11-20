import 'package:card_table/src/cashier_merchant_management.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:dio/dio.dart';

import 'dart:async';

import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi, Credentials;
import 'bms_loader_guard_test.dart' show loginSession;

void main() {
  test(
    'in-flight merchant write blocks concurrent writes and verification',
    () async {
      final login = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(login).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, login, 8);
      final adapter = Adapter(),
          entered = Completer<void>(),
          release = Completer<void>();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            entered.complete();
            await release.future;
            handler.next(options);
          },
        ),
      );
      final api = ProtocolCashierMerchantManagementApi(
        client: ProtocolClient(
          dio: dio,
          config: ApiConfig(
            apiBase: Uri.parse('https://api.test'),
            onlineBase: Uri.parse('https://online.test'),
            websocketBase: Uri.parse('wss://api.test'),
          ),
          credentialStore: Credentials(),
          requestGate: RequestGate(clock: DateTime.now),
        ),
      );
      final loader = SessionBoundCashierMerchantManagementLoader(
        session: session,
        api: api,
        phase: () => ConnectionPhase.online,
        generation: () => 1,
      );
      final first = loader.setOnline(2, false, () => true);
      await entered.future;
      expect((await loader.cancelSwitch(() => true)).failureOrNull, isNotNull);
      expect((await loader.verify(() => true)).failureOrNull, isNotNull);
      expect(adapter.requests, isEmpty);
      release.complete();
      expect((await first).failureOrNull, isNull);
      expect(loader.needsVerification, false);
      expect(adapter.requests.length, 1);
    },
  );
  for (final operation in ['config', 'switch', 'groups']) {
    test(
      'explicit verification for $operation must read the matching successful server state',
      () async {
        final login = Adapter();
        final session = SessionRepository(
          api: SessionApi(client: makeApi(login).client),
          credentialStore: Credentials(),
        );
        await loginSession(session, login, 8);
        final adapter = Adapter();
        var rejectRead = false;
        var tick = DateTime(2026);
        final expected = operation == 'config'
            ? '/sel/get_cnl_cfg'
            : operation == 'switch'
            ? '/sel/get_wkday_cnl_switch'
            : '/org/get_cnl_cfg_grp';
        adapter.onFetch = () {
          final path = adapter.requests.last.uri.path;
          if (path.contains('/save_') || path.contains('/enable_'))
            throw StateError('uncertain write');
          adapter.code = rejectRead ? 2 : 1;
          adapter.data = path == '/sel/get_cnl_cfg'
              ? {
                  'e_s': 2,
                  'max_amt': 0,
                  'dest_cnl_cfg_id': 0,
                  'def_cnl_cfg_id': 2,
                }
              : path == '/sel/get_wkday_cnl_switch'
              ? {'enabled': 2, 'id': 0, 'cnl_cfgs': []}
              : <String, Object?>{};
        };
        final client = ProtocolClient(
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
        );
        final loader = SessionBoundCashierMerchantManagementLoader(
          session: session,
          api: ProtocolCashierMerchantManagementApi(client: client),
          phase: () => ConnectionPhase.online,
          generation: () => 1,
        );
        if (operation == 'config') {
          await loader.saveConfig(
            CashierMerchantConfigDraft(
              entityId: 7,
              defaultMerchantId: 2,
              switchEnabled: false,
              maxAmount: 0,
              targetMerchantId: 0,
              seatMerchants: const {},
              hours: [
                for (var h = 0; h < 24; h++)
                  CashierMerchantHourRule(hour: h, maxAmount: 0, merchantId: 0),
              ],
            ),
            () => true,
          );
        } else if (operation == 'switch') {
          await loader.enableSwitch(2, () => true);
        } else {
          await loader.setOnline(2, false, () => true);
        }
        expect(loader.needsVerification, true);
        await loader.groups();
        expect(loader.needsVerification, true);
        final before = adapter.requests.length;
        expect((await loader.verify(() => false)).failureOrNull, isNotNull);
        expect(adapter.requests.length, before);
        rejectRead = true;
        expect((await loader.verify(() => true)).failureOrNull, isNotNull);
        expect(loader.needsVerification, true);
        expect(adapter.requests.last.uri.path, expected);
        rejectRead = false;
        expect((await loader.verify(() => true)).failureOrNull, isNull);
        expect(loader.needsVerification, false);
        expect(adapter.requests.last.uri.path, expected);
        if (operation == 'config')
          expect(adapter.requests.last.data, {'cnl_cfg_id': 7});
      },
    );
  }
  test(
    'unknown merchant write remains blocked across ordinary reloads',
    () async {
      final login = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(login).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, login, 8);
      final adapter = Adapter()..data = <String, Object?>{};
      adapter.onFetch = () {
        if (adapter.requests.last.uri.path == '/org/save_cnl_cfg_openclose')
          throw StateError('synthetic transport failure');
      };
      var tick = DateTime(2026);
      final client = ProtocolClient(
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
      );
      final loader = SessionBoundCashierMerchantManagementLoader(
        session: session,
        api: ProtocolCashierMerchantManagementApi(client: client),
        phase: () => ConnectionPhase.online,
        generation: () => 1,
      );
      expect(
        (await loader.setOnline(2, false, () => true)).failureOrNull,
        isNotNull,
      );
      expect((await loader.groups()).failureOrNull, isNull);
      await loader.setOnline(2, false, () => true);
      expect(
        adapter.requests
            .where((r) => r.uri.path == '/org/save_cnl_cfg_openclose')
            .length,
        1,
      );
    },
  );
  test('signed integer thresholds from legacy config remain readable and retain signs on save', () async {
    final adapter = Adapter()
      ..data = {
        'e_s': 1,
        'max_amt': -123,
        'dest_cnl_cfg_id': 2,
        'def_cnl_cfg_id': 2,
        'cnl_cfgs': [
          {'id': 2, 'n': '私', 'gs': 2},
        ],
        'hour_cfgs': [
          {'h': 12, 'm': -45, 'c': 2},
        ],
      };
    final api = ProtocolCashierMerchantManagementApi(
      client: makeApi(adapter).client,
    );
    final result = await api.config(ClientKind.cashier, 0);
    expect(result.failureOrNull, isNull);
    final config = result.valueOrNull!;
    expect(config.maxAmount, -123);
    expect(config.hours[12].maxAmount, -45);
    final draft = CashierMerchantConfigDraft(
      entityId: 0,
      defaultMerchantId: 2,
      switchEnabled: true,
      maxAmount: config.maxAmount,
      targetMerchantId: 2,
      seatMerchants: const {},
      hours: config.hours,
    );
    expect(
      (await api.saveConfig(
        ClientKind.cashier,
        draft,
        () => true,
      )).failureOrNull,
      isNull,
    );
    final body = adapter.requests.last.data as Map;
    expect(body['max_amt'], -123);
    expect((body['hour_max_amts'] as List).first, -45);
  });
  test(
    'fractional thresholds are not silently truncated while parsing config',
    () async {
      for (final value in [1.5, '1.5']) {
        final adapter = Adapter()
          ..data = {
            'e_s': 1,
            'max_amt': value,
            'dest_cnl_cfg_id': 2,
            'def_cnl_cfg_id': 2,
          };
        expect(
          (await ProtocolCashierMerchantManagementApi(
            client: makeApi(adapter).client,
          ).config(ClientKind.cashier, 0)).failureOrNull,
          isNotNull,
        );
      }
    },
  );
  test('empty primary holder and bank fields fall back like the source display helper', () {
    final merchant = CashierMerchant.fromWire({
      'id': 2,
      'n': '商户',
      'g': 2,
      'un': '',
      'u': '持卡人',
      'bn': '',
      'no': '62220001',
    });
    expect(merchant.holder, '持卡人');
    expect(merchant.bank, '62220001');
  });
  test('duplicate merchant IDs are rejected before ambiguous financial selectors render', () async {
    final adapter = Adapter()
      ..data = {
        'cnl_cfg_def': [
          {'id': 1, 'n': '商户A', 'g': 1},
          {'id': 1, 'n': '商户B', 'g': 2},
        ],
      };
    expect(
      (await ProtocolCashierMerchantManagementApi(
        client: makeApi(adapter).client,
      ).groups(ClientKind.cashier)).failureOrNull,
      isNotNull,
    );
  });
  test(
    'online closed aliases preserve per-entity precedence and single scope',
    () {
      for (final alias in [
        'closed_cnl_cfg_ids',
        'close_cnl_cfg_ids',
        'close_cnls',
        'close_cnl_ids',
        'closed_cnl_ids',
      ]) {
        final group = CashierMerchantGroups.fromWire({
          'cnl_cfg_def': [
            {'id': 1, 'n': '公', 'g': 1},
            {'id': 2, 'n': '私', 'g': 2},
            {'id': 3, 'n': '其他私', 'g': 2},
          ],
          alias: [3],
          'cnl_cfg_grps': [
            {
              'id': 1,
              'sids': [2],
              'rs': [11],
              'd': 1,
              alias: [2],
            },
          ],
        });
        expect(group.closedFor(1), {2});
        expect(group.closedFor(0), {3});
        expect(group.onlineMerchants(1).map((m) => m.id), [1, 2]);
        expect(group.onlineMerchants(0).length, 3);
      }
    },
  );
  test(
    'single entity config reads empty map and normalizes sparse hour defaults',
    () async {
      final adapter = Adapter()
        ..data = {
          'e_s': 2,
          'max_amt': 0,
          'dest_cnl_cfg_id': 0,
          'def_cnl_cfg_id': 2,
          'cnl_cfgs': [
            {'id': 2, 'n': '私', 'gs': 2},
          ],
          'hour_cfgs': [
            {'h': 12, 'm': 123, 'c': 2},
          ],
        };
      final result = await ProtocolCashierMerchantManagementApi(
        client: makeApi(adapter).client,
      ).config(ClientKind.cashier, 0);
      expect(adapter.requests.single.data, {});
      expect(result.valueOrNull!.hours.length, 24);
      expect(result.valueOrNull!.hours[12].maxAmount, 123);
      expect(result.valueOrNull!.hours[0].merchantId, 0);
    },
  );
  test('manual cancel preserves absent body and checks actual session before transport', () async {
    final login = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(login).client),
      credentialStore: Credentials(),
    );
    await loginSession(session, login, 8);
    var epoch = 1;
    final adapter = Adapter();
    final loader = SessionBoundCashierMerchantManagementLoader(
      session: session,
      api: ProtocolCashierMerchantManagementApi(
        client: makeApi(adapter).client,
      ),
      phase: () => ConnectionPhase.online,
      generation: () => epoch,
    );
    final pending = loader.cancelSwitch(() => true);
    epoch++;
    expect((await pending).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
    final sent = Adapter();
    expect(
      (await ProtocolCashierMerchantManagementApi(
        client: makeApi(sent).client,
      ).cancelSwitch(ClientKind.cashier, () => true)).failureOrNull,
      isNull,
    );
    expect(sent.requests.single.uri.path, '/sel/cancel_wkday_cnl_switch');
    expect(sent.requests.single.data, isNull);
  });
  test(
    'wrong client and unsafe IDs never issue configuration requests',
    () async {
      final adapter = Adapter();
      final api = ProtocolCashierMerchantManagementApi(
        client: makeApi(adapter).client,
      );
      expect((await api.groups(ClientKind.order)).failureOrNull, isNotNull);
      expect(
        (await api.config(ClientKind.cashier, -1)).failureOrNull,
        isNotNull,
      );
      expect((await api.hours(ClientKind.cashier, 0)).failureOrNull, isNotNull);
      expect(
        (await api.setOnline(
          ClientKind.cashier,
          0,
          true,
          () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
    },
  );
  test(
    'entity config uses integer yuan and exact source aligned arrays',
    () async {
      final adapter = Adapter();
      final api = ProtocolCashierMerchantManagementApi(
        client: makeApi(adapter).client,
      );
      final result = await api.saveConfig(
        ClientKind.cashier,
        CashierMerchantConfigDraft(
          entityId: 1,
          defaultMerchantId: 2,
          switchEnabled: true,
          maxAmount: 123,
          targetMerchantId: 2,
          seatMerchants: {7: 2},
          hours: [
            for (var i = 0; i < 24; i++)
              CashierMerchantHourRule(hour: i, maxAmount: i, merchantId: 2),
          ],
        ),
        () => true,
      );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.uri.path, '/sel/save_cnl_cfg');
      final body = adapter.requests.single.data as Map;
      expect(body.keys.toSet(), {
        'cnl_cfg_id',
        'def_cnl_cfg_id',
        'enable_switch',
        'max_amt',
        'dest_cnl_cfg_id',
        'seat_ids',
        'seat_cnl_ids',
        'hour_ids',
        'hour_max_amts',
        'hour_cnl_cfg_ids',
      });
      expect(body['max_amt'], 123);
      expect(body['seat_ids'], [7]);
      expect(body['seat_cnl_ids'], [2]);
      expect(body['hour_ids'], [
        for (var i = 12; i < 24; i++) i,
        for (var i = 0; i < 12; i++) i,
      ]);
    },
  );
  test(
    'group save and online switch use exact independent source contracts',
    () async {
      final adapter = Adapter();
      final api = ProtocolCashierMerchantManagementApi(
        client: makeApi(adapter).client,
      );
      expect(
        (await api.saveGroups(
          ClientKind.cashier,
          const CashierMerchantGroupsDraft(
            entityIds: [1, 2],
            defaultEntityId: 2,
            privateIdsByEntity: {
              1: [3],
              2: [4],
            },
            regionIdsByEntity: {
              1: [11],
              2: [12],
            },
          ),
          () => true,
        )).failureOrNull,
        isNull,
      );
      expect(adapter.requests.single.uri.path, '/org/save_cnl_cfg_grp');
      expect(adapter.requests.single.data, {
        'cnl_cfg_id1': 1,
        'cnl_cfg_id2': 2,
        'def_cnl_cfg_id': 2,
        's_cfg_ids_1': [3],
        's_cfg_ids_2': [4],
        'region_ids_1': [11],
        'region_ids_2': [12],
      });
      expect(
        (await api.setOnline(
          ClientKind.cashier,
          3,
          false,
          () => true,
        )).failureOrNull,
        isNull,
      );
      expect(adapter.requests.last.data, {'cnl_cfg_id': 3, 'close': 1});
    },
  );
  test('business failure and conflicting global ownership are not successful writes', () async {
    final adapter = Adapter()..code = 2;
    final api = ProtocolCashierMerchantManagementApi(
      client: makeApi(adapter).client,
    );
    expect(
      (await api.enableSwitch(ClientKind.cashier, 2, () => true)).failureOrNull,
      isNotNull,
    );
    final before = adapter.requests.length;
    expect(
      (await api.saveGroups(
        ClientKind.cashier,
        const CashierMerchantGroupsDraft(
          entityIds: [1, 2],
          defaultEntityId: 1,
          privateIdsByEntity: {
            1: [3],
            2: [3],
          },
          regionIdsByEntity: {
            1: [11],
            2: [12],
          },
        ),
        () => true,
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests.length, before);
  });
}
