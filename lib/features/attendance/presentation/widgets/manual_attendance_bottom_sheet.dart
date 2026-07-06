import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/attendance_record.dart';
import '../providers/attendance_provider.dart';

class ManualAttendanceBottomSheet extends ConsumerStatefulWidget {
  const ManualAttendanceBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ManualAttendanceBottomSheet(),
    );
  }

  @override
  ConsumerState<ManualAttendanceBottomSheet> createState() => _ManualAttendanceBottomSheetState();
}

class _ManualAttendanceBottomSheetState extends ConsumerState<ManualAttendanceBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late final DateTime _selectedDate;
  late final TimeOfDay _selectedTime;
  late AttendanceStatus _selectedStatus;
  late final TextEditingController _remarksController;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedStatus = AttendanceStatus.hadir;
    _selectedTime = TimeOfDay.fromDateTime(now);
    _remarksController = TextEditingController();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi dinonaktifkan. Silakan aktifkan GPS Anda.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin akses lokasi ditolak permanen. Silakan izinkan melalui pengaturan.');
    } 

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 7),
      );
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      throw Exception('Gagal mendapatkan koordinat GPS. Pastikan Anda berada di area terbuka atau aktifkan akurasi tinggi GPS.');
    }
  }

  void _showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onButtonPressed,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.featureCard),
                ),
                backgroundColor: context.appColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.appColors.dangerSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_off_rounded,
                          color: context.appColors.danger,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.appColors.textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: context.appColors.textSecondary,
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: AppPrimaryButton(
                          label: buttonLabel,
                          onPressed: onButtonPressed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      DateTime? checkInDateTime;
      double? latitude;
      double? longitude;

      if (_selectedStatus == AttendanceStatus.hadir) {
        setState(() => _isLocating = true);
        try {
          final position = await _determinePosition();
          if (position != null) {
            latitude = position.latitude;
            longitude = position.longitude;
          }
        } catch (e) {
          setState(() => _isLocating = false);
          if (mounted) {
            final errorMsg = e.toString().replaceAll('Exception: ', '');
            
            String title = 'Gagal Mengakses Lokasi';
            String buttonLabel = 'Mengerti';
            VoidCallback onButtonPressed = () => Navigator.pop(context);

            if (errorMsg.contains('Layanan lokasi dinonaktifkan')) {
              title = 'GPS Tidak Aktif';
              buttonLabel = 'Aktifkan Sekarang';
              onButtonPressed = () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
              };
            } else if (errorMsg.contains('Izin akses lokasi ditolak') || errorMsg.contains('ditolak permanen')) {
              title = 'Izin Lokasi Ditolak';
              buttonLabel = 'Buka Pengaturan';
              onButtonPressed = () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
              };
            }

            _showErrorDialog(
              context: context,
              title: title,
              message: errorMsg,
              buttonLabel: buttonLabel,
              onButtonPressed: onButtonPressed,
            );
          }
          return;
        }
        setState(() => _isLocating = false);

        checkInDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      }

      var finalStatus = _selectedStatus;
      if (_selectedStatus == AttendanceStatus.hadir && checkInDateTime != null) {
        final limit = DateTime(
          checkInDateTime.year,
          checkInDateTime.month,
          checkInDateTime.day,
          7,
          0,
        );
        if (checkInDateTime.isAfter(limit)) {
          finalStatus = AttendanceStatus.terlambat;
        }
      }

      final record = AttendanceRecord(
        date: _selectedDate,
        status: finalStatus,
        checkInTime: checkInDateTime,
        remarks: _selectedStatus != AttendanceStatus.hadir && _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        latitude: latitude,
        longitude: longitude,
      );

      final success = await ref.read(attendanceSubmissionProvider.notifier).submit(record);

      if (mounted && success) {
        AppToast.showSuccess(
          context,
          title: 'Presensi Berhasil!',
          message: 'Data kehadiran Anda telah tercatat hari ini.',
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(attendanceSubmissionProvider);
    final isLoading = submissionState.isLoading || _isLocating;

    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isSiswa = user?.isSiswa ?? true;
    final title = isSiswa ? 'Presensi Hari Ini' : 'Presensi Guru';

    final todayAttendance = ref.watch(todayAttendanceProvider);
    final hasCheckedIn = todayAttendance.maybeWhen(
      data: (record) => record != null,
      orElse: () => false,
    );

    final String buttonLabel;
    if (hasCheckedIn) {
      buttonLabel = 'Selesai Check-in';
    } else if (isSiswa) {
      buttonLabel = switch (_selectedStatus) {
        AttendanceStatus.hadir => 'Check-in Sekarang',
        AttendanceStatus.sakit => 'Ajukan Sakit',
        AttendanceStatus.izin => 'Ajukan Izin',
        _ => 'Kirim',
      };
    } else {
      buttonLabel = switch (_selectedStatus) {
        AttendanceStatus.hadir => 'Check-in Sekarang',
        AttendanceStatus.sakit => 'Ajukan Sakit',
        AttendanceStatus.izin => 'Ajukan Izin',
        _ => 'Kirim',
      };
    }

    final formattedDate = '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';
    final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pull bar and header
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
                      title,
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isSiswa
                      ? 'Silakan simpan kehadiran Anda hari ini.'
                      : 'Silakan simpan kehadiran Anda sebagai Guru hari ini.',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),

                // User Identity Card (for both Siswa and Guru)
                if (user != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.appColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: context.appColors.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: context.appColors.primary,
                          child: Text(
                            (user.displayName)[0].toUpperCase(),
                            style: TextStyle(
                              color: context.appColors.textInverse,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.appColors.primary,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.isSiswa
                                    ? 'XII RPL 1 • NIS 123456'
                                    : '${user.extraField ?? "Guru Matematika"} • NIP 19900815202607',
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: context.appColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Date Picker Field (Interactive Dummy)
                Text(
                  'Tanggal Presensi',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.appColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.appColors.textPrimary,
                            ),
                      ),
                      Icon(
                        Icons.calendar_today_rounded,
                        color: context.appColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Otomatis mengikuti tanggal hari ini',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Status Selector
                Text(
                  'Status Kehadiran',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _StatusOption(
                      label: 'Hadir',
                      icon: Icons.check_circle_outline_rounded,
                      isSelected: _selectedStatus == AttendanceStatus.hadir,
                      selectedColor: context.appColors.success,
                      selectedBgColor: context.appColors.successSoft,
                      onTap: hasCheckedIn ? null : () => setState(() => _selectedStatus = AttendanceStatus.hadir),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatusOption(
                      label: 'Sakit',
                      icon: Icons.sick_outlined,
                      isSelected: _selectedStatus == AttendanceStatus.sakit,
                      selectedColor: context.appColors.warning,
                      selectedBgColor: context.appColors.warningSoft,
                      onTap: hasCheckedIn ? null : () => setState(() => _selectedStatus = AttendanceStatus.sakit),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatusOption(
                      label: 'Izin',
                      icon: Icons.info_outline_rounded,
                      isSelected: _selectedStatus == AttendanceStatus.izin,
                      selectedColor: context.appColors.primary,
                      selectedBgColor: context.appColors.primarySoft,
                      onTap: hasCheckedIn ? null : () => setState(() => _selectedStatus = AttendanceStatus.izin),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Conditional fields based on status
                if (_selectedStatus == AttendanceStatus.hadir) ...[
                  Text(
                    'Waktu Masuk (Check-in)',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.appColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedTime,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.appColors.textPrimary,
                              ),
                        ),
                        Icon(
                          Icons.access_time_rounded,
                          color: context.appColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Menggunakan waktu server (Batas masuk: 07:00 • Batas terlambat: 07:15)',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                  ),
                ] else ...[
                  Text(
                    'Keterangan / Alasan',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _remarksController,
                    enabled: !isLoading && !hasCheckedIn,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _selectedStatus == AttendanceStatus.sakit
                          ? 'Contoh: Demam, Surat Dokter menyusul'
                          : 'Contoh: Ada acara keluarga penting',
                      hintStyle: TextStyle(color: context.appColors.textMuted),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: BorderSide(color: context.appColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: BorderSide(color: context.appColors.border),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: BorderSide(color: context.appColors.border.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: BorderSide(color: context.appColors.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Keterangan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),

                if (submissionState.hasError) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.appColors.dangerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: context.appColors.danger, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            submissionState.error.toString().replaceAll('Exception: ', ''),
                            style: TextStyle(color: context.appColors.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Microcopy privacy note
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'Lokasi digunakan hanya untuk validasi kehadiran saat check-in.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: context.appColors.textMuted,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: AppSecondaryButton(
                        label: 'Batal',
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: isLoading
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(context.appColors.primary),
                                  ),
                                ),
                              ),
                            )
                          : AppPrimaryButton(
                              label: buttonLabel,
                              onPressed: hasCheckedIn ? null : _handleSubmit,
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

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBgColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : context.appColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : context.appColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? selectedColor : context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
