/// Represents a single classroom (ruang kelas) inside a grade level.
///
/// Example: Ruang X-A adalah bagian dari tingkat Kelas X.
class ClassRoom {
  const ClassRoom({
    required this.id,
    required this.name,
    required this.level,
    this.capacity = 30,
    this.guruWaliId,
    this.guruWaliName,
    this.studentCount = 0,
  });

  /// Firestore document ID.
  final String id;

  /// Display name, e.g. "X-A", "XI-B", "XII-A".
  final String name;

  /// Grade level, e.g. "X", "XI", "XII".
  final String level;

  /// Maximum number of students this room can hold.
  final int capacity;

  /// UID of the homeroom teacher (guru wali kelas). Nullable — may not be assigned yet.
  final String? guruWaliId;

  /// Display name of the homeroom teacher, denormalized for easy display.
  final String? guruWaliName;

  /// Cached count of enrolled students (denormalized).
  final int studentCount;

  bool get hasWali => guruWaliId != null;

  bool get isFull => studentCount >= capacity;

  /// Full readable label: "Kelas X-A".
  String get fullLabel => 'Kelas $name';

  ClassRoom copyWith({
    String? id,
    String? name,
    String? level,
    int? capacity,
    String? guruWaliId,
    String? guruWaliName,
    int? studentCount,
  }) {
    return ClassRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      capacity: capacity ?? this.capacity,
      guruWaliId: guruWaliId ?? this.guruWaliId,
      guruWaliName: guruWaliName ?? this.guruWaliName,
      studentCount: studentCount ?? this.studentCount,
    );
  }
}
