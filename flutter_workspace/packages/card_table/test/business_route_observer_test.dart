import 'dart:async';

import 'package:card_table/src/business_route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'cleans captured business page/dialog identities without closing new login routes',
    (tester) async {
      final observer = BusinessRouteObserver();
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [observer],
          home: const Scaffold(body: Text('卡台')),
        ),
      );
      final owner = ModalRoute.of(tester.element(find.text('卡台')))!;
      observer.registerOwner(owner);
      final business = MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: BusinessRouteObserver.childRouteName,
        ),
        builder: (_) => const Scaffold(body: Text('旧支付页')),
      );
      unawaited(nav.currentState!.push(business));
      await tester.pumpAndSettle();
      unawaited(
        showDialog<void>(
          context: tester.element(find.text('旧支付页')),
          builder: (_) => const AlertDialog(title: Text('旧确认弹窗')),
        ),
      );
      await tester.pumpAndSettle();
      observer.closeAllOwnedRoutes();
      // Before deferred removal runs, a new, unrelated route may already exist.
      unawaited(
        nav.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('新登录页')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(business.isActive, false);
      expect(find.text('旧确认弹窗'), findsNothing);
      expect(find.text('新登录页'), findsOneWidget);
      unawaited(
        showDialog<void>(
          context: tester.element(find.text('新登录页')),
          builder: (_) => const AlertDialog(title: Text('新登录弹窗')),
        ),
      );
      await tester.pumpAndSettle();
      // A late completion/disposal from the retired owner cannot close these.
      observer.closeOwnedRoutes(owner);
      observer.unregisterOwner(owner);
      await tester.pumpAndSettle();
      expect(find.text('新登录页'), findsOneWidget);
      expect(find.text('新登录弹窗'), findsOneWidget);
    },
  );
}
