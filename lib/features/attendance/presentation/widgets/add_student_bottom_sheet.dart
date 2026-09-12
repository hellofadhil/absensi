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
import '../providers/attendance_provider.dart';

class AddStudentBottomSheet extends ConsumerStatefulWidget {
  const AddStudentBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddStudentBottomSheet(),
    );
  }

  @override
  ConsumerState<AddStudentBottomSheet> createState() =>
      _AddStudentBottomSheetState();
}

class _AddStudentBottomSheetState
    extends ConsumerState<AddStudentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nisnController = TextEditingController();
  final _attendanceNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _availableAngkatan = ['10', '11', '12', '13'];
  late String _selectedAngkatan;

  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedClassLevel;
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _selectedAngkatan = '12';
    // Collect distinct angkatans from existing users if available
    final allUsers = ref.read(allUsersProvider).asData?.value ?? [];
    for (final u in allUsers) {
      if (u.angkatan != null && u.angkatan!.isNotEmpty) {
        final clean = u.angkatan!.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').trim();
        if (clean.isNotEmpty && !_availableAngkatan.contains(clean)) {
          _availableAngkatan.add(clean);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nisnController.dispose();
    _attendanceNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final newStudent = AppUser(
        uid: '',
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: 'siswa',
        roomId: _selectedClassId,
        roomName: _selectedClassName,
        classLevel: _selectedClassLevel,
        angkatan: _selectedAngkatan,
        attendanceNumber: int.tryParse(_attendanceNumberController.text.trim()),
        extraField: 'NISN: ${_nisnController.text.trim()}',
        isFirstLogin: true,
      );

      await repository.createUser(
        newStudent,
        password: _passwordController.text.trim(),
      );

      ref.invalidate(allUsersProvider);
      ref.invalidate(classRoomsProvider);
      ref.invalidate(todayStudentsAttendanceProvider);

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil!',
          message:
              'Data siswa ${_nameController.text.trim()} berhasil ditambahkan.',
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.appColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: context.appColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Tambah Siswa Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Name field
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.appColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Siswa *',
                  hintText: 'Contoh: Ahmad Fadhil',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(color: context.appColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(
                        color: context.appColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama siswa wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.appColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email Akun Siswa *',
                  hintText: 'siswa@sekolah.sch.id',
                  prefixIcon: const Icon(Icons.email_outlined),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(color: context.appColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(
                        color: context.appColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Email siswa wajib diisi';
                  }
                  if (!val.contains('@')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Angkatan Selector
              Text(
                'Angkatan Siswa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textSecondary,
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
              const SizedBox(height: AppSpacing.lg),

              // Class selection dropdown
              roomsAsync.when(
                data: (rooms) {
                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    style: TextStyle(color: context.appColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Pilih Kelas *',
                      hintText: 'Contoh: Kelas X - RPL 1',
                      prefixIcon: const Icon(Icons.school_outlined),
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
                            color: context.appColors.primary, width: 2),
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
                      setState(() {
                        _selectedClassId = val;
                        final match =
                            rooms.firstWhere((r) => r.id == val);
                        _selectedClassName = match.name;
                        _selectedClassLevel = match.level;
                      });
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Silakan pilih kelas siswa';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Nomor Absen
              TextFormField(
                controller: _attendanceNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                style: TextStyle(color: context.appColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nomor Absen Siswa *',
                  hintText: 'Contoh: 1, 15, 32',
                  prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(color: context.appColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(
                        color: context.appColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nomor absen wajib diisi';
                  }
                  final num = int.tryParse(val.trim());
                  if (num == null || num <= 0) {
                    return 'Nomor absen harus angka minimal 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // NISN / Extra Info
              TextFormField(
                controller: _nisnController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: TextStyle(color: context.appColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'NISN (Nomor Induk Siswa Nasional) *',
                  hintText: 'Contoh: 0071234567 (10 digit angka)',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(color: context.appColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(
                        color: context.appColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'NISN siswa wajib diisi';
                  }
                  if (val.trim().length < 8) {
                    return 'NISN minimal 8 digit angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: context.appColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password Akun *',
                  hintText: 'Minimal 6 karakter',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: context.appColors.textSecondary,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(color: context.appColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide(
                        color: context.appColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Password wajib diisi';
                  }
                  if (val.trim().length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: context.appColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Simpan Siswa',
                      onPressed: _isSaving ? null : _onSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
