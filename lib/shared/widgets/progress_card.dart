import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_button.dart';
import 'app_card.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.progress,
    required this.actionLabel,
    required this.onPressed,
  });

  final String eyebrow;
  final String title;
  final String description;
  final double progress;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    final percentage = (normalizedProgress * 100).round();

    return AppCard(
      variant: AppCardVariant.softBlue,
      radius: AppRadius.featureCard,
      padding: const EdgeInsets.all(AppSpacing.xl),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(
                  Icons.play_lesson_rounded,
                  color: context.appColors.primaryDeep,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: context.appColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleLarge!),
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: Theme.of(context).textTheme.bodySmall!),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: LinearProgressIndicator(
                    value: normalizedProgress,
                    minHeight: 7,
                    color: context.appColors.primary,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? context.appColors.textPrimary.withValues(alpha: 0.12)
                        : context.appColors.surface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.labelLarge!,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: actionLabel,
            onPressed: onPressed,
            icon: onPressed == null ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}
