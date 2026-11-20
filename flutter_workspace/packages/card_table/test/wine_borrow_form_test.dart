import 'dart:async';

import 'package:card_table/src/wine_borrow_return_views.dart';
import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class FormLoader implements WineLoader, WineBorrowFormContext {
  @override
  Object? borrowFormContext = Object();
  Completer<void>? preflight;
  final writes = <Map<String, Object?>>[];
  bool fail = false;
  int reloads = 0;
  @override
  Future<Result<List<Map<String, Object?>>>> loadWineBorrowEmployees(
    String query,
  ) async => const Success([
    {'id': 7, 'n': '员工甲'},
  ]);
  @override
  Future<Result<List<Map<String, Object?>>>> loadWineReturnOptions({
    String keyword = '',
  }) async {
    if (keyword.isEmpty) await preflight?.future;
    return const Success([
      {'id': 11, 'n': '酒水甲', 'c': 3},
      {'id': 12, 'n': '酒水乙', 'c': 4},
    ]);
  }

  @override
  Future<Result<List<Map<String, Object?>>>> loadWineCanBorrowList({
    String keyword = '',
  }) => loadWineReturnOptions(keyword: keyword);
  @override
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowInvtList({
    String keyword = '',
  }) async => const Success([]);
  @override
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowReturnList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    int type = 0,
  }) async {
    reloads++;
    return const Success([]);
  }

  @override
  Future<Result<void>> submitWineBorrow(Map<String, Object?> fields) async {
    writes.add(fields);
    return fail
        ? const FailureResult(
            AppFailure(
              kind: FailureKind.business,
              code: 'test',
              safeMessage: '服务端拒绝',
            ),
          )
        : const Success(null);
  }

  @override
  Future<Result<void>> submitWineReturn(Map<String, Object?> fields) =>
      submitWineBorrow(fields);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final scenario in [
    'over stock',
    'fraction',
    'zero',
    'duplicate total',
    'cancel preflight',
    'back preflight',
    'session preflight',
  ]) {
    testWidgets('borrow form rejects $scenario without writes', (tester) async {
      final loader = FormLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WineBorrowView(loader: loader)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增借酒'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('wine-form-employee-search')),
        '甲',
      );
      await tester.tap(find.byKey(const Key('wine-form-employee-find')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('员工甲'));
      await tester.pumpAndSettle();
      for (var i = 0; i < (scenario == 'duplicate total' ? 2 : 1); i++) {
        final search = find.byKey(Key('wine-form-search-$i'));
        await tester.ensureVisible(search);
        await tester.enterText(search, '酒');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(Key('wine-form-find-$i')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('wine-form-find-$i')));
        await tester.pumpAndSettle();
        tester
            .widget<DropdownButtonFormField<int>>(
              find.byKey(Key('wine-form-choice-$i')),
            )
            .onChanged!(11);
        await tester.pumpAndSettle();
        final count = find.byKey(Key('wine-form-count-$i'));
        await tester.ensureVisible(count);
        await tester.enterText(count, switch (scenario) {
          'over stock' => '4',
          'fraction' => '1.5',
          'zero' => '0',
          _ => '2',
        });
      }
      if (scenario.endsWith('preflight')) loader.preflight = Completer<void>();
      await tester.tap(find.byKey(const Key('wine-form-submit')));
      await tester.pump();
      if (scenario == 'cancel preflight') {
        await tester.tap(find.text('取消'));
        await tester.pump();
      }
      if (scenario == 'back preflight') {
        await tester.binding.handlePopRoute();
        await tester.pump();
      }
      if (scenario == 'session preflight') loader.borrowFormContext = Object();
      loader.preflight?.complete();
      await tester.pumpAndSettle();
      expect(loader.writes, isEmpty);
      if (scenario != 'cancel preflight' && scenario != 'back preflight') {
        expect(find.byKey(const Key('wine-form-submit')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final returning in [false, true]) {
    testWidgets(
      'multi wine ${returning ? 'return' : 'borrow'} posts employee and parallel arrays, failure retains form',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final loader = FormLoader()..fail = true;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: returning
                  ? WineReturnView(loader: loader)
                  : WineBorrowView(loader: loader),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(returning ? '新增还酒' : '新增借酒'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('wine-form-employee-search')),
          '甲',
        );
        await tester.tap(find.byKey(const Key('wine-form-employee-find')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('员工甲'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 2; i++) {
          final search = find.byKey(Key('wine-form-search-$i'));
          await tester.ensureVisible(search);
          await tester.enterText(search, '酒');
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(Key('wine-form-find-$i')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(Key('wine-form-find-$i')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(Key('wine-form-choice-$i')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(Key('wine-form-choice-$i')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(i == 0 ? '酒水甲' : '酒水乙').last);
          await tester.pumpAndSettle();
          final count = find.byKey(Key('wine-form-count-$i'));
          await tester.ensureVisible(count);
          await tester.enterText(count, i == 0 ? '2' : '3');
          final remark = find.byKey(Key('wine-form-remark-$i'));
          await tester.ensureVisible(remark);
          await tester.enterText(remark, '备注$i');
        }
        final optionalSearch = find.byKey(const Key('wine-form-search-2'));
        await tester.ensureVisible(optionalSearch);
        await tester.enterText(optionalSearch, '酒');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('wine-form-find-2')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('wine-form-find-2')));
        await tester.pumpAndSettle();
        tester
            .widget<DropdownButtonFormField<int>>(
              find.byKey(const Key('wine-form-choice-2')),
            )
            .onChanged!(12);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('wine-form-submit')));
        await tester.pumpAndSettle();
        expect(loader.writes.single, {
          'br_emp_id': 7,
          'prd_ids': [11, 12],
          'prd_cnts': [2, 3],
          'remarks': ['备注0', '备注1'],
        });
        expect(find.text('服务端拒绝'), findsOneWidget);
        expect(find.text('服务端拒绝').hitTestable(), findsOneWidget);
        expect(loader.reloads, 1);
        loader.fail = false;
        await tester.tap(find.byKey(const Key('wine-form-submit')));
        await tester.pumpAndSettle();
        expect(loader.reloads, 2);
        expect(find.byKey(const Key('wine-form-submit')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
