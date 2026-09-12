import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import 'grid_stat_item.dart';

class TeacherAttendanceSummaryCard extends StatelessWidget {
  final int totalTeachers;
  final int presentTeachers;
  final int lateTeachers;
  final int sickTeachers;
  final int permissionTeachers;
  final int absentTeachers;
  final int unsubmittedTeachers;

  const TeacherAttendanceSummaryCard({
    super.key,
    required this.totalTeachers,
    required this.presentTeachers,
    required this.lateTeachers,
    required this.sickTeachers,
    required this.permissionTeachers,
    required this.absentTeachers,
    required this.unsubmittedTeachers,
  });

  @override
  Widget build(BuildContext context) {
    final totalPresent = presentTeachers + lateTeachers;
    final attendanceRate =
        totalTeachers > 0 ? totalPresent / totalTeachers : 0.0;
    final attendancePercentage = (attendanceRate * 100).toStringAsFixed(1);
    final combinedPermission = sickTeachers + permissionTeachers;

    late String statusLabel;
    late Color statusColor;
    late Color statusBackground;

    if (attendanceRate >= 0.95) {
      statusLabel = 'Sangat Baik';
      statusColor = context.appColors.success;
      statusBackground = context.appColors.successSoft;
    } else if (attendanceRate >= 0.90) {
      statusLabel = 'Baik';
      statusColor = context.appColors.primary;
      statusBackground = context.appColors.primarySoft;
    } else if (attendanceRate >= 0.80) {
      statusLabel = 'Perlu Perhatian';
      statusColor = context.appColors.warning;
      statusBackground = context.appColors.warningSoft;
    } else {
      statusLabel = 'Rendah';
      statusColor = context.appColors.danger;
      statusBackground = context.appColors.dangerSoft;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.appColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.badge_rounded,
                  size: 21,
                  color: context.appColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kehadiran Guru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ringkasan presensi terbaru',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 94,
                height: 94,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: attendanceRate.clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 94,
                          height: 94,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            backgroundColor: context.appColors.surfaceSoft,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.appColors.primary,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$attendancePercentage%',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: context.appColors.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                            Text(
                              'hadir',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalPresent guru hadir',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dari total $totalTeachers guru\nyang terdaftar',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: GridStatItem(
                  count: '$absentTeachers',
                  label: 'Belum Hadir',
                  countColor: context.appColors.danger,
                  bgColor: context.appColors.dangerSoft,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GridStatItem(
                  count: '$lateTeachers',
                  label: 'Terlambat',
                  countColor: context.appColors.warning,
                  bgColor: context.appColors.warningSoft,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GridStatItem(
                  count: '$combinedPermission',
                  label: 'Izin / Sakit',
                  countColor: context.appColors.primary,
                  bgColor: context.appColors.primarySoft,
                ),
              ),
            ],
          ),
          if (unsubmittedTeachers > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.appColors.warningSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.appColors.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.pending_actions_rounded,
                      size: 18,
                      color: context.appColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$unsubmittedTeachers guru belum presensi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Periksa guru yang belum mengirimkan data kehadiran.',
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.appColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
