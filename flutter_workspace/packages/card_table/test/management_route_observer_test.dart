import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final operation in ['identity', 'remove', 'replace']) {
    testWidgets(
      '$operation cleanup removes only A-owned routes, preserving new login and popup',
      (tester) async {
        final observer = ManagementRouteObserver();
        final navigator = GlobalKey<NavigatorState>();
        final cleanup = ValueNotifier(false);
        addTearDown(cleanup.dispose);
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            navigatorObservers: [observer],
            home: ValueListenableBuilder<bool>(
              valueListenable: cleanup,
              builder: (_, value, _) {
                if (value) observer.closeAllOwnedRoutes();
                return const Scaffold(body: Text('管理A'));
              },
            ),
          ),
        );
        final owner = ModalRoute.of(tester.element(find.text('管理A')))!;
        observer.registerOwner(owner);
        final detail = MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: ManagementRouteObserver.childRouteName,
          ),
          builder: (_) => const Scaffold(body: Text('A详情')),
        );
        unawaited(navigator.currentState!.push(detail));
        await tester.pumpAndSettle();
        final oldPopup = DialogRoute<void>(
          context: tester.element(find.text('A详情')),
          builder: (_) => const AlertDialog(title: Text('A弹窗')),
        );
        unawaited(navigator.currentState!.push(oldPopup));
        await tester.pumpAndSettle();
        final login = MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('新登录')),
        );
        unawaited(navigator.currentState!.push(login));
        await tester.pumpAndSettle();
        final loginPopup = DialogRoute<void>(
          context: tester.element(find.text('新登录')),
          builder: (_) => const AlertDialog(title: Text('新登录弹窗')),
        );
        unawaited(navigator.currentState!.push(loginPopup));
        await tester.pumpAndSettle();
        if (operation == 'identity') {
          // Invoke during a build to exercise Navigator's locked/frame boundary.
          cleanup.value = true;
        } else if (operation == 'remove') {
          navigator.currentState!.removeRoute(owner);
        } else {
          navigator.currentState!.replace(
            oldRoute: owner,
            newRoute: MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('替换根页')),
            ),
          );
        }
        await tester.pumpAndSettle();
        expect(detail.isActive, isFalse);
        expect(oldPopup.isActive, isFalse);
        expect(login.isActive, isTrue);
        expect(loginPopup.isActive, isTrue);
        expect(find.text('新登录弹窗'), findsOneWidget);
        expect(find.text('新登录'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
