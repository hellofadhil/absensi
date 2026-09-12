# Absensi

Aplikasi Flutter untuk absensi sekolah SMK TI Bazma.

Project ini memakai Firebase Auth, Cloud Firestore, Riverpod, Geolocator, dan integrasi API hari libur Indonesia dari `https://libur.deno.dev/`.

## Dokumentasi

- [Project overview](docs/README.md)
- [Architecture](docs/architecture.md)
- [Attendance and holidays](docs/attendance-and-holidays.md)

## Fitur Utama

- Login dan auth gate.
- Home dengan status presensi hari ini.
- Presensi manual untuk hadir, sakit, dan izin.
- Validasi lokasi saat check-in hadir.
- Riwayat presensi bulanan dengan kalender.
- Tampilan daftar siswa untuk role guru.
- Penanda hari libur nasional/cuti bersama.
- Penonaktifan presensi saat tanggal merah.

## Struktur Singkat

```txt
lib/
  core/
  features/
    attendance/
    auth/
    home/
    profile/
  shared/
```

## Manual Verification

Command berat tidak dijalankan otomatis di project ini. Jalankan manual bila dibutuhkan:

```sh
flutter analyze
flutter test
flutter run
```
