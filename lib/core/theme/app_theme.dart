import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light =>
      _build(brightness: Brightness.light, colors: AppColors.light);

  static ThemeData get dark =>
      _build(brightness: Brightness.dark, colors: AppColors.dark);

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.textInverse,
      primaryContainer: colors.primarySoft,
      onPrimaryContainer: colors.textPrimary,
      secondary: colors.ai,
      onSecondary: colors.textInverse,
      secondaryContainer: colors.aiSoft,
      onSecondaryContainer: colors.textPrimary,
      error: colors.danger,
      onError: colors.textInverse,
      errorContainer: colors.dangerSoft,
      onErrorContainer: colors.textPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.border,
      outlineVariant: colors.border,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.background,
      inversePrimary: colors.primary,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: BorderSide(color: colors.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [colors],
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      cardColor: colors.surface,
      disabledColor: colors.textDisabled,
      textTheme: AppTypography.textTheme(brightness: brightness),
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: colors.border),
        ),
      ),
      iconTheme: IconThemeData(color: colors.textSecondary),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 54),
          backgroundColor: colors.primary,
          foregroundColor: colors.textInverse,
          disabledBackgroundColor: colors.surfaceSoft,
          disabledForegroundColor: colors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 54),
          foregroundColor: colors.primaryPressed,
          disabledForegroundColor: colors.textDisabled,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textMuted),
        errorStyle: TextStyle(color: colors.danger),
        enabledBorder: inputBorder,
        border: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.6)),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.cardTitle.copyWith(
          color: colors.textPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: colors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        modalBackgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colors.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: TextStyle(color: colors.textPrimary),
        actionTextColor: colors.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.border,
        circularTrackColor: colors.border,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.textMuted),
        trackColor: WidgetStatePropertyAll(colors.surfaceSoft),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        textStyle: TextStyle(color: colors.textPrimary, fontSize: 12),
      ),
    );
  }
}
