import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

void main() {
  testWidgets('selection lists original nine terminal systems, not super-admin authorization', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: BusinessSystemSelectionScreen(
      authorize: (system) async => Success(MachineSession(machineId: 'test',
        machineName: 'test', client: system.client)))));
    expect(find.byType(FilledButton), findsNWidgets(9));
    expect(find.byKey(BusinessSystemSelectionScreen.vipKey), findsOneWidget);
    expect(find.byKey(BusinessSystemSelectionScreen.erpWarehouseKey), findsOneWidget);
    expect(find.byKey(BusinessSystemSelectionScreen.erpKey), findsOneWidget);
    expect(find.byKey(BusinessSystemSelectionScreen.superAdminKey), findsNothing);
  });
  test('every original terminal client has its own business landing', () {
    const expected = {
      ClientKind.orgManager: '/BMS/codeRules',
      ClientKind.booking: '/cardMachine',
      ClientKind.order: '/orderCard',
      ClientKind.cashier: '/moneyCard',
      ClientKind.vip: '/vipManager',
      ClientKind.erp: '/ERP/anotherInLib',
      ClientKind.erpAdmin: '/ERP/home',
      ClientKind.wine: '/wine/saveNeedToLib',
      ClientKind.queueDisplay: '/queue/bigScreen',
    };
    for (final entry in expected.entries) {
      final system = BusinessSystem.fromClient(entry.key);
      expect(system, isNotNull, reason: entry.key.name);
      expect(system!.client, entry.key);
      expect(system.landingPath, entry.value);
    }
    expect(BusinessSystem.values.map((s) => s.landingPath).toSet().length,
        BusinessSystem.values.length);
  });
}
