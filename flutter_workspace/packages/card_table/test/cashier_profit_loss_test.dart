import 'package:card_table/src/cashier_profit_loss.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:dio/dio.dart';

import 'dart:typed_data';

import 'package:session/session.dart';
import 'package:foundation/foundation.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi, Credentials;
import 'bms_loader_guard_test.dart' show loginSession;

void main() {
  test(
    'fractional and non-finite codes never report successful stock writes',
    () async {
      for (final raw in ['1.5', 'NaN', 'Infinity']) {
        final api = ProtocolCashierProfitLossApi(
          client: ProtocolClient(
            dio: Dio()..httpClientAdapter = _DoubleCodeAdapter(raw),
            config: ApiConfig(
              apiBase: Uri.parse('https://api.test'),
              onlineBase: Uri.parse('https://online.test'),
              websocketBase: Uri.parse('wss://api.test'),
            ),
            credentialStore: Credentials(),
            requestGate: RequestGate(clock: DateTime.now),
          ),
        );
        expect(
          (await api.submit(
            ClientKind.cashier,
            const CashierProfitLossDraft(
              libraryId: '1',
              entries: [
                CashierProfitLossEntry(productId: '7', profit: 0, loss: 0),
              ],
            ),
          )).failureOrNull,
          isNotNull,
        );
      }
    },
  );
  for (final write in [false, true]) {
    test(
      'integral double success code supports ${write ? 'submission' : 'records'}',
      () async {
        final dio = Dio()..httpClientAdapter = _DoubleCodeAdapter('1.0');
        final api = ProtocolCashierProfitLossApi(
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
        final result = write
            ? await api.submit(
                ClientKind.cashier,
                const CashierProfitLossDraft(
                  libraryId: '1',
                  entries: [
                    CashierProfitLossEntry(productId: '7', profit: 0, loss: 0),
                  ],
                ),
              )
            : await api.load(ClientKind.cashier);
        expect(result.failureOrNull, isNull);
      },
    );
  }
  test('session generation change while credentials prepare prevents transport dispatch', () async {
    final sessionAdapter = Adapter(), adapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    await loginSession(session, sessionAdapter, 8);
    var epoch = 1;
    final loader = SessionBoundCashierProfitLossLoader(
      session: session,
      api: ProtocolCashierProfitLossApi(client: makeApi(adapter).client),
      phase: () => ConnectionPhase.online,
      generation: () => epoch,
    );
    final pending = loader.submit(
      const CashierProfitLossDraft(
        libraryId: '1',
        entries: [CashierProfitLossEntry(productId: '7', profit: 1, loss: 0)],
      ),
      () => true,
    );
    epoch++;
    expect((await pending).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });
  test('session loader rejects absent session, UI cancellation and late generation', () async {
    final sessionAdapter = Adapter(), adapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    var phase = ConnectionPhase.online, epoch = 1;
    final loader = SessionBoundCashierProfitLossLoader(
      session: session,
      api: ProtocolCashierProfitLossApi(client: makeApi(adapter).client),
      phase: () => phase,
      generation: () => epoch,
    );
    const draft = CashierProfitLossDraft(
      libraryId: '1',
      entries: [CashierProfitLossEntry(productId: '7', profit: 1, loss: 0)],
    );
    expect((await loader.submit(draft, () => true)).failureOrNull, isNotNull);
    await loginSession(session, sessionAdapter, 8);
    expect((await loader.submit(draft, () => false)).failureOrNull, isNotNull);
    phase = ConnectionPhase.blocked;
    expect((await loader.load()).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
    phase = ConnectionPhase.online;
    adapter.onFetch = () {
      epoch++;
    };
    expect(
      (await loader.submit(draft, () => true)).failureOrNull?.code,
      'profit_loss.context_changed',
    );
    expect(adapter.requests.length, 1);
  });
  test('code2 is not stock success and malformed records never become empty success', () async {
    final rejected = Adapter()..code = 2;
    final api = ProtocolCashierProfitLossApi(client: makeApi(rejected).client);
    expect(
      (await api.submit(
        ClientKind.cashier,
        const CashierProfitLossDraft(
          libraryId: '1',
          entries: [CashierProfitLossEntry(productId: '7', profit: 1, loss: 0)],
        ),
      )).failureOrNull?.kind,
      FailureKind.business,
    );
    for (final data in [
      [],
      {'records': false},
      {
        'records': [
          {
            'rs': [false],
          },
        ],
      },
    ]) {
      expect(
        (await ProtocolCashierProfitLossApi(
          client: makeApi(Adapter()..data = data).client,
        ).load(ClientKind.cashier)).failureOrNull,
        isNotNull,
      );
    }
  });
  test('profit loss posts exact aligned arrays preserving repeated products and signed integers', () async {
    final adapter = Adapter();
    final api = ProtocolCashierProfitLossApi(client: makeApi(adapter).client);
    final result = await api.submit(
      ClientKind.cashier,
      const CashierProfitLossDraft(
        libraryId: '3',
        entries: [
          CashierProfitLossEntry(productId: '7', profit: 2, loss: 1),
          CashierProfitLossEntry(productId: '7', profit: -1, loss: 0),
        ],
      ),
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/sel/do_prd_profit_loss');
    expect(adapter.requests.single.data, {
      'mklib_id': 3,
      'prd_ids': [7, 7],
      'prd_profit_cnts': [2, -1],
      'prd_loss_cnts': [1, 0],
    });
  });
  test('profit loss records decode source groups and detail columns without money conversion', () async {
    final adapter = Adapter()
      ..data = {
        'records': [
          {
            'm': '酒库',
            'o': '操作员',
            't': '2026-09-22',
            'rs': [
              {'n': '啤酒', 'on': '酒水', 'tn': '啤酒类', 'pc': 3, 'lc': -2},
            ],
          },
        ],
      };
    final rows = (await ProtocolCashierProfitLossApi(
      client: makeApi(adapter).client,
    ).load(ClientKind.cashier)).valueOrNull!;
    expect(adapter.requests.single.data, isNull);
    expect(rows.single.library, '酒库');
    expect(rows.single.entries.single.profit, '3');
    expect(rows.single.entries.single.loss, '-2');
  });
  test('wrong clients and malformed draft make no stock requests', () async {
    final adapter = Adapter();
    final api = ProtocolCashierProfitLossApi(client: makeApi(adapter).client);
    const valid = CashierProfitLossDraft(
      libraryId: '3',
      entries: [CashierProfitLossEntry(productId: '7', profit: 0, loss: 0)],
    );
    expect(
      (await api.submit(ClientKind.order, valid)).failureOrNull,
      isNotNull,
    );
    expect((await api.load(ClientKind.order)).failureOrNull, isNotNull);
    expect(
      (await api.submit(
        ClientKind.cashier,
        const CashierProfitLossDraft(libraryId: '0', entries: []),
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
  });
}

class _DoubleCodeAdapter implements HttpClientAdapter {
  _DoubleCodeAdapter(this.code);
  final String code;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (stream != null) await stream.drain<void>();
    return ResponseBody.fromString('{"code":$code,"data":{"records":[]}}', 200);
  }

  @override
  void close({bool force = false}) {}
}
