import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin akses lokasi ditolak secara permanen. Harap aktifkan izin lokasi di pengaturan perangkat Anda.',
      );
    } 

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
