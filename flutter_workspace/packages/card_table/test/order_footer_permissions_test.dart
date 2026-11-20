import 'package:card_table/src/order_card_display.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permissions/permissions.dart';

PermissionSnapshot permission(Set<int> roles, {Set<int> modules = const {}}) =>
    PermissionSnapshot(
      available: true,
      stationId: 9,
      roleIds: roles,
      moduleIds: modules,
      subPermissions: const {},
    );

void main() {
  bool visible({
    Set<int> roles = const {},
    Set<int> modules = const {},
    bool cashier = false,
    bool? checked,
    bool pc = true,
    bool wide = false,
    bool safe = false,
    Object? regions = const [],
    String? region = '2',
  }) => OrderCardDisplay.canShowFooterAmounts(
    permissions: permission(roles, modules: modules),
    isPc: pc,
    isCashier: cashier,
    canLookOrderAmount: checked,
    regionId: region,
    supervisorRegions: regions,
    isWide: wide,
    safeModeEnabled: safe,
  );
  test('ordinary actors require explicit server permission; cashier bypasses only that check', () {
    expect(visible(), false);
    expect(visible(checked: false), false);
    expect(visible(checked: true), true);
    expect(visible(cashier: true), true);
    for (final role in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
      expect(visible(roles: {role}, checked: true), true, reason: 'role $role');
      expect(visible(roles: {role}, checked: false), false, reason: 'role $role');
    }
    expect(visible(cashier: true, roles: {3}, modules: {12, 99}), false);
    expect(
      visible(cashier: true, roles: {3}, modules: {12, 99}, pc: false),
      true,
    );
  });
  test('supervisor uses dataset56 station/status and whole venue zero, on all platforms', () {
    expect(visible(roles: {11}, checked: true), false);
    expect(
      visible(
        roles: {11},
        checked: true,
        regions: [
          [9, 2, 1],
        ],
      ),
      true,
    );
    expect(
      visible(
        roles: {11},
        checked: true,
        regions: [
          [9, 0, 1],
        ],
      ),
      true,
    );
    for (final rows in [
      null,
      [
        [8, 2, 1],
      ],
      [
        [9, 2, 0],
      ],
      [
        [9, 3, 1],
      ],
      [
        [9],
      ],
      'bad',
    ]) {
      expect(
        visible(cashier: true, roles: {11}, regions: rows, pc: false),
        false,
      );
    }
    expect(
      visible(
        roles: {11},
        checked: true,
        region: null,
        regions: [
          [9, 0, 1],
        ],
      ),
      false,
    );
  });
  test(
    'wide safety guard differs from portrait; unknown permissions always deny',
    () {
      expect(visible(checked: true, wide: true, safe: true), false);
      expect(visible(checked: true, wide: false, safe: true), true);
      expect(
        OrderCardDisplay.canShowFooterAmounts(
          permissions: null,
          isPc: false,
          isCashier: true,
          canLookOrderAmount: true,
          regionId: '2',
          supervisorRegions: [],
          isWide: false,
          safeModeEnabled: false,
        ),
        false,
      );
    },
  );
}
