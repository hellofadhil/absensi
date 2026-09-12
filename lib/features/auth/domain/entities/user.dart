class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.avatarUrl,
    this.nickname,
    this.birthDate,
    this.address,
    this.phoneNumber,
    this.extraField,
    this.classLevel,
    this.roomId,
    this.roomName,
    this.attendanceNumber,
    this.titlePrefix,
    this.angkatan,
    this.isFirstLogin = false,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role; // 'siswa', 'guru', or 'admin'
  final String? avatarUrl;
  final String? nickname;
  final String? birthDate;
  final String? address;
  final String? phoneNumber;
  final String? extraField;
  final String? titlePrefix;
  final bool isFirstLogin;

  /// Grade level of a student, e.g. "X", "XI", "XII".
  /// Null for guru and admin.
  final String? classLevel;

  /// Firestore ID of the [ClassRoom] the student belongs to.
  /// Null for guru and admin.
  final String? roomId;

  /// Display name of the classroom, e.g. "X-A", "XI-B".
  /// Denormalized for easy display without extra Firestore reads.
  /// Null for guru and admin.
  final String? roomName;

  /// Student roll/attendance number in the classroom, e.g. 1, 15, 36.
  /// Null for guru and admin.
  final int? attendanceNumber;

  /// Student cohort/generation number, e.g. "12" or "Angkatan 12".
  /// Null for guru and admin.
  final String? angkatan;

  bool get isGuru => role == 'guru';
  bool get isSiswa => role == 'siswa';
  bool get isAdmin => role == 'admin';

  /// Returns the formatted attendance number badge, e.g. "No. 05".
  String? get formattedAttendanceNumber =>
      attendanceNumber != null ? 'No. ${attendanceNumber.toString().padLeft(2, '0')}' : null;

  /// Returns the formatted batch/generation, e.g. "Angkatan 12".
  String? get formattedAngkatan {
    if (angkatan == null || angkatan!.trim().isEmpty) return null;
    final trimmed = angkatan!.trim();
    if (trimmed.toLowerCase().startsWith('angkatan')) return trimmed;
    return 'Angkatan $trimmed';
  }

  /// Returns the full class label, e.g. "Kelas X-A", or null if not a student.
  String? get fullClassLabel => roomName != null
      ? (roomName!.toLowerCase().startsWith('kelas') ||
              roomName!.toLowerCase().startsWith('ruang')
          ? roomName
          : 'Kelas $roomName')
      : null;

  /// Checks whether all mandatory profile fields are filled.
  bool get isProfileComplete {
    if (displayName.trim().isEmpty) return false;
    if (nickname == null || nickname!.trim().isEmpty) return false;
    if (phoneNumber == null || phoneNumber!.trim().isEmpty) return false;
    if (birthDate == null || birthDate!.trim().isEmpty) return false;
    if (address == null || address!.trim().isEmpty) return false;
    if (extraField == null || extraField!.trim().isEmpty) return false;
    if (isSiswa && (roomId == null || roomId!.isEmpty)) return false;
    return true;
  }

  /// Whether the user needs to complete their profile.
  /// True if flagged as first login OR if any mandatory profile data is missing (for student / teacher).
  bool get needsProfileCompletion {
    if (isAdmin) return false;
    if (isFirstLogin) return true;
    return !isProfileComplete;
  }

  /// Returns the display name with title prefix if available, e.g. "Bapak Ahmad Hidayat, S.Pd".
  String get displayNameWithTitle {
    if (titlePrefix != null && titlePrefix!.trim().isNotEmpty) {
      final prefix = titlePrefix!.trim();
      if (displayName.toLowerCase().startsWith('bapak') ||
          displayName.toLowerCase().startsWith('ibu')) {
        return displayName;
      }
      return '$prefix $displayName';
    }
    return displayName;
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? avatarUrl,
    String? nickname,
    String? birthDate,
    String? address,
    String? phoneNumber,
    String? extraField,
    String? classLevel,
    String? roomId,
    String? roomName,
    int? attendanceNumber,
    String? titlePrefix,
    String? angkatan,
    bool? isFirstLogin,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nickname: nickname ?? this.nickname,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      extraField: extraField ?? this.extraField,
      classLevel: classLevel ?? this.classLevel,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      attendanceNumber: attendanceNumber ?? this.attendanceNumber,
      titlePrefix: titlePrefix ?? this.titlePrefix,
      angkatan: angkatan ?? this.angkatan,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }
}
