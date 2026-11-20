import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'pay_order_stale_context_audit_test.dart' as fixture;

void main() {
  testWidgets(
    'unknown transfer is locked through auto-refresh until explicit successful verification',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0, reads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: fixture.table(),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            tables: () => [fixture.table()],
            loadOrders: ({required seatId, required turnoverCount}) async {
                  reads++;
                  if (reads == 3) return const FailureResult(AppFailure(
                    kind: FailureKind.network, code: 'network.read', safeMessage: '读取失败'));
              return Success(
                PayOrderData(seatId: seatId, unpayItems: [row('line')]),
              );
            },
            moveOrder:
                ({
                  required seatId,
                  required destSeatId,
                  required orderIds,
                  counts = const [],
                  totalAmtFen,
                  canDispatch,
                }) async {
                  calls++;
                  return const FailureResult(
                    AppFailure(
                      kind: FailureKind.network,
                      code: 'network.timeout',
                      safeMessage: '结果未知',
                    ),
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('转单'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RadioListTile<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认转单'));
      await tester.pumpAndSettle();
      expect(reads, greaterThan(1));
      await tester.tap(find.text('转单'));
      await tester.pumpAndSettle();
      expect(find.text('确认转单'), findsNothing);
      expect(calls, 1);
      await tester.tap(find.text('核实转单结果'));
      await tester.pumpAndSettle();
      expect(find.text('核实转单结果'), findsOneWidget);
      await tester.tap(find.text('核实转单结果'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('转单'));
      await tester.pumpAndSettle();
      expect(find.text('确认转单'), findsOneWidget);
    },
  );
  testWidgets('transfer cannot dispatch during route return animation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool Function()? guard;
    final response = Completer<Result<void>>();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const Scaffold()),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => PayOrderScreen(
            table: fixture.table(),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            tables: () => [fixture.table()],
            loadOrders: ({required seatId, required turnoverCount}) async =>
                Success(
                  PayOrderData(seatId: seatId, unpayItems: [row('line')]),
                ),
            moveOrder:
                ({
                  required seatId,
                  required destSeatId,
                  required orderIds,
                  counts = const [],
                  totalAmtFen,
                  canDispatch,
                }) {
                  guard = canDispatch;
                  return response.future;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('转单'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RadioListTile<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认转单'));
    await tester.pumpAndSettle();
    expect(guard, isNotNull);
    navigator.currentState!.pop();
    await tester.pump();
    expect(guard!(), isFalse);
    response.complete(const Success(null));
    await tester.pumpAndSettle();
  });
  for (final author in [false, true]) {
    testWidgets(
      'batch ${author ? 'author' : 'waiter'} selects current paid tab rows and real employee',
      (tester) async {
        tester.view.physicalSize = Size(author ? 390 : 1500, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        List<String>? written;
        String? employee;
        final data = PayOrderData(
          seatId: '100',
          unpayItems: [row('unpaid')],
          payedOrders: [
            PayedOrderRecord(
              id: '80',
              items: [
                row('normal'),
                row('special', at: 8),
                row('online', online: true),
                row('refund', back: true),
              ],
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: PayOrderScreen(
              table: fixture.table(),
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              employees: () => const [
                CardEmployee(
                  id: '77',
                  name: '张三',
                  deptId: '1',
                  code: '9001',
                  namePy: 'zs',
                ),
              ],
              loadOrders: ({required seatId, required turnoverCount}) async =>
                  Success(data),
              batchUpdateOrderWaiter:
                  ({
                    required seatId,
                    required orderIds,
                    required waiterEmpId,
                    canDispatch,
                  }) async {
                    expect(canDispatch!(), isTrue);
                    written = orderIds;
                    employee = waiterEmpId;
                    return const Success(null);
                  },
              batchUpdateOrderAuther:
                  ({
                    required seatId,
                    required orderIds,
                    required authEmpId,
                    canDispatch,
                  }) async {
                    expect(canDispatch!(), isTrue);
                    written = orderIds;
                    employee = authEmpId;
                    return const Success(null);
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        expect(find.text('改服务员'), findsNothing);
        await tester.tapAt(const Offset(20, 500));
        await tester.pumpAndSettle();
        await tester.tap(find.text('全部消费'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(PopupMenuButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(author ? '改授权人' : '改服务员'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, '输入姓名、工号或拼音'),
          '9001',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('张三（9001）'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('确认修改'));
        await tester.pumpAndSettle();
        expect(written, author ? ['special'] : ['unpaid', 'normal', 'special']);
        expect(employee, '77');
      },
    );
  }
}

PayOrderItem row(
  String id, {
  int at = 0,
  bool online = false,
  bool back = false,
}) => PayOrderItem(
  id: id,
  productId: '1',
  name: id,
  count: 1,
  unitPrice: '10',
  amount: '10',
  authorizationType: at,
  online: online,
  refunded: back,
);
