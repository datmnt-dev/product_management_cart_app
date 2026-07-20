import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Assembles Material 3 [ThemeData] for light and dark modes from design tokens.
///
/// Role chrome accents are **not** defined here — use [AppRole.accentColor]
/// (`#7C3AED` admin / `#0F766E` manager / `#D97706` customer).
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = AppColors.brandPrimary(brightness);
    final secondary = AppColors.brandSecondary(brightness);
    final tertiary = AppColors.brandTertiary(brightness);
    final surface = AppColors.card(brightness);
    final scaffold = AppColors.scaffold(brightness);
    final elevated = AppColors.elevated(brightness);
    final error = AppColors.error(brightness);

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      error: error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme(scheme),
    );

    return base.copyWith(
      // ─── AppBar ────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: scheme.onSurface,
          letterSpacing: -.5,
        ),
      ),

      // ─── Cards ─────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.borderXl,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .25),
            width: 1.0,
          ),
        ),
      ),

      // ─── Divider ───────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .2),
        thickness: 1,
        space: 1,
      ),

      // ─── Buttons ───────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: .3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: .3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      // ─── FAB ───────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderXl),
      ),

      // ─── Input fields (no hard-coded Colors.white) ─────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? elevated : surface,
        border: OutlineInputBorder(
          borderRadius: AppRadii.borderLg,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderLg,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderLg,
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderLg,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.borderLg,
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return scheme.primary;
          return scheme.onSurfaceVariant;
        }),
      ),

      // ─── Dialogs ───────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: elevated,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderXxl),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: scheme.onSurface,
          letterSpacing: -.3,
        ),
      ),

      // ─── Bottom sheets ─────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxxl)),
        ),
      ),

      // ─── SnackBar ──────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? elevated : scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: isDark ? scheme.onSurface : scheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
        elevation: 4,
      ),

      // ─── Chips ─────────────────────────────────────────────────
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),

      // ─── ExpansionTile ─────────────────────────────────────────
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderXl),
        collapsedShape: RoundedRectangleBorder(borderRadius: AppRadii.borderXl),
      ),

      // ─── Checkbox / ListTile ───────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      listTileTheme: const ListTileThemeData(
        visualDensity: VisualDensity.compact,
      ),

      // ─── Segmented button ──────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
          ),
        ),
      ),

      // ─── PopupMenu ─────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: elevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderXl),
        elevation: 4,
      ),

      // ─── Navigation bar (M3 defaults; shell uses later) ────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? .28 : .14),
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
