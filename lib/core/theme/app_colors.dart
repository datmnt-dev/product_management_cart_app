import 'package:flutter/material.dart';

/// Brand and semantic color tokens for StoreFlow.
///
/// Role chrome colors live on [AppRole.accentColor] (canonical), not here.
abstract final class AppColors {
  // ─── Brand ──────────────────────────────────────────────────────
  static const Color brandPrimaryLight = Color(0xFF0D5C58);
  static const Color brandPrimaryDark = Color(0xFF3DABA5);

  static const Color brandSecondaryLight = Color(0xFFE07A5F);
  static const Color brandSecondaryDark = Color(0xFFF0A08C);

  static const Color brandTertiaryLight = Color(0xFF2D6A4F);
  static const Color brandTertiaryDark = Color(0xFF5FA882);

  // ─── Surfaces ───────────────────────────────────────────────────
  static const Color scaffoldLight = Color(0xFFF4F7F6);
  static const Color scaffoldDark = Color(0xFF0F1413);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A2220);

  static const Color elevatedLight = Color(0xFFFFFFFF);
  static const Color elevatedDark = Color(0xFF232B29);

  // ─── Semantic ───────────────────────────────────────────────────
  static const Color successLight = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF4ADE80);

  static const Color warningLight = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFFBBF24);

  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);

  /// Resolves brand primary for the given brightness.
  static Color brandPrimary(Brightness brightness) {
    return brightness == Brightness.dark
        ? brandPrimaryDark
        : brandPrimaryLight;
  }

  static Color brandSecondary(Brightness brightness) {
    return brightness == Brightness.dark
        ? brandSecondaryDark
        : brandSecondaryLight;
  }

  static Color brandTertiary(Brightness brightness) {
    return brightness == Brightness.dark
        ? brandTertiaryDark
        : brandTertiaryLight;
  }

  static Color scaffold(Brightness brightness) {
    return brightness == Brightness.dark ? scaffoldDark : scaffoldLight;
  }

  static Color card(Brightness brightness) {
    return brightness == Brightness.dark ? cardDark : cardLight;
  }

  static Color elevated(Brightness brightness) {
    return brightness == Brightness.dark ? elevatedDark : elevatedLight;
  }

  static Color success(Brightness brightness) {
    return brightness == Brightness.dark ? successDark : successLight;
  }

  static Color warning(Brightness brightness) {
    return brightness == Brightness.dark ? warningDark : warningLight;
  }

  static Color error(Brightness brightness) {
    return brightness == Brightness.dark ? errorDark : errorLight;
  }
}
