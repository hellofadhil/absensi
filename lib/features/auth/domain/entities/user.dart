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
  });

  final String uid;
  final String email;
  final String displayName;
  final String role; // 'siswa' or 'guru'
  final String? avatarUrl;
  final String? nickname;
  final String? birthDate;
  final String? address;
  final String? phoneNumber;
  final String? extraField;

  bool get isGuru => role == 'guru';
  bool get isSiswa => role == 'siswa';

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
    );
  }
}
