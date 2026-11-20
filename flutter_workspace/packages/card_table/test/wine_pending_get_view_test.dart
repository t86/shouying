import 'dart:async';

import 'package:card_table/src/wine_inventory_views.dart';
import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:card_table/src/wine_pending_get.dart';
import 'package:card_table/src/wine_pending_get_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'wine_pending_get_dialog_test.dart' show record, inventory;

class PendingLoader
    implements WineLoader, WinePendingGetLoader, WineBorrowFormContext {
  Object? token = Object();
  int writes = 0;
  String? rejectReason;
  List<String>? ids;
  Completer<Result<void>>? writePending;
  Completer<Result<List<WineGetSubItem>>>? pending;
  @override
  Object? get borrowFormContext => token;
  @override
  Future<Result<WinePendingGetContext>> loadPendingGetContext({
    String keyword = '',
  }) async => const Success(
    WinePendingGetContext(records: [record], needsAuthorization: false),
  );
  @override
  Future<Result<List<WineGetSubItem>>> loadPendingGetInventory(
    String phone,
  ) async => pending?.future ?? const Success(inventory);
  @override
  Future<Result<void>> confirmAuthGetNeedToLib(
    Map<String, Object?> fields,
  ) async {
    writes++;
    return const Success(null);
  }

  @override
  Future<Result<void>> confirmGetNeedToLib(List<String> selected) async {
    writes++;
    ids = selected;
    return writePending?.future ?? const Success(null);
  }

  @override
  Future<Result<void>> backGetNeedToLib(
    List<String> selected, {
    String reason = '',
  }) async {
    writes++;
    ids = selected;
    rejectReason = reason;
    return writePending?.future ?? const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> showView(WidgetTester tester, PendingLoader loader) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: WineGetNeedView(loader: loader)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final reject in [false, true]) {
    for (final scenario in [
      'cancel',
      'changed',
      'offline',
      'stable',
      'late',
      'late-route',
      'selection',
    ]) {
      testWidgets(
        'batch ${reject ? 'reject' : 'confirm'} protects $scenario context',
        (tester) async {
          final loader = PendingLoader();
          if (scenario.startsWith('late')) {
            loader.writePending = Completer<Result<void>>();
          }
          await showView(tester, loader);
          await tester.tap(find.byType(Checkbox).first);
          await tester.pump();
          await tester.tap(
            find.byKey(
              Key(reject ? 'wine-get-need-reject' : 'wine-get-need-confirm'),
            ),
          );
          await tester.pumpAndSettle();
          if (scenario == 'changed') loader.token = Object();
          if (scenario == 'offline') loader.token = null;
          if (scenario == 'selection') {
            tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged!(
              false,
            );
          }
          await tester.tap(
            find.text(
              scenario == 'cancel'
                  ? '取消'
                  : reject
                  ? '确定驳回'
                  : '确定',
            ),
          );
          if (scenario.startsWith('late')) {
            await tester.pump();
            if (scenario == 'late') {
              loader.token = Object();
            } else {
              final nav = Navigator.of(
                tester.element(find.byType(WineGetNeedView)),
              );
              unawaited(
                nav.push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const Scaffold(body: Text('new batch page')),
                  ),
                ),
              );
              await tester.pump();
            }
            loader.writePending!.complete(const Success(null));
          }
          await tester.pumpAndSettle();
          expect(
            loader.writes,
            scenario == 'stable' ||
                    scenario == 'selection' ||
                    scenario.startsWith('late')
                ? 1
                : 0,
          );
          if (scenario == 'stable' || scenario == 'selection') {
            expect(loader.ids, ['71']);
          }
          if (scenario.startsWith('late')) {
            expect(find.text(reject ? '驳回成功' : '确认出库成功'), findsNothing);
          }
          if (scenario == 'late-route') {
            expect(find.text('new batch page'), findsOneWidget);
          }
        },
      );
    }
  }
  testWidgets(
    'pending inventory from an expired view context cannot open authorization',
    (tester) async {
      final loader = PendingLoader()
        ..pending = Completer<Result<List<WineGetSubItem>>>();
      await showView(tester, loader);
      await tester.tap(find.text('编辑取酒'));
      await tester.pump();
      loader.token = Object();
      loader.pending!.complete(const Success(inventory));
      await tester.pumpAndSettle();
      expect(find.byType(WinePendingGetDialog), findsNothing);
      expect(loader.writes, 0);
    },
  );
  testWidgets(
    'opened pending authorization cannot write after session context changes',
    (tester) async {
      final loader = PendingLoader();
      await showView(tester, loader);
      await tester.tap(find.text('编辑取酒'));
      await tester.pumpAndSettle();
      loader.token = Object();
      await tester.tap(find.byKey(const Key('wine-get-submit')));
      await tester.pumpAndSettle();
      expect(loader.writes, 0);
    },
  );
  testWidgets('pending rejection does not collect a discarded reason', (
    tester,
  ) async {
    final loader = PendingLoader();
    await showView(tester, loader);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('wine-get-need-reject')));
    await tester.pumpAndSettle();
    expect(find.text('驳回原因'), findsNothing);
    await tester.tap(find.text('确定驳回'));
    await tester.pumpAndSettle();
    expect(loader.rejectReason, '');
  });
}
