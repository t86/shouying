import 'package:card_table/src/vip_manager.dart';
import 'package:card_table/src/vip_pages.dart';
import 'package:card_table/src/vip_pages_loader.dart';
import 'package:card_table/src/vip_manager_loader.dart';
import 'package:card_table/src/vip_nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;
import 'bms_loader_guard_test.dart' show loginSession;

void main() {
  for (final allowed in [false, true]) {
    test(
      'create card loader follows module30 $allowed, with dispatch guard',
      () async {
        final auth = Adapter(), requests = Adapter()..data = {'id': 1};
        final session = SessionRepository(
          api: SessionApi(client: makeApi(auth).client),
          credentialStore: Credentials(),
        );
        await loginSession(session, auth, 16);
        final loader = SessionBoundVipManagerLoader(
          session: session,
          api: ProtocolVipManagerApi(client: makeApi(requests).client),
          phase: () => ConnectionPhase.online,
          generation: () => 1,
          hasMemberEditModule: () => allowed,
        );
        final result = await loader.createCard(
          cardNo: 'V1',
          typeId: '1',
          levelId: '1',
          name: '测试',
        );
        expect(result.failureOrNull == null, allowed);
        expect(requests.requests.length, allowed ? 1 : 0);
      },
    );
  }
  testWidgets(
    'open edit dialog stays revoked when parent rebuilds with new permissions',
    (tester) async {
      final auth = Adapter(), requests = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(auth).client),
        credentialStore: Credentials(),
      );
      await tester.runAsync(() => loginSession(session, auth, 16));
      final client = makeApi(requests).client;
      var epoch = 1;
      final loader = SessionBoundVipPagesLoader(
        session: session,
        pages: ProtocolVipPagesApi(client: client),
        cards: ProtocolVipManagerApi(client: client),
        phase: () => ConnectionPhase.online,
        generation: () => 1,
        hasMemberEditModule: () => true,
        accessGeneration: () => epoch,
      );
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return VipNavScreen(
                onBack: () {},
                pages: loader.workspace,
                listCards:
                    ({
                      required int pageNum,
                      required int pageSize,
                      String keyword = '',
                      bool init = false,
                    }) async => const Success(
                      VipCardPage(
                        total: 1,
                        records: [
                          VipCardRow(
                            id: '1',
                            name: '测试会员',
                            statusName: '正常',
                            bindPhone: '',
                            contactPhone: '',
                            sex: '',
                            birthday: '',
                            cardNo: 'V1',
                            typeName: '',
                            levelName: '',
                            balance: '0',
                            points: '0',
                            salesName: '',
                          ),
                        ],
                      ),
                    ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑会员卡信息'));
      await tester.pumpAndSettle();
      rebuild(() => epoch += 2);
      await tester.pump();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(requests.requests, isEmpty);
    },
  );
  test('workspace retained by a dialog cannot write after permission revoke and restore', () async {
    final auth = Adapter(), requests = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(auth).client),
      credentialStore: Credentials(),
    );
    await loginSession(session, auth, 16);
    final client = makeApi(requests).client;
    var epoch = 1;
    final loader = SessionBoundVipPagesLoader(
      session: session,
      pages: ProtocolVipPagesApi(client: client),
      cards: ProtocolVipManagerApi(client: client),
      phase: () => ConnectionPhase.online,
      generation: () => 1,
      hasMemberEditModule: () => true,
      accessGeneration: () => epoch,
    );
    final dialogPages = loader.workspace;
    epoch += 2;
    expect(
      (await dialogPages.changeLevel!(cardId: '1', levelId: '2')).failureOrNull,
      isNotNull,
    );
    expect(requests.requests, isEmpty);
    expect(
      (await loader.workspace.changeLevel!(
        cardId: '1',
        levelId: '2',
      )).failureOrNull,
      isNull,
    );
  });
  for (final editAllowed in [false, true]) {
    test(
      'VIP module30 $editAllowed preserves only source member-edit exception',
      () async {
        final auth = Adapter(), requests = Adapter();
        final session = SessionRepository(
          api: SessionApi(client: makeApi(auth).client),
          credentialStore: Credentials(),
        );
        await loginSession(session, auth, 16);
        final client = makeApi(requests).client;
        final loader = SessionBoundVipPagesLoader(
          session: session,
          pages: ProtocolVipPagesApi(client: client),
          cards: ProtocolVipManagerApi(client: client),
          phase: () => ConnectionPhase.online,
          generation: () => 1,
          hasMemberEditModule: () => editAllowed,
        );
        expect(
          (await loader.changeLevel(cardId: '1', levelId: '2')).failureOrNull ==
              null,
          editAllowed,
        );
        expect((await loader.lockCard('1')).failureOrNull, isNull);
        expect(
          (await loader.depositPoints(cardId: '1', points: 10)).failureOrNull,
          isNotNull,
        );
        expect(
          (await loader.savePointRule(typeId: 1, baseAmt: 0)).failureOrNull,
          isNotNull,
        );
        expect(requests.requests.length, editAllowed ? 2 : 1);
      },
    );
  }
  test(
    'withdrawn then restored module epoch never revives in-flight edit',
    () async {
      final auth = Adapter(), requests = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(auth).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, auth, 16);
      final client = makeApi(requests).client;
      var epoch = 1;
      final loader = SessionBoundVipPagesLoader(
        session: session,
        pages: ProtocolVipPagesApi(client: client),
        cards: ProtocolVipManagerApi(client: client),
        phase: () => ConnectionPhase.online,
        generation: () => 1,
        hasMemberEditModule: () => true,
        accessGeneration: () => epoch,
      );
      final pending = loader.changeLevel(cardId: '1', levelId: '2');
      epoch += 2;
      expect((await pending).failureOrNull, isNotNull);
      expect(requests.requests, isEmpty);
    },
  );
  for (final mode in [8, 16]) {
    test(
      'same terminal code respects selected client $mode for card rules',
      () async {
        final auth = Adapter(), requests = Adapter();
        final session = SessionRepository(
          api: SessionApi(client: makeApi(auth).client),
          credentialStore: Credentials(),
        );
        await loginSession(session, auth, mode);
        final client = makeApi(requests).client;
        final loader = SessionBoundVipPagesLoader(
          session: session,
          pages: ProtocolVipPagesApi(client: client),
          cards: ProtocolVipManagerApi(client: client),
          phase: () => ConnectionPhase.online,
          generation: () => 1,
        );
        final result = await loader.saveCardNoRule(numLength: 8, prefix: 'V');
        expect(result.failureOrNull == null, mode == 8);
        expect(requests.requests.length, mode == 8 ? 1 : 0);
      },
    );
  }
  test(
    'generation revoked during credentials blocks card-rule dispatch',
    () async {
      final auth = Adapter(), requests = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(auth).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, auth, 8);
      var epoch = 1;
      final client = makeApi(requests).client;
      final loader = SessionBoundVipPagesLoader(
        session: session,
        pages: ProtocolVipPagesApi(client: client),
        cards: ProtocolVipManagerApi(client: client),
        phase: () => ConnectionPhase.online,
        generation: () => epoch,
      );
      final pending = loader.saveCardNoRule(numLength: 8, prefix: 'V');
      epoch++;
      expect((await pending).failureOrNull, isNotNull);
      expect(requests.requests, isEmpty);
    },
  );
  testWidgets('standalone VIP hides cashier return and card number rule', (
    tester,
  ) async {
    final auth = Adapter(), requests = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(auth).client),
      credentialStore: Credentials(),
    );
    await tester.runAsync(() => loginSession(session, auth, 16));
    final client = makeApi(requests).client;
    final loader = SessionBoundVipPagesLoader(
      session: session,
      pages: ProtocolVipPagesApi(client: client),
      cards: ProtocolVipManagerApi(client: client),
      phase: () => ConnectionPhase.online,
      generation: () => 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: VipNavScreen(
          onBack: () {},
          pages: loader.workspace,
          listCards: ({
            required int pageNum,
            required int pageSize,
            String keyword = '',
            bool init = false,
          }) async => const Success(VipCardPage(total: 0)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('返回'), findsNothing);
    expect(find.text('充值'), findsNothing);
    await tester.tap(find.text('业务配置'));
    await tester.pumpAndSettle();
    expect(find.text('会员卡号生成规则'), findsNothing);
  });
}
