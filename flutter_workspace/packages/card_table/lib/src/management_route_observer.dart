import 'package:flutter/widgets.dart';

/// Tracks only management-owned dialogs and explicitly marked child pages.
final class ManagementRouteObserver extends NavigatorObserver {
  static const childRouteName = 'management-child';
  final _registrations = <Route<dynamic>, int>{};
  final _owners = <Route<dynamic>, Route<dynamic>>{};
  final _pendingRemoval = <Route<dynamic>>{};
  bool _cleanupScheduled = false;

  void registerOwner(Route<dynamic> owner) {
    _registrations.update(owner, (count) => count + 1, ifAbsent: () => 1);
  }

  void unregisterOwner(Route<dynamic> owner) {
    final count = _registrations[owner] ?? 0;
    if (count > 1) {
      _registrations[owner] = count - 1;
    } else {
      _registrations.remove(owner);
      _cleanupOwner(owner);
    }
  }

  void closeOwnedRoutes(Route<dynamic> owner) {
    if (!owner.isActive) return;
    _queueCleanup(
      _owners.entries
          .where((entry) => identical(entry.value, owner))
          .map((entry) => entry.key),
    );
  }

  /// Call synchronously when the authenticated user changes. Capture existing
  /// routes now; deferred cleanup must not include the next user's new routes.
  void closeAllOwnedRoutes() => _queueCleanup(_owners.keys);

  void _cleanupOwner(Route<dynamic> owner) {
    _queueCleanup(
      _owners.entries
          .where((entry) => identical(entry.value, owner))
          .map((entry) => entry.key),
    );
    _owners.removeWhere((route, value) => identical(value, owner));
  }

  void _queueCleanup(Iterable<Route<dynamic>> routes) {
    _pendingRemoval.addAll(routes);
    if (_cleanupScheduled || _pendingRemoval.isEmpty) return;
    _cleanupScheduled = true;
    // didRemove/didReplace may run while Navigator is locked. A frame also
    // covers calls made during widget rebuilding or from an idle session event.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = _pendingRemoval.toList().reversed;
      _pendingRemoval.clear();
      _cleanupScheduled = false;
      for (final route in pending) {
        if (route.isActive) route.navigator?.removeRoute(route);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final owner = _registrations.containsKey(previousRoute)
        ? previousRoute
        : _owners[previousRoute];
    if (owner != null &&
        (route is PopupRoute || route.settings.name == childRouteName)) {
      _owners[route] = owner;
    }
  }

  void _forget(Route<dynamic> route) {
    _owners.remove(route);
    if (_registrations.remove(route) != null) {
      _cleanupOwner(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final owner = _owners[oldRoute];
    if (oldRoute != null) _forget(oldRoute);
    if (newRoute != null &&
        owner != null &&
        (newRoute is PopupRoute || newRoute.settings.name == childRouteName)) {
      _owners[newRoute] = owner;
    }
  }
}
