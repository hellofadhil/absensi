import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return MockAttendanceRepository();
});

// A Notifier to track which month the user is currently viewing in the calendar
class SelectedCalendarMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = month;
  }
}

final selectedCalendarMonthProvider = NotifierProvider<SelectedCalendarMonth, DateTime>(SelectedCalendarMonth.new);

// FutureProvider that fetches history for the currently selected month
final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) {
    return const [];
  }

  final selectedMonth = ref.watch(selectedCalendarMonthProvider);
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAttendanceHistory(authState.user.uid, selectedMonth);
});
