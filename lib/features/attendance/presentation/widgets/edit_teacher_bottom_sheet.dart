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
import '../../presentation/providers/attendance_provider.dart';
import '../../../profile/presentation/widgets/edit_profile_bottom_sheet.dart';

class EditTeacherBottomSheet extends ConsumerStatefulWidget {
  const EditTeacherBottomSheet({super.key, required this.user});

  final AppUser user;

  static Future<void> show(BuildContext context, AppUser user) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTeacherBottomSheet(user: user),
    );
  }

  @override
  ConsumerState<EditTeacherBottomSheet> createState() =>
      _EditTeacherBottomSheetState();
}

class _EditTeacherBottomSheetState
    extends ConsumerState<EditTeacherBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _extraFieldController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneNumberController;

  bool _isSaving = false;
  late String _selectedTitlePrefix;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _selectedTitlePrefix = u.titlePrefix ??
        (u.displayName.toLowerCase().startsWith('ibu') ? 'Ibu' : 'Bapak');
    _displayNameController = TextEditingController(text: u.displayName);
    _nicknameController = TextEditingController(text: u.nickname ?? '');
    _extraFieldController = TextEditingController(text: u.extraField ?? '');
    _birthDateController = TextEditingController(text: u.birthDate ?? '');
    _addressController = TextEditingController(text: u.address ?? '');
    _phoneNumberController =
        TextEditingController(text: u.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nicknameController.dispose();
    _extraFieldController.dispose();
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
    DateTime initialDate = DateTime(1985, 1, 1);

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
      firstDate: DateTime(1950),
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

      final cleanPhone = _phoneNumberController.text.trim().isNotEmpty
          ? _normalizePhone(_phoneNumberController.text.trim())
          : null;

      final extraFieldVal = _extraFieldController.text.trim().isNotEmpty
          ? _extraFieldController.text.trim()
          : null;

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
        titlePrefix: _selectedTitlePrefix,
      );

      await authRepo.updateUser(updatedUser);

      // Invalidate providers
      ref.invalidate(allUsersProvider);
      ref.invalidate(todayTeachersAttendanceProvider);

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil!',
          message: 'Data guru ${updatedUser.displayName} berhasil diperbarui.',
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
                      'Edit Data Guru',
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

                // Sapaan Guru (Bapak / Ibu)
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
                      child: _buildTitleOption('Bapak', Icons.person_rounded),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildTitleOption('Ibu', Icons.person_2_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Nama Lengkap
                _buildTextField(
                  label: 'Nama Lengkap Guru *',
                  controller: _displayNameController,
                  icon: Icons.person_outline_rounded,
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Nama guru tidak boleh kosong'
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

                // NIP / Mata Pelajaran / Jabatan
                _buildTextField(
                  label: 'NIP / Mapel Ajar / Jabatan',
                  controller: _extraFieldController,
                  icon: Icons.school_outlined,
                  hintText: 'Contoh: NIP. 198501... / Guru Matematika',
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

                // Nomor HP Pribadi
                _buildTextField(
                  label: 'Nomor HP Pribadi (Opsional)',
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
                  icon: Icons.location_on_outlined,
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
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    String? hintText,
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
            hintText: hintText,
            prefixIcon:
                Icon(icon, color: context.appColors.textSecondary, size: 20),
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

  Widget _buildTitleOption(String title, IconData icon) {
    final isSelected = _selectedTitlePrefix == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedTitlePrefix = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? context.appColors.primary.withAlpha(25)
              : context.appColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isSelected ? context.appColors.primary : context.appColors.border,
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
