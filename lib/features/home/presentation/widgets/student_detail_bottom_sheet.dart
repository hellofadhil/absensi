import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/domain/entities/student_attendance.dart';

class StudentDetailBottomSheet extends StatelessWidget {
  const StudentDetailBottomSheet({
    super.key,
    required this.student,
  });

  final StudentAttendance student;

  static void show(BuildContext context, StudentAttendance student) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StudentDetailBottomSheet(student: student),
    );
  }

  static Future<void> _launchPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> _launchWhatsApp(String phone) async {
    var clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = student.record;
    String statusLabel;
    Color statusColor;
    IconData statusIcon;

    if (record == null) {
      statusLabel = 'Belum Melakukan Presensi';
      statusColor = context.appColors.textMuted;
      statusIcon = Icons.help_outline_rounded;
    } else {
      switch (record.status) {
        case AttendanceStatus.hadir:
          statusLabel = 'Hadir Tepat Waktu';
          statusColor = context.appColors.success;
          statusIcon = Icons.check_circle_rounded;
          break;
        case AttendanceStatus.terlambat:
          statusLabel = 'Hadir Terlambat';
          statusColor = context.appColors.warning;
          statusIcon = Icons.access_time_rounded;
          break;
        case AttendanceStatus.sakit:
          statusLabel = 'Sakit (Izin Sakit)';
          statusColor = context.appColors.warning;
          statusIcon = Icons.healing_rounded;
          break;
        case AttendanceStatus.izin:
          statusLabel = 'Izin (Keperluan Khusus)';
          statusColor = context.appColors.primary;
          statusIcon = Icons.event_note_rounded;
          break;
        case AttendanceStatus.alpa:
          statusLabel = 'Alpa (Tanpa Keterangan)';
          statusColor = context.appColors.danger;
          statusIcon = Icons.cancel_rounded;
          break;
        default:
          statusLabel = 'Belum Presensi';
          statusColor = context.appColors.textMuted;
          statusIcon = Icons.help_outline_rounded;
      }
    }

    String? timeStr;
    if (record?.checkInTime != null) {
      final h = record!.checkInTime!.hour.toString().padLeft(2, '0');
      final m = record.checkInTime!.minute.toString().padLeft(2, '0');
      timeStr = '$h:$m WIB';
    }

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
        top: AppSpacing.lg,
        bottom: AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
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
                    color: context.appColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detail Kehadiran Siswa',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Student Profile Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border:
                      Border.all(color: context.appColors.border.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: statusColor.withAlpha(30),
                      child: Text(
                        student.studentName.isNotEmpty
                            ? student.studentName[0].toUpperCase()
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
                            student.studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${student.roomName ?? student.className ?? 'Kelas -'}${student.formattedAttendanceNumber != null ? ' • ${student.formattedAttendanceNumber}' : ''}${student.formattedAngkatan != null ? ' • ${student.formattedAngkatan}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
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
              _buildDetailRow(context, Icons.email_outlined, 'Email Akun',
                  student.email),

              if (student.formattedAngkatan != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(context, Icons.school_outlined, 'Angkatan Siswa',
                    student.formattedAngkatan!),
              ],

              if (student.phoneNumber != null &&
                  student.phoneNumber!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRowWithContact(
                  context,
                  Icons.phone_android_rounded,
                  'No. HP Orang Tua / Siswa',
                  student.phoneNumber!,
                  onCall: () => _launchPhone(student.phoneNumber!),
                  onWa: () => _launchWhatsApp(student.phoneNumber!),
                ),
              ],

              if (record?.remarks != null &&
                  record!.remarks!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow(context, Icons.notes_rounded,
                    'Keterangan / Alasan', record.remarks!),
              ],

              if (record?.attachmentUrl != null &&
                  record!.attachmentUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRowWithLink(
                  context,
                  Icons.attachment_rounded,
                  'Bukti Surat',
                  'Buka Surat Lampiran',
                  record.attachmentUrl!,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
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
                  onTap: () => _launchUrl(url),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.appColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 13,
                        color: context.appColors.primary,
                      ),
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
}
