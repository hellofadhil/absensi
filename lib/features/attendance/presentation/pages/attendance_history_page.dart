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
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/attendance_record.dart';
import '../providers/attendance_provider.dart';

class AttendanceHistoryPage extends ConsumerStatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  ConsumerState<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  int _currentPage = 1;
  static const _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedCalendarMonthProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);

    return AppScaffold(
      topBar: AppTopBar(
        title: 'Riwayat Presensi',
        onHomePressed: () {},
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.history,
        onDestinationSelected: (destination) =>
            _handleNavigation(context, destination),
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Gagal memuat riwayat: $err',
              style: TextStyle(color: context.appColors.danger),
            ),
          ),
        ),
        data: (records) {
          // Calculate monthly stats
          final totalHadir = records.where((r) => r.isHadir).length;
          final totalSakitIzin = records.where((r) => r.isSakit || r.isIzin).length;
          final totalAlfa = records.where((r) => r.isAlfa).length;

          // Pagination logic
          final reversedRecords = records.reversed.toList();
          final totalItems = reversedRecords.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();
          
          // Clamp active page to valid range
          final activePage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);
          final startIndex = (activePage - 1) * _itemsPerPage;
          final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
          final paginatedRecords = totalItems > 0 
              ? reversedRecords.sublist(startIndex, endIndex)
              : <AttendanceRecord>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector Card
                _MonthSelector(
                  selectedMonth: selectedMonth,
                  onPrevMonth: () {
                    setState(() => _currentPage = 1);
                    ref.read(selectedCalendarMonthProvider.notifier).setMonth(
                        DateTime(selectedMonth.year, selectedMonth.month - 1, 1));
                  },
                  onNextMonth: () {
                    // Prevent navigating to future months
                    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
                    if (nextMonth.isBefore(DateTime.now())) {
                      setState(() => _currentPage = 1);
                      ref.read(selectedCalendarMonthProvider.notifier).setMonth(nextMonth);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Calendar Grid Card
                _CalendarGrid(
                  selectedMonth: selectedMonth,
                  records: records,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Stats Summary
                _StatsSummaryCard(
                  totalHadir: totalHadir,
                  totalSakitIzin: totalSakitIzin,
                  totalAlfa: totalAlfa,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Details List Header
                const SectionHeader(title: 'Detail Kehadiran'),
                const SizedBox(height: AppSpacing.md),

                // Details List
                if (records.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Text(
                        'Tidak ada data presensi pada bulan ini.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: context.appColors.textMuted,
                            ),
                      ),
                    ),
                  )
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paginatedRecords.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final record = paginatedRecords.elementAt(index);
                      return _AttendanceLogTile(record: record);
                    },
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      radius: AppRadius.small,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            onPressed: activePage > 1
                                ? () => setState(() => _currentPage = activePage - 1)
                                : null,
                          ),
                          Text(
                            'Halaman $activePage dari $totalPages',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.textPrimary,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                            onPressed: activePage < totalPages
                                ? () => setState(() => _currentPage = activePage + 1)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.bottomNavigationClearance),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleNavigation(
    BuildContext context,
    AppBottomDestination destination,
  ) {
    if (destination == AppBottomDestination.history) return;

    if (destination == AppBottomDestination.home) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
      return;
    }

    final label = switch (destination) {
      AppBottomDestination.home => 'Beranda',
      AppBottomDestination.calendar => 'Jadwal',
      AppBottomDestination.scan => 'Presensi',
      AppBottomDestination.history => 'Riwayat',
      AppBottomDestination.profile => 'Profil',
    };
    _showComingSoon(context, label);
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Fitur $label akan segera hadir.'),
          duration: const Duration(seconds: 1),
        ),
      );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  String _getMonthName(int month) {
    return switch (month) {
      1 => 'Januari',
      2 => 'Februari',
      3 => 'Maret',
      4 => 'April',
      5 => 'Mei',
      6 => 'Juni',
      7 => 'Juli',
      8 => 'Agustus',
      9 => 'September',
      10 => 'Oktober',
      11 => 'November',
      12 => 'Desember',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrevMonth,
          ),
          Text(
            '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: isCurrentMonth ? null : onNextMonth,
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.selectedMonth,
    required this.records,
  });

  final DateTime selectedMonth;
  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(selectedMonth.year, selectedMonth.month, 1).weekday;
    
    // Weekday start offset (assuming Monday is the first day of week)
    final offset = firstDayWeekday - 1;
    
    final totalCells = daysInMonth + offset;
    final totalRows = (totalCells / 7).ceil();

    final weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      showShadow: true,
      child: Column(
        children: [
          // Weekdays header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              final isWeekend = day == 'Sab' || day == 'Min';
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: isWeekend
                                ? context.appColors.danger.withValues(alpha: 0.7)
                                : context.appColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.xs),

          // Days grid
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalRows,
            itemBuilder: (context, rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    final dayNumber = cellIndex - offset + 1;

                    if (dayNumber <= 0 || dayNumber > daysInMonth) {
                      return const Expanded(child: SizedBox());
                    }

                    final date = DateTime(selectedMonth.year, selectedMonth.month, dayNumber);
                    
                    // Find attendance record for this day
                    final record = records.firstWhere(
                      (r) => r.date.year == date.year &&
                             r.date.month == date.month &&
                             r.date.day == date.day,
                      orElse: () => AttendanceRecord(date: date, status: AttendanceStatus.none),
                    );

                    return Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.1,
                        child: _CalendarCell(record: record),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final date = record.date;
    final isToday = DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    Color? backgroundColor;
    Color? borderOutlineColor;
    Color textColor = context.appColors.textPrimary;

    if (record.isHadir) {
      backgroundColor = context.appColors.successSoft;
      borderOutlineColor = context.appColors.success.withValues(alpha: 0.3);
      textColor = context.appColors.success;
    } else if (record.isSakit || record.isIzin) {
      backgroundColor = context.appColors.warningSoft;
      borderOutlineColor = context.appColors.warning.withValues(alpha: 0.3);
      textColor = context.appColors.warning;
    } else if (record.isAlfa) {
      backgroundColor = context.appColors.dangerSoft;
      borderOutlineColor = context.appColors.danger.withValues(alpha: 0.3);
      textColor = context.appColors.danger;
    } else if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      textColor = context.appColors.textMuted;
    }

    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: borderOutlineColor != null
              ? Border.all(color: borderOutlineColor)
              : (isToday ? Border.all(color: context.appColors.primary, width: 1.5) : null),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isToday || record.status != AttendanceStatus.none
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: textColor,
                fontSize: 14,
              ),
            ),
            if (isToday)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: context.appColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsSummaryCard extends StatelessWidget {
  const _StatsSummaryCard({
    required this.totalHadir,
    required this.totalSakitIzin,
    required this.totalAlfa,
  });

  final int totalHadir;
  final int totalSakitIzin;
  final int totalAlfa;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatSummaryCol(
            label: 'Hadir',
            value: '$totalHadir',
            color: context.appColors.success,
          ),
          Container(width: 1, height: 32, color: context.appColors.border),
          _StatSummaryCol(
            label: 'Sakit/Izin',
            value: '$totalSakitIzin',
            color: context.appColors.warning,
          ),
          Container(width: 1, height: 32, color: context.appColors.border),
          _StatSummaryCol(
            label: 'Alfa',
            value: '$totalAlfa',
            color: context.appColors.danger,
          ),
        ],
      ),
    );
  }
}

