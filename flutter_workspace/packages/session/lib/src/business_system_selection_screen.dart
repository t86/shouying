import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:session/src/business_system.dart';
import 'package:session/src/session_models.dart';

typedef BusinessSystemAuthorization =
    Future<Result<MachineSession>> Function(BusinessSystem system);

final class BusinessSystemSelectionScreen extends StatefulWidget {
  const BusinessSystemSelectionScreen({
    required this.authorize,
    this.onSuperAdmin,
    this.onRegister,
    super.key,
  });

  static const Key bookingKey = Key('business-system-booking');
  static const Key orderKey = Key('business-system-order');
  static const Key cashierKey = Key('business-system-cashier');
  static const Key vipKey = Key('business-system-vip');
  static const Key erpWarehouseKey = Key('business-system-erp-warehouse');
  static const Key wineKey = Key('business-system-wine');
  static const Key queueKey = Key('business-system-queue');
  static const Key bmsKey = Key('business-system-bms');
  static const Key erpKey = Key('business-system-erp');
  static const Key superAdminKey = Key('business-system-super-admin');

  final BusinessSystemAuthorization authorize;
  final VoidCallback? onSuperAdmin;
  final VoidCallback? onRegister;

  @override
  State<BusinessSystemSelectionScreen> createState() =>
      _BusinessSystemSelectionScreenState();
}

final class _BusinessSystemSelectionScreenState
    extends State<BusinessSystemSelectionScreen> {
  BusinessSystem? _authorizing;
  AppFailure? _failure;

  @override
  Widget build(BuildContext context) {
    final systems = BusinessSystem.values
        .where((system) => system.client.termType != null)
        .toList(growable: false);
    final tier = BookingViewportTier.of(context);
    final columns = tier.isPhone ? 2 : 3;

    return Scaffold(
      backgroundColor: BookingTokens.canvasLogin,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              BookingTokens.canvasLogin,
              BookingTokens.surfacePanelDark,
              BookingTokens.canvasPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: tier.isPhone ? 16 : 28,
                vertical: tier.isPhone ? 20 : 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: tier.isPhone ? 460 : 760,
                ),
                child: Container(
                  padding: EdgeInsets.all(tier.isPhone ? 18 : 28),
                  decoration: BoxDecoration(
                    color: BookingTokens.surfaceLoginCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0x5932B9FF),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x401A89FF),
                        blurRadius: 28,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: BookingTokens.brandPrimary.withValues(
                                alpha: 0.22,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: BookingTokens.accentGlowBorder,
                              ),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: BookingTokens.textIceBlue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '选择登录系统',
                                  style: TextStyle(
                                    color: BookingTokens.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '选择业务系统后将自动完成终端授权，随后使用员工工号登录',
                                  style: TextStyle(
                                    color: BookingTokens.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Divider(color: BookingTokens.dividerBlue),
                      const SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: systems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: tier.isPhone ? 10 : 14,
                          mainAxisSpacing: tier.isPhone ? 10 : 14,
                          mainAxisExtent: tier.isPhone ? 68 : 74,
                        ),
                        itemBuilder: (context, index) {
                          final system = systems[index];
                          final isBooking = system == BusinessSystem.booking;
                          final busy = _authorizing == system;
                          return FilledButton(
                            key: _keyFor(system),
                            style: FilledButton.styleFrom(
                              backgroundColor: isBooking
                                  ? BookingTokens.brandPrimary
                                  : BookingTokens.surfaceHeader,
                              foregroundColor: BookingTokens.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isBooking
                                      ? BookingTokens.accentGlowBorder
                                      : BookingTokens.dividerBlue,
                                ),
                              ),
                            ),
                            onPressed: _authorizing == null
                                ? () => _authorize(system)
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  _iconFor(system),
                                  size: 18,
                                  color: isBooking
                                      ? BookingTokens.textPrimary
                                      : BookingTokens.textIceBlue,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    busy ? '${system.label}授权中…' : system.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (_failure case final failure?) ...<Widget>[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: BookingTokens.dangerRed.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: BookingTokens.dangerRed.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              failure.safeMessage,
                              style: const TextStyle(
                                color: Color(0xFFFF8FA3),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (widget.onRegister != null ||
                          widget.onSuperAdmin != null) ...<Widget>[
                        const SizedBox(height: 20),
                        const Divider(color: BookingTokens.tableBorder),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: <Widget>[
                            const Text(
                              '维护入口',
                              style: TextStyle(
                                color: BookingTokens.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (widget.onRegister != null)
                                  TextButton.icon(
                                    onPressed: _authorizing == null
                                        ? widget.onRegister
                                        : null,
                                    icon: const Icon(
                                      Icons.devices_other,
                                      size: 16,
                                    ),
                                    label: const Text('终端注册'),
                                  ),
                                if (widget.onSuperAdmin != null)
                                  TextButton.icon(
                                    key: BusinessSystemSelectionScreen
                                        .superAdminKey,
                                    onPressed: _authorizing == null
                                        ? widget.onSuperAdmin
                                        : null,
                                    icon: const Icon(
                                      Icons.admin_panel_settings_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('超级账号'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _authorize(BusinessSystem system) async {
    if (_authorizing != null) return;
    setState(() {
      _authorizing = system;
      _failure = null;
    });
    final result = await widget.authorize(system);
    if (!mounted) return;
    setState(() {
      _authorizing = null;
      _failure = result.failureOrNull;
    });
  }

  static IconData _iconFor(BusinessSystem system) => switch (system) {
    BusinessSystem.booking => Icons.event_seat_rounded,
    BusinessSystem.order => Icons.restaurant_menu_rounded,
    BusinessSystem.cashier => Icons.point_of_sale_rounded,
    BusinessSystem.vip => Icons.card_membership_rounded,
    BusinessSystem.erpWarehouse => Icons.warehouse_outlined,
    BusinessSystem.wine => Icons.wine_bar_rounded,
    BusinessSystem.queue => Icons.tv_rounded,
    BusinessSystem.bms => Icons.settings_applications_outlined,
    BusinessSystem.erp => Icons.inventory_2_outlined,
    BusinessSystem.superAdmin => Icons.admin_panel_settings_outlined,
  };

  static Key _keyFor(BusinessSystem system) => switch (system) {
    BusinessSystem.booking => BusinessSystemSelectionScreen.bookingKey,
    BusinessSystem.order => BusinessSystemSelectionScreen.orderKey,
    BusinessSystem.cashier => BusinessSystemSelectionScreen.cashierKey,
    BusinessSystem.vip => BusinessSystemSelectionScreen.vipKey,
    BusinessSystem.erpWarehouse =>
      BusinessSystemSelectionScreen.erpWarehouseKey,
    BusinessSystem.wine => BusinessSystemSelectionScreen.wineKey,
    BusinessSystem.queue => BusinessSystemSelectionScreen.queueKey,
    BusinessSystem.bms => BusinessSystemSelectionScreen.bmsKey,
    BusinessSystem.erp => BusinessSystemSelectionScreen.erpKey,
    BusinessSystem.superAdmin => BusinessSystemSelectionScreen.superAdminKey,
  };
}
