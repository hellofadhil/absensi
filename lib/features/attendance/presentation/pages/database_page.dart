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
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../school/domain/entities/class_room.dart';
import '../../../school/presentation/providers/school_provider.dart';
import '../../../school/presentation/widgets/add_edit_classroom_bottom_sheet.dart';
import '../../../school/presentation/widgets/classroom_detail_bottom_sheet.dart';
import '../widgets/manual_attendance_bottom_sheet.dart';
import '../widgets/add_teacher_bottom_sheet.dart';
import '../widgets/add_student_bottom_sheet.dart';
import '../widgets/edit_student_bottom_sheet.dart';
import '../widgets/change_class_bottom_sheet.dart';
import '../widgets/edit_teacher_bottom_sheet.dart';
import '../providers/attendance_provider.dart';
import 'package:absensi/shared/widgets/app_skeleton.dart';

class DatabasePage extends ConsumerStatefulWidget {
  const DatabasePage({super.key});

  @override
  ConsumerState<DatabasePage> createState() => _DatabasePageState();
}

class _DatabasePageState extends ConsumerState<DatabasePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isAdmin = user?.isAdmin ?? false;
    final isGuru = user?.isGuru ?? false;

    final usersAsync = ref.watch(allUsersProvider);
    final roomsAsync = ref.watch(classRoomsProvider);

    return AppScaffold(
      topBar: const AppTopBar(
        title: 'Database Sekolah',
        subtitle: 'Manajemen Data Guru & Siswa',
        showThemeToggle: true,
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.database,
        isGuru: isGuru,
        isAdmin: isAdmin,
        onDestinationSelected: (destination) =>
            _handleNavigation(context, destination, isGuru, isAdmin),
      ),
      body: usersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: StudentListSkeletonList(),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Gagal memuat database: $err',
                style: TextStyle(color: context.appColors.danger)),
          ),
        ),
        data: (users) {
          final teachers =
              users.where((u) => u.role == 'guru').toList();
          final students =
              users.where((u) => u.role == 'siswa').toList();

          final filteredTeachers = teachers
              .where((t) =>
                  t.displayName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  t.email
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();

          final filteredStudents = students
              .where((s) =>
                  s.displayName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  s.email
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();

          return Column(
            children: [
              // Statistics Summary Row
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard('Total Siswa',
                          '${students.length}', Icons.school_rounded,
                          context.appColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildSummaryCard('Total Guru',
                          '${teachers.length}', Icons.badge_rounded,
                          context.appColors.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val),
                  style:
                      TextStyle(color: context.appColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email...',
                    prefixIcon: Icon(Icons.search,
                        color: context.appColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.appColors.surfaceSoft,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md),
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
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tab Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceSoft,
                    borderRadius:
                        BorderRadius.circular(AppRadius.button),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: context.appColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppRadius.button),
                    ),
                    labelColor: context.appColors.textInverse,
                    unselectedLabelColor:
                        context.appColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: const [
                      Tab(text: 'Siswa'),
                      Tab(text: 'Guru'),
                      Tab(text: 'Ruang Kelas'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Subheader: Contextual Add Action Button
              if (isAdmin) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () => _onFabPressed(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.appColors.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.appColors.primary.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 16,
                                color: context.appColors.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _getFabLabel(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
              ] else
                const SizedBox(height: AppSpacing.xs),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1 — Students grouped by classroom
                    _buildGroupedStudentsView(filteredStudents),
                    // Tab 2 — Teachers flat list
                    _buildFlatUserList(
                      items: filteredTeachers,
                      avatarIcon: Icons.badge_rounded,
                      avatarColor: context.appColors.success,
                      subtitleBuilder: (t) =>
                          t.extraField ?? 'Guru',
                    ),
                    // Tab 3 — Classrooms
                    roomsAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text('Gagal memuat ruang kelas: $e'),
                      ),
                      data: (rooms) => _buildClassRoomsView(rooms, users),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    ref.invalidate(allUsersProvider);
    ref.invalidate(classRoomsProvider);
    ref.invalidate(todayStudentsAttendanceProvider);
    ref.invalidate(todayTeachersAttendanceProvider);
    ref.invalidate(teacherAssignmentsProvider);
    await Future.wait([
      ref.refresh(allUsersProvider.future),
      ref.refresh(classRoomsProvider.future),
    ]);
  }

  // ─── Grouped Students View ──────────────────────────────────────────────

  Widget _buildGroupedStudentsView(List<AppUser> students) {
    if (students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            alignment: const Alignment(0, -0.3),
            padding: const EdgeInsets.all(AppSpacing.xl),
            constraints: const BoxConstraints(minHeight: 300),
            child: Text(
              'Tidak ada siswa ditemukan.',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // Group by roomName or classLevel
    final Map<String, List<AppUser>> grouped = {};
    for (final s in students) {
      final name = s.roomName ?? (s.classLevel != null && s.classLevel!.isNotEmpty ? 'Kelas ${s.classLevel}' : 'Kelas Siswa');
      final key = name.toLowerCase().startsWith('kelas') || name.toLowerCase().startsWith('ruang')
          ? name
          : 'Kelas $name';
      grouped.putIfAbsent(key, () => []).add(s);
    }

    // Sort group keys alphabetically
    final sortedKeys = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.bottomNavigationClearance),
        itemCount: sortedKeys.length,
        itemBuilder: (context, i) {
          final groupName = sortedKeys[i];
          final groupStudents = grouped[groupName]!;
          groupStudents.sort((a, b) {
            if (a.attendanceNumber != null && b.attendanceNumber != null) {
              return a.attendanceNumber!.compareTo(b.attendanceNumber!);
            }
            if (a.attendanceNumber != null) return -1;
            if (b.attendanceNumber != null) return 1;
            return a.displayName.compareTo(b.displayName);
          });
          return _buildStudentGroup(groupName, groupStudents, isFirst: i == 0);
        },
      ),
    );
  }

  Widget _buildStudentGroup(String groupName, List<AppUser> students, {bool isFirst = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              top: isFirst ? AppSpacing.xs : AppSpacing.md, bottom: AppSpacing.sm),
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
                '${students.length} siswa',
                style: TextStyle(
                    color: context.appColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        ...students.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildUserCard(
                user: s,
                subtitle:
                    '${s.fullClassLabel ?? 'Siswa'}${s.formattedAngkatan != null ? ' • ${s.formattedAngkatan}' : ''}',
                showAvatar: false,
              ),
            )),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // ─── Flat User List (Guru) ──────────────────────────────────────────────

  Widget _buildFlatUserList({
    required List<AppUser> items,
    required IconData avatarIcon,
    required Color avatarColor,
    required String Function(AppUser) subtitleBuilder,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            alignment: const Alignment(0, -0.3),
            padding: const EdgeInsets.all(AppSpacing.xl),
            constraints: const BoxConstraints(minHeight: 300),
            child: Text(
              'Tidak ada data ditemukan.',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.bottomNavigationClearance),
        itemCount: items.length,
        itemBuilder: (context, idx) {
          final item = items[idx];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildUserCard(
              user: item,
              avatarIcon: avatarIcon,
              avatarColor: avatarColor,
              subtitle: subtitleBuilder(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard({
    required AppUser user,
    required String subtitle,
    IconData? avatarIcon,
    Color? avatarColor,
    bool showAvatar = true,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          if (user.isSiswa && user.attendanceNumber != null) ...[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.appColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.appColors.primary.withAlpha(40),
                ),
              ),
              child: Text(
                '${user.attendanceNumber}',
                style: TextStyle(
                  color: context.appColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ] else if (showAvatar && avatarIcon != null && avatarColor != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(avatarIcon, color: avatarColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 12)),
                Text(user.email,
                    style: TextStyle(
                        color: context.appColors.textMuted,
                        fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: context.appColors.textSecondary),
            onPressed: () => _showUserOptions(context, user),
          ),
        ],
      ),
    );
  }

  // ─── Classrooms View ────────────────────────────────────────────────────

  Widget _buildClassRoomsView(List<ClassRoom> rooms, List<AppUser> allUsers) {
    if (rooms.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            alignment: const Alignment(0, -0.3),
            padding: const EdgeInsets.all(AppSpacing.xl),
            constraints: const BoxConstraints(minHeight: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Belum ada ruang kelas.',
                  style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tap tombol + untuk menambahkan ruang kelas.',
                  style: TextStyle(
                      color: context.appColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Group rooms by level dynamically based only on existing rooms!
    final Map<String, List<ClassRoom>> grouped = {};
    for (final r in rooms) {
      grouped.putIfAbsent(r.level, () => []).add(r);
    }

    final levelKeys = grouped.keys.toList()
      ..sort((a, b) {
        final order = {'X': 1, 'XI': 2, 'XII': 3, 'XIII': 4, 'XIV': 5};
        final valA = order[a] ?? 99;
        final valB = order[b] ?? 99;
        if (valA != valB) return valA.compareTo(valB);
        return a.compareTo(b);
      });

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.bottomNavigationClearance),
        itemCount: levelKeys.length,
        itemBuilder: (context, i) {
          final level = levelKeys[i];
          final levelRooms = grouped[level]!;
          final levelLabel = level.toLowerCase().startsWith('kelas') ||
                  level.toLowerCase().startsWith('ruang') ||
                  level.toLowerCase().startsWith('tingkat')
              ? level
              : 'Kelas $level';
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: i == 0 ? AppSpacing.xs : AppSpacing.md, bottom: AppSpacing.sm),
                child: SectionHeader(title: levelLabel),
              ),
              ...levelRooms.map((room) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _buildClassRoomCard(room, allUsers),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClassRoomCard(ClassRoom room, List<AppUser> allUsers) {
    final actualStudents = allUsers.where((u) {
      if (!u.isSiswa) return false;
      if (u.roomId != null && u.roomId!.isNotEmpty) {
        return u.roomId == room.id;
      }
      return u.roomName?.trim().toLowerCase() == room.name.trim().toLowerCase();
    }).toList();
    final actualCount = actualStudents.length;

    final fillRatio =
        room.capacity > 0 ? actualCount / room.capacity : 0.0;
    final fillColor = fillRatio >= 1.0
        ? context.appColors.danger
        : fillRatio >= 0.8
            ? context.appColors.warning
            : context.appColors.success;

    final homeroomTeacher = room.hasWali
        ? allUsers.where((u) => u.isGuru && u.uid == room.guruWaliId).firstOrNull
        : null;
    final waliTitle = homeroomTeacher != null
        ? homeroomTeacher.displayNameWithTitle
        : (room.hasWali ? (room.guruWaliName ?? '-') : 'Wali kelas belum ditentukan');

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => ClassroomDetailBottomSheet.show(
        context,
        room: room.copyWith(studentCount: actualCount),
        allUsers: allUsers,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name.toLowerCase().startsWith('kelas') ||
                            room.name.toLowerCase().startsWith('ruang')
                        ? room.name
                        : 'Kelas ${room.name}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    waliTitle.startsWith('Wali') ? waliTitle : 'Wali: $waliTitle',
                    style: TextStyle(
                        color: room.hasWali
                            ? context.appColors.textSecondary
                            : context.appColors.warning,
                        fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Capacity progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fillRatio.clamp(0.0, 1.0),
                      backgroundColor:
                          context.appColors.surfaceSoft,
                      color: fillColor,
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$actualCount/${room.capacity} siswa',
                        style: TextStyle(
                            color: fillColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Ketuk untuk lihat siswa',
                        style: TextStyle(
                          color: context.appColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert_rounded,
                  color: context.appColors.textSecondary),
              onPressed: () => _showClassRoomOptions(
                  context, room.copyWith(studentCount: actualCount), allUsers),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Summary Card ────────────────────────────────────────────────────────

  Widget _buildSummaryCard(
      String title, String count, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(count,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Sheets & Dialogs ─────────────────────────────────────────────

  IconData _getFabIcon() {
    return Icons.add_rounded;
  }

  String _getFabLabel() {
    switch (_tabController.index) {
      case 0:
        return 'Tambah Siswa';
      case 1:
        return 'Tambah Guru';
      case 2:
        return 'Tambah Kelas';
      default:
        return 'Tambah';
    }
  }

  void _onFabPressed(BuildContext context) {
    final tab = _tabController.index;
    if (tab == 0) {
      AddStudentBottomSheet.show(context);
    } else if (tab == 1) {
      AddTeacherBottomSheet.show(context);
    } else {
      _showAddClassRoomSheet(context);
    }
  }

  void _showUserOptions(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.displayName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            Text(user.email,
                style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 13)),
            const SizedBox(height: AppSpacing.xl),
            _buildOptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Data',
              color: context.appColors.primary,
              onTap: () {
                Navigator.pop(context);
                if (user.isSiswa) {
                  EditStudentBottomSheet.show(context, user);
                } else if (user.isGuru) {
                  EditTeacherBottomSheet.show(context, user);
                }
              },
            ),
            if (user.isSiswa)
              _buildOptionTile(
                icon: Icons.class_rounded,
                label: 'Pindah Kelas',
                color: context.appColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  ChangeClassBottomSheet.show(context, user);
                },
              ),
            _buildOptionTile(
              icon: Icons.delete_rounded,
              label: 'Hapus Pengguna',
              color: context.appColors.danger,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteUser(context, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: const Text('Hapus Pengguna',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Apakah Anda yakin ingin menghapus data ${user.displayName}? Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authRepositoryProvider).deleteUser(user.uid);
                ref.invalidate(allUsersProvider);
                ref.invalidate(classRoomsProvider);
                ref.invalidate(todayStudentsAttendanceProvider);
                ref.invalidate(todayTeachersAttendanceProvider);
                ref.invalidate(teacherAssignmentsProvider);
                if (context.mounted) {
                  AppToast.showSuccess(
                    context,
                    title: 'Berhasil',
                    message: 'Data ${user.displayName} telah dihapus.',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.showError(
                    context,
                    title: 'Gagal',
                    message: 'Gagal menghapus pengguna. Silakan coba lagi.',
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showClassRoomOptions(
      BuildContext context, ClassRoom room, List<AppUser> allUsers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                room.name.toLowerCase().startsWith('kelas') ||
                        room.name.toLowerCase().startsWith('ruang')
                    ? room.name
                    : 'Kelas ${room.name}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${room.studentCount}/${room.capacity} siswa',
                style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 13)),
            const SizedBox(height: AppSpacing.xl),
            _buildOptionTile(
              icon: Icons.groups_rounded,
              label: 'Lihat Daftar Siswa & Wali',
              color: context.appColors.primary,
              onTap: () {
                Navigator.pop(context);
                ClassroomDetailBottomSheet.show(
                  context,
                  room: room,
                  allUsers: allUsers,
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.person_add_rounded,
              label: room.hasWali ? 'Ganti Wali Kelas' : 'Tetapkan Wali Kelas',
              color: context.appColors.primary,
              onTap: () {
                Navigator.pop(context);
                _showAssignWaliSheet(context, room);
              },
            ),
            _buildOptionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Ruang Kelas',
              color: context.appColors.warning,
              onTap: () {
                Navigator.pop(context);
                AddEditClassRoomBottomSheet.show(context, room: room);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_rounded,
              label: 'Hapus Ruang Kelas',
              color: context.appColors.danger,
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteClassRoom(context, room);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClassRoomSheet(BuildContext context) {
    AddEditClassRoomBottomSheet.show(context);
  }

  void _confirmDeleteClassRoom(BuildContext context, ClassRoom room) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: const Text('Hapus Ruang Kelas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Apakah Anda yakin ingin menghapus Ruang Kelas ${room.name}? Data siswa dalam ruangan ini akan terlepas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(classRoomNotifierProvider.notifier)
                    .delete(room.id);
                if (context.mounted) {
                  AppToast.showSuccess(
                    context,
                    title: 'Berhasil',
                    message: 'Ruang kelas ${room.name} telah dihapus.',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.showError(
                    context,
                    title: 'Gagal',
                    message: 'Gagal menghapus ruang kelas. Silakan coba lagi.',
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAssignWaliSheet(BuildContext context, ClassRoom room) {
    final allUsersAsync = ref.read(allUsersProvider);
    final teachers = allUsersAsync.maybeWhen(
      data: (users) => users.where((u) => u.isGuru).toList(),
      orElse: () => <AppUser>[],
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Wali ${room.name}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: AppSpacing.md),
            if (teachers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Belum ada data guru terdaftar.',
                    style: TextStyle(color: context.appColors.textMuted),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final t = teachers[index];
                    final isCurrentWali = room.guruWaliId == t.uid;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: context.appColors.primarySoft,
                        child: Icon(Icons.person, color: context.appColors.primary),
                      ),
                      title: Text(t.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t.extraField ?? t.email),
                      trailing: isCurrentWali
                          ? Icon(Icons.check_circle_rounded,
                              color: context.appColors.success)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(classRoomNotifierProvider.notifier)
                            .assignWali(
                              roomId: room.id,
                              teacherUid: t.uid,
                              teacherName: t.displayName,
                            );
                        if (context.mounted) {
                          AppToast.showSuccess(
                            context,
                            title: 'Berhasil!',
                            message:
                                '${t.displayName} ditugaskan sebagai Wali Kelas ${room.name}.',
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            if (room.hasWali) ...[
              const Divider(),
              ListTile(
                leading: Icon(Icons.remove_circle_outline,
                    color: context.appColors.danger),
                title: Text('Lepas Wali Kelas',
                    style: TextStyle(
                        color: context.appColors.danger,
                        fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(classRoomNotifierProvider.notifier)
                      .removeWali(room.id);
                  if (context.mounted) {
                    AppToast.showInfo(
                      context,
                      title: 'Wali Kelas Dilepas',
                      message: 'Wali kelas untuk ${room.name} telah dilepas.',
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void _handleNavigation(
    BuildContext context,
    AppBottomDestination destination,
    bool isGuru,
    bool isAdmin,
  ) {
    if (destination == AppBottomDestination.database) return;
    if (destination == AppBottomDestination.home) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } else if (destination == AppBottomDestination.laporan) {
      Navigator.pushReplacementNamed(context, RouteNames.laporan);
    } else if (destination == AppBottomDestination.history) {
      Navigator.pushReplacementNamed(context, RouteNames.history);
    } else if (destination == AppBottomDestination.profile) {
      Navigator.pushReplacementNamed(context, RouteNames.profile);
    } else if (destination == AppBottomDestination.calendar) {
      if (isGuru) {
        Navigator.pushReplacementNamed(context, RouteNames.students);
      } else {
        AppToast.showInfo(context,
            title: 'Segera Hadir!',
            message: 'Fitur Jadwal sedang dalam tahap pengembangan.');
      }
    } else if (destination == AppBottomDestination.scan) {
      ManualAttendanceBottomSheet.show(context);
    }
  }
}
