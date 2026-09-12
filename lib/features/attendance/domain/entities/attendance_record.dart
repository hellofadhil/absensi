enum AttendanceStatus { hadir, terlambat, sakit, izin, alpa, none }

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.status,
    this.checkInTime,
    this.remarks,
    this.latitude,
    this.longitude,
    this.attachmentUrl,
  });

  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkInTime; // only if status is hadir or terlambat
  final String? remarks; // e.g., 'Surat Dokter' for sakit, 'Acara Keluarga' for izin, or late description
  final double? latitude;
  final double? longitude;
  final String? attachmentUrl; // Kora Drive upload link or attachment URL for sakit/izin proof

  bool get isHadir => status == AttendanceStatus.hadir;
  bool get isTerlambat => status == AttendanceStatus.terlambat;
  bool get isSakit => status == AttendanceStatus.sakit;
  bool get isIzin => status == AttendanceStatus.izin;
  bool get isAlpa => status == AttendanceStatus.alpa;

  AttendanceRecord copyWith({
    DateTime? date,
    AttendanceStatus? status,
    DateTime? checkInTime,
    String? remarks,
    double? latitude,
    double? longitude,
    String? attachmentUrl,
  }) {
    return AttendanceRecord(
      date: date ?? this.date,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      remarks: remarks ?? this.remarks,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}
