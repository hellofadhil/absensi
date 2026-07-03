import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

enum AppCardVariant { standard, softBlue, ai }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.standard,
    this.padding = AppSpacing.cardPadding,
    this.radius = AppRadius.card,
    this.showShadow = false,
    this.showBorder = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool showShadow;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, borderColor) = switch (variant) {
      AppCardVariant.standard => (
        context.appColors.surface,
        context.appColors.border,
      ),
      AppCardVariant.softBlue => (
        context.appColors.primarySoft,
        context.appColors.primaryBorder,
      ),
      AppCardVariant.ai => (
        context.appColors.aiSoft,
        context.appColors.aiBorder,
      ),
    };
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: showBorder ? Border.all(color: borderColor) : null,
        boxShadow: showShadow ? AppShadows.card : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
