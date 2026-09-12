Berikut adalah rekapan menyeluruh mengenai kapabilitas aplikasi Absensi (SMK TI Bazma / E-AbsensiQu) saat ini, apa saja yang sudah 
  berfungsi, bagian yang masih berupa mockup, serta rekomendasi komprehensif untuk pengembangan fitur admin dan rencana pembuatan    
  Dashboard Admin berbasis Next.js.                                                                                                  
  ──────                                                                                                                             
  ## 1. Rekapan: Aplikasi Ini Bisa Ngapain Aja & Apa yang Sudah Berjalan?                                                            
                                                                                                                                     
  Arsitektur aplikasi mobile saat ini dibangun menggunakan Flutter + Riverpod, terhubung langsung ke Firebase Auth dan Cloud         
  Firestore, serta dilengkapi integrasi layanan eksternal (API Hari Libur Indonesia & Kora Drive Cloud Storage).                     
                                                                                                                                     
  Secara garis besar, aplikasi ini memiliki 3 peran (multi-role): Siswa, Guru, dan Admin.                                            
                                                                                                                                     
  ### 📱 A. Sisi Siswa (Student)                                                                                                     
                                                                                                                                     
  • Autentikasi & Profil:                                                                                                            
      • Login dengan Email & Password dengan validasi keberadaan akun di Firestore.                                                  
      • Tampilan profil lengkap: NISN, kelas, jurusan, kontak orang tua/wali, alamat, dan tanggal lahir (profile_page.dart).         
      • Edit biodata profil mandiri melalui modal sheet (edit_profile_bottom_sheet.dart).                                            
  • Presensi Mandiri (Check-in):                                                                                                     
      • Opsi status kehadiran: Hadir, Sakit, dan Izin (manual_attendance_bottom_sheet.dart).                                         
      • Geofencing & GPS Validation: Check-in hadir memvalidasi koordinat GPS perangkat terhadap radius sekolah SMK TI Bazma secara  
      real-time via Geolocator.                                                                                                      
      • Kalkulasi Keterlambatan Otomatis: Jika siswa check-in hadir melewati batas jam masuk (misal > 07:15 WIB), status otomatis    
      tercatat sebagai Terlambat.                                                                                                    
      • Upload Bukti Surat Izin/Sakit: Mendukung pengambilan foto dari kamera atau galeri, yang otomatis diunggah ke storage cloud   
      Kora Drive (kora_drive_service.dart).                                                                                          
      • Integrasi Hari Libur: Terhubung ke API https://libur.deno.dev/api/today (holiday_service.dart). Saat tanggal merah / cuti    
      bersama, sistem menampilkan banner libur dan mengunci tombol presensi.                                                         
  • Riwayat Presensi:                                                                                                                
      • Kalender interaktif bulanan dengan indikator warna untuk masing-masing status kehadiran (attendance_history_page.dart).      
      • Statistik agregat bulanan (jumlah Hadir, Terlambat, Sakit, Izin, dan Alpa).                                                  
                                                                                                                                     
  ──────                                                                                                                             
  ### 👨‍🏫 B. Sisi Guru (Teacher)                                                                                                      
                                                                                                                                     
  • Monitoring Kehadiran Siswa Hari Ini:                                                                                             
      • Beranda guru menampilkan kartu ringkasan kehadiran seluruh siswa secara teragregasi (teacher_home_view.dart).                
      • Daftar seluruh siswa per kelas dengan status presensinya hari ini (student_list_page.dart).                                  
      • Tombol aksi cepat (quick action) untuk menghubungi siswa/wali murid via WhatsApp / panggilan telepon langsung dari aplikasi. 
  • Presensi Mandiri Guru: Guru juga memiliki alur presensi datang/pulang mandiri.                                                   
  ──────                                                                                                                             
  ### 🛡️ C. Sisi Admin Saat Ini (Mobile App)                                                                                         
                                                                                                                                     
  • Dashboard Beranda Admin:                                                                                                         
      • Tab beralih cepat antara Rekap Siswa dan Rekap Guru hari ini (admin_home_view.dart).                                         
      • Menampilkan statistik real-time: Hadir, Terlambat, Sakit/Izin, Alpa, dan Belum Presensi.                                     
      • Ringkasan aktivitas anomali disiplin harian (daftar siswa/guru yang terlambat atau alpa).                                    
  • Database Master Data Sekolah (database_page.dart):                                                                               
      • Manajemen Siswa: Daftar siswa dikelompokkan rapi per ruang kelas dengan fitur pencarian nama/email.                          
      • Manajemen Guru: Daftar guru beserta mata pelajaran/jabatan dan email.                                                        
      • Manajemen Ruang Kelas: Visualisasi kapasitas kelas (progress bar jumlah siswa vs kuota) dan informasi guru wali kelas.       
      • CRUD yang Sudah Berfungsi:                                                                                                   
          • Tambah siswa baru (add_student_bottom_sheet.dart) menggunakan secondary Firebase App agar admin tidak ter-logout.        
          • Tambah guru baru (add_teacher_bottom_sheet.dart).                                                                        
          • Tambah & Edit Ruang Kelas (add_edit_classroom_bottom_sheet.dart) termasuk penugasan Wali Kelas.                          
          • Hapus pengguna (siswa/guru) dan hapus ruang kelas langsung dari Firestore.                                               
                                                                                                                                     
  • Konfigurasi Sekolah & Geofencing:                                                                                                
      • Admin dapat mengubah nama sekolah, NPSN, jam masuk, batas toleransi telat, titik koordinat GPS (latitude, longitude), radius 
      presensi (meter), dan alamat sekolah melalui edit_school_info_bottom_sheet.dart.                                               
  • Keamanan Data:                                                                                                                   
      • Memiliki aturan keamanan Firestore bertingkat (firestore.rules) yang memastikan siswa tidak bisa memodifikasi presensi siswa 
      lain atau merusak data master.                                                                                                 
                                                                                                                                     
  ──────                                                                                                                             
  ## 2. Bagian yang Masih Menjadi Keterbatasan / Masih Mockup Saat Ini                                                               
                                                                                                                                     
  1. Halaman Laporan (LaporanPage):                                                                                                  
      • Masih menggunakan angka dan grafik mingguan statis (hardcoded).                                                              
      • Tombol "Unduh Laporan PDF/Excel" masih berupa fungsi kosong (onPressed: () {}).                                              
  2. Aksi Manajemen Siswa Tertentu:                                                                                                  
      • Opsi "Edit Data" dan "Pindah Kelas" pada menu siswa di database sekolah masih menampilkan dialog "Segera Hadir!".            
  3. Manajemen Akun:                                                                                                                 
      • Tombol "Ubah Kata Sandi" di halaman profil belum memiliki logika ubah password/reset link.                                   
  4. Menu Jadwal:                                                                                                                    
      • Tab navigasi Jadwal untuk siswa masih berupa placeholder toast info.                                                         
  5. Alur Validasi Surat Izin/Sakit:                                                                                                 
      • Siswa sudah bisa mengunggah surat dokter/izin, tetapi belum ada modul bagi guru/admin untuk melakukan Approve / Reject surat 
      tersebut.                                                                                                                      
                                                                                                                                     
  ──────                                                                                                                             
  ## 3. Rekomendasi Fitur yang Harus Ditambahkan (Fokus Kebutuhan Admin)                                                             
                                                                                                                                     
  Berikut fitur-fitur krusial yang idealnya tersedia bagi administrator sekolah:                                                     
                                                                                                                                     
   Area                                 │ Fitur yang Direkomendasikan                 │ Nilai Manfaat
  ──────────────────────────────────────┼─────────────────────────────────────────────┼──────────────────────────────────────────────
   Alur Persetujuan (Approval Workflow) │ Verifikasi Surat Izin / Sakit               │ Admin atau Wali Kelas dapat melihat berkas
                                        │                                             │ foto surat dokter yang diupload siswa, lalu
                                        │                                             │ memberi keputusan: Approved (status tetap
                                        │                                             │ Sakit/Izin) atau Rejected (otomatis berubah
                                        │                                             │ jadi Alpa).
   Rekapitulasi & Pelaporan             │ Export Laporan Otomatis (Excel & PDF)       │ Export rekap absensi per tanggal, mingguan,
                                        │                                             │ bulanan, atau per semester per kelas yang
                                        │                                             │ siap cetak untuk laporan wali kelas & dinas
                                        │                                             │ pendidikan.
   Operasional Akademik                 │ Fitur Pindah & Kenaikan Kelas Massal (Bulk  │ Memindahkan seluruh siswa kelas X ke XI saat
                                        │ Promotion)                                  │ pergantian tahun ajaran baru tanpa perlu
                                        │                                             │ edit satu per satu.
   Import Data Massal                   │ Import Siswa/Guru via Excel/CSV             │ Memudahkan input 100+ siswa baru sekaligus
                                        │                                             │ saat penerimaan murid baru (PPDB).
   Kedisiplinan & Notifikasi            │ Push Notification Pengingat (FCM)           │ Pengingat otomatis pada pukul 06.45 WIB ke
                                        │                                             │ HP siswa yang belum melakukan check-in.
   Koreksi Absensi                      │ Manual Override / Penyesuaian Status        │ Jika ada kendala teknis (misal GPS HP siswa
                                        │                                             │ bermasalah atau siswa izin mendadak via
                                        │                                             │ telepon), admin/guru bisa mengubah status
                                        │                                             │ presensi siswa secara manual disertai alasan
                                        │                                             │ perubahan.
   Keamanan & Audit                     │ Audit Trail / Activity Log                  │ Catatan log setiap kali ada akun yang
                                        │                                             │ dibuat, dihapus, atau status absensi yang
                                        │                                             │ diubah manual oleh admin/guru.
  ──────                                                                                                                             
  ## 4. Rencana Dashboard Admin Berbasis Next.js                                                                                     
                                                                                                                                     
  Keputusan Anda untuk membuat Dashboard Admin terpisah menggunakan Next.js adalah langkah yang sangat tepat.                        
                                                                                                                                     
  ### Mengapa Next.js untuk Admin Dashboard?                                                                                         
                                                                                                                                     
  • Efisiensi Kerja Staf Tata Usaha / Admin: Mengelola ratusan data siswa, ruang kelas, melihat tabel lebar, dan mencetak laporan    
  jauh lebih nyaman di layar desktop / PC daripada layar smartphone.                                                                 
  • Keamanan Lebih Terjamin: Menggunakan Firebase Admin SDK di Next.js Server Components / Route Handlers, sehingga pembuatan akun   
  siswa massal atau modifikasi data penting dapat diproses di server-side dengan hak akses admin tanpa bergantung pada koneksi atau  
  batasan client mobile.                                                                                                             
  • Ekspor Dokumen Cepat: Pembuatan laporan spreadsheet (.xlsx) dan PDF jauh lebih cepat dan fleksibel di lingkungan Node.js/Next.js.
  ──────                                                                                                                             
  ### 📐 Arsitektur Dashboard Next.js                                                                                                
                                                                                                                                     
    ┌─────────────────────────────────────────────────────────┐                                                                      
    │              Next.js 14/15 (App Router)                 │                                                                      
    │                                                         │                                                                      
    │  ┌────────────────────┐       ┌──────────────────────┐  │                                                                      
    │  │   Server Actions   │       │ API Route Handlers   │  │                                                                      
    │  │   / Server Comps   │       │ (Export, Webhooks)   │  │                                                                      
    │  └─────────┬──────────┘       └──────────┬───────────┘  │                                                                      
    │            │                             │              │                                                                      
    │            ▼                             ▼              │                                                                      
    │  ┌───────────────────────────────────────────────────┐  │                                                                      
    │  │               Firebase Admin SDK                  │  │                                                                      
    │  │  - Auth (Custom Claims: role='admin')             │  │                                                                      
    │  │  - Cloud Firestore (Bypass client rules aman)     │  │                                                                      
    │  └───────────────────────┬───────────────────────────┘  │                                                                      
    └──────────────────────────┼──────────────────────────────┘                                                                      
                               ▼                                                                                                     
              ┌──────────────────────────────────┐                                                                                   
              │     Cloud Firestore Database     │                                                                                   
              │  users / classRooms / attendance │                                                                                   
              └──────────────────────────────────┘                                                                                   
  ──────                                                                                                                             
  ### 🗂️ Modul & Halaman yang Perlu Ada di Dashboard Next.js                                                                         
                                                                                                                                     
  1. Dashboard Analytics & Real-time Live Feed:                                                                                      
      • Kartu ringkasan kehadiran hari ini (Tingkat kehadiran %, siswa hadir, terlambat, sakit, alpa).                               
      • Grafik tren kehadiran mingguan dan bulanan (menggunakan Recharts / Chart.js).                                                
      • Feed langsung (live ticker) yang menampilkan siswa/guru yang baru saja check-in beserta jamnya.                              
  2. Data Induk Siswa & Guru (Master Data):                                                                                          
      • Tabel interaktif dengan pencarian, filter kelas, dan sorting (menggunakan TanStack Table).                                   
      • Formulir Tambah/Edit Data Siswa & Guru.                                                                                      
      • Fitur Import Excel/CSV untuk menambah data siswa secara massal.                                                              
      • Tombol Reset Password akun siswa/guru.                                                                                       
  3. Manajemen Ruang Kelas & Wali Kelas:                                                                                             
      • Daftar kelas, penentuan kapasitas, dan penugasan guru wali kelas.                                                            
      • Fitur naik kelas / ganti kelas massal.                                                                                       
  4. Verifikasi Izin & Sakit (Inbox Approval):                                                                                       
      • Menampilkan daftar siswa yang mengajukan izin/sakit hari ini.                                                                
      • Pratinjau langsung bukti surat dokter/izin yang tersimpan di Kora Drive.                                                     
      • Tombol aksi Setujui atau Tolak.                                                                                              
  5. Pusat Rekap & Cetak Laporan (Report Center):                                                                                    
      • Filter fleksibel: Berdasarkan Rentang Tanggal, Kelas, atau Individu Siswa.                                                   
      • Ekspor 1-klik ke format Microsoft Excel (.xlsx) dan PDF Rekap Presensi.                                                      
  6. Pengaturan Sekolah & Geofencing:                                                                                                
      • Peta interaktif (Leaflet / Google Maps) untuk menentukan titik koordinat sekolah dan visualisasi lingkaran radius toleransi  
      presensi (geofence).                                                                                                           
      • Konfigurasi jam masuk sekolah dan batas toleransi terlambat.                                                                 
                                                                                                                                     
  ──────                                                                                                                             
  ### 🛠️ Rekomendasi Tech Stack untuk Next.js Dashboard                                                                              
                                                                                                                                     
  • Framework: Next.js (App Router) + TypeScript                                                                                     
  • UI Components: Tailwind CSS + shadcn/ui (sangat modern, bersih, dan cepat dikembangkan)                                          
  • Tabel & Data Grid: @tanstack/react-table (sorting, filtering, pagination)                                                        
  • Visualisasi Grafik: recharts                                                                                                     
  • Firebase Backend: firebase-admin (untuk server-side queries & authentication token verification)                                 
  • Export File: exceljs atau xlsx (Excel) dan @react-pdf/renderer atau jspdf (PDF)                                                  
  • Peta Geofence: react-leaflet atau leaflet                                                                                        
  ──────                                                                                                                             
  ### Langkah Selanjutnya yang Bisa Kita Lakukan:                                                                                    
                                                                                                                                     
  1. Langkah 1: Menyempurnakan sisa fungsi edit data siswa/guru di aplikasi mobile saat ini (atau memperbaiki pengujian unit test).  
  2. Langkah 2: Menyiapkan struktur folder dan fondasi project Next.js untuk Dashboard Admin yang langsung terhubung ke database     
  Firebase project ini.                                                                                                              
                                                                                                                                     
  Bagian mana yang ingin Anda prioritaskan terlebih dahulu?    