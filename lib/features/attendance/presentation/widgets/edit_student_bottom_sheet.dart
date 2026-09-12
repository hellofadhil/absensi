import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../school/presentation/providers/school_provider.dart';
import '../../presentation/providers/attendance_provider.dart';
import '../../../profile/presentation/widgets/edit_profile_bottom_sheet.dart';

class EditStudentBottomSheet extends ConsumerStatefulWidget {
  const EditStudentBottomSheet({super.key, required this.user});

  final AppUser user;

  static Future<void> show(BuildContext context, AppUser user) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditStudentBottomSheet(user: user),
    );
  }

  @override
  ConsumerState<EditStudentBottomSheet> createState() =>
      _EditStudentBottomSheetState();
}

class _EditStudentBottomSheetState
    extends ConsumerState<EditStudentBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _nisnController;
  late final TextEditingController _attendanceNumberController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneNumberController;

  String? _selectedRoomId;
  String? _selectedRoomName;
  String? _selectedClassLevel;
  bool _isSaving = false;

  final List<String> _availableAngkatan = ['10', '11', '12', '13'];
  late String _selectedAngkatan;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _displayNameController = TextEditingController(text: u.displayName);
    _nicknameController = TextEditingController(text: u.nickname ?? '');

    // Extract NISN digits if stored with prefix 'NISN: ...'
    String cleanNisn = u.extraField ?? '';
    if (cleanNisn.startsWith('NISN:')) {
      cleanNisn = cleanNisn.replaceFirst('NISN:', '').trim();
    } else if (cleanNisn.startsWith('NISN')) {
      cleanNisn = cleanNisn.replaceFirst('NISN', '').trim();
    } else if (cleanNisn.toLowerCase().contains('siswa')) {
      cleanNisn = '';
    }
    _nisnController = TextEditingController(text: cleanNisn);
    _attendanceNumberController =
        TextEditingController(text: u.attendanceNumber?.toString() ?? '');

    _birthDateController = TextEditingController(text: u.birthDate ?? '');
    _addressController = TextEditingController(text: u.address ?? '');
    _phoneNumberController =
        TextEditingController(text: u.phoneNumber ?? '');

    _selectedRoomId = u.roomId;
    _selectedRoomName = u.roomName;
    _selectedClassLevel = u.classLevel;

    final userAngkatan = u.angkatan?.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').trim();
    _selectedAngkatan = (userAngkatan != null && userAngkatan.isNotEmpty) ? userAngkatan : '12';
    if (!_availableAngkatan.contains(_selectedAngkatan)) {
      _availableAngkatan.insert(0, _selectedAngkatan);
    }
    // Collect distinct angkatans from existing users if available
    final allUsers = ref.read(allUsersProvider).asData?.value ?? [];
    for (final user in allUsers) {
      if (user.angkatan != null && user.angkatan!.isNotEmpty) {
        final clean = user.angkatan!.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').trim();
        if (clean.isNotEmpty && !_availableAngkatan.contains(clean)) {
          _availableAngkatan.add(clean);
        }
      }
    }
  }

  Future<void> _showAddAngkatanDialog() async {
    final customCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Tambah Angkatan Baru',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: context.appColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan nomor angkatan (misal: 14, 15, dll)',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: customCtrl,
              autofocus: true,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Contoh: 14',
                filled: true,
                fillColor: context.appColors.surfaceSoft,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(color: context.appColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            onPressed: () {
              final newAngkatan = customCtrl.text.trim();
              if (newAngkatan.isNotEmpty) {
                final clean = newAngkatan.toLowerCase().startsWith('angkatan')
                    ? newAngkatan.substring(8).trim()
                    : newAngkatan;
                if (clean.isNotEmpty) {
                  setState(() {
                    if (!_availableAngkatan.contains(clean)) {
                      _availableAngkatan.add(clean);
                    }
                    _selectedAngkatan = clean;
                  });
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nicknameController.dispose();
    _nisnController.dispose();
    _attendanceNumberController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  String _normalizePhone(String input) {
    var clean = input.replaceAll('-', '').replaceAll(' ', '');
    if (clean.startsWith('0')) {
      clean = '+62${clean.substring(1)}';
    } else if (clean.startsWith('62') && !clean.startsWith('+62')) {
      clean = '+$clean';
    } else if (!clean.startsWith('+62') && clean.isNotEmpty) {
      clean = '+62$clean';
    }
    return clean;
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    DateTime initialDate = DateTime(2008, 1, 1);

    try {
      final text = _birthDateController.text.trim();
      final parts = text.split(' ');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1].toLowerCase();
        final year = int.parse(parts[2]);

        const months = [
          'januari', 'februari', 'maret', 'april', 'mei', 'juni',
          'juli', 'agustus', 'september', 'oktober', 'november', 'desember'
        ];
        final monthIndex = months.indexOf(monthStr);
        if (monthIndex != -1) {
          initialDate = DateTime(year, monthIndex + 1, day);
        }
      }
    } catch (_) {}

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: now,
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

    if (pickedDate != null) {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final formattedDate =
          '${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}';
      setState(() {
        _birthDateController.text = formattedDate;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final schoolRepo = ref.read(schoolRepositoryProvider);

      final originalRoomId = widget.user.roomId;
      final newRoomId = _selectedRoomId;

      // If room changed, handle transfer of student count atomically
      if (newRoomId != null &&
          newRoomId.isNotEmpty &&
          newRoomId != originalRoomId) {
        await schoolRepo.transferStudentClass(
          studentUid: widget.user.uid,
          fromRoomId: originalRoomId,
          toRoomId: newRoomId,
          toRoomName: _selectedRoomName ?? '',
          toClassLevel: _selectedClassLevel ?? 'X',
        );
      }

      final cleanPhone = _phoneNumberController.text.trim().isNotEmpty
          ? _normalizePhone(_phoneNumberController.text.trim())
          : null;

      final cleanNisn = _nisnController.text.trim();
      final extraFieldVal = cleanNisn.isNotEmpty ? 'NISN: $cleanNisn' : null;

      final updatedUser = widget.user.copyWith(
        displayName: _displayNameController.text.trim(),
        nickname: _nicknameController.text.trim().isNotEmpty
            ? _nicknameController.text.trim()
            : null,
        birthDate: _birthDateController.text.trim().isNotEmpty
            ? _birthDateController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        phoneNumber: cleanPhone,
        extraField: extraFieldVal,
        roomId: _selectedRoomId,
        roomName: _selectedRoomName,
        classLevel: _selectedClassLevel,
        angkatan: _selectedAngkatan,
        attendanceNumber: int.tryParse(_attendanceNumberController.text.trim()),
      );

      await authRepo.updateUser(updatedUser);

      // Invalidate relevant providers to refresh UI state
      ref.invalidate(allUsersProvider);
      ref.invalidate(classRoomsProvider);
      ref.invalidate(todayStudentsAttendanceProvider);

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil!',
          message: 'Data siswa ${updatedUser.displayName} berhasil diperbarui.',
        );
        Navigator.pop(context);
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
    final roomsAsync = ref.watch(classRoomsProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header drag indicator
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Data Siswa',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Nama Lengkap
                _buildTextField(
                  label: 'Nama Lengkap Siswa *',
                  controller: _displayNameController,
                  icon: Icons.person_outline_rounded,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Nama siswa tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Nama Panggilan
                _buildTextField(
                  label: 'Nama Panggilan (Opsional)',
                  controller: _nicknameController,
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: AppSpacing.md),

                // Angkatan Selector
                Text(
                  'Angkatan Siswa',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._availableAngkatan.map((ang) {
                      final isSelected = _selectedAngkatan == ang;
                      return ChoiceChip(
                        label: Text('Angkatan $ang'),
                        selected: isSelected,
                        selectedColor: context.appColors.primary,
                        backgroundColor: context.appColors.surfaceSoft,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : context.appColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? context.appColors.primary
                                : context.appColors.border,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedAngkatan = ang);
                          }
                        },
                      );
                    }),
                    // Add Angkatan Option Chip
                    ActionChip(
                      avatar: Icon(Icons.add_rounded,
                          size: 16, color: context.appColors.primary),
                      label: Text(
                        'Tambah Angkatan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.primary,
                        ),
                      ),
                      backgroundColor: context.appColors.primary.withAlpha(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: context.appColors.primary.withAlpha(80),
                        ),
                      ),
                      onPressed: _showAddAngkatanDialog,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Ruang Kelas Dropdown
                roomsAsync.when(
                  data: (rooms) {
                    final isValidRoom =
                        rooms.any((r) => r.id == _selectedRoomId);
                    final currentValue = isValidRoom ? _selectedRoomId : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ruang Kelas *',
                          style:
                              Theme.of(context).textTheme.titleSmall!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          value: currentValue,
                          style: TextStyle(
                              color: context.appColors.textPrimary),
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.meeting_room_outlined),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              borderSide:
                                  BorderSide(color: context.appColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              borderSide:
                                  BorderSide(color: context.appColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                              borderSide: BorderSide(
                                color: context.appColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          items: rooms.map((room) {
                            final cleanName = room.name.trim();
                            final level = room.level.trim();
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
                            return DropdownMenuItem<String>(
                              value: room.id,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final matched =
                                  rooms.firstWhere((r) => r.id == val);
                              setState(() {
                                _selectedRoomId = matched.id;
                                _selectedRoomName = matched.name;
                                _selectedClassLevel = matched.level;
                              });
                            }
                          },
                          validator: (val) => val == null || val.isEmpty
                              ? 'Pilih ruang kelas siswa'
                              : null,
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Nomor Absen
                _buildTextField(
                  label: 'Nomor Absen Siswa',
                  controller: _attendanceNumberController,
                  icon: Icons.format_list_numbered_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // NISN
                _buildTextField(
                  label: 'NISN (Opsional)',
                  controller: _nisnController,
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),

                // Tanggal Lahir
                _buildTextField(
                  label: 'Tanggal Lahir',
                  controller: _birthDateController,
                  icon: Icons.calendar_today_rounded,
                  readOnly: true,
                  onTap: _selectBirthDate,
                ),
                const SizedBox(height: AppSpacing.md),

                // Nomor HP Orang Tua / Wali
                _buildTextField(
                  label: 'Nomor HP Orang Tua / Wali (Opsional)',
                  controller: _phoneNumberController,
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneTextInputFormatter()],
                ),
                const SizedBox(height: AppSpacing.md),

                // Alamat Tinggal
                _buildTextField(
                  label: 'Alamat Tinggal (Opsional)',
                  controller: _addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Batal',
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: _isSaving
                          ? Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.appColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : AppPrimaryButton(
                              label: 'Simpan Perubahan',
                              onPressed: _handleSave,
                            ),
                    ),
                  ],
                ),
              ],
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
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
          style: TextStyle(color: context.appColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: context.appColors.textSecondary, size: 20)
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
              borderSide:
                  BorderSide(color: context.appColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
