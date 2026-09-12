import 'package:absensi/core/services/holiday_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HolidayItem & HolidayStatus Serialization', () {
    test('HolidayItem.fromJson parses JSON correctly', () {
      final json = {
        'date': '2026-08-17',
        'name': 'Hari Kemerdekaan RI',
        'is_national_holiday': true,
      };

      final item = HolidayItem.fromJson(json);

      expect(item.name, equals('Hari Kemerdekaan RI'));
      expect(item.isNationalHoliday, isTrue);
      expect(item.dateKey, equals('2026-08-17'));
    });

    test('HolidayStatus.fromJson parses JSON correctly', () {
      final json = {
        'date': '2026-08-17',
        'is_holiday': true,
        'holiday_list': ['Hari Kemerdekaan RI'],
        'is_national_holiday': true,
      };

      final status = HolidayStatus.fromJson(json);

      expect(status.isHoliday, isTrue);
      expect(status.holidayList, contains('Hari Kemerdekaan RI'));
      expect(status.isNationalHoliday, isTrue);
    });

    test('HolidayStatus.empty returns default non-holiday state', () {
      final emptyStatus = HolidayStatus.empty();

      expect(emptyStatus.isHoliday, isFalse);
      expect(emptyStatus.holidayList, isEmpty);
      expect(emptyStatus.isNationalHoliday, isFalse);
    });

    test('HolidayService.formatDateKey formats DateTime correctly', () {
      final date = DateTime(2026, 8, 12);
      final key = HolidayService.formatDateKey(date);

      expect(key, equals('2026-08-12'));
    });
  });
}
