import 'package:flutter/material.dart';

/// Motion tokens. Prefer these over magic durations/curves.
///
/// When [MediaQuery.disableAnimationsOf] is true, animations should jump to end.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration enter = Duration(milliseconds: 400);
  static const Duration badge = Duration(milliseconds: 300);
  static const Duration chart = Duration(milliseconds: 600);

  static const Curve fastCurve = Curves.easeOut;
  static const Curve normalCurve = Curves.easeInOut;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve staggerCurve = Curves.easeOutBack;
  static const Curve badgeCurve = Curves.elasticOut;
  static const Curve chartCurve = Curves.easeOutCubic;

  /// Stagger delay for product grid: +40–60ms per index, capped at +400ms.
  static Duration staggerDelay(int index, {int stepMs = 50, int capMs = 400}) {
    final ms = (index * stepMs).clamp(0, capMs);
    return Duration(milliseconds: ms);
  }

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }
}
