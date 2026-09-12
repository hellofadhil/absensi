# Attendance And Holidays

Dokumen ini menjelaskan alur presensi dan integrasi API hari libur.

## Alur Presensi

1. User login melalui Firebase Auth.
2. Home membaca status presensi hari ini dari `todayAttendanceProvider`.
3. Jika user belum presensi dan hari ini bukan libur, user dapat membuka `ManualAttendanceBottomSheet`.
4. Untuk status hadir, aplikasi meminta lokasi menggunakan Geolocator.
5. Jika lokasi valid, data disimpan ke Firestore melalui `AttendanceRepository`.
6. Provider presensi di-invalidate agar Home, riwayat, dan daftar siswa refresh.

## Status Presensi

Status tersedia di `AttendanceStatus`:

- `hadir`
- `terlambat`
- `sakit`
- `izin`
- `alpa`
- `none`

Status `terlambat` dihitung otomatis jika check-in hadir melewati batas jam masuk.

## Validasi Lokasi

Validasi lokasi dilakukan di bottom sheet presensi sebelum data dikirim. Saat ini aplikasi membandingkan posisi user dengan koordinat SMK TI Bazma dan radius maksimum yang ditentukan di kode.

Jika user berada di luar radius, aplikasi menampilkan dialog error dan tidak menyimpan presensi.

## Integrasi API Hari Libur

Endpoint dasar disimpan di:

```txt
lib/core/constants/api_endpoints.dart
```

Service berada di:

```txt
lib/core/services/holiday_service.dart
```

Endpoint yang dipakai:

```txt
GET https://libur.deno.dev/api/today
GET https://libur.deno.dev/api?year={year}
```

`/api/today` digunakan untuk menentukan apakah presensi hari ini perlu dinonaktifkan.

`/api?year={year}` digunakan untuk memberi tanda tanggal libur di kalender riwayat presensi.

## Perilaku Saat Hari Libur

Jika hari ini libur:

- Home menampilkan banner hari libur nasional atau cuti bersama.
- Kartu presensi menampilkan status hari libur.
- Tombol presensi di Home dinonaktifkan.
- Bottom sheet presensi menampilkan info libur.
- Submit presensi tetap dicegah dari sisi bottom sheet sebagai guard tambahan.

## Perilaku Jika API Gagal

Jika request API hari libur gagal, service mengembalikan data kosong/non-libur. Ini menjaga aplikasi tetap bisa dipakai, tetapi berarti aplikasi tidak otomatis memblokir presensi berdasarkan hari libur sampai API berhasil diakses.

## Pengembangan Lanjutan

Rekomendasi berikutnya:

- Tambahkan cache hasil libur tahunan agar kalender tetap informatif saat offline.
- Tambahkan unit test untuk parsing response holiday API.
- Pindahkan konfigurasi koordinat sekolah dan radius ke config terpusat.
- Tambahkan metadata `createdAt` dan `updatedAt` untuk dokumen presensi jika aturan data Firestore diperketat.

