import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/services/holiday_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'package:absensi/features/attendance/domain/entities/attendance_record.dart';
import 'package:absensi/features/attendance/domain/entities/student_attendance.dart';
import 'package:absensi/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:absensi/features/attendance/presentation/widgets/manual_attendance_bottom_sheet.dart';
import 'package:absensi/features/auth/domain/entities/user.dart';
import '../widgets/date_time_display.dart';
import '../widgets/first_login_banner.dart';
import '../widgets/student_detail_bottom_sheet.dart';
import '../widgets/today_attendance_card.dart';

class TeacherHomeView extends ConsumerStatefulWidget {
  final AppUser user;
  final String greetingPart;
  final String namePart;

  const TeacherHomeView({
    super.key,
    required this.user,
    required this.greetingPart,
    required this.namePart,
  });

  @override
  ConsumerState<TeacherHomeView> createState() => _TeacherHomeViewState();
}

class _TeacherHomeViewState extends ConsumerState<TeacherHomeView> {
  // 0: Terlambat, 1: Belum Hadir, 2: Izin / Sakit
  int _selectedStudentCategory = 0;

  @override
  Widget build(BuildContext context) {
    final todayHoliday = ref.watch(todayHolidayProvider);
    final todayAttendance = ref.watch(todayAttendanceProvider);
    final todayStudentsAsync = ref.watch(todayStudentsAttendanceProvider);

    final hasCheckedIn = todayAttendance.maybeWhen(
      data: (record) => record != null,
      orElse: () => false,
    );
    final isHolidayToday = todayHoliday.maybeWhen(
      data: (holiday) => holiday.isHoliday,
      orElse: () => false,
    );

    final onPressed = hasCheckedIn || isHolidayToday
        ? null
        : () => ManualAttendanceBottomSheet.show(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.user.isFirstLogin) FirstLoginBanner(user: widget.user),
        const DateTimeDisplay(),
        const SizedBox(height: AppSpacing.sm),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${widget.greetingPart},\n',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
              TextSpan(
                text: widget.namePart.contains('👋')
                    ? widget.namePart
                    : '${widget.namePart} 👋',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        todayHoliday.when(
          data: (holiday) {
            if (holiday.isHoliday) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: context.appColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: context.appColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holiday.isNationalHoliday
                                ? 'Hari Libur Nasional'
                                : 'Cuti Bersama',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            holiday.holidayList.join(', '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Teacher's personal check-in card
        TodayAttendanceCard(
          record: todayAttendance.maybeWhen(
            data: (record) => record,
            orElse: () => null,
          ),
          isHoliday: isHolidayToday,
          onPresensiPressed: onPressed,
          onDetailPressed: () {
            Navigator.pushReplacementNamed(
              context,
              RouteNames.history,
            );
          },
        ),

        const SizedBox(height: AppSpacing.xl),

        // Ruang Kelas & Siswa Section
        const SectionHeader(title: 'Ruang Kelas & Siswa'),
        const SizedBox(height: AppSpacing.md),
        todayStudentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Gagal memuat daftar siswa: $err',
              style: TextStyle(color: context.appColors.danger),
            ),
          ),
          data: (students) {
            final lateStudents = students
                .where((s) => s.record?.status == AttendanceStatus.terlambat)
                .length;
            final sickStudents = students
                .where((s) => s.record?.status == AttendanceStatus.sakit)
                .length;
            final permissionStudents = students
                .where((s) => s.record?.status == AttendanceStatus.izin)
                .length;
            final absentStudents = students
                .where((s) => s.record?.status == AttendanceStatus.alpa)
                .length;
            final unsubmittedStudents =
                students.where((s) => s.record == null).length;

            final sickAndPermission = sickStudents + permissionStudents;
            final notPresentCount = absentStudents + unsubmittedStudents;

            // Filtered list based on selected student category
            final List<StudentAttendance> filteredList;
            if (_selectedStudentCategory == 0) {
              // Terlambat
              filteredList = students
                  .where((s) => s.record?.status == AttendanceStatus.terlambat)
                  .toList();
            } else if (_selectedStudentCategory == 1) {
              // Belum Hadir (Alpa & Belum Presensi)
              filteredList = students
                  .where((s) =>
                      s.record?.status == AttendanceStatus.alpa ||
                      s.record == null)
                  .toList();
            } else {
              // Izin / Sakit
              filteredList = students
                  .where((s) =>
                      s.record?.status == AttendanceStatus.sakit ||
                      s.record?.status == AttendanceStatus.izin)
                  .toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGroupedStudentsView(context, students),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Aktivitas Hari Ini'),
                const SizedBox(height: AppSpacing.md),

                // Interactive Category Filter Tabs (Cardless, no icons)
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildCategoryTab(
                        index: 0,
                        currentIndex: _selectedStudentCategory,
                        onTap: () =>
                            setState(() => _selectedStudentCategory = 0),
                        title: 'Terlambat',
                        count: lateStudents,
                        color: context.appColors.warning,
                      ),
                      _buildCategoryTab(
                        index: 1,
                        currentIndex: _selectedStudentCategory,
                        onTap: () =>
                            setState(() => _selectedStudentCategory = 1),
                        title: 'Belum Hadir',
                        count: notPresentCount,
                        color: context.appColors.danger,
                      ),
                      _buildCategoryTab(
                        index: 2,
                        currentIndex: _selectedStudentCategory,
                        onTap: () =>
                            setState(() => _selectedStudentCategory = 2),
                        title: 'Izin / Sakit',
                        count: sickAndPermission,
                        color: context.appColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Student List (Cardless)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedStudentCategory == 0
                                ? 'Siswa Terlambat (${filteredList.length})'
                                : _selectedStudentCategory == 1
                                    ? 'Siswa Belum Hadir (${filteredList.length})'
                                    : 'Siswa Izin / Sakit (${filteredList.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          if (filteredList.isNotEmpty)
                            Text(
                              'Sentuh untuk detail',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.appColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Divider(
                        height: 1,
                        color: context.appColors.border.withAlpha(80)),
                    const SizedBox(height: AppSpacing.xs),
                    if (filteredList.isEmpty)
                      _buildStudentEmptyState(context)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: context.appColors.border.withAlpha(60),
                        ),
                        itemBuilder: (context, index) {
                          final student = filteredList[index];
                          return _buildStudentItemTile(context, student);
                        },
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTab({
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
    required String title,
    required int count,
    required Color color,
  }) {
    final isSelected = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? context.appColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.button - 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? context.appColors.textPrimary
                          : context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withAlpha(30)
                          : context.appColors.border.withAlpha(60),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? color
                            : context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentEmptyState(BuildContext context) {
    String emptyTitle;

    if (_selectedStudentCategory == 0) {
      emptyTitle = 'Tidak Ada Siswa Terlambat';
    } else if (_selectedStudentCategory == 1) {
      emptyTitle = 'Tidak Ada Siswa Belum Hadir';
    } else {
      emptyTitle = 'Tidak Ada Siswa Izin / Sakit';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl, horizontal: AppSpacing.md),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.appColors.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: context.appColors.success,
                size: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentItemTile(
      BuildContext context, StudentAttendance student) {
    Color badgeColor;
    if (_selectedStudentCategory == 0) {
      badgeColor = context.appColors.warning;
    } else if (_selectedStudentCategory == 1) {
      badgeColor = context.appColors.danger;
    } else {
      badgeColor = student.record?.status == AttendanceStatus.sakit
          ? context.appColors.warning
          : context.appColors.primary;
    }

    String? timeStr;
    if (student.record?.checkInTime != null) {
      final h =
          student.record!.checkInTime!.hour.toString().padLeft(2, '0');
      final m =
          student.record!.checkInTime!.minute.toString().padLeft(2, '0');
      timeStr = '$h:$m';
    }

    return InkWell(
      onTap: () => StudentDetailBottomSheet.show(context, student),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: badgeColor.withAlpha(25),
              child: Text(
                student.studentName.isNotEmpty
                    ? student.studentName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.studentName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        student.roomName ?? student.className ?? 'Kelas -',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      if (student.formattedAttendanceNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: context.appColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: context.appColors.border.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            student.formattedAttendanceNumber!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildBadgeForStudent(context, student, timeStr),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: context.appColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeForStudent(
      BuildContext context, StudentAttendance student, String? timeStr) {
    if (_selectedStudentCategory == 0) {
      // Terlambat
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.appColors.warning.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded,
                size: 12, color: context.appColors.warning),
            const SizedBox(width: 4),
            Text(
              timeStr != null ? '$timeStr WIB' : 'Terlambat',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.appColors.warning,
              ),
            ),
          ],
        ),
      );
    } else if (_selectedStudentCategory == 1) {
      // Belum Hadir (Alpa / Belum Presensi)
      final isAlpa = student.record?.status == AttendanceStatus.alpa;
      final color = isAlpa
          ? context.appColors.danger
          : context.appColors.textMuted;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isAlpa ? 'Alpa' : 'Belum Presensi',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    } else {
      // Izin / Sakit
      final isSakit = student.record?.status == AttendanceStatus.sakit;
      final color = isSakit
          ? context.appColors.warning
          : context.appColors.primary;
      final label = isSakit ? 'Sakit' : 'Izin';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }
  }

  Widget _buildGroupedStudentsView(
      BuildContext context, List<StudentAttendance> studentAttendances) {
    if (studentAttendances.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Belum ada data siswa terdaftar.',
            style: TextStyle(color: context.appColors.textSecondary),
          ),
        ),
      );
    }

    // Group student attendances by roomName
    final Map<String, List<StudentAttendance>> grouped = {};
    for (final item in studentAttendances) {
      final roomName = item.roomName ?? item.className ?? 'Kelas Siswa';
      final key = roomName.toLowerCase().startsWith('kelas') ||
              roomName.toLowerCase().startsWith('ruang')
          ? roomName
          : 'Kelas $roomName';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    // Sort group keys alphabetically
    final sortedKeys = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedKeys.map((groupName) {
        final items = grouped[groupName]!;
        return _buildStudentGroup(context, groupName, items);
      }).toList(),
    );
  }

  Widget _buildStudentGroup(BuildContext context, String groupName,
      List<StudentAttendance> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: context.appColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  groupName,
                  style: TextStyle(
                    color: context.appColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${items.length} siswa',
                style: TextStyle(
                    color: context.appColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildStudentCard(context, item),
            )),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentAttendance item) {
    final record = item.record;

    String statusLabel = 'Belum Presensi';
    Color statusColor = context.appColors.textMuted;
    Color statusBg = context.appColors.surfaceSoft;

    if (record != null) {
      switch (record.status) {
        case AttendanceStatus.hadir:
          statusLabel = 'Hadir';
          statusColor = context.appColors.success;
          statusBg = context.appColors.successSoft;
          break;
        case AttendanceStatus.terlambat:
          statusLabel = 'Terlambat';
          statusColor = context.appColors.warning;
          statusBg = context.appColors.warningSoft;
          break;
        case AttendanceStatus.izin:
          statusLabel = 'Izin';
          statusColor = context.appColors.primary;
          statusBg = context.appColors.primarySoft;
          break;
        case AttendanceStatus.sakit:
          statusLabel = 'Sakit';
          statusColor = context.appColors.primary;
          statusBg = context.appColors.primarySoft;
          break;
        case AttendanceStatus.alpa:
          statusLabel = 'Alpa';
          statusColor = context.appColors.danger;
          statusBg = context.appColors.dangerSoft;
          break;
        default:
          statusLabel = 'Belum Presensi';
          statusColor = context.appColors.textMuted;
          statusBg = context.appColors.surfaceSoft;
          break;
      }
    }

    return InkWell(
      onTap: () => StudentDetailBottomSheet.show(context, item),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.email,
                    style: TextStyle(
                        color: context.appColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