class _StatSummaryCol extends StatelessWidget {
  const _StatSummaryCol({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: context.appColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _AttendanceLogTile extends StatelessWidget {
  const _AttendanceLogTile({required this.record});

  final AttendanceRecord record;

  String _formatDate(DateTime date) {
    final weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    String badgeText = '';
    Color badgeBgColor = context.appColors.surfaceSoft;
    Color badgeTextColor = context.appColors.textSecondary;

    if (record.isHadir) {
      final checkInStr = record.checkInTime != null
          ? '${record.checkInTime!.hour.toString().padLeft(2, '0')}:${record.checkInTime!.minute.toString().padLeft(2, '0')}'
          : '--:--';
      badgeText = 'Hadir • $checkInStr';
      badgeBgColor = context.appColors.successSoft;
      badgeTextColor = context.appColors.success;
    } else if (record.isSakit) {
      badgeText = 'Sakit';
      badgeBgColor = context.appColors.warningSoft;
      badgeTextColor = context.appColors.warning;
    } else if (record.isIzin) {
      badgeText = 'Izin';
      badgeBgColor = context.appColors.warningSoft;
      badgeTextColor = context.appColors.warning;
    } else if (record.isAlfa) {
      badgeText = 'Alfa';
      badgeBgColor = context.appColors.dangerSoft;
      badgeTextColor = context.appColors.danger;
    }

    return AppCard(
      radius: AppRadius.small,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.date),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (record.remarks != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    record.remarks!,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: context.appColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              badgeText,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
