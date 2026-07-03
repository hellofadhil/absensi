import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_controller.dart';

/// Reusable page header for top-level and detail pages.
///
/// Top-level pages normally show a title, language selector, and info action.
/// Detail pages normally show back navigation, a subtitle, and contextual
/// actions such as bookmark and info.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.showLanguageSelector = false,
    this.selectedLanguage = 'English',
    this.onLanguageTap,
    this.showBookmark = false,
    this.isBookmarked = false,
    this.onBookmarkTap,
    this.showInfo = false,
    this.onInfoTap,
    this.onBackTap,
    this.actions = const [],
    // Kept temporarily so existing pages can migrate incrementally.
    this.onHomePressed,
    this.onLanguagePressed,
    this.onBookmarkPressed,
    this.onInfoPressed,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool showLanguageSelector;
  final String selectedLanguage;
  final VoidCallback? onLanguageTap;
  final bool showBookmark;
  final bool isBookmarked;
  final VoidCallback? onBookmarkTap;
  final bool showInfo;
  final VoidCallback? onInfoTap;
  final VoidCallback? onBackTap;
  final List<Widget> actions;

  @Deprecated('Use showBackButton and onBackTap instead.')
  final VoidCallback? onHomePressed;
  @Deprecated('Use showLanguageSelector and onLanguageTap instead.')
  final VoidCallback? onLanguagePressed;
  @Deprecated('Use showBookmark and onBookmarkTap instead.')
  final VoidCallback? onBookmarkPressed;
  @Deprecated('Use showInfo and onInfoTap instead.')
  final VoidCallback? onInfoPressed;

  bool get _hasSubtitle => subtitle?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final height = _hasSubtitle ? 82.0 : 72.0;
    final effectiveShowBookmark = showBookmark || onBookmarkPressed != null;
    final effectiveShowInfo = showInfo || onInfoPressed != null;

    return SafeArea(
      bottom: false,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.appColors.navigation,
          border: Border(
            bottom: BorderSide(color: context.appColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (showBackButton) ...[
              _TopBarIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Kembali',
                onTap: onBackTap ?? () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  if (_hasSubtitle) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (effectiveShowBookmark) ...[
              const SizedBox(width: AppSpacing.xs),
              _TopBarIconButton(
                icon: isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                semanticLabel: isBookmarked
                    ? 'Hapus dari tersimpan'
                    : 'Simpan konten',
                isActive: isBookmarked,
                onTap: onBookmarkTap ?? onBookmarkPressed,
              ),
            ],
            if (effectiveShowInfo) ...[
              const SizedBox(width: AppSpacing.xs),
              _TopBarIconButton(
                icon: Icons.info_outline_rounded,
                semanticLabel: 'Informasi halaman',
                onTap: onInfoTap ?? onInfoPressed,
              ),
            ],
            const SizedBox(width: AppSpacing.xs),
            const _ThemeToggleButton(),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: isActive ? context.appColors.aiSoft : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: context.appColors.ai.withValues(alpha: 0.10),
          highlightColor: context.appColors.ai.withValues(alpha: 0.05),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              icon,
              size: 21,
              color: isActive
                  ? context.appColors.ai
                  : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = isDark ? 'Aktifkan mode terang' : 'Aktifkan mode gelap';

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: IconButton(
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          padding: EdgeInsets.zero,
          splashRadius: 22,
          color: context.appColors.primary,
          onPressed: () => ThemeControllerScope.of(
            context,
          ).toggle(Theme.of(context).brightness),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: RotationTransition(
                turns: Tween<double>(begin: 0.9, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
