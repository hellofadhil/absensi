import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/school_repository_impl.dart';
import '../../domain/entities/class_room.dart';
import '../../domain/entities/teacher_assignment.dart';
import '../../domain/entities/school_info.dart';
import '../../domain/repositories/school_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';

// ─── Repository Provider ───────────────────────────────────────────────────

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepositoryImpl();
});

// ─── ClassRoom Providers ────────────────────────────────────────────────────

/// All classrooms ordered by level then name with real-time synchronized student counts.
final classRoomsProvider = FutureProvider<List<ClassRoom>>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  final rooms = await repo.getClassRooms();
  final usersAsync = ref.watch(allUsersProvider);
  final users = usersAsync.maybeWhen(
    data: (u) => u,
    orElse: () => null,
  );

  if (users == null) {
    return rooms;
  }

  final syncedRooms = <ClassRoom>[];
  for (final room in rooms) {
    // 1. Calculate actual enrolled students count directly from current users data
    final actualCount = users.where((u) {
      if (!u.isSiswa) return false;
      if (u.roomId != null && u.roomId!.isNotEmpty) {
        return u.roomId == room.id;
      }
      return u.roomName != null &&
          u.roomName!.trim().toLowerCase() == room.name.trim().toLowerCase();
    }).length;

    // 2. Resolve homeroom teacher's latest display name & title prefix
    String? resolvedWaliName = room.guruWaliName;
    if (room.hasWali) {
      final waliUser =
          users.where((u) => u.isGuru && u.uid == room.guruWaliId).firstOrNull;
      if (waliUser != null) {
        resolvedWaliName = waliUser.displayNameWithTitle;
      }
    }

    // 3. If Firestore counter is out of sync, auto-heal in the background
    if (room.studentCount != actualCount) {
      repo.syncClassRoomStudentCount(room.id, actualCount);
    }

    syncedRooms.add(room.copyWith(
      studentCount: actualCount,
      guruWaliName: resolvedWaliName,
    ));
  }

  return syncedRooms;
});

/// Classrooms grouped by level: { "X": [...], "XI": [...], "XII": [...] }.
final classRoomsByLevelProvider =
    FutureProvider<Map<String, List<ClassRoom>>>((ref) async {
  final rooms = await ref.watch(classRoomsProvider.future);
  final Map<String, List<ClassRoom>> grouped = {};
  for (final room in rooms) {
    grouped.putIfAbsent(room.level, () => []).add(room);
  }
  return grouped;
});

/// Classrooms for a specific grade level.
final classRoomsForLevelProvider =
    FutureProvider.family<List<ClassRoom>, String>((ref, level) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getClassRoomsByLevel(level);
});

// ─── TeacherAssignment Providers ───────────────────────────────────────────

/// All teacher assignments, optionally filtered by roomId.
final teacherAssignmentsProvider =
    FutureProvider.family<List<TeacherAssignment>, String?>((ref, roomId) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getTeacherAssignments(roomId: roomId);
});

// ─── ClassRoom Notifier ────────────────────────────────────────────────────

/// Notifier for creating, editing, and deleting classrooms.
/// Automatically invalidates [classRoomsProvider] after mutations.
class ClassRoomNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  SchoolRepository get _repo => ref.read(schoolRepositoryProvider);

  Future<ClassRoom> create(ClassRoom room) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createClassRoom(room);
      ref.invalidate(classRoomsProvider);
      state = const AsyncData(null);
      return created;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<void> save(ClassRoom room) async {
    state = const AsyncLoading();
    try {
      await _repo.updateClassRoom(room);
      ref.invalidate(classRoomsProvider);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<void> delete(String roomId) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteClassRoom(roomId);
      ref.invalidate(classRoomsProvider);
      ref.invalidate(allUsersProvider);
      ref.invalidate(todayStudentsAttendanceProvider);
      ref.invalidate(teacherAssignmentsProvider);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<void> assignWali({
    required String roomId,
    required String teacherUid,
    required String teacherName,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.assignWaliKelas(
        roomId: roomId,
        teacherUid: teacherUid,
        teacherName: teacherName,
      );
      ref.invalidate(classRoomsProvider);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<void> removeWali(String roomId) async {
    state = const AsyncLoading();
    try {
      await _repo.removeWaliKelas(roomId);
      ref.invalidate(classRoomsProvider);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }
}

final classRoomNotifierProvider =
    AsyncNotifierProvider<ClassRoomNotifier, void>(ClassRoomNotifier.new);

// ─── SchoolInfo Providers ───────────────────────────────────────────────────

/// FutureProvider that fetches school info configuration.
final schoolInfoProvider = FutureProvider<SchoolInfo>((ref) async {
  final repo = ref.watch(schoolRepositoryProvider);
  return repo.getSchoolInfo();
});

/// Notifier to manage school info mutations.
class SchoolInfoNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  SchoolRepository get _repo => ref.read(schoolRepositoryProvider);

  Future<void> save(SchoolInfo info) async {
    state = const AsyncLoading();
    try {
      await _repo.updateSchoolInfo(info);
      ref.invalidate(schoolInfoProvider);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }
}

final schoolInfoNotifierProvider =
    AsyncNotifierProvider<SchoolInfoNotifier, void>(SchoolInfoNotifier.new);
