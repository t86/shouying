import 'package:design_system/src/booking_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a responsive dark drawer matching Vue's `el-drawer` (`#202C42` body,
/// `#222D47` header, `#161D33` sticky footer):
/// - Desktop/Tablet/Web: right-side panel with subtle cyan-blue edge glow.
/// - Phone: full-height dark modal sheet that cleanly avoids the soft keyboard.
Future<T?> showBookingDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double desktopWidth = 560,
  double tabletWidthFactor = 0.78,
  bool barrierDismissible = true,
  RouteSettings? routeSettings,
}) {
  final tier = BookingViewportTier.of(context);
  if (tier.isPhone) {
    return showModalBottomSheet<T>(
      context: context,
      routeSettings: routeSettings,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: barrierDismissible,
      enableDrag: barrierDismissible,
      backgroundColor: BookingTokens.surfaceDrawer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          if (barrierDismissible)
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(sheetContext).maybePop(),
        },
        child: FractionallySizedBox(
          heightFactor: 0.94,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: builder(sheetContext),
          ),
        ),
      ),
    );
  }

  return showGeneralDialog<T>(
    context: context,
    routeSettings: routeSettings,
    barrierDismissible: barrierDismissible,
    barrierLabel: '关闭',
    barrierColor: const Color(0x88040814),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogContext, _, _) {
      final size = MediaQuery.sizeOf(dialogContext);
      final width = tier.isDesktop
          ? desktopWidth.clamp(360.0, size.width * 0.92)
          : (size.width * tabletWidthFactor).clamp(360.0, size.width * 0.94);
      return CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          if (barrierDismissible)
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(dialogContext).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: BookingTokens.surfaceDrawer,
              child: Container(
                width: width,
                height: size.height,
                decoration: const BoxDecoration(
                  color: BookingTokens.surfaceDrawer,
                  border: Border(
                    left: BorderSide(color: Color(0x6632B9FF)),
                  ),
                  boxShadow: BookingTokens.drawerShadow,
                ),
                child: SafeArea(
                  left: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
                    ),
                    child: builder(dialogContext),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// Standard dark drawer chrome with `#222D47` header, `#202C42` body, and
/// `#161D33` sticky action bar.
final class BookingDrawerScaffold extends StatelessWidget {
  const BookingDrawerScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.headerActions = const <Widget>[],
    this.footer,
    this.onClose,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> headerActions;
  final Widget body;
  final Widget? footer;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isPhone = BookingViewportTier.of(context).isPhone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: EdgeInsets.fromLTRB(isPhone ? 16 : 20, 8, 12, 8),
          decoration: BoxDecoration(
            color: BookingTokens.surfaceHeader,
            borderRadius: isPhone
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.zero,
            border: const Border(
              bottom: BorderSide(color: BookingTokens.dividerBlue),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: BookingTokens.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: BookingTokens.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ...headerActions,
              IconButton(
                tooltip: '关闭',
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.close,
                  color: BookingTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: BookingTokens.surfaceDrawer,
            child: body,
          ),
        ),
        if (footer != null)
          Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: BookingTokens.surfaceDrawerFooter,
              border: Border(
                top: BorderSide(color: BookingTokens.tableBorder),
              ),
            ),
            child: footer,
          ),
      ],
    );
  }
}

/// Unified dark confirmation dialog for Booking system actions.
/// Supports `Enter` to confirm and `Esc` to cancel.
Future<bool?> showBookingConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = '取消',
  String confirmLabel = '确定',
  bool destructive = false,
  Key? confirmKey,
  Key? cancelKey,
}) => showDialog<bool>(
  context: context,
  builder: (dialogContext) => CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.of(dialogContext).pop(false),
      const SingleActivator(LogicalKeyboardKey.enter): () =>
          Navigator.of(dialogContext).pop(true),
      const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
          Navigator.of(dialogContext).pop(true),
    },
    child: Focus(
      autofocus: true,
      child: AlertDialog(
        backgroundColor: BookingTokens.surfaceDialog,
        surfaceTintColor: Colors.transparent,
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x9932B9FF)),
        ),
        title: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
          decoration: const BoxDecoration(
            color: BookingTokens.surfaceHeader,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(bottom: BorderSide(color: BookingTokens.dividerBlue)),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                destructive ? Icons.warning_amber_rounded : Icons.help_outline,
                color: destructive
                    ? BookingTokens.warningAmber
                    : BookingTokens.accentGlowBorder,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: BookingTokens.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(dialogContext).pop(false),
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: BookingTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 440),
          child: Text(
            message,
            style: const TextStyle(
              color: BookingTokens.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            key: cancelKey,
            style: TextButton.styleFrom(
              backgroundColor: BookingTokens.brandSecondary,
              foregroundColor: BookingTokens.textPrimary,
              minimumSize: const Size(104, 40),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0x33FFFFFF)),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          const SizedBox(width: 8),
          BookingPrimaryPillButton(
            key: confirmKey,
            label: confirmLabel,
            backgroundColor: destructive
                ? BookingTokens.statusOrdered
                : BookingTokens.brandPrimary,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    ),
  ),
);

/// Primary pill CTA (`#4B89FF` / `#455EFF` with subtle top highlight).
final class BookingPrimaryPillButton extends StatelessWidget {
  const BookingPrimaryPillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = BookingTokens.brandPrimaryLight,
    this.minWidth = 104,
    this.height = 40,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final double minWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: BookingTokens.textPrimary,
      minimumSize: Size(minWidth, height),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(height / 2),
        side: const BorderSide(color: Color(0x4DFFFFFF)),
      ),
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 17),
        label: Text(label),
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

/// Secondary pill CTA (`#374368` with subtle top highlight).
final class BookingSecondaryPillButton extends StatelessWidget {
  const BookingSecondaryPillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.minWidth = 104,
    this.height = 40,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double minWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: BookingTokens.brandSecondary,
      foregroundColor: BookingTokens.textPrimary,
      minimumSize: Size(minWidth, height),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(height / 2),
        side: const BorderSide(color: Color(0x33FFFFFF)),
      ),
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 17),
        label: Text(label),
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

/// Outlined pill toolbar button matching `tabContent.less` (`新增预留`/`删除预留`).
final class BookingOutlinePillButton extends StatelessWidget {
  const BookingOutlinePillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive
        ? BookingTokens.dangerRed
        : BookingTokens.outlineActionText;
    final borderColor = destructive
        ? BookingTokens.dangerRed
        : BookingTokens.outlineActionBorder;
    final style = OutlinedButton.styleFrom(
      foregroundColor: fg,
      side: BorderSide(color: borderColor),
      minimumSize: const Size(104, 34),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

/// Signature ice-white rounded footer switch card (`#F8FEFF` / `#08080A`),
/// used for 「预留管理」 / 「预订管理」 navigation.
final class BookingIceSwitchCard extends StatelessWidget {
  const BookingIceSwitchCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: BookingTokens.surfaceIceWhite,
    borderRadius: BorderRadius.circular(compact ? 10 : 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: compact ? 72 : 84,
          minHeight: compact ? 40 : 50,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 10,
          vertical: compact ? 6 : 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          border: const Border.fromBorderSide(
            BorderSide(color: BookingTokens.surfaceIceAccent),
          ),
        ),
        child: compact
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 16, color: BookingTokens.textOnIce),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      color: BookingTokens.textOnIce,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 18, color: BookingTokens.textOnIce),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: BookingTokens.textOnIce,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
