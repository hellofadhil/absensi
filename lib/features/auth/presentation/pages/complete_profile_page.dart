import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../school/domain/entities/class_room.dart';
import '../../../school/presentation/providers/school_provider.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

class PhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    var clean = text.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('0')) {
      clean = '+62${clean.substring(1)}';
    } else if (clean.startsWith('62') && !clean.startsWith('+62')) {
      clean = '+$clean';
    } else if (!clean.startsWith('+62') && clean.isNotEmpty) {
      clean = '+62$clean';
    }

    if (clean.startsWith('+62')) {
      final suffix = clean.substring(3);
      String formatted = '+62 ';
      if (suffix.isNotEmpty) {
        if (suffix.length <= 3) {
          formatted += suffix;
        } else if (suffix.length <= 7) {
          formatted += '${suffix.substring(0, 3)}-${suffix.substring(3)}';
        } else {
          formatted +=
              '${suffix.substring(0, 3)}-${suffix.substring(3, 7)}-${suffix.substring(7)}';
        }
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _extraFieldController;

  String? _selectedRoomId;
  String? _selectedRoomName;
  String? _selectedClassLevel;
  String? _selectedTitlePrefix;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTitlePrefix =
        widget.user.titlePrefix ?? (widget.user.isGuru ? 'Bapak' : null);
    _displayNameController =
        TextEditingController(text: widget.user.displayName);
    _nicknameController =
        TextEditingController(text: widget.user.nickname ?? '');
    _birthDateController =
        TextEditingController(text: widget.user.birthDate ?? '');
    _addressController =
        TextEditingController(text: widget.user.address ?? '');
    _phoneNumberController =
        TextEditingController(text: _formatPhoneNumberForUi(widget.user.phoneNumber));

    final initialExtra = widget.user.extraField ?? '';
    _extraFieldController = TextEditingController(
      text: widget.user.isSiswa && initialExtra.startsWith('NISN: ')
          ? initialExtra.replaceFirst('NISN: ', '')
          : initialExtra,
    );

    _selectedRoomId = widget.user.roomId;
    _selectedRoomName = widget.user.roomName;
    _selectedClassLevel = widget.user.classLevel;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nicknameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _extraFieldController.dispose();
    super.dispose();
  }

  String _normalizePhoneNumberForDb(String input) {
    var clean = input.replaceAll('-', '').replaceAll(' ', '');
    if (clean.startsWith('0')) {
      clean = '+62${clean.substring(1)}';
    } else if (clean.startsWith('62') && !clean.startsWith('+62')) {
      clean = '+$clean';
    } else if (!clean.startsWith('+62') && clean.isNotEmpty) {
      if (clean.length >= 9 && !clean.startsWith('+')) {
        clean = '+62$clean';
      }
    }
    return clean;
  }

  String _formatPhoneNumberForUi(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    var clean = phone.replaceAll('-', '').replaceAll(' ', '');
    if (clean.startsWith('0')) {
      clean = '+62${clean.substring(1)}';
    }
    if (clean.startsWith('+62')) {
      final suffix = clean.substring(3);
      String formatted = '+62 ';
      if (suffix.isNotEmpty) {
        if (suffix.length <= 3) {
          formatted += suffix;
        } else if (suffix.length <= 7) {
          formatted += '${suffix.substring(0, 3)}-${suffix.substring(3)}';
        } else {
          formatted +=
              '${suffix.substring(0, 3)}-${suffix.substring(3, 7)}-${suffix.substring(7)}';
        }
      }
      return formatted;
    }
    return phone;
  }

  Future<void> _selectBirthDate() async {
    DateTime initial = DateTime(2006, 1, 1);
    if (widget.user.isGuru) {
      initial = DateTime(1995, 1, 1);
    }
    if (_birthDateController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_birthDateController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.appColors.primary,
              onPrimary: context.appColors.textInverse,
              surface: context.appColors.surface,
              onSurface: context.appColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _birthDateController.text = formatted;
      });
    }
  }

  Future<void> _onSave() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (widget.user.isSiswa &&
        (_selectedRoomId == null || _selectedRoomId!.isEmpty)) {
      AppToast.showError(
        context,
        title: 'Ruang Kelas Belum Dipilih',
        message: 'Siswa wajib memilih atau terdaftar pada suatu ruang kelas.',
      );
      return;
    }
    if (!isValid) {
      AppToast.showError(
        context,
        title: 'Formulir Belum Lengkap',
        message: 'Harap periksa dan lengkapi kolom yang bertanda wajib (*).',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final extraVal = widget.user.isSiswa
          ? 'NISN: ${_extraFieldController.text.trim()}'
          : _extraFieldController.text.trim();

      final updatedUser = widget.user.copyWith(
        displayName: widget.user.isSiswa
            ? widget.user.displayName
            : _displayNameController.text.trim(),
        titlePrefix:
            widget.user.isGuru ? _selectedTitlePrefix : widget.user.titlePrefix,
        nickname: _nicknameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        phoneNumber:
            _normalizePhoneNumberForDb(_phoneNumberController.text.trim()),
        address: _addressController.text.trim(),
        extraField: extraVal.isNotEmpty ? extraVal : null,
        roomId: _selectedRoomId,
        roomName: _selectedRoomName,
        classLevel: _selectedClassLevel,
        attendanceNumber: widget.user.attendanceNumber,
        isFirstLogin: false,
      );

      final success = await ref
          .read(authProvider.notifier)
          .updateProfile(updatedUser);

      if (success && mounted) {
        ref.invalidate(allUsersProvider);
        ref.invalidate(todayStudentsAttendanceProvider);
        ref.invalidate(todayTeachersAttendanceProvider);
        ref.invalidate(classRoomsProvider);

        AppToast.showSuccess(
          context,
          title: 'Profil Berhasil Dilengkapi!',
          message:
              'Selamat datang, ${_nicknameController.text.trim()}! Data Anda telah tersimpan.',
        );
      } else if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal Menyimpan',
          message: 'Terjadi kesalahan saat menyimpan data profil Anda.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal Menyimpan',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleTitle = widget.user.isGuru
        ? 'Guru'
        : (widget.user.isSiswa ? 'Siswa' : 'Pengguna');
    final roomsAsync = ref.watch(classRoomsProvider);
    final allUsersAsync = ref.watch(allUsersProvider);

    final effectiveRoomId = _selectedRoomId ?? widget.user.roomId;
    final matchedRoom = roomsAsync.maybeWhen(
      data: (rooms) => rooms.where((r) => r.id == effectiveRoomId).firstOrNull,
      orElse: () => null,
    );
    String waliKelasDisplay = '-';
    if (matchedRoom != null) {
      final waliName = matchedRoom.guruWaliName?.trim();
      final waliId = matchedRoom.guruWaliId;
      if (waliName != null && waliName.isNotEmpty) {
        final teacherUser = allUsersAsync.maybeWhen(
          data: (users) => users.where((u) => u.uid == waliId).firstOrNull,
          orElse: () => null,
        );
        final titlePrefix = teacherUser?.titlePrefix?.trim();
        final lowerName = waliName.toLowerCase();
        if (lowerName.startsWith('bapak') || lowerName.startsWith('ibu')) {
          waliKelasDisplay = waliName;
        } else if (titlePrefix != null && titlePrefix.isNotEmpty) {
          waliKelasDisplay = '$titlePrefix $waliName';
        } else {
          waliKelasDisplay = 'Bapak / Ibu $waliName';
        }
      } else {
        waliKelasDisplay = 'Belum ditentukan';
      }
    }

    return PopScope(
      canPop: false,
      child: AppScaffold(
        topBar: AppTopBar(
          title: 'Lengkapi Profil',
          subtitle: 'Data Wajib $roleTitle Baru',
          showThemeToggle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.appColors.primary.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.user.isGuru
                                ? Icons.badge_rounded
                                : Icons.school_rounded,
                            size: 28,
                            color: context.appColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lengkapi Biodata $roleTitle',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Silakan lengkapi biodata Anda di bawah ini untuk memulai.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // For Siswa: Data Nama Lengkap & Kelas sudah ditetapkan oleh Admin
                  if (widget.user.isSiswa) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.appColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: context.appColors.primary.withAlpha(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 18,
                                color: context.appColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Data Terdaftar Sekolah',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: context.appColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Nama Lengkap Siswa (Read-only)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.appColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: context.appColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nama Lengkap Siswa',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: context.appColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.user.displayName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.appColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Ruang Kelas Siswa (Read-only)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.appColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.meeting_room_rounded,
                                  size: 18,
                                  color: context.appColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ruang Kelas',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: context.appColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.user.fullClassLabel ??
                                          'Kelas ${_selectedRoomName ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.appColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.appColors.success.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: context.appColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Terdaftar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: context.appColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // Wali Kelas Siswa (Read-only)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.appColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.supervisor_account_rounded,
                                  size: 18,
                                  color: context.appColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wali Kelas',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: context.appColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      waliKelasDisplay,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.appColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.user.attendanceNumber != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            // Nomor Absen Siswa (Read-only)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.appColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.format_list_numbered_rounded,
                                    size: 18,
                                    color: context.appColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nomor Absen Siswa',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: context.appColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.user.formattedAttendanceNumber ??
                                            'No. ${widget.user.attendanceNumber}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: context.appColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (widget.user.formattedAngkatan != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            // Angkatan Siswa (Read-only)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.appColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.school_outlined,
                                    size: 18,
                                    color: context.appColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Angkatan Siswa',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: context.appColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.user.formattedAngkatan!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: context.appColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Fallback room picker only if student somehow has no room
                    if (_selectedRoomId == null || _selectedRoomId!.isEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      roomsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (rooms) => DropdownButtonFormField<String>(
                          value: _selectedRoomId,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.appColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Pilih Ruang Kelas *',
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.appColors.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.meeting_room_rounded,
                              size: 20,
                              color: context.appColors.textMuted,
                            ),
                            filled: true,
                            fillColor: context.appColors.surfaceSoft,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: rooms.map((r) {
                            final cleanName = r.name.trim();
                            final level = r.level.trim();
                            String label;
                            if (cleanName.toLowerCase().startsWith('kelas')) {
                              label = cleanName;
                            } else if (cleanName
                                .toLowerCase()
                                .startsWith(level.toLowerCase())) {
                              final remainder =
                                  cleanName.substring(level.length).trim();
                              final cleanRemainder = remainder.startsWith('-')
                                  ? remainder.substring(1).trim()
                                  : remainder;
                              label = cleanRemainder.isNotEmpty
                                  ? 'Kelas $level - $cleanRemainder'
                                  : 'Kelas $cleanName';
                            } else {
                              label = 'Kelas $level - $cleanName';
                            }
                            return DropdownMenuItem(
                              value: r.id,
                              child: Text(label, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final match = rooms.firstWhere((r) => r.id == val);
                              setState(() {
                                _selectedRoomId = match.id;
                                _selectedRoomName = match.name;
                                _selectedClassLevel = match.level;
                              });
                            }
                          },
                          validator: (v) => v == null || v.isEmpty
                              ? 'Ruang kelas wajib dipilih'
                              : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Lengkapi Data Diri Siswa',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ] else ...[
                    if (widget.user.isGuru) ...[
                      Text(
                        'Sapaan Guru *',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTitleOption(
                              'Bapak',
                              Icons.person_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildTitleOption(
                              'Ibu',
                              Icons.person_2_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // 1. Nama Lengkap for non-siswa
                    _buildTextField(
                      label: 'Nama Lengkap *',
                      controller: _displayNameController,
                      icon: Icons.person_outline_rounded,
                      hint: 'Masukkan nama lengkap sesuai identitas',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }
                        if (v.trim().length < 3) {
                          return 'Nama lengkap minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 2. Nama Panggilan
                  _buildTextField(
                    label: 'Nama Panggilan *',
                    controller: _nicknameController,
                    icon: Icons.badge_outlined,
                    hint: 'Nama panggilan akrab untuk sapaan',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama panggilan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. NISN (Siswa) OR Mata Pelajaran (Guru)
                  if (widget.user.isSiswa) ...[
                    _buildTextField(
                      label: 'Nomor Induk Siswa Nasional (NISN) *',
                      controller: _extraFieldController,
                      icon: Icons.numbers_rounded,
                      hint: 'Contoh: 0071234567 (10 digit angka)',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'NISN wajib diisi';
                        }
                        if (v.trim().length < 8) {
                          return 'NISN minimal 8 digit angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else ...[
                    _buildTextField(
                      label: 'Mata Pelajaran / Jabatan *',
                      controller: _extraFieldController,
                      icon: Icons.menu_book_rounded,
                      hint: 'Contoh: Guru Produktif RPL / Wali Kelas',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Mata Pelajaran / Jabatan wajib diisi';
                        }
                        if (v.trim().length < 3) {
                          return 'Minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 4. No. HP / WhatsApp
                  _buildTextField(
                    label: widget.user.isSiswa
                        ? 'Nomor HP Orang Tua / Wali *'
                        : 'Nomor HP Pribadi / WhatsApp *',
                    controller: _phoneNumberController,
                    icon: Icons.phone_outlined,
                    hint: '+62 812-3456-7890',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneTextInputFormatter()],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nomor HP wajib diisi';
                      }
                      final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                      if (clean.length < 9) {
                        return 'Nomor HP tidak valid (minimal 9 digit)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Tanggal Lahir
                  _buildTextField(
                    label: 'Tanggal Lahir *',
                    controller: _birthDateController,
                    icon: Icons.calendar_today_rounded,
                    hint: 'YYYY-MM-DD',
                    readOnly: true,
                    onTap: _selectBirthDate,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Tanggal lahir wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 6. Alamat Lengkap Domisili
                  _buildTextField(
                    label: 'Alamat Tinggal Domisili *',
                    controller: _addressController,
                    hint: 'Masukkan alamat tempat tinggal Anda saat ini...',
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Alamat tempat tinggal wajib diisi';
                      }
                      if (v.trim().length < 5) {
                        return 'Alamat terlalu singkat (minimal 5 karakter)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit Action Button
                  AppPrimaryButton(
                    label: _isSaving
                        ? 'Menyimpan Profil...'
                        : 'Simpan & Masuk Aplikasi',
                    icon: Icons.check_circle_rounded,
                    onPressed: _isSaving ? null : _onSave,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    String? hint,
    int? maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          enabled: !_isSaving,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: context.appColors.textMuted.withAlpha(140),
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: context.appColors.textSecondary,
                    size: 20,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: context.appColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: context.appColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(
                color: context.appColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(
                color: context.appColors.danger,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(
                color: context.appColors.danger,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleOption(String title, IconData icon) {
    final isSelected = _selectedTitlePrefix == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedTitlePrefix = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appColors.primary.withAlpha(25)
              : context.appColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isSelected
                ? context.appColors.primary
                : context.appColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? context.appColors.primary
                  : context.appColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? context.appColors.primary
                    : context.appColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
