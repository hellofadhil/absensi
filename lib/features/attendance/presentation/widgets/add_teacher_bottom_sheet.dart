import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/attendance_provider.dart';

class AddTeacherBottomSheet extends ConsumerStatefulWidget {
  const AddTeacherBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTeacherBottomSheet(),
    );
  }

  @override
  ConsumerState<AddTeacherBottomSheet> createState() =>
      _AddTeacherBottomSheetState();
}

class _AddTeacherBottomSheetState extends ConsumerState<AddTeacherBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSaving = false;
  bool _obscurePassword = true;
  String _selectedTitlePrefix = 'Bapak';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final newTeacher = AppUser(
        uid: '',
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: 'guru',
        titlePrefix: _selectedTitlePrefix,
        extraField: _subjectController.text.trim(),
        isFirstLogin: true,
      );

      await repository.createUser(
        newTeacher,
        password: _passwordController.text.trim(),
      );

      ref.invalidate(allUsersProvider);
      ref.invalidate(todayTeachersAttendanceProvider);

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil!',
          message: 'Data guru ${_nameController.text.trim()} berhasil ditambahkan.',
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
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Handle
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.appColors.success.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.badge_rounded,
                            size: 20,
                            color: context.appColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Tambah Data Guru',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
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

                // 1. Nama Lengkap Guru
                _buildTextField(
                  label: 'Nama Lengkap Guru',
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  hint: 'Contoh: Ahmad Hidayat, S.Pd',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama guru tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),

                // 2. Alamat Email
                _buildTextField(
                  label: 'Alamat Email',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  hint: 'Contoh: ahmad.guru@sekolah.sch.id',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!v.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // 3. Mata Pelajaran / Jabatan
                _buildTextField(
                  label: 'Mata Pelajaran / Jabatan *',
                  controller: _subjectController,
                  icon: Icons.menu_book_rounded,
                  hint: 'Contoh: Guru Produktif RPL / Wali Kelas XI-A',
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
                const SizedBox(height: AppSpacing.sm),

                // 4. Kata Sandi
                _buildTextField(
                  label: 'Kata Sandi',
                  controller: _passwordController,
                  icon: Icons.lock_outline_rounded,
                  hint: 'Min. 6 Karakter',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: context.appColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Sandi wajib diisi';
                    }
                    if (v.trim().length < 6) {
                      return 'Min. 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Bottom Navigation Buttons
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
                      child: AppPrimaryButton(
                        label: _isSaving ? 'Menyimpan...' : 'Simpan Guru',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _isSaving ? null : _onSave,
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
    String? hint,
    int? maxLines = 1,
    int? minLines,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: context.appColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.appColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontSize: 12,
          color: context.appColors.textMuted.withAlpha(120),
        ),
        prefixIcon: Icon(icon, size: 20, color: context.appColors.textMuted),
        suffixIcon: suffixIcon,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(
            color: context.appColors.primary,
            width: 1.5,
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
