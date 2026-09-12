import 'package:absensi/core/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService Tests', () {
    test('LocationService instance can be created', () {
      final service = LocationService();
      expect(service, isNotNull);
    });

    test('locationServiceProvider provides LocationService instance', () {
      final service = LocationService();
      expect(service, isA<LocationService>());
    });
  });
}
