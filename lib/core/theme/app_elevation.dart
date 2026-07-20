import 'package:flutter/material.dart';

/// Soft elevation levels for cards, bars, and heroes.
abstract final class AppElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;

  static List<BoxShadow> softShadow(Color base, {double opacity = 0.08}) {
    return [
      BoxShadow(
        color: base.withValues(alpha: opacity),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }
}
