import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

enum AppBottomDestination { home, calendar, scan, history, profile }

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedDestination,
    required this.onDestinationSelected,
    this.isGuru = false,
  });

  final AppBottomDestination selectedDestination;
  final ValueChanged<AppBottomDestination> onDestinationSelected;
  final bool isGuru;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final colors = context.appColors;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: 108 + safeBottom,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _NotchedBarPainter(
                  backgroundColor: colors.navigation,
                  borderColor: colors.border,
                ),
              ),
            ),
            Positioned(
              top: 32,
              left: 8,
              right: 8,
              bottom: safeBottom,
              child: Row(
                children: [
                  _NavigationItem(
                    label: 'Beranda',
                    icon: Icons.home_rounded,
                    isSelected:
                        selectedDestination == AppBottomDestination.home,
                    onTap: () =>
                        onDestinationSelected(AppBottomDestination.home),
                  ),
                  _NavigationItem(
                    label: isGuru ? 'Siswa' : 'Jadwal',
                    icon: isGuru ? Icons.people_alt_rounded : Icons.calendar_month_rounded,
                    isSelected:
                        selectedDestination == AppBottomDestination.calendar,
                    onTap: () =>
                        onDestinationSelected(AppBottomDestination.calendar),
                  ),
                  const Expanded(child: SizedBox()),
                  _NavigationItem(
                    label: 'Riwayat',
                    icon: Icons.history_rounded,
                    isSelected:
                        selectedDestination == AppBottomDestination.history,
                    onTap: () =>
                        onDestinationSelected(AppBottomDestination.history),
                  ),
                  _NavigationItem(
                    label: 'Profil',
                    icon: Icons.account_circle_rounded,
                    isSelected:
                        selectedDestination == AppBottomDestination.profile,
                    onTap: () =>
                        onDestinationSelected(AppBottomDestination.profile),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 14,
              child: Semantics(
                label: 'Presensi',
                button: true,
                selected: selectedDestination == AppBottomDestination.scan,
                child: InkResponse(
                  onTap: () =>
                      onDestinationSelected(AppBottomDestination.scan),
                  radius: 36,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.appColors.primary,
                      border: Border.all(
                        color: context.appColors.primaryBorder,
                        width: 4,
                      ),
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? const []
                          : AppShadows.ai,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: context.appColors.textInverse,
                      size: 31,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 84,
              child: Text(
                'Presensi',
                style: TextStyle(
                  color: selectedDestination == AppBottomDestination.scan
                      ? context.appColors.primary
                      : context.appColors.textSecondary,
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.iconBuilder,
  }) : assert(icon != null || iconBuilder != null);

  final String label;
  final IconData? icon;
  final Widget Function(Color color)? iconBuilder;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? context.appColors.primaryDeep
        : context.appColors.textMuted;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconBuilder?.call(color) ?? Icon(icon, color: color, size: 27),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    height: 1,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter({
    required this.backgroundColor,
    required this.borderColor,
  });

  final Color backgroundColor;
  final Color borderColor;

  static const _top = 32.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final path = Path()
      ..moveTo(0, _top)
      ..lineTo(center - 54, _top)
      ..cubicTo(center - 44, _top, center - 42, 38, center - 36, 45)
      ..cubicTo(center - 28, 55, center - 19, 62, center, 62)
      ..cubicTo(center + 19, 62, center + 28, 55, center + 36, 45)
      ..cubicTo(center + 42, 38, center + 44, _top, center + 54, _top)
      ..lineTo(size.width, _top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = backgroundColor);

    final topEdge = Path()
      ..moveTo(0, _top)
      ..lineTo(center - 54, _top)
      ..cubicTo(center - 44, _top, center - 42, 38, center - 36, 45)
      ..cubicTo(center - 28, 55, center - 19, 62, center, 62)
      ..cubicTo(center + 19, 62, center + 28, 55, center + 36, 45)
      ..cubicTo(center + 42, 38, center + 44, _top, center + 54, _top)
      ..lineTo(size.width, _top);

    canvas.drawPath(
      topEdge,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) =>
      backgroundColor != oldDelegate.backgroundColor ||
      borderColor != oldDelegate.borderColor;
}
