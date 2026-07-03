import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 48.0;

  static const screenPadding = EdgeInsets.symmetric(horizontal: xl);
  static const cardPadding = EdgeInsets.all(lg);
  static const bottomNavigationClearance = 152.0;
}
