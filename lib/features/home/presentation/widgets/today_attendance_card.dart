import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import 'package:absensi/features/attendance/domain/entities/attendance_record.dart';

class TodayAttendanceCard extends StatelessWidget {
  const TodayAttendanceCard({
    super.key,
    required this.record,
    required this.isHoliday,
    required this.onPresensiPressed,
    required this.onDetailPressed,
  });

  final AttendanceRecord? record;
  final bool isHoliday;
  final VoidCallback? onPresensiPressed;
  final VoidCallback onDetailPressed;

  @override
  Widget build(BuildContext context) {
    final hasCheckedIn = record != null;

    String cardTitle = 'Status Presensi Hari Ini';
    String line1 = 'Batas presensi: 07:00 WIB';
    String? line2;

    if (hasCheckedIn) {
      final rec = record!;
      if (rec.checkInTime != null) {
        final timeStr =
            '${rec.checkInTime!.hour.toString().padLeft(2, '0')}:${rec.checkInTime!.minute.toString().padLeft(2, '0')} WIB';
        line1 = timeStr;
        line2 =
            'Lokasi: ${rec.latitude != null ? 'Dalam area sekolah' : 'Luar area sekolah'}';
      } else {
        line1 = rec.remarks != null
            ? 'Keterangan: ${rec.remarks}'
            : 'Tidak ada keterangan';
        line2 = null;
      }
    } else if (isHoliday) {
      line1 = 'Hari libur';
      line2 = 'Presensi dinonaktifkan untuk hari ini';
    } else {
      final now = DateTime.now();
      final limit = DateTime(now.year, now.month, now.day, 7, 0);
      final difference = limit.difference(now);
      if (difference.isNegative) {
        line2 = 'Batas presensi terlewati';
      } else {
        line2 = 'Sisa waktu: ${difference.inMinutes} menit';
      }
    }

    return AppCard(
      variant: AppCardVariant.standard,
      radius: AppRadius.featureCard,
      padding: const EdgeInsets.all(AppSpacing.xl),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardTitle,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            line1,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
          ),
          if (line2 != null) ...[
            const SizedBox(height: 4),
            Text(
              line2,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: context.appColors.textSecondary,
                  ),
            ),
          ],
          if (record?.attachmentUrl != null) ...[
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(record!.attachmentUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.attachment_rounded,
                        size: 16, color: context.appColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Lihat Lampiran Surat (Kora Drive)',
                      style: TextStyle(
                        color: context.appColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: hasCheckedIn
                ? OutlinedButton.icon(
                    onPressed: onDetailPressed,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Lihat Detail Presensi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appColors.primary,
                      side: BorderSide(color: context.appColors.primaryBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onPresensiPressed,
                    icon: Icon(
                      isHoliday
                          ? Icons.event_busy_rounded
                          : Icons.qr_code_scanner_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isHoliday ? 'Presensi Libur' : 'Presensi Sekarang',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.primary,
                      foregroundColor: context.appColors.textInverse,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
