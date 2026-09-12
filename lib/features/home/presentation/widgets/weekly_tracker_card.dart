import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import 'package:absensi/features/attendance/domain/entities/attendance_record.dart';
import 'package:absensi/features/attendance/presentation/providers/attendance_provider.dart';

class WeeklyTrackerCard extends ConsumerWidget {
  const WeeklyTrackerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyAttendanceProvider);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monday = todayStart.subtract(Duration(days: now.weekday - 1));
    final weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'];
    final dates = List.generate(
      5,
      (index) => monday.add(Duration(days: index)),
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kehadiran Minggu Ini',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                    ),
              ),
              Text(
                'Senin - Jumat',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: context.appColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          weeklyAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => Center(
              child: Text(
                'Gagal memuat status mingguan',
                style: TextStyle(
                  color: context.appColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            data: (records) {
              final recordsMap = {
                for (final r in records)
                  '${r.date.year}-${r.date.month}-${r.date.day}': r,
              };

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  final date = dates[index];
                  final dayLabel = weekdays[index];
                  final dateKey = '${date.year}-${date.month}-${date.day}';
                  final record = recordsMap[dateKey];
                  final isFuture = date.isAfter(todayStart);
                  final isToday = date.isAtSameMomentAs(todayStart);

                  AttendanceStatus status =
                      record?.status ?? AttendanceStatus.none;

                  Color bgColor;
                  Color iconColor;
                  Widget iconOrText;

                  if (isFuture) {
                    bgColor = Colors.transparent;
                    iconColor = context.appColors.textDisabled;
                    iconOrText = Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    );
                  } else {
                    switch (status) {
                      case AttendanceStatus.hadir:
                        bgColor = context.appColors.successSoft;
                        iconColor = context.appColors.success;
                        iconOrText = Icon(
                          Icons.check_rounded,
                          color: iconColor,
                          size: 20,
                        );
                        break;
                      case AttendanceStatus.terlambat:
                        bgColor = context.appColors.warningSoft;
                        iconColor = context.appColors.warning;
                        iconOrText = Icon(
                          Icons.access_time_filled_rounded,
                          color: iconColor,
                          size: 18,
                        );
                        break;
                      case AttendanceStatus.sakit:
                        bgColor = context.appColors.primarySoft;
                        iconColor = context.appColors.primary;
                        iconOrText = Icon(
                          Icons.healing_rounded,
                          color: iconColor,
                          size: 16,
                        );
                        break;
                      case AttendanceStatus.izin:
                        bgColor = context.appColors.aiSoft;
                        iconColor = context.appColors.ai;
                        iconOrText = Icon(
                          Icons.assignment_ind_rounded,
                          color: iconColor,
                          size: 18,
                        );
                        break;
                      case AttendanceStatus.alpa:
                        bgColor = context.appColors.dangerSoft;
                        iconColor = context.appColors.danger;
                        iconOrText = Icon(
                          Icons.close_rounded,
                          color: iconColor,
                          size: 20,
                        );
                        break;
                      case AttendanceStatus.none:
                        bgColor = context.appColors.surfaceSoft;
                        iconColor = context.appColors.textMuted;
                        iconOrText = Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        );
                        break;
                    }
                  }

                  return Column(
                    children: [
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday
                              ? context.appColors.primary
                              : context.appColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                          border: isFuture
                              ? Border.all(
                                  color: context.appColors.border,
                                  width: 1.5,
                                )
                              : (status == AttendanceStatus.none
                                  ? Border.all(
                                      color: context.appColors.border,
                                      width: 1.5,
                                    )
                                  : null),
                          boxShadow: isToday && !isFuture
                              ? [
                                  BoxShadow(
                                    color: (status == AttendanceStatus.none
                                            ? context.appColors.primary
                                            : iconColor)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: iconOrText,
                      ),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
