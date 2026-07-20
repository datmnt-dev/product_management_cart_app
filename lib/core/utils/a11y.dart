import 'package:flutter/material.dart';

/// Accessibility helpers for StoreFlow (lab bar).
abstract final class AppA11y {
  /// Minimum interactive target size (Material / WCAG-minded).
  static const double minTouchTarget = 44;

  /// Whether the platform requests reduced motion.
  static bool reduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// Effective text scale factor for layout QA (e.g. 1.3).
  static double textScale(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1);
  }

  /// Constrain a child to at least [minTouchTarget] for hit testing.
  static Widget ensureMinTapTarget({
    required Widget child,
    double minSize = minTouchTarget,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: child,
    );
  }
}
