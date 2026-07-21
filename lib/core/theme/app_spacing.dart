import 'package:flutter/material.dart';

/// Spacing scale for StoreFlow layouts.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets pagePaddingLg = EdgeInsets.fromLTRB(md, sm, md, xxxl);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}
