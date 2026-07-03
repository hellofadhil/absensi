import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const hero = TextStyle(
    fontSize: 38,
    height: 1.08,
    letterSpacing: -1.1,
    fontWeight: FontWeight.w800,
  );

  static const pageTitle = TextStyle(
    fontSize: 30,
    height: 1.15,
    letterSpacing: -0.6,
    fontWeight: FontWeight.w800,
  );

  static const sectionTitle = TextStyle(
    fontSize: 22,
    height: 1.2,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w700,
  );

  static const cardTitle = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const small = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const label = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  static TextTheme textTheme({required Brightness brightness}) {
    final colors = brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return TextTheme(
      displayLarge: hero.copyWith(color: colors.textPrimary),
      headlineLarge: pageTitle.copyWith(color: colors.textPrimary),
      headlineMedium: sectionTitle.copyWith(color: colors.textPrimary),
      titleLarge: cardTitle.copyWith(color: colors.textPrimary),
      bodyLarge: body.copyWith(color: colors.textSecondary),
      bodyMedium: bodyMedium.copyWith(color: colors.textPrimary),
      bodySmall: small.copyWith(color: colors.textSecondary),
      labelLarge: label.copyWith(color: colors.textPrimary),
      labelSmall: caption.copyWith(color: colors.textMuted),
    );
  }
}
