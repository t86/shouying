import 'package:flutter/material.dart';

/// Responsive viewport tier for desktop (macOS/Windows), tablet (Android),
/// and phone (Android) layouts.
enum BookingViewportTier {
  phone,
  tablet,
  desktop;

  static const double tabletMinWidth = 720;
  static const double desktopMinWidth = 1200;

  static BookingViewportTier fromWidth(double width) {
    if (width >= desktopMinWidth) return BookingViewportTier.desktop;
    if (width >= tabletMinWidth) return BookingViewportTier.tablet;
    return BookingViewportTier.phone;
  }

  static BookingViewportTier of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isPhone => this == BookingViewportTier.phone;
  bool get isTablet => this == BookingViewportTier.tablet;
  bool get isDesktop => this == BookingViewportTier.desktop;
  bool get isCompact => this == BookingViewportTier.phone;
}

/// Source-aligned visual tokens for the Booking (S1) dark theme across
/// macOS, Windows, Android Tablet, and Android Phone.
final class BookingTokens {
  const BookingTokens._();

  // Surface hierarchy
  static const Color canvasPrimary = Color(0xFF202C4A);
  static const Color surfaceCanvas = canvasPrimary;
  static const Color canvasDeep = Color(0xFF08080A);
  static const Color surfaceMenu = canvasDeep;
  static const Color canvasLogin = Color(0xFF080B16);
  static const Color surfaceToolbar = Color(0xFF1E3152);
  static const Color surfaceHeader = Color(0xFF222D47);
  static const Color surfaceFooter = Color(0xFF0D172D);
  static const Color surfaceDrawer = Color(0xFF202C42);
  static const Color surfaceDrawerFooter = Color(0xFF161D33);
  static const Color surfacePanelDark = Color(0xFF11182D);
  static const Color surfaceLoginCard = Color(0xFF141D35);
  static const Color surfaceDialog = Color(0xFF1B2742);
  static const Color surfaceTableHeader = Color(0xFF182037);
  static const Color tableHeaderBg = surfaceTableHeader;
  static const Color tableRowAlt = surfaceLoginCard;
  static const Color surfaceTableRowDark = Color(0xFF0B0D15);
  static const Color surfaceTableStripe = Color(0xFF293449);
  static const Color surfaceRegionGroup = Color(0xFF2A3959);
  static const Color surfaceInput = Color(0x3D000000);
  static const Color surfaceSubtleTint = Color(0x0AFFFFFF);

  // Table 7-state semantic palette (high-contrast dark palette aligned with
  // 2026-11-19 Booking parity review & S1 visual restoration spec)
  static const Color statusEmpty = Color(0xFF465675);
  static const Color statusLock = Color(0xFF7D6A33);
  static const Color statusReserved = Color(0xFF008F95);
  static const Color statusOpened = Color(0xFFD08322);
  static const Color statusOrdered = Color(0xFFC83758);
  static const Color statusPartialPaid = Color(0xFFC83758);
  static const Color statusPaid = Color(0xFF5C3BC1);

  static Color bookingCardStatusColor(int status) => switch (status) {
    1 => statusEmpty,
    2 => statusLock,
    3 || 8 => statusReserved,
    4 => statusOpened,
    5 || 6 => statusOrdered,
    7 => statusPaid,
    _ => statusEmpty,
  };

  static Color statusColor(int status) => bookingCardStatusColor(status);

  // Brand and interaction accents
  static const Color brandPrimary = Color(0xFF455EFF);
  static const Color brandPrimaryLight = Color(0xFF4B89FF);
  static const Color brandSecondary = Color(0xFF374368);
  static const Color accentGlowBorder = Color(0xFF32B9FF);
  static const Color accentGlowShadow = Color(0xCC1A89FF);
  static const Color textIceBlue = Color(0xFFAED8FF);
  static const Color menuText = textIceBlue;
  static const Color surfaceIceWhite = Color(0xFFF8FEFF);
  static const Color surfaceIceAccent = Color(0xFFA9D1FA);
  static const Color dividerBlue = Color(0x802775BA);
  static const Color pillTopHighlight = Color(0xFF2775BA);
  static const Color focusBorder = Color(0xFF5C9FFF);
  static const Color outlineActionBorder = Color(0xFF2767BA);
  static const Color outlineActionText = Color(0xFF6A9EFF);

  // Badges and business semantics
  static const Color badgeOnline = Color(0xFF2FD1FF);
  static const Color badgeMark = Color(0xFFF1FF00);
  static const Color badgeLock = Color(0xFFFFBD00);
  static const Color badgeTipGreen = Color(0xFF1DC344);
  static const Color progressFull = Color(0xFF7CF5B0);
  static const Color dangerRed = Color(0xFFFF2F4B);
  static const Color dangerSoft = Color(0xFFF56C6C);
  static const Color successGreen = Color(0xFF67C23A);
  static const Color warningAmber = Color(0xFFFFAD45);
  static const Color discountOrange = Color(0xFFE6A23C);
  static const Color neutralBadge = Color(0xFF909399);
  static const Color selectYellow = Color(0xFFFDFF5F);
  static const Color reportLevelOneFill = Color(0x2E4B89FF);

