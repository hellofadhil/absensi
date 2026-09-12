import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/student_attendance.dart';
import '../providers/attendance_provider.dart';
import '../../../school/presentation/providers/school_provider.dart';
import '../widgets/manual_attendance_bottom_sheet.dart';

class LaporanPage extends ConsumerStatefulWidget {
  const LaporanPage({super.key});

  @override
  ConsumerState<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends ConsumerState<LaporanPage> {
  String _selectedClass = 'Semua';
  String _selectedPeriod = 'Hari ini';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isAdmin = user?.isAdmin ?? false;
    final isGuru = user?.isGuru ?? false;

    final todayStudentsAsync = ref.watch(todayStudentsAttendanceProvider);
    final roomsAsync = ref.watch(classRoomsProvider);

    return AppScaffold(
      topBar: const AppTopBar(
        title: 'Laporan Presensi',
        subtitle: 'Rekap & Analisis Kehadiran Siswa',
        showThemeToggle: true,
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.laporan,
        isGuru: isGuru,
        isAdmin: isAdmin,
        onDestinationSelected: (destination) =>
            _handleNavigation(context, destination, isGuru, isAdmin),
      ),
      body: todayStudentsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Gagal memuat rekap laporan: $err',
              style: TextStyle(color: context.appColors.danger),
            ),
          ),
        ),
        data: (allStudents) {
          final rooms = roomsAsync.value ?? [];

          // Filter students by selected classroom
          final filteredStudents = _selectedClass == 'Semua'
              ? allStudents
              : allStudents.where((s) {
                  final target = _selectedClass
                      .toLowerCase()
                      .replaceAll('kelas', '')
                      .trim();
                  final cName = s.className?.toLowerCase() ?? '';
                  final rName = s.roomName?.toLowerCase() ?? '';
                  return cName.contains(target) || rName.contains(target);
                }).toList();

          // Calculate real metrics
          final total = filteredStudents.length;
          final hadir = filteredStudents
              .where((s) => s.record?.status == AttendanceStatus.hadir)
              .length;
          final terlambat = filteredStudents
              .where((s) => s.record?.status == AttendanceStatus.terlambat)
              .length;
          final sakit = filteredStudents
              .where((s) => s.record?.status == AttendanceStatus.sakit)
              .length;
          final izin = filteredStudents
              .where((s) => s.record?.status == AttendanceStatus.izin)
              .length;
          final alpa = filteredStudents
              .where((s) => s.record?.status == AttendanceStatus.alpa)
              .length;
          final unsubmitted = filteredStudents
              .where((s) =>
                  s.record == null || s.record?.status == AttendanceStatus.none)
              .length;

          final totalPresent = hadir + terlambat;
          final presentPct =
              total > 0 ? (totalPresent / total * 100) : 0.0;
          final latePct = total > 0 ? (terlambat / total * 100) : 0.0;

          // Build class dropdown options
          final classOptions = ['Semua'];
          for (final r in rooms) {
            final label = r.name.toLowerCase().startsWith('kelas') ||
                    r.name.toLowerCase().startsWith('ruang')
                ? r.name
                : 'Kelas ${r.name}';
            if (!classOptions.contains(label)) {
              classOptions.add(label);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.bottomNavigationClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceSoft,
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                          border: Border.all(color: context.appColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: context.appColors.textSecondary),
                            dropdownColor: context.appColors.surface,
                            style: TextStyle(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            items: ['Hari ini', 'Bulan ini']
                                .map((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPeriod = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceSoft,
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                          border: Border.all(color: context.appColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: classOptions.contains(_selectedClass)
                                ? _selectedClass
                                : 'Semua',
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: context.appColors.textSecondary),
                            dropdownColor: context.appColors.surface,
                            style: TextStyle(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            items: classOptions.map((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(
                                  val,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedClass = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Stat Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Tingkat Hadir',
                        value: '${presentPct.toStringAsFixed(1)}%',
                        subtitle: '$totalPresent dari $total siswa',
                        icon: Icons.check_circle_rounded,
                        iconColor: context.appColors.success,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Terlambat',
                        value: '${latePct.toStringAsFixed(1)}%',
                        subtitle: '$terlambat siswa terlambat',
                        icon: Icons.access_time_rounded,
                        iconColor: context.appColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Detail Metrics Breakdown
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rincian Status Presensi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Tepat Waktu',
                              count: hadir,
                              color: context.appColors.success,
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Terlambat',
                              count: terlambat,
                              color: context.appColors.warning,
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Sakit',
                              count: sakit,
                              color: context.appColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Izin',
                              count: izin,
                              color: context.appColors.primaryDeep,
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Alpa',
                              count: alpa,
                              color: context.appColors.danger,
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Belum Absen',
                              count: unsubmitted,
                              color: context.appColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Ringkasan per Kelas
                const SectionHeader(title: 'Ringkasan Kehadiran per Kelas'),
                const SizedBox(height: AppSpacing.md),

                if (rooms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Belum ada ruang kelas terdaftar.',
                      style: TextStyle(color: context.appColors.textSecondary),
                    ),
                  )
                else
                  ...rooms.map((room) {
                    final target = room.name.toLowerCase().trim();
                    final classStudents = allStudents.where((s) {
                      final cName = s.className?.toLowerCase() ?? '';
                      final rName = s.roomName?.toLowerCase() ?? '';
                      return cName.contains(target) || rName.contains(target);
                    }).toList();

                    final cTotal = classStudents.length;
                    final cPresent = classStudents
                        .where((s) =>
                            s.record?.status == AttendanceStatus.hadir ||
                            s.record?.status == AttendanceStatus.terlambat)
                        .length;
                    final cPct =
                        cTotal > 0 ? (cPresent / cTotal * 100) : 0.0;
                    final label = room.name
                                .toLowerCase()
                                .startsWith('kelas') ||
                            room.name.toLowerCase().startsWith('ruang')
                        ? room.name
                        : 'Kelas ${room.name}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildClassSummaryRow(
                        className: label,
                        present: cPresent,
                        total: cTotal,
                        pct: cPct,
                      ),
                    );
                  }),

                const SizedBox(height: AppSpacing.xl),

                // Export Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleExportReport(
                      context,
                      filteredStudents,
                      _selectedClass,
                      _selectedPeriod,
                      hadir,
                      terlambat,
                      sakit,
                      izin,
                      alpa,
                      unsubmitted,
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Ekspor & Salin Laporan Presensi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.primary,
                      foregroundColor: context.appColors.textInverse,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: context.appColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSummaryRow({
    required String className,
    required int present,
    required int total,
    required double pct,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$present dari $total Siswa Hadir',
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: pct >= 85
                  ? context.appColors.successSoft
                  : (pct >= 60
                      ? context.appColors.primarySoft
                      : context.appColors.dangerSoft),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                color: pct >= 85
                    ? context.appColors.success
                    : (pct >= 60
                        ? context.appColors.primary
                        : context.appColors.danger),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleExportReport(
    BuildContext context,
    List<StudentAttendance> students,
    String selectedClass,
    String selectedPeriod,
    int hadir,
    int terlambat,
    int sakit,
    int izin,
    int alpa,
    int unsubmitted,
  ) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    final buffer = StringBuffer();
    buffer.writeln('===========================================');
    buffer.writeln('    REKAP LAPORAN PRESENSI - SMK TI BAZMA');
    buffer.writeln('===========================================');
    buffer.writeln('Tanggal Cetak : $dateStr');
    buffer.writeln('Filter Kelas  : $selectedClass');
    buffer.writeln('Periode       : $selectedPeriod');
    buffer.writeln('Total Siswa   : ${students.length}');
    buffer.writeln('-------------------------------------------');
    buffer.writeln('RINGKASAN KEHADIRAN:');
    buffer.writeln('• Hadir Tepat Waktu : $hadir');
    buffer.writeln('• Terlambat         : $terlambat');
    buffer.writeln('• Sakit             : $sakit');
    buffer.writeln('• Izin              : $izin');
    buffer.writeln('• Alpa              : $alpa');
    buffer.writeln('• Belum Absen       : $unsubmitted');
    buffer.writeln('-------------------------------------------');
    buffer.writeln('DAFTAR SISWA & STATUS:');

    int idx = 1;
    for (final s in students) {
      final statusName = s.record != null
          ? s.record!.status.name.toUpperCase()
          : 'BELUM ABSEN';
      final timeStr = s.record?.checkInTime != null
          ? ' (${s.record!.checkInTime!.hour.toString().padLeft(2, '0')}:${s.record!.checkInTime!.minute.toString().padLeft(2, '0')})'
          : '';
      buffer.writeln(
          '$idx. ${s.studentName} [${s.className}] -> $statusName$timeStr');
      idx++;
    }
    buffer.writeln('===========================================');

    final reportText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: const Text(
          'Rekap Laporan Presensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan berhasil digenerate berdasarkan data real-time database:',
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  border: Border.all(color: context.appColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    reportText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.primary,
              foregroundColor: context.appColors.textInverse,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: reportText));
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (context.mounted) {
                AppToast.showSuccess(
                  context,
                  title: 'Disalin!',
                  message:
                      'Rekap laporan berhasil disalin ke clipboard. Siap ditempel ke Excel, WhatsApp, atau Catatan.',
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin Laporan'),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(
    BuildContext context,
    AppBottomDestination destination,
    bool isGuru,
    bool isAdmin,
  ) {
    if (destination == AppBottomDestination.laporan) return;
    if (destination == AppBottomDestination.home) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } else if (destination == AppBottomDestination.database) {
      Navigator.pushReplacementNamed(context, RouteNames.database);
    } else if (destination == AppBottomDestination.history) {
      Navigator.pushReplacementNamed(context, RouteNames.history);
    } else if (destination == AppBottomDestination.profile) {
      Navigator.pushReplacementNamed(context, RouteNames.profile);
    } else if (destination == AppBottomDestination.calendar) {
      if (isGuru) {
        Navigator.pushReplacementNamed(context, RouteNames.students);
      } else {
        AppToast.showInfo(
          context,
          title: 'Segera Hadir!',
          message: 'Fitur Jadwal sedang dalam tahap pengembangan.',
        );
      }
    } else if (destination == AppBottomDestination.scan) {
      ManualAttendanceBottomSheet.show(context);
    }
  }
}
