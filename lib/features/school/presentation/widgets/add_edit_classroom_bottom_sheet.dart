import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../domain/entities/class_room.dart';
import '../providers/school_provider.dart';

class AddEditClassRoomBottomSheet extends ConsumerStatefulWidget {
  const AddEditClassRoomBottomSheet({super.key, this.room});

  final ClassRoom? room;

  static Future<void> show(BuildContext context, {ClassRoom? room}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditClassRoomBottomSheet(room: room),
    );
  }

  @override
  ConsumerState<AddEditClassRoomBottomSheet> createState() =>
      _AddEditClassRoomBottomSheetState();
}

class _AddEditClassRoomBottomSheetState
    extends ConsumerState<AddEditClassRoomBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;

  final List<String> _availableLevels = ['X', 'XI', 'XII', 'XIII'];
  late String _selectedLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room?.name ?? '');
    _capacityController =
        TextEditingController(text: (widget.room?.capacity ?? 30).toString());

    _selectedLevel = widget.room?.level ?? 'X';
    if (!_availableLevels.contains(_selectedLevel)) {
      _availableLevels.insert(0, _selectedLevel);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _showAddLevelDialog() async {
    final customLevelCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(
          'Tambah Tingkat Kelas Baru',
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
              'Masukkan nama tingkat kelas (misal: XIV, Program Khusus, dll)',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: customLevelCtrl,
              autofocus: true,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Contoh: XIV',
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
              final newLevel = customLevelCtrl.text.trim().toUpperCase();
              if (newLevel.isNotEmpty) {
                if (!_availableLevels.contains(newLevel)) {
                  setState(() {
                    _availableLevels.add(newLevel);
                    _selectedLevel = newLevel;
                  });
                } else {
                  setState(() {
                    _selectedLevel = newLevel;
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
      final name = _nameController.text.trim();
      final capacity = int.tryParse(_capacityController.text.trim()) ?? 30;
      final notifier = ref.read(classRoomNotifierProvider.notifier);

      if (widget.room == null) {
        // Create new classroom
        await notifier.create(ClassRoom(
          id: '',
          name: name,
          level: _selectedLevel,
          capacity: capacity,
        ));
        if (mounted) {
          AppToast.showSuccess(
            context,
            title: 'Berhasil!',
            message: 'Ruang kelas $name berhasil ditambahkan.',
          );
        }
      } else {
        // Edit existing classroom
        final updatedRoom = widget.room!.copyWith(
          name: name,
          level: _selectedLevel,
          capacity: capacity,
        );
        await notifier.save(updatedRoom);
        if (mounted) {
          AppToast.showSuccess(
            context,
            title: 'Berhasil!',
            message: 'Ruang kelas $name berhasil diperbarui.',
          );
        }
      }

      if (mounted) {
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
    final isEditing = widget.room != null;

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
                            color: context.appColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isEditing
                                ? Icons.edit_rounded
                                : Icons.meeting_room_rounded,
                            size: 20,
                            color: context.appColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isEditing ? 'Edit Ruang Kelas' : 'Tambah Ruang Kelas',
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
                const SizedBox(height: AppSpacing.lg),

                // Tingkat Kelas Options Selector
                Text(
                  'Tingkat Kelas',
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
                    ..._availableLevels.map((lvl) {
                      final isSelected = _selectedLevel == lvl;
                      return ChoiceChip(
                        label: Text('Tingkat $lvl'),
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
                            setState(() => _selectedLevel = lvl);
                          }
                        },
                      );
                    }),
                    // Add Level Option Chip
                    ActionChip(
                      avatar: Icon(Icons.add_rounded,
                          size: 16, color: context.appColors.primary),
                      label: Text(
                        'Tambah Tingkat',
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
                      onPressed: _showAddLevelDialog,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Nama Ruangan Input
                Text(
                  'Nama Ruangan *',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama ruangan tidak boleh kosong'
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Contoh: X-A, XI-B, XII-IPA 1',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: context.appColors.textMuted,
                    ),
                    prefixIcon: Icon(Icons.meeting_room_outlined,
                        size: 20, color: context.appColors.textSecondary),
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      borderSide: BorderSide(color: context.appColors.danger, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      borderSide: BorderSide(color: context.appColors.danger, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Kapasitas Siswa Input
                Text(
                  'Maksimal Kapasitas Siswa *',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Kapasitas wajib diisi';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: '30',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: context.appColors.textMuted,
                    ),
                    prefixIcon: Icon(Icons.groups_outlined,
                        size: 20, color: context.appColors.textSecondary),
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      borderSide: BorderSide(color: context.appColors.danger, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      borderSide: BorderSide(color: context.appColors.danger, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Bottom Action Buttons
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
                        label: _isSaving
                            ? 'Menyimpan...'
                            : isEditing
                                ? 'Simpan Perubahan'
                                : 'Simpan Ruangan',
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
}