  // Text hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xD1FFFFFF);
  static const Color textMuted = Color(0x85FFFFFF);
  static const Color textPlaceholder = Color(0x59FFFFFF);
  static const Color textDisabled = Color(0xBF606266);
  static const Color textOnIce = Color(0xFF08080A);

  // Input & card borders
  static const Color inputBorder = Color(0x26FFFFFF);
  static const Color cardTopHighlight = Color(0x8CFFFFFF);
  static const Color tableBorder = Color(0x1FFFFFFF);

  static const List<BoxShadow> glowShadow = <BoxShadow>[
    BoxShadow(color: accentGlowShadow, blurRadius: 12),
  ];

  static const List<BoxShadow> drawerShadow = <BoxShadow>[
    BoxShadow(color: Color(0x991A89FF), blurRadius: 16, offset: Offset(-2, 0)),
  ];

  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];
}

/// Unified dark Material theme for the Booking system and shared shell modals.
final class BookingTheme {
  const BookingTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: BookingTokens.brandPrimaryLight,
      onPrimary: BookingTokens.textPrimary,
      primaryContainer: BookingTokens.brandPrimary,
      onPrimaryContainer: BookingTokens.textPrimary,
      secondary: BookingTokens.accentGlowBorder,
      onSecondary: BookingTokens.textOnIce,
      secondaryContainer: BookingTokens.brandSecondary,
      onSecondaryContainer: BookingTokens.textPrimary,
      tertiary: BookingTokens.warningAmber,
      onTertiary: BookingTokens.textOnIce,
      tertiaryContainer: BookingTokens.canvasDeep,
      onTertiaryContainer: BookingTokens.textPrimary,
      error: BookingTokens.dangerRed,
      onError: BookingTokens.textPrimary,
      errorContainer: Color(0xFF5A1624),
      onErrorContainer: BookingTokens.textPrimary,
      surface: BookingTokens.surfaceDrawer,
      onSurface: BookingTokens.textPrimary,
      surfaceContainerLowest: BookingTokens.canvasDeep,
      surfaceContainerLow: BookingTokens.surfaceFooter,
      surfaceContainer: BookingTokens.surfacePanelDark,
      surfaceContainerHigh: BookingTokens.surfaceDialog,
      surfaceContainerHighest: BookingTokens.surfaceHeader,
      onSurfaceVariant: BookingTokens.textSecondary,
      outline: BookingTokens.dividerBlue,
      outlineVariant: BookingTokens.tableBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: BookingTokens.canvasPrimary,
      canvasColor: BookingTokens.surfaceDrawer,
      cardColor: BookingTokens.surfaceDialog,
      dividerColor: BookingTokens.dividerBlue,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: BookingTokens.inputBorder),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: BookingTokens.focusBorder, width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: BookingTokens.dangerSoft),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: BookingTokens.surfaceHeader,
        foregroundColor: BookingTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: BookingTokens.surfaceLoginCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: BookingTokens.tableBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BookingTokens.surfaceDialog,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: BookingTokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: BookingTokens.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x8032B9FF)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: BookingTokens.surfaceDrawer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: BookingTokens.surfaceDrawer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: BookingTokens.canvasDeep,
        surfaceTintColor: Colors.transparent,
        textStyle: const TextStyle(
          color: BookingTokens.textIceBlue,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: BookingTokens.accentGlowBorder),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(
            BookingTokens.canvasDeep,
          ),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          side: const WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: BookingTokens.accentGlowBorder),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BookingTokens.surfaceInput,
        labelStyle: const TextStyle(color: BookingTokens.textSecondary),
        hintStyle: const TextStyle(color: BookingTokens.textPlaceholder),
        prefixIconColor: BookingTokens.textSecondary,
        suffixIconColor: BookingTokens.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        disabledBorder: inputBorder,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BookingTokens.brandPrimaryLight,
          foregroundColor: BookingTokens.textPrimary,
          disabledBackgroundColor: BookingTokens.brandSecondary.withValues(
            alpha: 0.45,
          ),
          disabledForegroundColor: BookingTokens.textMuted,
          minimumSize: const Size(88, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BookingTokens.outlineActionText,
          side: const BorderSide(color: BookingTokens.outlineActionBorder),
          minimumSize: const Size(80, 38),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BookingTokens.textIceBlue,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: BookingTokens.surfaceFooter,
        selectedColor: BookingTokens.brandPrimary,
        disabledColor: BookingTokens.surfacePanelDark,
        labelStyle: const TextStyle(color: BookingTokens.textPrimary),
        secondaryLabelStyle: const TextStyle(color: BookingTokens.textPrimary),
        side: const BorderSide(color: BookingTokens.dividerBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.selected)
              ? BookingTokens.brandPrimaryLight
              : Colors.transparent,
        ),
        side: const BorderSide(color: BookingTokens.textMuted, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.selected)
              ? BookingTokens.brandPrimaryLight
              : BookingTokens.textMuted,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BookingTokens.dividerBlue,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BookingTokens.canvasDeep,
        contentTextStyle: const TextStyle(
          color: BookingTokens.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: BookingTokens.accentGlowBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(
          BookingTokens.textMuted.withValues(alpha: 0.45),
        ),
        radius: const Radius.circular(4),
        thickness: const WidgetStatePropertyAll<double>(6),
      ),
    );
  }
}
