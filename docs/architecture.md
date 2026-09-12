# Architecture

Project ini memakai pendekatan feature-first dengan pemisahan sederhana antara core, shared, dan feature.

## Core

`lib/core` berisi kode lintas fitur:

- `constants`: endpoint dan konstanta global.
- `errors`: exception umum aplikasi.
- `network`: client dan parser untuk kebutuhan request.
- `router`: route name dan route generator.
- `services`: service lintas fitur seperti lokasi, shared preferences, dan hari libur.
- `theme`: warna, typography, spacing, radius, shadow, dan controller tema.

## Shared

`lib/shared/widgets` berisi komponen UI yang dipakai banyak halaman, seperti:

- `AppScaffold`
- `AppTopBar`
- `AppBottomNavBar`
- `AppCard`
- `AppButton`
- `AppToast`
- `SectionHeader`

Gunakan widget shared sebelum membuat style baru di halaman.

## Features

`lib/features` berisi fitur utama aplikasi:

- `auth`: entity user, repository auth, provider auth, login page, auth gate.
- `attendance`: entity presensi, repository Firestore, provider Riverpod, halaman riwayat, daftar siswa, dan bottom sheet presensi.
- `home`: halaman utama setelah login.
- `profile`: halaman profil dan form edit profil.

## State Management

Project memakai Riverpod. Provider sebaiknya hanya mengoordinasikan state dan memanggil repository/service. Query Firestore langsung dari widget harus dihindari.

Contoh alur yang dipakai:

```txt
Widget
  -> Riverpod Provider
  -> Repository / Service
  -> Firebase / External API
```

## Routing

Route name dipusatkan di:

- `lib/core/router/route_names.dart`
- `lib/core/router/app_router.dart`

Jangan membuat string route baru langsung di widget jika route tersebut dipakai berulang.

## Data Persistence

Firestore menyimpan data user dan presensi. Struktur yang saat ini dipakai untuk presensi:

```txt
users/{uid}/attendance/{yyyy-MM-dd}
```

Field presensi:

```json
{
  "date": "ISO-8601 string",
  "status": "hadir | terlambat | sakit | izin | alpa | none",
  "checkInTime": "ISO-8601 string or null",
  "remarks": "string or null",
  "latitude": "number or null",
  "longitude": "number or null"
}
```

## Development Rules

- Jaga business logic tetap di provider/repository/service, bukan di widget besar.
- Tambahkan model/entity typed jika data mulai kompleks.
- Jangan hardcode endpoint baru di widget.
- Hindari dependency baru kecuali manfaatnya jelas.
- Jangan jalankan build/test/analyze otomatis tanpa izin eksplisit.

