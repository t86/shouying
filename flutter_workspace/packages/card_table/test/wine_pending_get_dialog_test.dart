import 'dart:async';

import 'package:card_table/src/wine_models.dart';
import 'package:card_table/src/wine_pending_get_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

const record = WineGetRecord(
  id: '71',
  customerName: '客人',
  customerPhone: '138',
  seatName: 'A1',
  salesName: '',
  waiterName: '',
  getTime: '',
  items: [WineGetSubItem(id: '91', name: '原酒', unit: '瓶', count: 2)],
);
const inventory = [
  WineGetSubItem(id: '91', name: '原酒', unit: '瓶', count: 3),
  WineGetSubItem(id: '92', name: '新酒', unit: '瓶', count: 4),
];

Future<void> open(
  WidgetTester tester, {
  bool auth = false,
  bool Function()? isCurrent,
  required Future<Result<void>> Function(Map<String, Object?>) submit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => WinePendingGetDialog(
                record: record,
                inventory: inventory,
                needsAuthorization: auth,
                submit: submit,
                isCurrent: isCurrent,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('expired dialog context never submits and does not revive', (tester) async {
    var current=true,writes=0;
    await open(tester,isCurrent:()=>current,submit:(_)async{writes++;return const Success(null);});
    current=false;
    await tester.tap(find.byKey(const Key('wine-get-submit')));await tester.pumpAndSettle();
    expect(writes,0);
    current=true;
    await tester.tap(find.byKey(const Key('wine-get-submit')));await tester.pumpAndSettle();
    expect(writes,0);
  });
  testWidgets('late confirmation closes its own dialog, never a newer page', (
    tester,
  ) async {
    final pending = Completer<Result<void>>();
    await open(tester, submit: (_) => pending.future);
    await tester.tap(find.byKey(const Key('wine-get-submit')));
    await tester.pump();
    final navigator = Navigator.of(
      tester.element(find.byType(WinePendingGetDialog)),
    );
    unawaited(
      navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('new page')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    pending.complete(const Success(null));
    await tester.pumpAndSettle();
    expect(find.text('new page'), findsOneWidget);
    expect(
      find.byType(WinePendingGetDialog, skipOffstage: false),
      findsNothing,
    );
  });
  testWidgets(
    'edits real inventory quantities; removes original; empty credentials without auth',
    (tester) async {
      Map<String, Object?>? body;
      await open(
        tester,
        submit: (value) async {
          body = value;
          return const Success(null);
        },
      );
      expect(find.text('可取总数：5'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('wine-get-count-91')), '0');
      await tester.enterText(find.byKey(const Key('wine-get-count-92')), '3');
      await tester.tap(find.byKey(const Key('wine-get-submit')));
      await tester.pumpAndSettle();
      expect(body, {
        'bef_out_id': 71,
        'invt_ids': [92],
        'prd_cnts': [3],
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'pass_type': 1,
      });
      expect(find.byType(WinePendingGetDialog), findsNothing);
    },
  );
  testWidgets('invalid quantity and cancellation never submit', (tester) async {
    var writes = 0;
    await open(
      tester,
      submit: (_) async {
        writes++;
        return const Success(null);
      },
    );
    for (final value in ['6', '-1', '1.5']) {
      await tester.enterText(find.byKey(const Key('wine-get-count-91')), value);
      await tester.tap(find.byKey(const Key('wine-get-submit')));
      await tester.pumpAndSettle();
      expect(writes, 0);
    }
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(writes, 0);
  });
  for (final card in [false, true]) {
    testWidgets(
      'authorization ${card ? 'card' : 'account'} sends separate hashed fields and retains failure',
      (tester) async {
        Map<String, Object?>? body;
        await open(
          tester,
          auth: true,
          submit: (value) async {
            body = value;
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'denied',
                safeMessage: '授权失败',
              ),
            );
          },
        );
        await tester.tap(find.byKey(const Key('wine-get-submit')));
        await tester.pumpAndSettle();
        expect(body, isNull);
        if (card) {
          await tester.tap(find.byType(DropdownButton<int>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('员工卡（手工输入）').last);
          await tester.pumpAndSettle();
          expect(find.textContaining('自动读卡尚未接入'), findsOneWidget);
        }
        await tester.enterText(
          find.byKey(const Key('wine-get-account')),
          'employee',
        );
        await tester.enterText(find.byKey(const Key('wine-get-secret')), 'abc');
        await tester.tap(find.byKey(const Key('wine-get-submit')));
        await tester.pumpAndSettle();
        expect(body!['pass_type'], card ? 2 : 1);
        expect(body!['auth_emp_passwd'], '900150983CD24FB0D6963F7D28E17F72');
        expect(body!['invt_ids'], [91]);
        expect(find.text('授权失败'), findsOneWidget);
      },
    );
  }
}
