import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:absensi/core/router/route_names.dart';
import 'package:absensi/features/attendance/presentation/widgets/manual_attendance_bottom_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedCalendarMonthProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);

    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isGuru = user?.isGuru ?? false;

    return AppScaffold(
      topBar: AppTopBar(
        title: 'Riwayat Presensi',
        subtitle: '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
        showThemeToggle: true,
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedDestination: AppBottomDestination.history,
        isGuru: isGuru,
        onDestinationSelected: (destination) =>
            _handleNavigation(context, destination, isGuru),
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
          final totalTerlambat = records.where((r) => r.isTerlambat).length;
          final totalSakit = records.where((r) => r.isSakit).length;
          final totalIzin = records.where((r) => r.isIzin).length;
          final totalAlpa = records.where((r) => r.isAlpa).length;

          // Filter by selected date
          final filteredRecords = _selectedDate == null
              ? records
              : records.where((r) =>
                  r.date.year == _selectedDate!.year &&
                  r.date.month == _selectedDate!.month &&
                  r.date.day == _selectedDate!.day).toList();

          // Pagination logic
          final reversedRecords = filteredRecords.reversed.toList();
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
                    setState(() {
                      _currentPage = 1;
                      _selectedDate = null;
                    });
                    ref.read(selectedCalendarMonthProvider.notifier).setMonth(
                        DateTime(selectedMonth.year, selectedMonth.month - 1, 1));
                  },
                  onNextMonth: () {
                    // Prevent navigating to future months
                    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
                    if (nextMonth.isBefore(DateTime.now())) {
                      setState(() {
                        _currentPage = 1;
                        _selectedDate = null;
                      });
                      ref.read(selectedCalendarMonthProvider.notifier).setMonth(nextMonth);
                    }
                  },
                  onMonthSelected: (newMonth) {
                    setState(() {
                      _currentPage = 1;
                      _selectedDate = null;
                    });
                    ref.read(selectedCalendarMonthProvider.notifier).setMonth(newMonth);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Calendar Grid Card
                _CalendarGrid(
                  selectedMonth: selectedMonth,
                  records: records,
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _currentPage = 1;
                      // Toggle selection
                      if (_selectedDate != null &&
                          _selectedDate!.year == date.year &&
                          _selectedDate!.month == date.month &&
                          _selectedDate!.day == date.day) {
                        _selectedDate = null;
                      } else {
                        _selectedDate = date;
                      }
                    });
                  },
                ),
                
                // Selected Date Detail Box (if a date is selected)
                if (_selectedDate != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SelectedDateDetailBox(
                    date: _selectedDate!,
                    record: records.firstWhere(
                      (r) => r.date.year == _selectedDate!.year &&
                             r.date.month == _selectedDate!.month &&
                             r.date.day == _selectedDate!.day,
                      orElse: () => AttendanceRecord(date: _selectedDate!, status: AttendanceStatus.none),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Stats Summary
                _StatsSummaryCard(
                  selectedMonth: selectedMonth,
                  totalHadir: totalHadir,
                  totalTerlambat: totalTerlambat,
                  totalSakit: totalSakit,
                  totalIzin: totalIzin,
                  totalAlpa: totalAlpa,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Details List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SectionHeader(
                        title: _selectedDate == null
                            ? 'Detail Kehadiran'
                            : 'Presensi ${toIndonesianDateString(_selectedDate!)}',
                      ),
                    ),
                    if (_selectedDate != null)
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedDate = null),
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text('Semua Hari', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Details List
                if (filteredRecords.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Text(
                        _selectedDate == null
                            ? 'Tidak ada data presensi pada bulan ini.'
                            : 'Tidak ada data presensi pada tanggal ini.',
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
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
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

  String toIndonesianDateString(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

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

  void _handleNavigation(
    BuildContext context,
    AppBottomDestination destination,
    bool isGuru,
  ) {
    if (destination == AppBottomDestination.history) return;

    if (destination == AppBottomDestination.home) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
      return;
    }

    if (destination == AppBottomDestination.calendar) {
      if (isGuru) {
        Navigator.pushReplacementNamed(context, RouteNames.students);
      } else {
        _showComingSoon(context, 'Jadwal');
      }
      return;
    }

    if (destination == AppBottomDestination.scan) {
      ManualAttendanceBottomSheet.show(context);
      return;
    }

    if (destination == AppBottomDestination.profile) {
      Navigator.pushReplacementNamed(context, RouteNames.profile);
      return;
    }
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
          content: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: context.appColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.appColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.appColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.appColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Segera Hadir!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.appColors.primaryDeep,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fitur $label sedang dalam tahap pengembangan.',
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
        ),
      );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onMonthSelected,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onMonthSelected;

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
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2024),
                lastDate: now,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: context.appColors.primary,
                        onPrimary: context.appColors.textInverse,
                        surface: context.appColors.surface,
                        onSurface: context.appColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onMonthSelected(DateTime(picked.year, picked.month, 1));
              }
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textPrimary,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: context.appColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
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

class _PeriodPickerBottomSheet extends StatefulWidget {
  const _PeriodPickerBottomSheet({
    required this.initialMonth,
    required this.onApplied,
  });

  final DateTime initialMonth;
  final ValueChanged<DateTime> onApplied;

  @override
  State<_PeriodPickerBottomSheet> createState() => _PeriodPickerBottomSheetState();
}

class _PeriodPickerBottomSheetState extends State<_PeriodPickerBottomSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  final List<int> _years = [2024, 2025, 2026, 2027];
  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
    _selectedMonth = widget.initialMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'Pilih Periode',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tahun',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _years.map((year) {
                final isSelected = year == _selectedYear;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        '$year',
                        style: TextStyle(
                          color: isSelected ? context.appColors.textInverse : context.appColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: context.appColors.primary,
                      backgroundColor: context.appColors.surfaceSoft,
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedYear = year);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Bulan',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.0,
              ),
              itemBuilder: (context, index) {
                final monthNum = index + 1;
                final isSelected = monthNum == _selectedMonth;
                final monthName = _months[index];
                
                final isFuture = _selectedYear > now.year || 
                    (_selectedYear == now.year && monthNum > now.month);

                return InkWell(
                  onTap: isFuture
                      ? null
                      : () => setState(() => _selectedMonth = monthNum),
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.appColors.primary
                          : (isFuture ? context.appColors.surfaceSoft.withValues(alpha: 0.5) : context.appColors.surfaceSoft),
                      borderRadius: BorderRadius.circular(8.0),
                      border: isSelected
                          ? Border.all(color: context.appColors.primary)
                          : Border.all(color: Colors.transparent),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      monthName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? context.appColors.textInverse
                            : (isFuture ? context.appColors.textDisabled : context.appColors.textPrimary),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Batal',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Terapkan',
                    onPressed: () {
                      widget.onApplied(DateTime(_selectedYear, _selectedMonth, 1));
                      Navigator.pop(context);
                    },
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

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.selectedMonth,
    required this.records,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedMonth;
  final List<AttendanceRecord> records;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      showShadow: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weekdays header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              final isWeekend = day == 'Sab' || day == 'Min';
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
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
          const Divider(height: 1),
          const SizedBox(height: 4.0),

          // Days grid
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalRows,
            itemBuilder: (context, rowIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
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

                    final isSelected = selectedDate != null &&
                        selectedDate!.year == date.year &&
                        selectedDate!.month == date.month &&
                        selectedDate!.day == date.day;

                    return Expanded(
                      child: SizedBox(
                        height: 44.0,
                        child: InkWell(
                          onTap: () => onDateSelected(date),
                          borderRadius: BorderRadius.circular(22),
                          child: _CalendarCell(
                            record: record,
                            isSelected: isSelected,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(top: 14.0),
            padding: const EdgeInsets.only(top: 12.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.appColors.border,
                  width: 1.0,
                ),
              ),
            ),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: [
                _LegendItem(label: 'Hadir', color: context.appColors.success),
                _LegendItem(label: 'Terlambat', color: context.appColors.warning),
                _LegendItem(label: 'Sakit/Izin', color: context.appColors.primary),
                _LegendItem(label: 'Alpa', color: context.appColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: context.appColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.record,
    required this.isSelected,
  });

  final AttendanceRecord record;
  final bool isSelected;

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
    } else if (record.isTerlambat) {
      backgroundColor = context.appColors.warningSoft;
      borderOutlineColor = context.appColors.warning.withValues(alpha: 0.3);
      textColor = context.appColors.warning;
    } else if (record.isSakit || record.isIzin) {
      backgroundColor = context.appColors.primarySoft;
      borderOutlineColor = context.appColors.primary.withValues(alpha: 0.3);
      textColor = context.appColors.primary;
    } else if (record.isAlpa) {
      backgroundColor = context.appColors.dangerSoft;
      borderOutlineColor = context.appColors.danger.withValues(alpha: 0.3);
      textColor = context.appColors.danger;
    } else if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      textColor = context.appColors.textMuted;
    }

    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: context.appColors.primary, width: 2.0)
              : (borderOutlineColor != null
                  ? Border.all(color: borderOutlineColor)
                  : (isToday ? Border.all(color: context.appColors.primary.withValues(alpha: 0.5), width: 1.5) : null)),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isToday || isSelected || record.status != AttendanceStatus.none
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected ? context.appColors.primary : textColor,
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
                    color: isSelected ? context.appColors.primary : context.appColors.primary,
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

class _SelectedDateDetailBox extends StatelessWidget {
  const _SelectedDateDetailBox({
    required this.date,
    required this.record,
  });

  final DateTime date;
  final AttendanceRecord record;

  String _formatIndonesianFullDate(DateTime date) {
    final weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final isFuture = date.isAfter(todayMidnight);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final hasStatus = record.status != AttendanceStatus.none;

    String statusText = '';
    String subStatusText = '';
    Color textColor = context.appColors.textSecondary;
    IconData icon = Icons.info_outline_rounded;
    Color iconColor = context.appColors.textMuted;

    if (record.isHadir) {
      final timeStr = record.checkInTime != null
          ? ' • ${record.checkInTime!.hour.toString().padLeft(2, '0')}:${record.checkInTime!.minute.toString().padLeft(2, '0')}'
          : '';
      statusText = 'Hadir$timeStr';
      textColor = context.appColors.success;
      icon = Icons.check_circle_outline_rounded;
      iconColor = context.appColors.success;
    } else if (record.isTerlambat) {
      final timeStr = record.checkInTime != null
          ? ' • ${record.checkInTime!.hour.toString().padLeft(2, '0')}:${record.checkInTime!.minute.toString().padLeft(2, '0')}'
          : '';
      statusText = 'Terlambat$timeStr';
      subStatusText = record.remarks ?? '';
      textColor = context.appColors.warning;
      icon = Icons.access_time_rounded;
      iconColor = context.appColors.warning;
    } else if (record.isSakit) {
      statusText = 'Sakit';
      subStatusText = record.remarks ?? '';
      textColor = context.appColors.primary;
      icon = Icons.sick_outlined;
      iconColor = context.appColors.primary;
    } else if (record.isIzin) {
      statusText = 'Izin';
      subStatusText = record.remarks ?? '';
      textColor = context.appColors.primary;
      icon = Icons.info_outline_rounded;
      iconColor = context.appColors.primary;
    } else if (record.isAlpa) {
      statusText = 'Alpa';
      subStatusText = 'Tidak hadir tanpa keterangan';
      textColor = context.appColors.danger;
      icon = Icons.cancel_outlined;
      iconColor = context.appColors.danger;
    } else {
      // status is none
      if (isFuture) {
        statusText = 'Data belum tersedia';
        subStatusText = 'Presensi untuk tanggal ini belum dibuka.';
        textColor = context.appColors.textMuted;
        icon = Icons.lock_outline_rounded;
        iconColor = context.appColors.textMuted;
      } else {
        statusText = 'Tidak ada presensi';
        subStatusText = isWeekend 
            ? 'Hari libur akhir pekan.' 
            : 'Hari libur atau belum ada data kehadiran.';
        textColor = context.appColors.textSecondary;
        icon = Icons.event_busy_rounded;
        iconColor = context.appColors.textMuted;
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: AppRadius.small,
      variant: AppCardVariant.softBlue,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatIndonesianFullDate(date),
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: textColor,
                        fontWeight: hasStatus ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                if (subStatusText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subStatusText,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSummaryCard extends StatelessWidget {
  const _StatsSummaryCard({
    required this.selectedMonth,
    required this.totalHadir,
    required this.totalTerlambat,
    required this.totalSakit,
    required this.totalIzin,
    required this.totalAlpa,
  });

  final DateTime selectedMonth;
  final int totalHadir;
  final int totalTerlambat;
  final int totalSakit;
  final int totalIzin;
  final int totalAlpa;

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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekap ${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatSummaryCol(
                label: 'Hadir',
                value: '$totalHadir',
                color: context.appColors.success,
              ),
              Container(width: 1, height: 32, color: context.appColors.border),
              _StatSummaryCol(
                label: 'Telat',
                value: '$totalTerlambat',
                color: context.appColors.warning,
              ),
              Container(width: 1, height: 32, color: context.appColors.border),
              _StatSummaryCol(
                label: 'Sakit',
                value: '$totalSakit',
                color: context.appColors.primary,
              ),
              Container(width: 1, height: 32, color: context.appColors.border),
              _StatSummaryCol(
                label: 'Izin',
                value: '$totalIzin',
                color: context.appColors.primary,
              ),
              Container(width: 1, height: 32, color: context.appColors.border),
              _StatSummaryCol(
                label: 'Alpa',
                value: '$totalAlpa',
                color: context.appColors.danger,
              ),
            ],
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
    } else if (record.isTerlambat) {
      final checkInStr = record.checkInTime != null
          ? '${record.checkInTime!.hour.toString().padLeft(2, '0')}:${record.checkInTime!.minute.toString().padLeft(2, '0')}'
          : '--:--';
      badgeText = 'Terlambat • $checkInStr';
      badgeBgColor = context.appColors.warningSoft;
      badgeTextColor = context.appColors.warning;
    } else if (record.isSakit) {
      badgeText = 'Sakit';
      badgeBgColor = context.appColors.primarySoft;
      badgeTextColor = context.appColors.primary;
    } else if (record.isIzin) {
      badgeText = 'Izin';
      badgeBgColor = context.appColors.primarySoft;
      badgeTextColor = context.appColors.primary;
    } else if (record.isAlpa) {
      badgeText = 'Alpa';
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
