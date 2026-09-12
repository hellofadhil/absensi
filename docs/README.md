# Absensi Project Documentation

Dokumentasi ini menjelaskan kondisi project saat ini: aplikasi Flutter untuk absensi sekolah SMK TI Bazma.

## Ringkasan

Project ini adalah aplikasi absensi mobile berbasis Flutter. Aplikasi memakai Firebase untuk autentikasi dan penyimpanan data, Riverpod untuk state management, Geolocator untuk validasi lokasi check-in, serta API hari libur Indonesia dari `https://libur.deno.dev/` untuk menandai tanggal merah dan menonaktifkan presensi saat libur.

## Stack

- Flutter
- Riverpod
- Firebase Core
- Firebase Auth
- Cloud Firestore
- Geolocator
- Shared Preferences
- API Hari Libur Indonesia: `https://libur.deno.dev/api`

## Struktur Utama

```txt
lib/
  core/
    constants/
    errors/
    network/
    router/
    services/
    theme/
  features/
    attendance/
    auth/
    home/
    profile/
  shared/
    widgets/
```

## Fitur Saat Ini

- Login dan auth gate berbasis Firebase Auth.
- Home siswa/guru dengan status presensi hari ini.
- Presensi manual dengan status hadir, sakit, dan izin.
- Validasi lokasi untuk presensi hadir.
- Penyimpanan riwayat presensi per user di Firestore.
- Halaman riwayat presensi dengan kalender bulanan.
- Daftar siswa dan presensi hari ini untuk role guru.
- Integrasi hari libur nasional/cuti bersama.
- Profil pengguna dan preferensi tema.

## Catatan Integrasi Libur

Integrasi libur berada di:

- `lib/core/constants/api_endpoints.dart`
- `lib/core/services/holiday_service.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/attendance/presentation/pages/attendance_history_page.dart`
- `lib/features/attendance/presentation/widgets/manual_attendance_bottom_sheet.dart`

Saat API menyatakan hari ini libur, aplikasi menampilkan banner, menonaktifkan tombol presensi, dan mencegah submit dari bottom sheet.

## Perintah Manual

Karena project ini berjalan di hardware terbatas, command berat tidak dijalankan otomatis. Jalankan manual bila perlu:

```bash
flutter analyze
flutter test
flutter run
```

