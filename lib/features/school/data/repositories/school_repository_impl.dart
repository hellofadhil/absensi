import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/class_room.dart';
import '../../domain/entities/teacher_assignment.dart';
import '../../domain/entities/school_info.dart';
import '../../domain/repositories/school_repository.dart';

/// Firestore-backed implementation of [SchoolRepository].
///
/// Firestore collection layout:
/// ```
/// classRooms/{roomId}
///   - name        : "X-A"
///   - level       : "X"
///   - capacity    : 30
///   - guruWaliId  : uid | null
///   - guruWaliName: string | null
///   - studentCount: int
///   - createdAt   : Timestamp
///   - updatedAt   : Timestamp
///
/// teacherAssignments/{assignmentId}
///   - teacherUid  : uid
///   - teacherName : string
///   - roomId      : string
///   - roomName    : string
///   - subject     : string
///   - createdAt   : Timestamp
///   - updatedAt   : Timestamp
/// ```
class SchoolRepositoryImpl implements SchoolRepository {
  final FirebaseFirestore _firestore;

  SchoolRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _roomsCol =>
      _firestore.collection('classRooms');

  CollectionReference<Map<String, dynamic>> get _assignmentsCol =>
      _firestore.collection('teacherAssignments');

  // ─── ClassRoom ─────────────────────────────────────────────────────────────

  @override
  Future<List<ClassRoom>> getClassRooms() async {
    final snap = await _roomsCol.get();
    final rooms = snap.docs.map(_roomFromDoc).toList();
    rooms.sort((a, b) {
      final levelComp = a.level.compareTo(b.level);
      if (levelComp != 0) return levelComp;
      return a.name.compareTo(b.name);
    });
    return rooms;
  }

  @override
  Future<List<ClassRoom>> getClassRoomsByLevel(String level) async {
    final snap = await _roomsCol
        .where('level', isEqualTo: level)
        .get();
    final rooms = snap.docs.map(_roomFromDoc).toList();
    rooms.sort((a, b) => a.name.compareTo(b.name));
    return rooms;
  }

  @override
  Future<ClassRoom?> getClassRoomById(String id) async {
    final doc = await _roomsCol.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return _roomFromDoc(doc);
  }

  @override
  Future<ClassRoom> createClassRoom(ClassRoom room) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _roomsCol.add({
      'name': room.name,
      'level': room.level,
      'capacity': room.capacity,
      'guruWaliId': room.guruWaliId,
      'guruWaliName': room.guruWaliName,
      'studentCount': room.studentCount,
      'createdAt': now,
      'updatedAt': now,
    });
    return room.copyWith(id: ref.id);
  }

  @override
  Future<void> updateClassRoom(ClassRoom room) async {
    await _roomsCol.doc(room.id).update({
      'name': room.name,
      'level': room.level,
      'capacity': room.capacity,
      'guruWaliId': room.guruWaliId,
      'guruWaliName': room.guruWaliName,
      'studentCount': room.studentCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteClassRoom(String id) async {
    // 1. Unlink students assigned to this classroom
    try {
      final studentsSnap = await _firestore
          .collection('users')
          .where('roomId', isEqualTo: id)
          .get();
      for (final doc in studentsSnap.docs) {
        await doc.reference.update({
          'roomId': null,
          'roomName': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}

    // 2. Delete teacher assignments associated with this room
    try {
      final assignmentsSnap = await _assignmentsCol
          .where('roomId', isEqualTo: id)
          .get();
      for (final doc in assignmentsSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    // 3. Delete room document
    await _roomsCol.doc(id).delete();
  }

  @override
  Future<void> assignWaliKelas({
    required String roomId,
    required String teacherUid,
    required String teacherName,
  }) async {
    await _roomsCol.doc(roomId).update({
      'guruWaliId': teacherUid,
      'guruWaliName': teacherName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeWaliKelas(String roomId) async {
    await _roomsCol.doc(roomId).update({
      'guruWaliId': null,
      'guruWaliName': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> transferStudentClass({
    required String studentUid,
    required String? fromRoomId,
    required String toRoomId,
    required String toRoomName,
    required String toClassLevel,
  }) async {
    // 1. Update user profile in Firestore
    await _firestore.collection('users').doc(studentUid).update({
      'roomId': toRoomId,
      'roomName': toRoomName,
      'classLevel': toClassLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Decrement studentCount on old room if different
    if (fromRoomId != null && fromRoomId.isNotEmpty && fromRoomId != toRoomId) {
      try {
        await _roomsCol
            .doc(fromRoomId)
            .update({'studentCount': FieldValue.increment(-1)});
      } catch (_) {}
    }

    // 3. Increment studentCount on new room
    if (toRoomId.isNotEmpty && fromRoomId != toRoomId) {
      try {
        await _roomsCol
            .doc(toRoomId)
            .update({'studentCount': FieldValue.increment(1)});
      } catch (_) {}
    }
  }

  @override
  Future<void> syncClassRoomStudentCount(String roomId, int count) async {
    try {
      await _roomsCol.doc(roomId).update({
        'studentCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─── TeacherAssignment ─────────────────────────────────────────────────────

  @override
  Future<List<TeacherAssignment>> getTeacherAssignments({String? roomId}) async {
    Query<Map<String, dynamic>> q = _assignmentsCol;
    if (roomId != null) {
      q = q.where('roomId', isEqualTo: roomId);
    }
    final snap = await q.get();
    return snap.docs.map(_assignmentFromDoc).toList();
  }

  @override
  Future<TeacherAssignment> createTeacherAssignment(
      TeacherAssignment assignment) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _assignmentsCol.add({
      'teacherUid': assignment.teacherUid,
      'teacherName': assignment.teacherName,
      'roomId': assignment.roomId,
      'roomName': assignment.roomName,
      'subject': assignment.subject,
      'createdAt': now,
      'updatedAt': now,
    });
    return assignment.copyWith(id: ref.id);
  }

  @override
  Future<void> deleteTeacherAssignment(String id) async {
    await _assignmentsCol.doc(id).delete();
  }

  @override
  Future<SchoolInfo> getSchoolInfo() async {
    try {
      final doc = await _firestore.collection('details').doc('school').get();
      if (doc.exists && doc.data() != null) {
        return SchoolInfo.fromJson(doc.data()!);
      }
      return SchoolInfo.fromJson({});
    } catch (_) {
      return SchoolInfo.fromJson({});
    }
  }

  @override
  Future<void> updateSchoolInfo(SchoolInfo info) async {
    await _firestore
        .collection('details')
        .doc('school')
        .set(info.toJson(), SetOptions(merge: true));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  ClassRoom _roomFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ClassRoom(
      id: doc.id,
      name: d['name'] as String? ?? '',
      level: d['level'] as String? ?? '',
      capacity: d['capacity'] as int? ?? 30,
      guruWaliId: d['guruWaliId'] as String?,
      guruWaliName: d['guruWaliName'] as String?,
      studentCount: d['studentCount'] as int? ?? 0,
    );
  }

  TeacherAssignment _assignmentFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return TeacherAssignment(
      id: doc.id,
      teacherUid: d['teacherUid'] as String? ?? '',
      teacherName: d['teacherName'] as String? ?? '',
      roomId: d['roomId'] as String? ?? '',
      roomName: d['roomName'] as String? ?? '',
      subject: d['subject'] as String? ?? '',
    );
  }
}
