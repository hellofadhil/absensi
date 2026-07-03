class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.avatarUrl,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role; // 'siswa' or 'guru'
  final String? avatarUrl;

  bool get isGuru => role == 'guru';
  bool get isSiswa => role == 'siswa';

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? avatarUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
