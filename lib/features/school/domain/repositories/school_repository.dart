import '../entities/class_room.dart';
import '../entities/teacher_assignment.dart';
import '../entities/school_info.dart';

/// Contract for all school-related data operations.
/// Implementations live in the data layer.
abstract interface class SchoolRepository {
  /// Returns all classrooms ordered by level then name.
  Future<List<ClassRoom>> getClassRooms();

  /// Returns classrooms filtered by grade level (e.g. "X", "XI", "XII").
  Future<List<ClassRoom>> getClassRoomsByLevel(String level);

  /// Returns a single classroom by its Firestore ID.
  Future<ClassRoom?> getClassRoomById(String id);

  /// Creates a new classroom. Returns the created entity with its generated ID.
  Future<ClassRoom> createClassRoom(ClassRoom room);

  /// Updates an existing classroom.
  Future<void> updateClassRoom(ClassRoom room);

  /// Deletes a classroom by ID.
  Future<void> deleteClassRoom(String id);

  /// Assigns a homeroom teacher (wali kelas) to a classroom.
  Future<void> assignWaliKelas({
    required String roomId,
    required String teacherUid,
    required String teacherName,
  });

  /// Removes the wali kelas assignment from a classroom.
  Future<void> removeWaliKelas(String roomId);

  /// Transfers a student from one classroom to another and updates student counts atomically.
  Future<void> transferStudentClass({
    required String studentUid,
    required String? fromRoomId,
    required String toRoomId,
    required String toRoomName,
    required String toClassLevel,
  });

  /// Synchronizes student count on a classroom document.
  Future<void> syncClassRoomStudentCount(String roomId, int count);

  /// Returns all subject-teacher assignments, optionally filtered by [roomId].
  Future<List<TeacherAssignment>> getTeacherAssignments({String? roomId});

  /// Creates a new teacher assignment (guru mapel ke kelas).
  Future<TeacherAssignment> createTeacherAssignment(TeacherAssignment assignment);

  /// Deletes a teacher assignment.
  Future<void> deleteTeacherAssignment(String id);

  /// Returns the school configuration info from Firestore.
  Future<SchoolInfo> getSchoolInfo();

  /// Updates the school configuration info in Firestore.
  Future<void> updateSchoolInfo(SchoolInfo info);
}
