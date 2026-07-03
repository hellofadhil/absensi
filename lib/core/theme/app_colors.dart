import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.primaryBorder,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSoft,
    required this.navigation,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textInverse,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.ai,
    required this.aiPressed,
    required this.aiSoft,
    required this.aiBorder,
  });

  static const light = AppColors(
    primary: Color(0xFF0A84FF),
    primaryPressed: Color(0xFF0066D6),
    primarySoft: Color(0xFFEAF4FF),
    primaryBorder: Color(0xFFCFE6FF),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF1F5F9),
    navigation: Color(0xFFF8FAFC),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    textDisabled: Color(0xFF9CA3AF),
    textInverse: Color(0xFFFFFFFF),
    success: Color(0xFF10B981),
    successSoft: Color(0xFFECFDF5),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0xFFFFF7E6),
    danger: Color(0xFFEF4444),
    dangerSoft: Color(0xFFFEF2F2),
    ai: Color(0xFF8B5CF6),
    aiPressed: Color(0xFF7546DF),
    aiSoft: Color(0xFFF3E8FF),
    aiBorder: Color(0xFFE4D4FF),
  );

  static const dark = AppColors(
    primary: Color(0xFF4EA1FF),
    primaryPressed: Color(0xFF2F86E8),
    primarySoft: Color(0xFF132A40),
    primaryBorder: Color(0x664EA1FF),
    background: Color(0xFF101114),
    surface: Color(0xFF181A20),
    surfaceElevated: Color(0xFF20232B),
    surfaceSoft: Color(0xFF20232B),
    navigation: Color(0xFF16181D),
    border: Color(0xFF2E323D),
    textPrimary: Color(0xFFF5F7FB),
    textSecondary: Color(0xFFA7AFBD),
    textMuted: Color(0xFF7F8795),
    textDisabled: Color(0xFF666D79),
    textInverse: Color(0xFF101114),
    success: Color(0xFF2ED39A),
    successSoft: Color(0xFF143127),
    warning: Color(0xFFFFB547),
    warningSoft: Color(0xFF382A14),
    danger: Color(0xFFFF6B72),
    dangerSoft: Color(0xFF3B1C20),
    ai: Color(0xFFA675FF),
    aiPressed: Color(0xFF8958E8),
    aiSoft: Color(0xFF291D3C),
    aiBorder: Color(0x66A675FF),
  );

  final Color primary;
  final Color primaryPressed;
  Color get primaryDeep => primaryPressed;
  final Color primarySoft;
  final Color primaryBorder;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSoft;
  final Color navigation;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color textInverse;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color ai;
  final Color aiPressed;
  final Color aiSoft;
  final Color aiBorder;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryBorder: Color.lerp(primaryBorder, other.primaryBorder, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      navigation: Color.lerp(navigation, other.navigation, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      ai: Color.lerp(ai, other.ai, t)!,
      aiPressed: Color.lerp(aiPressed, other.aiPressed, t)!,
      aiSoft: Color.lerp(aiSoft, other.aiSoft, t)!,
      aiBorder: Color.lerp(aiBorder, other.aiBorder, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
