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
          formatted += '${suffix.substring(0, 3)}-${suffix.substring(3, 7)}-${suffix.substring(7)}';
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

class EditProfileBottomSheet extends ConsumerStatefulWidget {
  const EditProfileBottomSheet({super.key, required this.user});

  final AppUser user;

  static Future<void> show(BuildContext context, AppUser user) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileBottomSheet(user: user),
    );
  }

  @override
  ConsumerState<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends ConsumerState<EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _displayNameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _extraFieldController;
  
  bool _isSaving = false;

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

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    DateTime initialDate;
    
    try {
      final text = _birthDateController.text.trim();
      final parts = text.split(' ');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1].toLowerCase();
        final year = int.parse(parts[2]);
        
        final months = [
          'januari', 'februari', 'maret', 'april', 'mei', 'juni',
          'juli', 'agustus', 'september', 'oktober', 'november', 'desember'
        ];
        final monthIndex = months.indexOf(monthStr);
        if (monthIndex != -1) {
          initialDate = DateTime(year, monthIndex + 1, day);
        } else {
          initialDate = widget.user.isSiswa ? DateTime(2008, 10, 12) : DateTime(1982, 5, 12);
        }
      } else {
        initialDate = widget.user.isSiswa ? DateTime(2008, 10, 12) : DateTime(1982, 5, 12);
      }
    } catch (_) {
      initialDate = widget.user.isSiswa ? DateTime(2008, 10, 12) : DateTime(1982, 5, 12);
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
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
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      final formattedDate = '${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}';
      setState(() {
        _birthDateController.text = formattedDate;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    final isSiswa = u.isSiswa;
    _displayNameController = TextEditingController(text: u.displayName);
    _nicknameController = TextEditingController(text: u.nickname);
    _birthDateController = TextEditingController(
      text: u.birthDate ?? (isSiswa ? '12 Oktober 2008' : '12 Mei 1982'),
    );
    _addressController = TextEditingController(
      text: u.address ?? 'Jl. Jenderal Sudirman No. 45, Kota Bandung',
    );
    _phoneNumberController = TextEditingController(
      text: _formatPhoneNumberForUi(u.phoneNumber ?? (isSiswa ? '0812-3456-7890' : '0857-9988-1122')),
    );
    _extraFieldController = TextEditingController(
      text: u.extraField ?? (isSiswa ? 'Rekayasa Perangkat Lunak' : 'Wali Kelas & Staf Kurikulum'),
    );
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

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      
      final updatedUser = widget.user.copyWith(
        displayName: _displayNameController.text.trim(),
        nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _normalizePhoneNumberForDb(_phoneNumberController.text.trim()),
        extraField: _extraFieldController.text.trim(),
      );

      final success = await ref.read(authProvider.notifier).updateProfile(updatedUser);

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          AppToast.showSuccess(
            context,
            title: 'Profil Berhasil Diperbarui!',
            message: 'Data biodata Anda telah diperbarui.',
          );
          Navigator.pop(context);
        } else {
          AppToast.showError(
            context,
            title: 'Gagal Memperbarui Profil',
            message: 'Silakan coba beberapa saat lagi.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSiswa = widget.user.isSiswa;

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
                // Header
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
                      'Perbarui Biodata',
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Form fields
                _buildTextField(
                  label: 'Nama Lengkap',
                  controller: _displayNameController,
                  icon: Icons.person_outline_rounded,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                _buildTextField(
                  label: 'Nama Panggilan',
                  controller: _nicknameController,
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: AppSpacing.md),

                 _buildTextField(
                   label: 'Tanggal Lahir',
                   controller: _birthDateController,
                   icon: Icons.calendar_today_rounded,
                   readOnly: true,
                   onTap: _selectBirthDate,
                 ),
                const SizedBox(height: AppSpacing.md),

                _buildTextField(
                  label: 'Alamat Tinggal',
                  controller: _addressController,
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),

                _buildTextField(
                  label: isSiswa ? 'Nomor HP Orang Tua / Wali' : 'Nomor HP Pribadi',
                  controller: _phoneNumberController,
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneTextInputFormatter()],
                ),
                const SizedBox(height: AppSpacing.md),

                _buildTextField(
                  label: isSiswa ? 'Jurusan' : 'Jabatan / Peran',
                  controller: _extraFieldController,
                  icon: Icons.workspace_premium_outlined,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Batal',
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                              label: 'Simpan',
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
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: context.appColors.textSecondary, size: 20),
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
              borderSide: BorderSide(color: context.appColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
