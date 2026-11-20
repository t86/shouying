import 'dart:async';

import 'package:card_table/src/minimum_consumption_report.dart';
import 'package:card_table/src/minimum_consumption_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('shows all source columns and unchanged data without export', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    var calls = 0;
    await _pump(tester, canRead, () async {
      calls++;
      return Success([_row()]);
    });
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xffFAFAFC),
    );
    expect(find.text('低消进度统计表'), findsOneWidget);
    for (final label in MinimumConsumptionReportRow.columnLabels) {
      expect(find.text(label), findsOneWidget);
    }
    for (final cell in _row().cells.where((cell) => cell.isNotEmpty)) {
      expect(find.text(cell), findsOneWidget);
    }
    expect(find.text('1'), findsOneWidget);
    expect(find.textContaining('导出'), findsNothing);
    expect(find.textContaining('待接入'), findsNothing);
    expect(find.byType(Scrollbar), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    final lastColumn = find.text('标签');
    expect(lastColumn.hitTestable(), findsNothing);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-2200, 0),
    );
    await tester.pumpAndSettle();
    expect(lastColumn.hitTestable(), findsOneWidget);
    expect(find.text('原标签').hitTestable(), findsOneWidget);
  });

  testWidgets('shows loading then empty state', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
    await _pump(tester, canRead, () => pending.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const Success([]));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('暂无数据'), findsOneWidget);
  });

  testWidgets('displays safe failures and retries with fresh results', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    var calls = 0;
    await _pump(tester, canRead, () async {
      calls++;
      return calls == 1 ? const FailureResult(_safeFailure) : Success([_row()]);
    });
    await tester.pumpAndSettle();
    expect(find.text(_safeFailure.safeMessage), findsOneWidget);
    expect(find.text('测试订位人'), findsNothing);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text(_safeFailure.safeMessage), findsNothing);
    expect(find.text('测试订位人'), findsOneWidget);
  });

  testWidgets('unexpected loader throws never display raw errors', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    await _pump(tester, canRead, () => throw StateError('private response'));
    await tester.pumpAndSettle();
    expect(find.text('低消进度统计表查询失败，请重试'), findsOneWidget);
    expect(find.textContaining('private response'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initially denied read does not query until explicit retry', (
    tester,
  ) async {
    final canRead = ValueNotifier(false);
    addTearDown(canRead.dispose);
    var calls = 0;
    await _pump(tester, canRead, () async {
      calls++;
      return Success([_row()]);
    });
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('当前不可查询低消进度统计表'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(calls, 0);

    canRead.value = true;
    await tester.pump();
    expect(calls, 0);
    expect(find.text('测试订位人'), findsNothing);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('测试订位人'), findsOneWidget);
  });

  testWidgets(
    'losing read access removes loaded rows and never restores them',
    (tester) async {
      final canRead = ValueNotifier(true);
      addTearDown(canRead.dispose);
      final rows = [_row()];
      await _pump(tester, canRead, () async => Success(rows));
      await tester.pumpAndSettle();
      rows.clear();
      await tester.pump();
      expect(find.text('测试订位人'), findsOneWidget);

      canRead.value = false;
      await tester.pump();
      expect(find.text('测试订位人'), findsNothing);
      expect(find.text('当前不可查询低消进度统计表'), findsOneWidget);
      canRead.value = true;
      await tester.pumpAndSettle();
      expect(find.text('测试订位人'), findsNothing);
      expect(find.text('点击重试查询低消进度统计表'), findsOneWidget);
    },
  );

  testWidgets('false then true invalidates in-flight responses until retry', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final old = Completer<Result<List<MinimumConsumptionReportRow>>>();
    var calls = 0;
    await _pump(tester, canRead, () {
      calls++;
      return calls == 1 ? old.future : Future.value(Success([_row('新订位人')]));
    });
    canRead.value = false;
    canRead.value = true;
    old.complete(Success([_row()]));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('测试订位人'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('新订位人'), findsOneWidget);
  });

  testWidgets('late old request cannot overwrite a newer permitted retry', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final old = Completer<Result<List<MinimumConsumptionReportRow>>>();
    final current = Completer<Result<List<MinimumConsumptionReportRow>>>();
    var calls = 0;
    await _pump(
      tester,
      canRead,
      () => ++calls == 1 ? old.future : current.future,
    );
    canRead.value = false;
    canRead.value = true;
    await tester.pump();
    await tester.tap(find.text('重试'));
    await tester.pump();
    current.complete(Success([_row('新订位人')]));
    await tester.pumpAndSettle();
    old.complete(Success([_row()]));
    await tester.pumpAndSettle();
    expect(find.text('新订位人'), findsOneWidget);
    expect(find.text('测试订位人'), findsNothing);
  });

  testWidgets('repeated retry callbacks cannot launch overlapping requests', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
    var calls = 0;
    await _pump(tester, canRead, () {
      calls++;
      return calls == 1
          ? Future.value(const FailureResult(_safeFailure))
          : pending.future;
    });
    await tester.pumpAndSettle();
    final retry = tester
        .widget<TextButton>(find.widgetWithText(TextButton, '重试'))
        .onPressed!;
    retry();
    retry();
    await tester.pump();
    expect(calls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const Success([]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disposal removes permission listener and ignores late completion',
    (tester) async {
      final canRead = _ReadAccess(true);
      addTearDown(canRead.dispose);
      final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
      await _pump(tester, canRead, () => pending.future);
      expect(canRead.isObserved, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: Text('原卡台页')));
      canRead.value = false;
      pending.complete(Success([_row()]));
      await tester.pumpAndSettle();
      expect(find.text('原卡台页'), findsOneWidget);
      expect(find.text('测试订位人'), findsNothing);
      expect(canRead.isObserved, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('replacing the permission source also invalidates pending work', (
    tester,
  ) async {
    final first = _ReadAccess(true);
    final next = _ReadAccess(true);
    addTearDown(first.dispose);
    addTearDown(next.dispose);
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
    Future<Result<List<MinimumConsumptionReportRow>>> load() => pending.future;
    await _pump(tester, first, load);
    await _pump(tester, next, load);
    pending.complete(Success([_row()]));
    await tester.pumpAndSettle();
    expect(find.text('测试订位人'), findsNothing);
    expect(first.isObserved, isFalse);
    expect(next.isObserved, isTrue);
  });

  testWidgets(
    'host rebuild can revoke access on an already built report route',
    (tester) async {
      final canRead = ValueNotifier(true);
      addTearDown(canRead.dispose);
      final revision = ValueNotifier(0);
      addTearDown(revision.dispose);
      final report = MinimumConsumptionReportScreen(
        canRead: canRead,
        load: () async => Success([_row()]),
      );
      final host = MaterialApp(
        home: Stack(
          children: [
            report,
            ValueListenableBuilder<int>(
              valueListenable: revision,
              builder: (_, value, child) => _PermissionMutationHost(
                revision: value,
                onUpdate: () => canRead.value = false,
              ),
            ),
          ],
        ),
      );
      await tester.pumpWidget(host);
      await tester.pumpAndSettle();
      expect(find.text('测试订位人'), findsOneWidget);
      revision.value++;
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('测试订位人'), findsNothing);
      expect(find.text('当前不可查询低消进度统计表'), findsOneWidget);
    },
  );

  testWidgets('host build false then true never revives a pending response', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>.sync();
    final revision = ValueNotifier(0);
    addTearDown(revision.dispose);
    var calls = 0;
    final report = MinimumConsumptionReportScreen(
      canRead: canRead,
      load: () {
        calls++;
        return pending.future;
      },
    );
    final host = MaterialApp(
      home: Stack(
        children: [
          report,
          ValueListenableBuilder<int>(
            valueListenable: revision,
            builder: (_, value, child) => _PermissionMutationHost(
              revision: value,
              onUpdate: () {
                canRead.value = false;
                canRead.value = true;
                pending.complete(Success([_row()]));
              },
            ),
          ),
        ],
      ),
    );
    await tester.pumpWidget(host);
    revision.value++;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('测试订位人'), findsNothing);
    expect(find.text('点击重试查询低消进度统计表'), findsOneWidget);
  });

  testWidgets('host disposal can revoke access before the report disposes', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            _PermissionMutationHost(
              revision: 0,
              onUpdate: () {},
              onDispose: () => canRead.value = false,
            ),
            MinimumConsumptionReportScreen(
              canRead: canRead,
              load: () => pending.future,
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: Text('已离开卡台页')));
    expect(tester.takeException(), isNull);
    pending.complete(Success([_row()]));
    await tester.pumpAndSettle();
    expect(find.text('已离开卡台页'), findsOneWidget);
    expect(find.text('测试订位人'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('close returns to the same original home state', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const Text('原卡台筛选：A 区'),
                TextButton(
                  onPressed: () => unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => MinimumConsumptionReportScreen(
                          canRead: canRead,
                          load: () async => const Success([]),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('打开报表'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开报表'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('原卡台筛选：A 区'), findsOneWidget);
    expect(find.byType(MinimumConsumptionReportScreen), findsNothing);
  });

  testWidgets('rows are virtualized and vertically scroll to the last record', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    await _pump(
      tester,
      canRead,
      () async => Success(
        List.generate(
          300,
          (i) => MinimumConsumptionReportRow.fromWire({'rn': '区域$i'}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('区域0'), findsOneWidget);
    expect(find.text('区域299'), findsNothing);
    final list = tester.widget<ListView>(find.byType(ListView));
    final verticalScrollbar = find.byWidgetPredicate(
      (widget) => widget is Scrollbar && widget.controller == list.controller,
    );
    expect(
      tester.getRect(verticalScrollbar).right,
      lessThanOrEqualTo(
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      ),
    );
    list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('区域299'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('区域0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  ValueNotifier<bool> canRead,
  MinimumConsumptionLoader load,
) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData.dark(),
    home: MinimumConsumptionReportScreen(load: load, canRead: canRead),
  ),
);

MinimumConsumptionReportRow _row([String person = '测试订位人']) =>
    MinimumConsumptionReportRow.fromWire({
      'rn': 'A 区',
      'sn': '001',
      'o': '2026-08-31 19:30',
      'sd': '预订部',
      'se': person,
      'm': '000800.00',
      'za': 100.5,
      'ga': -700,
      'p': '12.5625%',
      't': '',
      'mk': '原标签',
    });

const AppFailure _safeFailure = AppFailure(
  kind: FailureKind.network,
  code: 'network.unavailable',
  safeMessage: '网络不可用，请稍后重试',
);

final class _ReadAccess extends ValueNotifier<bool> {
  _ReadAccess(super.value);

  bool get isObserved => hasListeners;
}

final class _PermissionMutationHost extends StatefulWidget {
  const _PermissionMutationHost({
    required this.revision,
    required this.onUpdate,
    this.onDispose,
  });

  final int revision;
  final VoidCallback onUpdate;
  final VoidCallback? onDispose;

  @override
  State<_PermissionMutationHost> createState() =>
      _PermissionMutationHostState();
}

final class _PermissionMutationHostState
    extends State<_PermissionMutationHost> {
  @override
  void didUpdateWidget(_PermissionMutationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision != oldWidget.revision) widget.onUpdate();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
