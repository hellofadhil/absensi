import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/holiday_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:absensi/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:absensi/features/attendance/presentation/widgets/manual_attendance_bottom_sheet.dart';
import 'package:absensi/features/auth/domain/entities/user.dart';
import '../widgets/date_time_display.dart';
import '../widgets/first_login_banner.dart';
import '../widgets/today_attendance_card.dart';
import '../widgets/weekly_tracker_card.dart';

class StudentHomeView extends ConsumerWidget {
  final AppUser user;
  final String greetingPart;
  final String namePart;

  const StudentHomeView({
    super.key,
    required this.user,
    required this.greetingPart,
    required this.namePart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayHoliday = ref.watch(todayHolidayProvider);
    final todayAttendance = ref.watch(todayAttendanceProvider);
    final hasCheckedIn = todayAttendance.maybeWhen(
      data: (record) => record != null,
      orElse: () => false,
    );
    final isHolidayToday = todayHoliday.maybeWhen(
      data: (holiday) => holiday.isHoliday,
      orElse: () => false,
    );

    final onPressed = hasCheckedIn || isHolidayToday
        ? null
        : () => ManualAttendanceBottomSheet.show(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.isFirstLogin) FirstLoginBanner(user: user),
        const DateTimeDisplay(),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$greetingPart,\n',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
              TextSpan(
                text: namePart.contains('👋') ? namePart : '$namePart 👋',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        todayHoliday.when(
          data: (holiday) {
            if (holiday.isHoliday) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: context.appColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: context.appColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holiday.isNationalHoliday
                                ? 'Hari Libur Nasional'
                                : 'Cuti Bersama',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            holiday.holidayList.join(', '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        TodayAttendanceCard(
          record: todayAttendance.maybeWhen(
            data: (record) => record,
            orElse: () => null,
          ),
          isHoliday: isHolidayToday,
          onPresensiPressed: onPressed,
          onDetailPressed: () {
            Navigator.pushReplacementNamed(
              context,
              RouteNames.history,
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        const WeeklyTrackerCard(),
      ],
    );
  }
}
