import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';

class HolidayItem {
  const HolidayItem({
    required this.date,
    required this.name,
    required this.isNationalHoliday,
  });

  final DateTime date;
  final String name;
  final bool isNationalHoliday;

  String get dateKey => HolidayService.formatDateKey(date);

  factory HolidayItem.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'] as String? ?? '';

    return HolidayItem(
      date: DateTime.tryParse(dateValue) ?? DateTime.fromMillisecondsSinceEpoch(0),
      name: json['name'] as String? ?? 'Hari libur',
      isNationalHoliday: json['is_national_holiday'] as bool? ?? false,
    );
  }
}

class HolidayStatus {
  const HolidayStatus({
    required this.date,
    required this.isHoliday,
    required this.holidayList,
    required this.isNationalHoliday,
  });

  final DateTime? date;
  final bool isHoliday;
  final List<String> holidayList;
  final bool isNationalHoliday;

  factory HolidayStatus.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'] as String?;

    return HolidayStatus(
      date: dateValue == null ? null : DateTime.tryParse(dateValue),
      isHoliday: json['is_holiday'] as bool? ?? false,
      holidayList: List<String>.from(json['holiday_list'] as List? ?? []),
      isNationalHoliday: json['is_national_holiday'] as bool? ?? false,
    );
  }

  factory HolidayStatus.empty() {
    return const HolidayStatus(
      date: null,
      isHoliday: false,
      holidayList: [],
      isNationalHoliday: false,
    );
  }
}

class HolidayService {
  final HttpClient _httpClient = HttpClient();

  static String formatDateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<HolidayStatus> checkTodayHoliday() async {
    try {
      final request = await _httpClient.getUrl(Uri.parse('${ApiEndpoints.holidayApi}/today'));
      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return HolidayStatus.fromJson(json);
      }
      return HolidayStatus.empty();
    } catch (_) {
      return HolidayStatus.empty();
    }
  }

  Future<Map<String, HolidayItem>> getHolidaysForYear(int year) async {
    try {
      final uri = Uri.parse(ApiEndpoints.holidayApi).replace(
        queryParameters: {'year': '$year'},
      );
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        final responseBody = await response.transform(utf8.decoder).join();
        final list = jsonDecode(responseBody) as List<dynamic>;
        final cache = <String, HolidayItem>{};
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final holiday = HolidayItem.fromJson(item);
            cache[holiday.dateKey] = holiday;
          }
        }
        return cache;
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}

final holidayServiceProvider = Provider<HolidayService>((ref) {
  return HolidayService();
});

final todayHolidayProvider = FutureProvider<HolidayStatus>((ref) async {
  final holidayService = ref.watch(holidayServiceProvider);
  return holidayService.checkTodayHoliday();
});

final yearlyHolidaysProvider = FutureProvider.family<Map<String, HolidayItem>, int>((ref, year) async {
  final holidayService = ref.watch(holidayServiceProvider);
  return holidayService.getHolidaysForYear(year);
});
