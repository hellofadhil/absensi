import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:absensi/core/router/route_names.dart';
import 'package:absensi/features/attendance/presentation/widgets/manual_attendance_bottom_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import 'package:absensi/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:absensi/features/attendance/domain/entities/attendance_record.dart';
import 'package:absensi/features/auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isGuru = user?.isGuru ?? false;
    final displayName = user != null
        ? (user.nickname ?? user.displayName)
        : 'Pengguna';

    final todayAttendance = ref.watch(todayAttendanceProvider);
    final hasCheckedIn = todayAttendance.maybeWhen(
      data: (record) => record != null,
      orElse: () => false,
    );

    final currentHour = DateTime.now().hour;
    final String timeOfDayGreeting;
    if (currentHour >= 5 && currentHour < 11) {
      timeOfDayGreeting = 'Selamat pagi';
    } else if (currentHour >= 11 && currentHour < 15) {
      timeOfDayGreeting = 'Selamat siang';
    } else if (currentHour >= 15 && currentHour < 18) {
      timeOfDayGreeting = 'Selamat sore';
    } else {
      timeOfDayGreeting = 'Selamat malam';
    }

    var titleText = '$timeOfDayGreeting, $displayName \u{1F44B}';
    var subtitleText = 'Jangan lupa presensi sebelum jam 07:00.';

    todayAttendance.whenOrNull(
      data: (record) {
        if (record != null) {
          if (record.status == AttendanceStatus.terlambat) {
            int minutesLate = 0;
            if (record.checkInTime != null) {
              final limit = DateTime(
                record.checkInTime!.year,
                record.checkInTime!.month,
                record.checkInTime!.day,
                7,
                0,
              );
              minutesLate = record.checkInTime!.difference(limit).inMinutes;
              if (minutesLate < 0) minutesLate = 0;
            }
            
            final String lateText;
            if (minutesLate < 60) {
              lateText = '$minutesLate menit';
            } else {
              final hours = minutesLate ~/ 60;
              final mins = minutesLate % 60;
              lateText = mins == 0 ? '$hours Jam' : '$hours Jam $mins menit';
            }

            titleText = 'Hai, $displayName';
            subtitleText = 'Anda terlambat $lateText hari ini.';
          } else if (record.status == AttendanceStatus.hadir) {
            titleText = '$timeOfDayGreeting, $displayName \u{1F44B}';
            subtitleText = 'Presensi hari ini sudah tercatat.';
          } else if (record.status == AttendanceStatus.sakit) {
            titleText = '$timeOfDayGreeting, $displayName \u{1F44B}';
            subtitleText = 'Status hari ini: Sakit${record.remarks != null ? ' (${record.remarks})' : ''}.';
          } else if (record.status == AttendanceStatus.izin) {
            titleText = '$timeOfDayGreeting, $displayName \u{1F44B}';
            subtitleText = 'Status hari ini: Izin${record.remarks != null ? ' (${record.remarks})' : ''}.';
          } else if (record.status == AttendanceStatus.alpa) {
            titleText = 'Hai, $displayName';
            subtitleText = 'Status hari ini: Alpa.';
          }
        }
      },
    );

    final onPressed = hasCheckedIn ? null : () => ManualAttendanceBottomSheet.show(context);

    return AppScaffold(
      topBar: const AppTopBar(
        title: 'SMK TI Bazma',
        subtitle: 'Tahun Ajaran 2026/2027',
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.home,
        isGuru: isGuru,
        onDestinationSelected: (destination) =>
            _handleNavigation(context, destination, isGuru),
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
              titleText,
              style: Theme.of(context).textTheme.headlineLarge!,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitleText,
              style: Theme.of(context).textTheme.bodyLarge!,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _TodayAttendanceCard(
              record: todayAttendance.maybeWhen(
                data: (record) => record,
                orElse: () => null,
              ),
              onPresensiPressed: onPressed,
              onDetailPressed: () {
                Navigator.pushReplacementNamed(context, RouteNames.history);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _AttendanceStatsCard(),
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
    bool isGuru,
  ) {
    if (destination == AppBottomDestination.home) return;

    if (destination == AppBottomDestination.calendar) {
      if (isGuru) {
        Navigator.pushReplacementNamed(context, RouteNames.students);
      } else {
        _showComingSoon(context, 'Jadwal');
      }
      return;
    }

    if (destination == AppBottomDestination.history) {
      Navigator.pushReplacementNamed(context, RouteNames.history);
      return;
    }

    if (destination == AppBottomDestination.scan) {
      ManualAttendanceBottomSheet.show(context);
      return;
    }

    if (destination == AppBottomDestination.profile) {
      Navigator.pushReplacementNamed(context, RouteNames.profile);
      return;
    }
  }


  void _showComingSoon(BuildContext context, String label) {
    AppToast.showInfo(
      context,
      title: 'Segera Hadir!',
      message: 'Fitur $label sedang dalam tahap pengembangan.',
    );
  }
}

class _TodayAttendanceCard extends StatelessWidget {
  const _TodayAttendanceCard({
    required this.record,
    required this.onPresensiPressed,
    required this.onDetailPressed,
  });

  final AttendanceRecord? record;
  final VoidCallback? onPresensiPressed;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    final hasCheckedIn = record != null;

    String cardTitle = 'Status Presensi Hari Ini';
    String line1 = 'Batas presensi: 07:00 WIB';
    String? line2;

    if (hasCheckedIn) {
      final rec = record!;
      if (rec.checkInTime != null) {
        final timeStr = '${rec.checkInTime!.hour.toString().padLeft(2, '0')}:${rec.checkInTime!.minute.toString().padLeft(2, '0')} WIB';
        line1 = timeStr;
        line2 = 'Lokasi: ${rec.latitude != null ? 'Dalam area sekolah' : 'Luar area sekolah'}';
      } else {
        line1 = rec.remarks != null ? 'Keterangan: ${rec.remarks}' : 'Tidak ada keterangan';
        line2 = null;
      }
    } else {
      final now = DateTime.now();
      final limit = DateTime(now.year, now.month, now.day, 7, 0);
      final difference = limit.difference(now);
      if (difference.isNegative) {
        line2 = 'Batas presensi terlewati';
      } else {
        line2 = 'Sisa waktu: ${difference.inMinutes} menit';
      }
    }

    return AppCard(
      variant: AppCardVariant.standard,
      radius: AppRadius.featureCard,
      padding: const EdgeInsets.all(AppSpacing.xl),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardTitle,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            line1,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
          ),
          if (line2 != null) ...[
            const SizedBox(height: 4),
            Text(
              line2,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: context.appColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: hasCheckedIn
                ? OutlinedButton.icon(
                    onPressed: onDetailPressed,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Lihat Detail Presensi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.primary,
                      side: BorderSide(color: context.appColors.primaryBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onPresensiPressed,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('Presensi Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.primary,
                      foregroundColor: context.appColors.textInverse,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStatsCard extends ConsumerWidget {
  const _AttendanceStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(currentMonthAttendanceHistoryProvider);

    return historyAsync.maybeWhen(
      data: (records) {
        final totalHadir = records.where((r) => r.isHadir).length;
        final totalSakitIzin = records.where((r) => r.isSakit || r.isIzin).length;
        final totalTerlambat = records.where((r) => r.isTerlambat).length;
        final totalAlpa = records.where((r) => r.isAlpa).length;

        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              _DailyStat(
                icon: Icons.check_circle_rounded,
                value: '$totalHadir Hari',
                label: 'Hadir',
                color: context.appColors.success,
              ),
              const _StatDivider(),
              _DailyStat(
                icon: Icons.info_rounded,
                value: '$totalSakitIzin Hari',
                label: 'Sakit/Izin',
                color: context.appColors.primary,
              ),
              const _StatDivider(),
              _DailyStat(
                icon: Icons.watch_later_rounded,
                value: '$totalTerlambat Hari',
                label: 'Terlambat',
                color: context.appColors.warning,
              ),
              const _StatDivider(),
              _DailyStat(
                icon: Icons.cancel_rounded,
                value: '$totalAlpa Hari',
                label: 'Alpa',
                color: context.appColors.danger,
              ),
            ],
          ),
        );
      },
      orElse: () => AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            _DailyStat(
              icon: Icons.check_circle_rounded,
              value: '- Hari',
              label: 'Hadir',
              color: context.appColors.success,
            ),
            const _StatDivider(),
            _DailyStat(
              icon: Icons.info_rounded,
              value: '- Hari',
              label: 'Sakit/Izin',
              color: context.appColors.primary,
            ),
            const _StatDivider(),
            _DailyStat(
              icon: Icons.watch_later_rounded,
              value: '- Hari',
              label: 'Terlambat',
              color: context.appColors.warning,
            ),
            const _StatDivider(),
            _DailyStat(
              icon: Icons.cancel_rounded,
              value: '- Hari',
              label: 'Alpa',
              color: context.appColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyStat extends StatelessWidget {
  const _DailyStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge!,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!,
            maxLines: 1,
            textAlign: TextAlign.center,
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
