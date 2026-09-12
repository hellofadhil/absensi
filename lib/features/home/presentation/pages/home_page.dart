import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:absensi/core/router/route_names.dart';
import 'package:absensi/core/theme/app_spacing.dart';
import 'package:absensi/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:absensi/features/attendance/presentation/widgets/manual_attendance_bottom_sheet.dart';
import 'package:absensi/features/auth/presentation/providers/auth_provider.dart';
import 'package:absensi/shared/widgets/app_bottom_nav_bar.dart';
import 'package:absensi/shared/widgets/app_scaffold.dart';
import 'package:absensi/shared/widgets/app_toast.dart';
import 'package:absensi/shared/widgets/app_top_bar.dart';

import '../views/admin_home_view.dart';
import '../views/student_home_view.dart';
import '../views/teacher_home_view.dart';

class AdminHomeTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int tab) {
    state = tab;
  }
}

final adminHomeTabProvider =
    NotifierProvider<AdminHomeTabNotifier, int>(AdminHomeTabNotifier.new);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isGuru = user?.isGuru ?? false;
    final isAdmin = user?.isAdmin ?? false;
    final displayName =
        user != null ? (user.nickname ?? user.displayName) : 'Pengguna';

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

    final adminName =
        user != null ? 'Admin ${user.nickname ?? 'Salsa'}' : 'Admin';

    final greetingPart = timeOfDayGreeting;
    final namePart = isAdmin ? '$adminName \u{1F44B}' : '$displayName \u{1F44B}';

    return AppScaffold(
      topBar: const AppTopBar(
        title: 'SMK TI Bazma',
        subtitle: 'Tahun Ajaran 2026/2027',
        showThemeToggle: true,
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.home,
        isGuru: isGuru,
        isAdmin: isAdmin,
        onDestinationSelected: (destination) =>
            _handleNavigation(context, destination, isGuru, isAdmin),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayStudentsAttendanceProvider);
          ref.invalidate(todayTeachersAttendanceProvider);
          ref.invalidate(allUsersProvider);
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(attendanceHistoryProvider);
          ref.invalidate(weeklyAttendanceProvider);
          if (isAdmin) {
            await Future.wait([
              ref.refresh(todayStudentsAttendanceProvider.future),
              ref.refresh(todayTeachersAttendanceProvider.future),
            ]);
          } else {
            await Future.wait([
              ref.refresh(todayAttendanceProvider.future),
              ref.refresh(weeklyAttendanceProvider.future),
            ]);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.bottomNavigationClearance,
          ),
          child: isAdmin
              ? AdminHomeView(
                  greetingPart: greetingPart,
                  namePart: namePart,
                )
              : (user != null
                  ? (isGuru
                      ? TeacherHomeView(
                          user: user,
                          greetingPart: greetingPart,
                          namePart: namePart,
                        )
                      : StudentHomeView(
                          user: user,
                          greetingPart: greetingPart,
                          namePart: namePart,
                        ))
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }

  void _handleNavigation(
    BuildContext context,
    AppBottomDestination destination,
    bool isGuru,
    bool isAdmin,
  ) {
    if (destination == AppBottomDestination.home) return;

    if (destination == AppBottomDestination.laporan) {
      Navigator.pushReplacementNamed(context, RouteNames.laporan);
      return;
    }

    if (destination == AppBottomDestination.database) {
      Navigator.pushReplacementNamed(context, RouteNames.database);
      return;
    }

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
