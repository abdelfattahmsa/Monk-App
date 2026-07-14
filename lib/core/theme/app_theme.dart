import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// DESIGN SYSTEM v3.0 — Monk
// ══════════════════════════════════════════════════════════════

/// Spacing system based on 4px grid
class Spacing {
  Spacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;

  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = w >= 768 ? 24.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: h, vertical: lg);
  }

  static const cardPadding = EdgeInsets.all(md);
  static const cardPaddingCompact =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

/// Responsive breakpoints
class Breakpoints {
  Breakpoints._();
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= tablet && w < desktop;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}

/// Central color palette
class AppColors {
  AppColors._();

  // ── DARK BACKGROUNDS ─────────────────────────────────────────
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF111111);
  static const card = Color(0xFF1A1A1A);
  static const cardHover = Color(0xFF222222);
  static const cardAlt = Color(0xFF222222);
  static const border = Color(0xFF2A2A2A);
  static const borderLight = Color(0xFF333333);

  // ── ACCENT — GREEN (primary) ──────────────────────────────────
  static const accent = Color(0xFF22C55E);
  static const accentLight = Color(0xFF4ADE80);
  static const accentDim = Color(0xFF166534);
  static const accentFaint = Color(0xFF052E16);

  // ── BRAND GOLD (logo / category highlights only) ──────────────
  static const gold = Color(0xFFC8A050);
  static const goldLight = Color(0xFFE8C97A);
  static const goldDim = Color(0xFF5A4418);
  static const goldFaint = Color(0xFF2A2010);

  // ── LIGHT MODE ────────────────────────────────────────────────
  static const lightBg = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF1F5F9);
  static const lightCardHover = Color(0xFFE8EEF6);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightBorderStrong = Color(0xFFCBD5E1);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightTextMuted = Color(0xFFCBD5E1);

  // ── CATEGORY COLORS ───────────────────────────────────────────
  static const deen    = Color(0xFF54C478);
  static const learn   = Color(0xFF6A8EF0);
  static const project = Color(0xFFAA70EE);
  static const health  = Color(0xFFD07848);
  static const work    = Color(0xFFC09840);
  static const fasting = Color(0xFFE08840);
  static const commute = Color(0xFF3AB8A8);
  static const rest    = Color(0xFF6B6080);

  // ── SEMANTIC ─────────────────────────────────────────────────
  static const success = Color(0xFF54C478);
  static const error = Color(0xFFE05050);
  static const warning = Color(0xFFE08840);
  static const info = Color(0xFF6A8EF0);

  // ── EVENT TYPES ──────────────────────────────────────────────
  static const personal = Color(0xFFE879A0);
  static const islamic = Color(0xFF54C478);
  static const finance = Color(0xFF3AB8A8);
  static const quran = Color(0xFF7ED4A0);
  static const travel = Color(0xFFF0C060);
  static const family = Color(0xFFF06870);
  static const done = Color(0xFF405040);

  // ── DARK TEXT ─────────────────────────────────────────────────
  static const textPrimary = Color(0xFFE8E8E8);
  static const textSecondary = Color(0xFF888888);
  static const textMuted = Color(0xFF444444);

  static Color categoryColor(String key) {
    return switch (key) {
      'deen'                           => deen,
      'learn' || 'pmp' || 'study'      => learn,
      'project' || 'kyb' || 'kyberia'  => project,
      'health'                         => health,
      'work'                           => work,
      'fast' || 'fasting'              => fasting,
      'com' || 'commute'               => commute,
      'rest'                           => rest,
      'personal'                       => personal,
      'islamic'                        => islamic,
      'finance'                        => finance,
      'quran'                          => quran,
      'travel' => travel,
      'family' => family,
      'done' => done,
      'milestone' => gold,
      _ => textSecondary,
    };
  }

  static Color categoryBg(String key) =>
      categoryColor(key).withValues(alpha: 0.08);
}

class AppTheme {
  AppTheme._();

  // ── DARK THEME ────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto', // global fallback for any TextStyle without explicit fontFamily
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
      ),
      textTheme: _darkTextTheme,
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent, size: 20);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.accent,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            );
        }),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        height: 64,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardAlt,
        contentTextStyle:
            const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.border),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.accent,
        overlayColor: Color(0x2222C55E),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          ),
      ),
    );
  }

  // ── LIGHT THEME ───────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto', // global fallback for any TextStyle without explicit fontFamily
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorderStrong,
      ),
      textTheme: _lightTextTheme,
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(
            color: AppColors.lightTextSecondary, fontSize: 12),
        hintStyle:
            const TextStyle(color: AppColors.lightTextMuted, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextSecondary,
          side: const BorderSide(color: AppColors.lightBorder),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.12),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent, size: 20);
          }
          return const IconThemeData(
              color: AppColors.lightTextSecondary, size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.accent,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: AppColors.lightTextSecondary,
            fontSize: 9,
            );
        }),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        height: 64,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightCard,
        contentTextStyle:
            const TextStyle(color: AppColors.lightTextPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightCard,
        side: const BorderSide(color: AppColors.lightBorder),
        labelStyle: const TextStyle(
          fontSize: 10,
          color: AppColors.lightTextSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.lightTextSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.lightBorder),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.lightBorder,
        thumbColor: AppColors.accent,
        overlayColor: Color(0x2222C55E),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.lightCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.lightBorder),
        ),
        textStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 11,
          ),
      ),
    );
  }

  // ── TEXT THEMES ───────────────────────────────────────────────

  static const _darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 40,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      letterSpacing: -1,
    ),
    displayMedium: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 11,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
    ),
    labelSmall: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
      color: AppColors.textSecondary,
    ),
  );

  static const _lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 40,
      fontWeight: FontWeight.w900,
      color: AppColors.lightTextPrimary,
      letterSpacing: -1,
    ),
    displayMedium: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextSecondary,
      letterSpacing: 0.5,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      color: AppColors.lightTextPrimary,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12,
      color: AppColors.lightTextPrimary,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 11,
      color: AppColors.lightTextSecondary,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.lightTextPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
      color: AppColors.lightTextPrimary,
    ),
    labelSmall: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
      color: AppColors.lightTextSecondary,
    ),
  );
}
