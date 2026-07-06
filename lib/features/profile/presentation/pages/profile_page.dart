import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../attendance/presentation/widgets/manual_attendance_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/edit_profile_bottom_sheet.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final bool _isLoading = false;
  bool _hasError = false;

  // Local helper for empty values
  Widget _buildValueText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Text(
        'Belum diisi',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: context.appColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
      );
    }
    return Text(
      value,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    var clean = phone.replaceAll('-', '').replaceAll(' ', '');
    if (clean.startsWith('0')) {
      clean = '+62${clean.substring(1)}';
    }
    if (clean.startsWith('+62')) {
      final suffix = clean.substring(3);
      if (suffix.length <= 3) {
        return '+62 $suffix';
      } else if (suffix.length <= 7) {
        return '+62 ${suffix.substring(0, 3)}-${suffix.substring(3)}';
      } else {
        return '+62 ${suffix.substring(0, 3)}-${suffix.substring(3, 7)}-${suffix.substring(7)}';
      }
    }
    return phone;
  }

  // Get two-letter initials for avatar fallback
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  void _handleNavigation(BuildContext context, AppBottomDestination destination, bool isGuru) {
    if (destination == AppBottomDestination.profile) return;

    if (destination == AppBottomDestination.home) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
      return;
    }

    if (destination == AppBottomDestination.calendar) {
      if (isGuru) {
        Navigator.pushReplacementNamed(context, RouteNames.students);
      } else {
        AppToast.showInfo(
          context,
          title: 'Segera Hadir!',
          message: 'Fitur Jadwal sedang dalam tahap pengembangan.',
        );
      }
      return;
    }

    if (destination == AppBottomDestination.history) {
      Navigator.pushReplacementNamed(context, RouteNames.history);
      return;
    }

    if (destination == AppBottomDestination.scan) {
      ManualAttendanceBottomSheet.show(context);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 1. LOADING STATE
    if (_isLoading) {
      return const AppScaffold(
        topBar: AppTopBar(title: 'Profil Pengguna', showThemeToggle: false),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. ERROR STATE
    if (_hasError) {
      return AppScaffold(
        topBar: const AppTopBar(title: 'Profil Pengguna', showThemeToggle: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: context.appColors.danger),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Profil Gagal Dimuat',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Koneksi internet bermasalah atau data tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: context.appColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    label: 'Coba Lagi',
                    onPressed: () => setState(() => _hasError = false),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Resolve current role
    final user = authState is Authenticated ? authState.user : null;
    final currentRole = user?.role ?? 'siswa';
    final isSiswa = currentRole == 'siswa';
    final displayName = user?.displayName ?? 'Fadhil Rabbani';
    final userEmail = user?.email ?? 'rabbani@sekolah.sch.id';

    return AppScaffold(
      topBar: const AppTopBar(
        title: 'Profil Pengguna',
        showThemeToggle: true,
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.profile,
        isGuru: !isSiswa,
        onDestinationSelected: (destination) => _handleNavigation(context, destination, !isSiswa),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.bottomNavigationClearance,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. HEADER PROFILE (Avatar, Nama)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Avatar Photo
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.appColors.primary.withValues(alpha: 0.2),
                              width: 3,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                context.appColors.primary,
                                context.appColors.primaryDeep,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _getInitials(displayName),
                            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                                  color: context.appColors.textInverse,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        // Camera Action Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.appColors.primary,
                              border: Border.all(
                                color: context.appColors.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: context.appColors.textInverse,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ==========================================
            // 2. CARD INFORMASI UTAMA
            // ==========================================
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Utama',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isSiswa) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NISN',
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      color: context.appColors.textMuted,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              _buildValueText('0054321987'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kelas',
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      color: context.appColors.textMuted,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              _buildValueText('XI RPL 1'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NIP / NUPTK',
                          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: context.appColors.textMuted,
                              ),
                        ),
                        const SizedBox(height: 2),
                        _buildValueText('198205122008011003'),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Icon(Icons.book_outlined, size: 14, color: context.appColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Mapel Ajar',
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: context.appColors.textMuted,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        _buildValueText('Matematika Peminatan'),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Lahir',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: context.appColors.textMuted,
                            ),
                      ),
                      const SizedBox(height: 2),
                      _buildValueText(user?.birthDate ?? (isSiswa ? '12 Oktober 2008' : '12 Mei 1982')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ==========================================
            // 3. CARD INFORMASI DETAIL
            // ==========================================
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Informasi',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Alamat
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: context.appColors.textMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alamat Tinggal',
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: context.appColors.textMuted,
                                  ),
                            ),
                            const SizedBox(height: 2),
                             _buildValueText(user?.address ?? 'Jl. Jenderal Sudirman No. 45, Kota Bandung'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Jurusan (Siswa) or Jabatan (Guru)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 18, color: context.appColors.textMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSiswa ? 'Jurusan' : 'Jabatan / Peran',
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: context.appColors.textMuted,
                                  ),
                            ),
                            const SizedBox(height: 2),
                             _buildValueText(user?.extraField ?? (isSiswa ? 'Rekayasa Perangkat Lunak' : 'Wali Kelas & Staf Kurikulum')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),

                  // Kontak
                  if (isSiswa) ...[
                    // Wali HP
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone_android_rounded, size: 18, color: context.appColors.textMuted),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NO. HP ORANG TUA / WALI',
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                        color: context.appColors.textSecondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                 _buildValueText(_formatPhoneNumber(user?.phoneNumber ?? '0812-3456-7890')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Guru HP
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.phone_iphone_rounded, size: 18, color: context.appColors.textMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nomor HP Pribadi',
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      color: context.appColors.textMuted,
                                    ),
                              ),
                              const SizedBox(height: 2),
                               _buildValueText(_formatPhoneNumber(user?.phoneNumber ?? '0857-9988-1122')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Guru Email
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 18, color: context.appColors.textMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Sekolah',
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      color: context.appColors.textMuted,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              _buildValueText(userEmail),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ==========================================
            // 4. CARD KEAMANAN & AKSI
            // ==========================================
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keamanan & Akun',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Perbarui Profil
                  InkWell(
                    onTap: user == null ? null : () => EditProfileBottomSheet.show(context, user),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.edit_note_rounded, color: context.appColors.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Perbarui Profil',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Text(
                            'Edit biodata',
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                  color: context.appColors.textMuted,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 18, color: context.appColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Ubah Kata Sandi
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset_rounded, color: context.appColors.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Ubah Kata Sandi',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Text(
                            'Ganti PIN',
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                  color: context.appColors.textMuted,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 18, color: context.appColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appColors.dangerSoft.withValues(alpha: 0.1),
                        foregroundColor: context.appColors.danger,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          side: BorderSide(
                            color: context.appColors.danger.withValues(alpha: 0.15),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        // Tampilkan overlay animasi transisi logout
                        showGeneralDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.black.withValues(alpha: 0.7),
                          transitionDuration: const Duration(milliseconds: 350),
                          pageBuilder: (context, anim1, anim2) {
                            return const SizedBox.shrink();
                          },
                          transitionBuilder: (context, anim, anim2, child) {
                            return BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                              child: FadeTransition(
                                opacity: anim,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                                  ),
                                  child: const _LogoutOverlay(),
                                ),
                              ),
                            );
                          },
                        );

                        await ref.read(authProvider.notifier).logout();

                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            RouteNames.login,
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text(
                        'Keluar dari Akun',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutOverlay extends StatefulWidget {
  const _LogoutOverlay();

  @override
  State<_LogoutOverlay> createState() => _LogoutOverlayState();
}

class _LogoutOverlayState extends State<_LogoutOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
    ]).animate(_controller);

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2.0 * 3.141592653589793).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: context.appColors.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.appColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.appColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Icon(
                        Icons.school_rounded,
                        size: 46,
                        color: context.appColors.primaryDeep,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Mengamankan Akun...',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Keluar dari sistem absensi',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: context.appColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
