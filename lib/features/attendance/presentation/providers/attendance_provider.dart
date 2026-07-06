import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl();
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

// FutureProvider that fetches history for the current calendar month
final currentMonthAttendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) {
    return const [];
  }

  final repo = ref.watch(attendanceRepositoryProvider);
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);
  return repo.getAttendanceHistory(authState.user.uid, currentMonth);
});

// FutureProvider that fetches today's attendance record
final todayAttendanceProvider = FutureProvider<AttendanceRecord?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) {
    return null;
  }

  final repo = ref.watch(attendanceRepositoryProvider);
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month, 1);
  final history = await repo.getAttendanceHistory(authState.user.uid, currentMonth);

  for (final record in history) {
    if (record.date.year == now.year &&
        record.date.month == now.month &&
        record.date.day == now.day) {
      return record;
    }
  }
  return null;
});

// Notifier for manual attendance submission
class AttendanceSubmissionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null); // Idle state
  }

  Future<bool> submit(AttendanceRecord record) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      state = AsyncError('Pengguna tidak terautentikasi', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.submitAttendance(authState.user.uid, record);
      state = const AsyncData(null);
      
      // Invalidate both history and any dependent providers
      ref.invalidate(attendanceHistoryProvider);
      ref.invalidate(todayAttendanceProvider);
      ref.invalidate(currentMonthAttendanceHistoryProvider);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final attendanceSubmissionProvider = NotifierProvider<AttendanceSubmissionNotifier, AsyncValue<void>>(
  AttendanceSubmissionNotifier.new,
);


