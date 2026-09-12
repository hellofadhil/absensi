import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../school/domain/entities/class_room.dart';
import '../../../school/presentation/providers/school_provider.dart';
import '../../presentation/providers/attendance_provider.dart';

class ChangeClassBottomSheet extends ConsumerStatefulWidget {
  const ChangeClassBottomSheet({super.key, required this.student});

  final AppUser student;

  static Future<void> show(BuildContext context, AppUser student) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeClassBottomSheet(student: student),
    );
  }

  @override
  ConsumerState<ChangeClassBottomSheet> createState() =>
      _ChangeClassBottomSheetState();
}

class _ChangeClassBottomSheetState
    extends ConsumerState<ChangeClassBottomSheet> {
  String? _selectedRoomId;
  ClassRoom? _selectedRoom;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.student.roomId;
  }

  Future<void> _handleConfirm() async {
    if (_selectedRoomId == null || _selectedRoom == null) {
      AppToast.showInfo(
        context,
        title: 'Pilih Kelas',
        message: 'Silakan pilih kelas tujuan terlebih dahulu.',
      );
      return;
    }

    if (_selectedRoomId == widget.student.roomId) {
      AppToast.showInfo(
        context,
        title: 'Kelas Sama',
        message: 'Siswa sudah berada di kelas tersebut.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final schoolRepo = ref.read(schoolRepositoryProvider);
      final targetRoom = _selectedRoom!;

      await schoolRepo.transferStudentClass(
        studentUid: widget.student.uid,
        fromRoomId: widget.student.roomId,
        toRoomId: targetRoom.id,
        toRoomName: targetRoom.name,
        toClassLevel: targetRoom.level,
      );

      // Refresh providers
      ref.invalidate(allUsersProvider);
      ref.invalidate(classRoomsProvider);
      ref.invalidate(todayStudentsAttendanceProvider);

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil Pindah Kelas!',
          message:
              '${widget.student.displayName} resmi dipindahkan ke Kelas ${targetRoom.name}.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal Memindahkan Kelas',
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
    final currentClassName = widget.student.fullClassLabel ??
        (widget.student.roomName != null
            ? 'Kelas ${widget.student.roomName}'
            : (widget.student.classLevel != null && widget.student.classLevel!.isNotEmpty
                ? 'Kelas ${widget.student.classLevel}'
                : 'Kelas Siswa'));

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Indicator
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
                  'Pindah Kelas Siswa',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Current Student Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.appColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: context.appColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kelas Sekarang: $currentClassName',
                          style: TextStyle(
                            color: context.appColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(
              'Pilih Kelas Tujuan Baru:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Classrooms List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.38,
              ),
              child: roomsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Gagal memuat ruang kelas: $e'),
                ),
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('Belum ada ruang kelas terdaftar.'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (context, idx) {
                      final room = rooms[idx];
                      final isCurrent = room.id == widget.student.roomId;
                      final isSelected = room.id == _selectedRoomId;
                      final label = room.name.toLowerCase().startsWith('kelas') ||
                              room.name.toLowerCase().startsWith('ruang')
                          ? room.name
                          : 'Kelas ${room.name}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap: isCurrent
                              ? null
                              : () {
                                  setState(() {
                                    _selectedRoomId = room.id;
                                    _selectedRoom = room;
                                  });
                                },
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm + 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.appColors.primarySoft
                                  : (isCurrent
                                      ? context.appColors.surfaceSoft
                                      : context.appColors.surface),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(
                                color: isSelected
                                    ? context.appColors.primary
                                    : (isCurrent
                                        ? context.appColors.border
                                        : context.appColors.border),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : (isCurrent
                                          ? Icons.lock_outline_rounded
                                          : Icons.radio_button_off_rounded),
                                  color: isSelected
                                      ? context.appColors.primary
                                      : (isCurrent
                                          ? context.appColors.textMuted
                                          : context.appColors.textSecondary),
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isCurrent
                                                  ? context
                                                      .appColors.textMuted
                                                  : context
                                                      .appColors.textPrimary,
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: context
                                                    .appColors.surfaceSoft,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Saat ini',
                                                style: TextStyle(
                                                  color: context
                                                      .appColors.textMuted,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        room.hasWali
                                            ? 'Wali: ${room.guruWaliName}'
                                            : 'Wali belum ada',
                                        style: TextStyle(
                                          color:
                                              context.appColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: room.isFull
                                        ? context.appColors.dangerSoft
                                        : context.appColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${room.studentCount}/${room.capacity}',
                                    style: TextStyle(
                                      color: room.isFull
                                          ? context.appColors.danger
                                          : context.appColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

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
                          label: 'Konfirmasi Pindah',
                          onPressed: _selectedRoomId == widget.student.roomId ||
                                  _selectedRoomId == null
                              ? null
                              : _handleConfirm,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
