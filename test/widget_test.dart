import 'package:absensi/features/attendance/domain/entities/attendance_record.dart';
import 'package:absensi/features/attendance/domain/entities/student_attendance.dart';
import 'package:absensi/features/attendance/domain/entities/teacher_attendance.dart';
import 'package:absensi/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:absensi/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:absensi/features/auth/domain/entities/user.dart';
import 'package:absensi/features/auth/domain/repositories/auth_repository.dart';
import 'package:absensi/features/auth/presentation/providers/auth_provider.dart';
import 'package:absensi/main.dart';
import 'package:absensi/core/theme/theme_controller.dart';
import 'package:absensi/core/services/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthRepository implements AuthRepository {
  final AppUser testUser = const AppUser(
    uid: 'siswa-456',
    email: 'siswa@sekolah.com',
    displayName: 'Fadhil',
    role: 'siswa',
  );

  @override
  Future<AppUser?> getCurrentUser() async => testUser;

  @override
  Future<AppUser?> login(String email, String password) async => testUser;

  @override
  Future<void> logout() async {}

  @override
  Future<void> updateProfile(String uid, AppUser user) async {}

  @override
  Future<void> updateUser(AppUser user) async {}

  @override
  Future<List<AppUser>> getAllUsers() async => [testUser];

  @override
  Future<void> createUser(AppUser user, {String? password}) async {}

  @override
  Future<void> deleteUser(String uid) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

class FakeAttendanceRepository implements AttendanceRepository {
  @override
  Future<List<AttendanceRecord>> getAttendanceHistory(String uid, DateTime month) async => [];

  @override
  Future<List<StudentAttendance>> getTodayStudentsAttendance() async => [];

  @override
  Future<List<TeacherAttendance>> getTodayTeachersAttendance() async => [];

  @override
  Future<void> submitAttendance(String uid, AttendanceRecord record) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('theme toggle changes the app theme immediately', (tester) async {
    SharedPreferences.setMockInitialValues({
      'cached_user': '{"uid":"siswa-456","email":"siswa@sekolah.com","displayName":"Fadhil","role":"siswa"}'
    });

    final prefs = await SharedPreferences.getInstance();
    final controller = ThemeController.inMemory(mode: ThemeMode.light);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          attendanceRepositoryProvider.overrideWithValue(FakeAttendanceRepository()),
        ],
        child: AbsensiApp(themeController: controller),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Aktifkan mode gelap'));
    await tester.pumpAndSettle();

    expect(controller.value, ThemeMode.dark);
    expect(find.bySemanticsLabel('Aktifkan mode terang'), findsOneWidget);
  });
}
