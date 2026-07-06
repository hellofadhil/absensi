import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:absensi/core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/student_attendance.dart';
import '../providers/attendance_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class StudentListPage extends ConsumerStatefulWidget {
  const StudentListPage({super.key});

  @override
  ConsumerState<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends ConsumerState<StudentListPage> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Hadir', 'Terlambat', 'Sakit/Izin', 'Belum'

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(todayStudentsAttendanceProvider);
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isGuru = user?.isGuru ?? false;

    return AppScaffold(
      topBar: const AppTopBar(
        title: 'Kehadiran Siswa',
        subtitle: 'Hari Ini',
        showThemeToggle: true,
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.calendar,
        isGuru: isGuru,
        onDestinationSelected: (destination) {
          if (destination == AppBottomDestination.home) {
            Navigator.pushReplacementNamed(context, RouteNames.home);
          } else if (destination == AppBottomDestination.history) {
            Navigator.pushReplacementNamed(context, RouteNames.history);
          } else if (destination == AppBottomDestination.profile) {
            Navigator.pushReplacementNamed(context, RouteNames.profile);
          }
        },
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Gagal memuat daftar siswa: $err',
              style: TextStyle(color: context.appColors.danger),
            ),
          ),
        ),
        data: (students) {
          // Filtered list based on search and status tabs
          final filteredStudents = students.where((s) {
            final matchesSearch = s.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.email.toLowerCase().contains(_searchQuery.toLowerCase());
            
            if (!matchesSearch) return false;

            if (_selectedFilter == 'Semua') return true;
            if (_selectedFilter == 'Hadir') {
              return s.record?.status == AttendanceStatus.hadir;
            }
            if (_selectedFilter == 'Terlambat') {
              return s.record?.status == AttendanceStatus.terlambat;
            }
            if (_selectedFilter == 'Sakit/Izin') {
              return s.record?.status == AttendanceStatus.sakit || s.record?.status == AttendanceStatus.izin;
            }
            if (_selectedFilter == 'Belum') {
              return s.record == null;
            }
            return true;
          }).toList();

          final totalPresent = students.where((s) => s.record?.isHadir == true || s.record?.isTerlambat == true).length;
          final totalStudents = students.length;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(todayStudentsAttendanceProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.appColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appColors.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people_rounded, color: context.appColors.primary, size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            '$totalPresent dari $totalStudents siswa telah hadir hari ini.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.primaryDeep,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: context.appColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Cari nama siswa...',
                      prefixIcon: Icon(Icons.search_rounded, color: context.appColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.appColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.appColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.appColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip('Semua'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('Hadir'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('Terlambat'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('Sakit/Izin'),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip('Belum'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Students List
                  if (filteredStudents.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Tidak ada siswa yang cocok.',
                          style: TextStyle(color: context.appColors.textMuted),
                        ),
                      ),
                    )
                  else ...(() {
                    final Map<String, List<StudentAttendance>> groups = {};
                    for (final student in filteredStudents) {
                      final groupKey = '${student.className ?? "XI RPL 1"} • ${student.roomName ?? "Lab RPL"}';
                      groups.putIfAbsent(groupKey, () => []).add(student);
                    }

                    return groups.entries.map((entry) {
                      final groupName = entry.key;
                      final studentsInGroup = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.meeting_room_rounded,
                                  size: 16,
                                  color: context.appColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  groupName,
                                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: context.appColors.primaryDeep,
                                      ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: context.appColors.primarySoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${studentsInGroup.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: context.appColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: studentsInGroup.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, idx) {
                              final student = studentsInGroup[idx];
                              return _StudentCard(student: student);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      );
                    }).toList();
                  }()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: context.appColors.primary,
      backgroundColor: context.appColors.surfaceSoft,
      labelStyle: TextStyle(
        color: isSelected ? context.appColors.textInverse : context.appColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = label);
        }
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final StudentAttendance student;

  Color _getStatusColor(BuildContext context, AttendanceStatus? status) {
    if (status == null) return context.appColors.textMuted;
    return switch (status) {
      AttendanceStatus.hadir => context.appColors.success,
      AttendanceStatus.terlambat => context.appColors.warning,
      AttendanceStatus.sakit || AttendanceStatus.izin => context.appColors.primary,
      AttendanceStatus.alpa => context.appColors.danger,
      AttendanceStatus.none => context.appColors.textMuted,
    };
  }

  Color _getStatusBg(BuildContext context, AttendanceStatus? status) {
    if (status == null) return context.appColors.surfaceSoft;
    return switch (status) {
      AttendanceStatus.hadir => context.appColors.successSoft,
      AttendanceStatus.terlambat => context.appColors.warningSoft,
      AttendanceStatus.sakit || AttendanceStatus.izin => context.appColors.primarySoft,
      AttendanceStatus.alpa => context.appColors.dangerSoft,
      AttendanceStatus.none => context.appColors.surfaceSoft,
    };
  }

  String _getStatusLabel(AttendanceStatus? status) {
    if (status == null) return 'Belum Presensi';
    return switch (status) {
      AttendanceStatus.hadir => 'Hadir',
      AttendanceStatus.terlambat => 'Terlambat',
      AttendanceStatus.sakit => 'Sakit',
      AttendanceStatus.izin => 'Izin',
      AttendanceStatus.alpa => 'Alpa',
      AttendanceStatus.none => 'Belum Presensi',
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = student.record?.status;
    final hasCheckedIn = student.record != null;
    final statusColor = _getStatusColor(context, status);
    final statusBg = _getStatusBg(context, status);
    final statusLabel = _getStatusLabel(status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.appColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  student.studentName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.appColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Student Name & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.appColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.email,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: context.appColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
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
          
          if (hasCheckedIn) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            Row(
              children: [
                Icon(Icons.watch_later_outlined, size: 14, color: context.appColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  student.record!.checkInTime != null
                      ? '${student.record!.checkInTime!.hour.toString().padLeft(2, '0')}:${student.record!.checkInTime!.minute.toString().padLeft(2, '0')} WIB'
                      : '-',
                  style: TextStyle(fontSize: 12, color: context.appColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.lg),
                Icon(Icons.location_on_outlined, size: 14, color: context.appColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    student.record!.remarks ?? 'Dalam area sekolah',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: context.appColors.textSecondary),
                  ),
                ),
              ],
            ),
          ] else if (student.phoneNumber != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Belum presensi hari ini',
                  style: TextStyle(fontSize: 11, color: context.appColors.textMuted, fontStyle: FontStyle.italic),
                ),
                Text(
                  student.phoneNumber!,
                  style: TextStyle(fontSize: 11, color: context.appColors.textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
