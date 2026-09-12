import 'class_room.dart';

/// Represents a single subject-teacher assignment.
/// A teacher can teach multiple subjects across multiple classrooms.
class TeacherAssignment {
  const TeacherAssignment({
    required this.id,
    required this.teacherUid,
    required this.teacherName,
    required this.roomId,
    required this.roomName,
    required this.subject,
  });

  /// Firestore document ID.
  final String id;

  /// UID of the subject teacher (guru mapel).
  final String teacherUid;

  /// Display name of the teacher, denormalized.
  final String teacherName;

  /// ID of the classroom this assignment belongs to.
  final String roomId;

  /// Display name of the classroom, denormalized.
  final String roomName;

  /// Subject name, e.g. "Matematika", "Bahasa Inggris".
  final String subject;

  TeacherAssignment copyWith({
    String? id,
    String? teacherUid,
    String? teacherName,
    String? roomId,
    String? roomName,
    String? subject,
  }) {
    return TeacherAssignment(
      id: id ?? this.id,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherName: teacherName ?? this.teacherName,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      subject: subject ?? this.subject,
    );
  }
}

/// Groups a classroom together with its list of subject-teacher assignments.
class ClassRoomWithAssignments {
  const ClassRoomWithAssignments({
    required this.room,
    required this.assignments,
  });

  final ClassRoom room;
  final List<TeacherAssignment> assignments;
}
