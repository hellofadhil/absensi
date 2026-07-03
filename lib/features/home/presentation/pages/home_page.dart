import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:absensi/core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/progress_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final displayName = authState is Authenticated ? authState.user.displayName : 'Pengguna';

    return AppScaffold(
      topBar: AppTopBar(
        title: 'Absensi Sekolah',
        onHomePressed: () {},
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: context.appColors.danger),
            tooltip: 'Keluar Akun',
            onPressed: () {
              showGeneralDialog<void>(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Keluar',
                barrierColor: Colors.black.withValues(alpha: 0.4),
                transitionDuration: const Duration(milliseconds: 240),
                pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
                transitionBuilder: (context, anim, anim2, child) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                        ),
                        child: AlertDialog(
                          title: const Text('Keluar Akun'),
                          content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Batal',
                                style: TextStyle(color: context.appColors.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                ref.read(authProvider.notifier).logout();
                              },
                              child: Text(
                                'Keluar',
                                style: TextStyle(
                                  color: context.appColors.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.home,
        onDestinationSelected: (destination) =>
            _handleNavigation(context, destination),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.bottomNavigationClearance,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $displayName \u{1F44B}',
              style: Theme.of(context).textTheme.headlineLarge!,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sudahkah Anda melakukan presensi hari ini?',
              style: Theme.of(context).textTheme.bodyLarge!,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ProgressCard(
              eyebrow: 'Kehadiran Bulan Ini',
              title: 'Persentase Kehadiran',
              description: 'Pertahankan kehadiran Anda untuk tetap di atas batas minimum sekolah (85%).',
              progress: 0.9,
              actionLabel: 'Lakukan Presensi Sekarang',
              onPressed: () => _showComingSoon(context, 'Presensi'),
            ),
            const SizedBox(height: AppSpacing.md),
            const _AttendanceStatsCard(),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(title: 'Jadwal Hari Ini'),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () => _showComingSoon(context, 'Detail Kelas'),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.appColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Icon(Icons.calculate_rounded, color: context.appColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matematika (Wajib)',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '08:00 - 09:30 • Ruang 204',
                          style: Theme.of(context).textTheme.bodySmall!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: context.appColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(
    BuildContext context,
    AppBottomDestination destination,
  ) {
    if (destination == AppBottomDestination.home) return;

    if (destination == AppBottomDestination.history) {
      Navigator.pushReplacementNamed(context, RouteNames.history);
      return;
    }

    final label = switch (destination) {
      AppBottomDestination.home => 'Beranda',
      AppBottomDestination.calendar => 'Jadwal',
      AppBottomDestination.scan => 'Presensi',
      AppBottomDestination.history => 'Riwayat',
      AppBottomDestination.profile => 'Profil',
    };
    _showComingSoon(context, label);
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Fitur $label akan segera hadir.'),
          duration: const Duration(seconds: 1),
        ),
      );
  }
}

class _AttendanceStatsCard extends StatelessWidget {
  const _AttendanceStatsCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          _DailyStat(
            icon: Icons.check_circle_rounded,
            value: '18 Hari',
            label: 'Hadir',
            isSuccess: true,
          ),
          _StatDivider(),
          _DailyStat(
            icon: Icons.info_rounded,
            value: '2 Hari',
            label: 'Sakit/Izin',
            isWarning: true,
          ),
          _StatDivider(),
          _DailyStat(
            icon: Icons.cancel_rounded,
            value: '0 Hari',
            label: 'Alfa',
            isDanger: true,
          ),
        ],
      ),
    );
  }
}

class _DailyStat extends StatelessWidget {
  const _DailyStat({
    required this.icon,
    required this.value,
    required this.label,
    this.isSuccess = false,
    this.isWarning = false,
    this.isDanger = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isSuccess;
  final bool isWarning;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    Color iconColor = context.appColors.textSecondary;
    if (isSuccess) {
      iconColor = context.appColors.success;
    } else if (isWarning) {
      iconColor = context.appColors.warning;
    } else if (isDanger) {
      iconColor = context.appColors.danger;
    }

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge!,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: context.appColors.border);
  }
}
