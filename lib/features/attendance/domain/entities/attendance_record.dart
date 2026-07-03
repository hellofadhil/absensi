enum AttendanceStatus { hadir, sakit, izin, alfa, none }

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.status,
    this.checkInTime,
    this.remarks,
  });

  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkInTime; // only if status is hadir
  final String? remarks; // e.g., 'Surat Dokter' for sakit, 'Acara Keluarga' for izin

  bool get isHadir => status == AttendanceStatus.hadir;
  bool get isSakit => status == AttendanceStatus.sakit;
  bool get isIzin => status == AttendanceStatus.izin;
  bool get isAlfa => status == AttendanceStatus.alfa;

  AttendanceRecord copyWith({
    DateTime? date,
    AttendanceStatus? status,
    DateTime? checkInTime,
    String? remarks,
  }) {
    return AttendanceRecord(
      date: date ?? this.date,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      remarks: remarks ?? this.remarks,
    );
  }
}
