import 'dart:async';

import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:card_table/src/erp_sout_workflow_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'erp_other_out_views_test.dart' show Loader;

class PrintLoader extends Loader {
  String status = '已完成';
  int reads = 0;
  Completer<void>? readGate;
  @override
  Future<Result<ErpSoutDocument>> loadOtherOutDocument(
    String id,
    ErpSoutDocumentMode mode,
  ) async {
    reads++;
    if (readGate != null) await readGate!.future;
    return Success(
      ErpSoutDocument({
        'code': 'PRINT-1',
        'status': status,
        'dtls': [
          {'id': 31, 'n': '果汁', 'c': 1, 'a': 2, 'sa': 3},
        ],
      }, mode),
    );
  }
}

Future<void> open(
  WidgetTester tester,
  PrintLoader loader, {
  ErpSoutPrint? print,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ErpAnotherOutLibView(loader: loader, onPrintDocument: print),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('查看详情'));
  await tester.pumpAndSettle();
}

Future<void> finishPdf(WidgetTester tester, bool Function() completed) async {
  for (var i = 0; i < 60 && !completed(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  expect(completed(), isTrue);
  await tester.pump();
}

void main() {
  testWidgets(
    'covered unknown result stays silent and retains duplicate lock',
    (tester) async {
      final completion = Completer<Result<void>>();
      bool Function()? guard;
      await open(
        tester,
        PrintLoader(),
        print: (_, _, allowed) {
          guard = allowed;
          return completion.future;
        },
      );
      await tester.tap(find.text('打印'));
      await finishPdf(tester, () => guard != null);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push<void>(
          MaterialPageRoute(builder: (_) => const Scaffold(body: Text('新页面'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(guard!(), isFalse);
      completion.complete(
        const FailureResult(
          AppFailure(
            kind: FailureKind.business,
            code: 'device.pdf_result_unknown',
            safeMessage: '未知',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('新页面'), findsOneWidget);
      expect(find.text('打印输出结果不确定，请核实，勿重复打印'), findsNothing);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '打印'))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('reversal dialog never offers print despite completed status', (
    tester,
  ) async {
    await open(
      tester,
      PrintLoader(),
      print: (_, _, _) async => const Success(null),
    );
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OUT1'));
    await tester.pump();
    await tester.tap(find.text('红冲'));
    await tester.pumpAndSettle();
    expect(find.text('确认分项红冲'), findsOneWidget);
    expect(find.text('打印'), findsNothing);
  });

  testWidgets(
    'only completed view prints; missing callback disabled; hc does not gate',
    (tester) async {
      final loader = PrintLoader()..hc = 2;
      await open(tester, loader);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '打印'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      loader.status = '待完成';
      await tester.tap(find.text('查看详情'));
      await tester.pumpAndSettle();
      expect(find.text('打印'), findsNothing);
    },
  );

  testWidgets(
    'printing re-reads latest view and dispatches PDF once during busy',
    (tester) async {
      final loader = PrintLoader()..hc = 2;
      var calls = 0;
      final completion = Completer<Result<void>>();
      await open(
        tester,
        loader,
        print: (bytes, name, allowed) async {
          calls++;
          expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
          expect(name, '其他出库单.pdf');
          expect(allowed(), isTrue);
          return completion.future;
        },
      );
      await tester.tap(find.text('打印'));
      await tester.tap(find.text('打印'));
      await finishPdf(tester, () => calls == 1);
      expect(loader.reads, 2);
      completion.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('已提交系统打印'), findsOneWidget);
      expect(calls, 1);
    },
  );

  testWidgets('latest status changes prevent dispatch', (tester) async {
    final loader = PrintLoader();
    var calls = 0;
    await open(
      tester,
      loader,
      print: (_, _, _) async {
        calls++;
        return const Success(null);
      },
    );
    loader.status = '已红冲';
    await tester.tap(find.text('打印'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('单据状态已变化，请重新打开详情'), findsOneWidget);
  });

  for (final close in [true, false]) {
    testWidgets(
      '${close ? 'close' : 'session change'} during preflight prevents dispatch',
      (tester) async {
        final loader = PrintLoader();
        var calls = 0;
        await open(
          tester,
          loader,
          print: (_, _, _) async {
            calls++;
            return const Success(null);
          },
        );
        loader.readGate = Completer<void>();
        await tester.tap(find.text('打印'));
        await tester.pump();
        if (close) {
          await tester.tap(find.text('关闭'));
        } else {
          loader.soutContext = Object();
        }
        loader.readGate!.complete();
        await tester.pumpAndSettle();
        expect(calls, 0);
        expect(find.text('已提交系统打印'), findsNothing);
      },
    );
  }

  testWidgets(
    'late result stays closed and dispatch guard expires immediately on back',
    (tester) async {
      final loader = PrintLoader();
      bool Function()? guard;
      final completion = Completer<Result<void>>();
      await open(
        tester,
        loader,
        print: (_, _, allowed) async {
          guard = allowed;
          return completion.future;
        },
      );
      await tester.tap(find.text('打印'));
      await finishPdf(tester, () => guard != null);
      expect(guard!(), isTrue);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      expect(guard!(), isFalse);
      completion.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('已提交系统打印'), findsNothing);
    },
  );

  for (final unknown in [false, true]) {
    testWidgets(
      '${unknown ? 'unknown locks' : 'cancel permits retry'} printing',
      (tester) async {
        var calls = 0;
        await open(
          tester,
          PrintLoader(),
          print: (_, _, _) async {
            calls++;
            return FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: unknown
                    ? 'device.pdf_result_unknown'
                    : 'device.pdf_not_accepted',
                safeMessage: '打印未完成',
              ),
            );
          },
        );
        await tester.tap(find.text('打印'));
        await finishPdf(tester, () => calls == 1);
        await tester.pumpAndSettle();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, '打印'),
        );
        expect(button.onPressed == null, unknown);
        expect(
          find.text(unknown ? '打印输出结果不确定，请核实，勿重复打印' : '打印已取消或未完成，可重试'),
          findsOneWidget,
        );
      },
    );
  }
}
