import 'dart:async';

import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_save_edit.dart';
import 'package:card_table/src/wine_save_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

WineSaveEditRecord record() => WineSaveEditRecord.fromWire({
  'o': 71,
  'm': 81,
  'si': 91,
  's': 'A1',
  'd': '2026-09-20',
  'c': '客人',
  'p': '13800000000',
  't': '2026/09/19 12:00:00',
  'r': '旧备注',
  'ss': [
    {
      'id': 101,
      'p': 201,
      'n': '酒',
      'u': '整瓶',
      'g': 0,
      'c': 2,
      'ce': 30,
      'a': '-',
    },
  ],
});

class Loader implements WineLoader, WineSaveEditLoader {
  @override
  Object? saveEditSession = Object();
  @override
  WineSaveEditMetadataSnapshot saveEditSnapshot =
      const WineSaveEditMetadataSnapshot(
        known: true,
        employees: [WineSaveEmployee(7, '订位人', '007', 'DWR')],
        businessDates: ['2026-09-20'],
      );
  final writes = <Map<String, Object?>>[];
  bool fail = false, auth = false;
  Completer<void>? pending;
  @override
  Future<Result<WineSaveEditContext>> loadSaveEditContext() async {
    if (pending != null) await pending!.future;
    return Success(WineSaveEditContext([record()], auth));
  }

  @override
  Future<Result<void>> chgSaveNeedToLib(Map<String, Object?> body) async {
    writes.add(body);
    return fail
        ? const FailureResult(
            AppFailure(
              kind: FailureKind.business,
              code: 'deny',
              safeMessage: '拒绝修改',
            ),
          )
        : const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> open(WidgetTester tester, Loader loader) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => WineSaveEditDialog(
                loader: loader,
                record: record(),
                needsAuthorization: loader.auth,
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
  for (final unknown in [false, true]) {
    testWidgets(
      'selected employee removed/unknown=$unknown fails closed without build error',
      (tester) async {
        final loader = Loader();
        await open(tester, loader);
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        tester
            .widget<DropdownButtonFormField<int>>(
              find.byType(DropdownButtonFormField<int>),
            )
            .onChanged!(7);
        await tester.pump();
        loader.saveEditSnapshot = WineSaveEditMetadataSnapshot(
          known: !unknown,
          businessDates: const ['2026-09-20'],
        );
        await tester.tap(find.byKey(const Key('save-edit-submit')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(loader.writes, isEmpty);
      },
    );
  }
  testWidgets(
    'free mode requires a chosen employee; explicit walk-in maps to zero',
    (tester) async {
      final loader = Loader();
      await open(tester, loader);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-edit-submit')));
      await tester.pumpAndSettle();
      expect(loader.writes, isEmpty);
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>),
          )
          .onChanged!(0);
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-edit-submit')));
      await tester.pumpAndSettle();
      expect(loader.writes.single['mode_type'], 2);
      expect(loader.writes.single['csm_id'], 0);
      expect(loader.writes.single['seat_id'], 91);
      expect(loader.writes.single['sales_emp_id'], 0);
    },
  );
  testWidgets('invalid calendar date and hour cannot submit', (tester) async {
    final loader = Loader();
    await open(tester, loader);
    final time = find.widgetWithText(TextField, '存酒时间 yyyy/MM/dd HH:mm:ss');
    for (final value in ['2026/02/31 12:00:00', '2026/09/19 25:00:00']) {
      await tester.enterText(time, value);
      await tester.tap(find.byKey(const Key('save-edit-submit')));
      await tester.pumpAndSettle();
      expect(loader.writes, isEmpty);
    }
  });
  testWidgets(
    'full linked body copies source detail ids and failure retains draft',
    (tester) async {
      final loader = Loader()..fail = true;
      await open(tester, loader);
      await tester.enterText(find.byKey(const Key('save-edit-remark')), '新备注');
      await tester.ensureVisible(find.text('复制'));
      await tester.tap(find.text('复制'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-edit-submit')));
      await tester.pumpAndSettle();
      expect(loader.writes.single['bef_in_dtl_ids'], [101, 101]);
      expect(loader.writes.single['prd_ids'], [201, 201]);
      expect(loader.writes.single['unit_types'], ['1', '1']);
      expect(loader.writes.single['remark'], '新备注');
      expect(loader.writes.single.containsKey('auth_emp_passwd'), false);
      expect(find.text('拒绝修改').hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('save-edit-remark')))
            .controller!
            .text,
        '新备注',
      );
    },
  );
  for (final scenario in ['cancel', 'back', 'session', 'metadata']) {
    testWidgets('$scenario during preflight cannot write', (tester) async {
      final loader = Loader()..pending = Completer<void>();
      await open(tester, loader);
      await tester.tap(find.byKey(const Key('save-edit-submit')));
      await tester.pump();
      if (scenario == 'cancel') {
        await tester.tap(find.text('取消'));
        await tester.pump();
      }
      if (scenario == 'back') {
        await tester.binding.handlePopRoute();
        await tester.pump();
      }
      if (scenario == 'session') loader.saveEditSession = Object();
      if (scenario == 'metadata') {
        loader.saveEditSnapshot = const WineSaveEditMetadataSnapshot();
      }
      loader.pending!.complete();
      await tester.pumpAndSettle();
      expect(loader.writes, isEmpty);
    });
  }
  testWidgets('unknown authorization cannot silently submit', (tester) async {
    final loader = Loader()..auth = true;
    await open(tester, loader);
    await tester.tap(find.byKey(const Key('save-edit-submit')));
    await tester.pumpAndSettle();
    expect(loader.writes, isEmpty);
    expect(find.text('请填写服务员授权信息'), findsOneWidget);
  });
}
