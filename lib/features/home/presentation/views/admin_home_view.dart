import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/entities/student_attendance.dart';
import '../../../attendance/domain/entities/teacher_attendance.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../pages/home_page.dart';
import '../widgets/date_time_display.dart';
import '../widgets/student_attendance_summary_card.dart';
import '../widgets/student_detail_bottom_sheet.dart';
import '../widgets/teacher_attendance_summary_card.dart';

class AdminHomeView extends ConsumerStatefulWidget {
  final String greetingPart;
  final String namePart;

  const AdminHomeView({
    super.key,
    required this.greetingPart,
    required this.namePart,
  });

  @override
  ConsumerState<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends ConsumerState<AdminHomeView> {
  // 0: Terlambat, 1: Belum Hadir, 2: Izin / Sakit
  int _selectedStudentCategory = 0;
  int _selectedTeacherCategory = 0;

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(adminHomeTabProvider);
    final todayStudentsAsync = ref.watch(todayStudentsAttendanceProvider);
    final todayTeachersAsync = ref.watch(todayTeachersAttendanceProvider);

    final cleanName = widget.namePart
        .replaceAll(' \u{1F44B}', '')
        .replaceFirst('Admin ', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                text: '$cleanName 👋',
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

        // Custom Capsule Tab Bar (Siswa / Guru)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.appColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(adminHomeTabProvider.notifier).setTab(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: activeTab == 0
                          ? context.appColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: activeTab == 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Siswa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: activeTab == 0
                              ? context.appColors.primary
                              : context.appColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(adminHomeTabProvider.notifier).setTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: activeTab == 1
                          ? context.appColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: activeTab == 1
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Guru',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: activeTab == 1
                              ? context.appColors.primary
                              : context.appColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Tab Content
        if (activeTab == 0)
          todayStudentsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'Gagal memuat ringkasan siswa: $err',
                style: TextStyle(color: context.appColors.danger),
              ),
            ),
            data: (students) {
              final totalStudents = students.length;
              final presentStudents = students
                  .where((s) => s.record?.status == AttendanceStatus.hadir)
                  .length;
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
                    .where((s) =>
                        s.record?.status == AttendanceStatus.terlambat)
                    .toList();
              } else if (_selectedStudentCategory == 1) {
                // Tidak Hadir (Alpa & Belum Presensi)
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
                  StudentAttendanceSummaryCard(
                    totalStudents: totalStudents,
                    presentStudents: presentStudents,
                    lateStudents: lateStudents,
                    sickStudents: sickStudents,
                    permissionStudents: permissionStudents,
                    absentStudents: absentStudents,
                    unsubmittedStudents: unsubmittedStudents,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section Header
                  const SectionHeader(title: 'Data Siswa Hari Ini'),
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
          )
        else
          todayTeachersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'Gagal memuat ringkasan guru: $err',
                style: TextStyle(color: context.appColors.danger),
              ),
            ),
            data: (teachers) {
              final totalTeachers = teachers.length;
              final presentTeachers = teachers
                  .where((t) => t.record?.status == AttendanceStatus.hadir)
                  .length;
              final lateTeachers = teachers
                  .where((t) => t.record?.status == AttendanceStatus.terlambat)
                  .length;
              final sickTeachers = teachers
                  .where((t) => t.record?.status == AttendanceStatus.sakit)
                  .length;
              final permissionTeachers = teachers
                  .where((t) => t.record?.status == AttendanceStatus.izin)
                  .length;
              final absentTeachers = teachers
                  .where((t) => t.record?.status == AttendanceStatus.alpa)
                  .length;

              final unsubmittedTeachers =
                  teachers.where((t) => t.record == null).length;
              final combinedPermission = sickTeachers + permissionTeachers;
              final notPresentTeachers = absentTeachers + unsubmittedTeachers;

              // Filtered list based on selected teacher category
              final List<TeacherAttendance> filteredTeachers;
              if (_selectedTeacherCategory == 0) {
                // Terlambat
                filteredTeachers = teachers
                    .where((t) =>
                        t.record?.status == AttendanceStatus.terlambat)
                    .toList();
              } else if (_selectedTeacherCategory == 1) {
                // Tidak Hadir (Alpa & Belum Presensi)
                filteredTeachers = teachers
                    .where((t) =>
                        t.record?.status == AttendanceStatus.alpa ||
                        t.record == null)
                    .toList();
              } else {
                // Izin / Sakit
                filteredTeachers = teachers
                    .where((t) =>
                        t.record?.status == AttendanceStatus.sakit ||
                        t.record?.status == AttendanceStatus.izin)
                    .toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TeacherAttendanceSummaryCard(
                    totalTeachers: totalTeachers,
                    presentTeachers: presentTeachers,
                    lateTeachers: lateTeachers,
                    sickTeachers: sickTeachers,
                    permissionTeachers: permissionTeachers,
                    absentTeachers: absentTeachers,
                    unsubmittedTeachers: unsubmittedTeachers,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section Header
                  const SectionHeader(title: 'Data Guru Hari Ini'),
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
                          currentIndex: _selectedTeacherCategory,
                          onTap: () =>
                              setState(() => _selectedTeacherCategory = 0),
                          title: 'Terlambat',
                          count: lateTeachers,
                          color: context.appColors.warning,
                        ),
                        _buildCategoryTab(
                          index: 1,
                          currentIndex: _selectedTeacherCategory,
                          onTap: () =>
                              setState(() => _selectedTeacherCategory = 1),
                          title: 'Belum Hadir',
                          count: notPresentTeachers,
                          color: context.appColors.danger,
                        ),
                        _buildCategoryTab(
                          index: 2,
                          currentIndex: _selectedTeacherCategory,
                          onTap: () =>
                              setState(() => _selectedTeacherCategory = 2),
                          title: 'Izin / Sakit',
                          count: combinedPermission,
                          color: context.appColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Teacher List (Cardless)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTeacherCategory == 0
                                  ? 'Guru Terlambat (${filteredTeachers.length})'
                                  : _selectedTeacherCategory == 1
                                      ? 'Guru Belum Hadir (${filteredTeachers.length})'
                                      : 'Guru Izin / Sakit (${filteredTeachers.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            if (filteredTeachers.isNotEmpty)
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
                      if (filteredTeachers.isEmpty)
                        _buildTeacherEmptyState(context)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTeachers.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: context.appColors.border.withAlpha(60),
                          ),
                          itemBuilder: (context, index) {
                            final teacher = filteredTeachers[index];
                            return _buildTeacherItemTile(context, teacher);
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
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
                        color:
                            isSelected ? color : context.appColors.textSecondary,
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

  Widget _buildTeacherEmptyState(BuildContext context) {
    String emptyTitle;

    if (_selectedTeacherCategory == 0) {
      emptyTitle = 'Tidak Ada Guru Terlambat';
    } else if (_selectedTeacherCategory == 1) {
      emptyTitle = 'Tidak Ada Guru Belum Hadir';
    } else {
      emptyTitle = 'Tidak Ada Guru Izin / Sakit';
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

  Widget _buildStudentItemTile(BuildContext context, StudentAttendance student) {
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
      onTap: () => _showStudentDetailBottomSheet(context, student),
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

  Widget _buildTeacherItemTile(BuildContext context, TeacherAttendance teacher) {
    Color badgeColor;
    if (_selectedTeacherCategory == 0) {
      badgeColor = context.appColors.warning;
    } else if (_selectedTeacherCategory == 1) {
      badgeColor = context.appColors.danger;
    } else {
      badgeColor = teacher.record?.status == AttendanceStatus.sakit
          ? context.appColors.warning
          : context.appColors.primary;
    }

    String? timeStr;
    if (teacher.record?.checkInTime != null) {
      final h =
          teacher.record!.checkInTime!.hour.toString().padLeft(2, '0');
      final m =
          teacher.record!.checkInTime!.minute.toString().padLeft(2, '0');
      timeStr = '$h:$m';
    }

    return InkWell(
      onTap: () => _showTeacherDetailBottomSheet(context, teacher),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: badgeColor.withAlpha(25),
              child: Text(
                teacher.teacherName.isNotEmpty
                    ? teacher.teacherName[0].toUpperCase()
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
                    teacher.teacherName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Guru / Tenaga Pendidik',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildBadgeForTeacher(context, teacher, timeStr),
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
      // Tidak Hadir (Alpa / Belum Presensi)
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

  Widget _buildBadgeForTeacher(
      BuildContext context, TeacherAttendance teacher, String? timeStr) {
    if (_selectedTeacherCategory == 0) {
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
    } else if (_selectedTeacherCategory == 1) {
      // Tidak Hadir (Alpa / Belum Presensi)
      final isAlpa = teacher.record?.status == AttendanceStatus.alpa;
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
      final isSakit = teacher.record?.status == AttendanceStatus.sakit;
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

  void _showStudentDetailBottomSheet(
      BuildContext context, StudentAttendance student) {
    StudentDetailBottomSheet.show(context, student);
  }

  void _showTeacherDetailBottomSheet(
      BuildContext context, TeacherAttendance teacher) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final record = teacher.record;
        String statusLabel;
        Color statusColor;
        IconData statusIcon;

        if (record == null) {
          statusLabel = 'Belum Melakukan Presensi';
          statusColor = ctx.appColors.textMuted;
          statusIcon = Icons.help_outline_rounded;
        } else {
          switch (record.status) {
            case AttendanceStatus.hadir:
              statusLabel = 'Hadir Tepat Waktu';
              statusColor = ctx.appColors.success;
              statusIcon = Icons.check_circle_rounded;
              break;
            case AttendanceStatus.terlambat:
              statusLabel = 'Hadir Terlambat';
              statusColor = ctx.appColors.warning;
              statusIcon = Icons.access_time_rounded;
              break;
            case AttendanceStatus.sakit:
              statusLabel = 'Sakit (Izin Sakit)';
              statusColor = ctx.appColors.warning;
              statusIcon = Icons.healing_rounded;
              break;
            case AttendanceStatus.izin:
              statusLabel = 'Izin (Cuti / Keperluan Khusus)';
              statusColor = ctx.appColors.primary;
              statusIcon = Icons.event_note_rounded;
              break;
            case AttendanceStatus.alpa:
              statusLabel = 'Alpa (Tanpa Keterangan)';
              statusColor = ctx.appColors.danger;
              statusIcon = Icons.cancel_rounded;
              break;
            default:
              statusLabel = 'Belum Presensi';
              statusColor = ctx.appColors.textMuted;
              statusIcon = Icons.help_outline_rounded;
          }
        }

        String? timeStr;
        if (record?.checkInTime != null) {
          final h =
              record!.checkInTime!.hour.toString().padLeft(2, '0');
          final m =
              record.checkInTime!.minute.toString().padLeft(2, '0');
          timeStr = '$h:$m WIB';
        }

        return Container(
          decoration: BoxDecoration(
            color: ctx.appColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.bottomSheet),
            ),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom: AppSpacing.xl + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ctx.appColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Detail Kehadiran Guru',
                          style:
                              Theme.of(ctx).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Teacher Profile Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: ctx.appColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                          color: ctx.appColors.border.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: statusColor.withAlpha(30),
                          child: Text(
                            teacher.teacherName.isNotEmpty
                                ? teacher.teacherName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher.teacherName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Tenaga Pendidik / Guru',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ctx.appColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: statusColor.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 20, color: statusColor),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (timeStr != null)
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Detail Rows
                  _buildDetailRow(
                      ctx, Icons.email_outlined, 'Email Akun', teacher.email),

                  if (teacher.phoneNumber != null &&
                      teacher.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRowWithContact(
                      ctx,
                      Icons.phone_android_rounded,
                      'No. HP / WhatsApp Guru',
                      teacher.phoneNumber!,
                      onCall: () => _launchPhone(teacher.phoneNumber!),
                      onWa: () => _launchWhatsApp(teacher.phoneNumber!),
                    ),
                  ],

                  if (record?.remarks != null &&
                      record!.remarks!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRow(ctx, Icons.notes_rounded,
                        'Keterangan / Alasan', record.remarks!),
                  ],

                  if (record?.attachmentUrl != null &&
                      record!.attachmentUrl!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _buildDetailRowWithLink(
                      ctx,
                      Icons.attachment_rounded,
                      'Bukti Surat',
                      'Buka Surat Cuti / Lampiran',
                      record.attachmentUrl!,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text('Tutup',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.appColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithContact(
    BuildContext context,
    IconData icon,
    String label,
    String phone, {
    required VoidCallback onCall,
    required VoidCallback onWa,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.appColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appColors.textSecondary,
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.phone_rounded,
                size: 18, color: context.appColors.primary),
            visualDensity: VisualDensity.compact,
            tooltip: 'Telepon',
            onPressed: onCall,
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: context.appColors.success),
            visualDensity: VisualDensity.compact,
            tooltip: 'WhatsApp',
            onPressed: onWa,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithLink(
    BuildContext context,
    IconData icon,
    String label,
    String buttonText,
    String url,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.appColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => _launchWeb(url),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded,
                          size: 13, color: context.appColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _launchWhatsApp(String phone) async {
    var clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$clean');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchWeb(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}
