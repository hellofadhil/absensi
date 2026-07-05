import 'dart:math';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  // Local cache to persist during runtime
  final Map<String, List<AttendanceRecord>> _recordsCache = {};

  List<AttendanceRecord> _generateMockData(DateTime month) {
    final records = <AttendanceRecord>[];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final now = DateTime.now();

    final rand = Random(month.month + month.year);

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      
      // Do not generate future records
      if (date.isAfter(now)) continue;

      // Skip weekends (Saturday = 6, Sunday = 7)
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        continue;
      }

      // 85% Hadir/Terlambat, 8% Sakit/Izin, 7% Alpa
      final roll = rand.nextDouble();
      if (roll < 0.85) {
        // Hadir atau Terlambat
        final hour = 7;
        final minute = rand.nextInt(35); // check-in between 07:00 and 07:35
        final checkInTime = DateTime(date.year, date.month, date.day, hour, minute);
        final isLate = minute > 15;
        records.add(AttendanceRecord(
          date: date,
          status: isLate ? AttendanceStatus.terlambat : AttendanceStatus.hadir,
          checkInTime: checkInTime,
          remarks: isLate ? 'Lewat ${minute - 15} menit dari batas toleransi' : null,
        ));
      } else if (roll < 0.90) {
        // Sakit
        records.add(AttendanceRecord(
          date: date,
          status: AttendanceStatus.sakit,
          remarks: 'Demam tinggi, Surat Dokter menyusul',
        ));
      } else if (roll < 0.95) {
        // Izin
        records.add(AttendanceRecord(
          date: date,
          status: AttendanceStatus.izin,
          remarks: 'Ada keperluan keluarga penting',
        ));
      } else {
        // Alpa
        records.add(AttendanceRecord(
          date: date,
          status: AttendanceStatus.alpa,
        ));
      }
    }

    return records;
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory(String uid, DateTime month) async {
    // Simulate short network delay
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final cacheKey = '${uid}_${month.year}_${month.month}';
    if (!_recordsCache.containsKey(cacheKey)) {
      _recordsCache[cacheKey] = _generateMockData(month);
    }

    return _recordsCache[cacheKey]!;
  }

  @override
  Future<void> submitAttendance(String uid, AttendanceRecord record) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    final cacheKey = '${uid}_${record.date.year}_${record.date.month}';
    if (!_recordsCache.containsKey(cacheKey)) {
      _recordsCache[cacheKey] = _generateMockData(record.date);
    }

    // Remove existing record for the same day if exists
    _recordsCache[cacheKey]!.removeWhere(
      (r) => r.date.year == record.date.year &&
             r.date.month == record.date.month &&
             r.date.day == record.date.day,
    );

    _recordsCache[cacheKey]!.add(record);
    // Sort chronologically
    _recordsCache[cacheKey]!.sort((a, b) => a.date.compareTo(b.date));
  }
}
