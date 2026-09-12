import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/class_room.dart';

/// Bottom sheet dialog to view a classroom's details, its homeroom teacher
/// (guru wali kelas), and all students enrolled in it sorted by attendance number.
class ClassroomDetailBottomSheet extends StatelessWidget {
  const ClassroomDetailBottomSheet({
    super.key,
    required this.room,
    required this.students,
    this.homeroomTeacher,
  });

  final ClassRoom room;
  final List<AppUser> students;
  final AppUser? homeroomTeacher;

  static Future<void> show(
    BuildContext context, {
    required ClassRoom room,
    required List<AppUser> allUsers,
  }) {
    // 1. Filter students in this classroom:
    // Match either by roomId or roomName or classLevel
    final roomStudents = allUsers.where((u) {
      if (!u.isSiswa) return false;
      if (u.roomId != null && u.roomId == room.id) return true;
      if (u.roomName != null &&
          u.roomName!.toLowerCase().trim() == room.name.toLowerCase().trim()) {
        return true;
      }
      return false;
    }).toList();

    // 2. Sort students strictly by attendance number ascending (1, 2, 3...)
    roomStudents.sort((a, b) {
      final numA = a.attendanceNumber ?? 999;
      final numB = b.attendanceNumber ?? 999;
      if (numA != numB) return numA.compareTo(numB);
      return a.displayName.compareTo(b.displayName);
    });

    // 3. Find homeroom teacher entity if available
    AppUser? wali;
    if (room.hasWali) {
      for (final u in allUsers) {
        if (u.isGuru && u.uid == room.guruWaliId) {
          wali = u;
          break;
        }
      }
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClassroomDetailBottomSheet(
        room: room,
        students: roomStudents,
        homeroomTeacher: wali,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = room.name.toLowerCase().startsWith('kelas') ||
            room.name.toLowerCase().startsWith('ruang')
        ? room.name
        : 'Kelas ${room.name}';

    final fillRatio =
        room.capacity > 0 ? (students.length / room.capacity) : 0.0;
    final fillColor = fillRatio >= 1.0
        ? context.appColors.danger
        : fillRatio >= 0.8
            ? context.appColors.warning
            : context.appColors.success;

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            const SizedBox(height: AppSpacing.sm),
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

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.appColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
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
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.appColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tingkat ${room.level} • ${students.length} Siswa Terdaftar',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  // Wali Kelas Card
                  Text(
                    'Guru Wali Kelas',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: room.hasWali
                                ? context.appColors.primarySoft
                                : context.appColors.warningSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            room.hasWali
                                ? Icons.school_rounded
                                : Icons.person_off_outlined,
                            color: room.hasWali
                                ? context.appColors.primary
                                : context.appColors.warning,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.hasWali
                                    ? (room.guruWaliName ?? homeroomTeacher?.displayName ?? '-')
                                    : 'Belum ditentukan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: room.hasWali
                                      ? context.appColors.textPrimary
                                      : context.appColors.warning,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                room.hasWali
                                    ? (homeroomTeacher?.extraField ??
                                        homeroomTeacher?.email ??
                                        'Wali Kelas Resmi')
                                    : 'Hubungi admin untuk menetapkan wali kelas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.appColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (room.hasWali)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.successSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Aktif',
                              style: TextStyle(
                                color: context.appColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Kapasitas Ruang Kelas Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kapasitas Ruangan',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.textPrimary,
                            ),
                      ),
                      Text(
                        '${students.length}/${room.capacity} Siswa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: fillColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fillRatio.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: context.appColors.surfaceSoft,
                      color: fillColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Daftar Siswa Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 18,
                            color: context.appColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Daftar Siswa (Berdasarkan No. Absen)',
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.textPrimary,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${students.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.appColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Siswa List
                  if (students.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 36,
                            color: context.appColors.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Belum ada siswa di ruang kelas ini.',
                            style: TextStyle(
                              color: context.appColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Siswa yang didaftarkan ke kelas ini akan muncul di sini.',
                            style: TextStyle(
                              color: context.appColors.textMuted,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, idx) {
                        final student = students[idx];
                        return _StudentItemTile(student: student);
                      },
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

class _StudentItemTile extends StatelessWidget {
  const _StudentItemTile({required this.student});

  final AppUser student;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          // Nomor Absen Circular Badge
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.appColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.appColors.primary.withAlpha(40),
              ),
            ),
            child: Text(
              student.attendanceNumber != null
                  ? '${student.attendanceNumber}'
                  : '-',
              style: TextStyle(
                color: context.appColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  student.email,
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (student.attendanceNumber != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.appColors.border),
              ),
              child: Text(
                'Absen ${student.attendanceNumber}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
