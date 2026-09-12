Berdasarkan analisis menyeluruh terhadap arsitektur, kualitas kode, pengujian, dan fitur aplikasi Absensi (E-     
  AbsensiQu) saat ini, berikut adalah poin-poin peningkatan (improvements) yang direkomendasikan:                   
  ──────                                                                                                            
  ### 1. 🏗️ Arsitektur & Refactoring Kode                                                                           
                                                                                                                    
  • Refactoring File Monolitik (home_page.dart)                                                                     
      • Masalah: File home_page.dart memiliki ~1.960 baris kode yang menggabungkan logika tampilan untuk 3 peran    
      (role): Siswa, Guru, dan Admin.                                                                               
      • Saran: Pecah menjadi file tampilan terpisah berdasarkan peran (StudentHomeView, TeacherHomeView,            
      AdminHomeView) dan ekstrak widget kecil seperti GreetingCard, AttendanceStatusCard, dan WeeklySummaryCard ke  
      komponen tersendiri agar kode lebih terstruktur dan mudah dirawat.                                            
                                                                                                                    
  ──────                                                                                                            
  ### 2. ⚡ Pembersihan Kode Legacy & Perbaikan Warning (flutter analyze)                                           
                                                                                                                    
  • Pembersihan Kode Sisa Template (Dead Code)                                                                      
      • Masalah: File di  (ai_prompt_api_client.dart, ai_prompt_transport_factory_web.dart) dan test pendukungnya   
      tidak digunakan dalam fitur absensi serta menggunakan dart:html yang memicu peringatan lint.                  
      • Saran: Hapus seluruh file network AI legacy tersebut.                                                       
  • Perbaikan Deprecated API & Lint Warning                                                                         
      • Geolocator: Penggunaan desiredAccuracy dan timeLimit pada manual_attendance_bottom_sheet.dart sudah         
      deprecated. Perbarui dengan LocationSettings.                                                                 
      • Color.withOpacity: Ganti method .withOpacity() yang deprecated pada Flutter SDK terbaru dengan .            
      withValues(alpha: ...).                                                                                       
      • Null-aware Elements: Gunakan syntax null-aware ? pada app_scaffold.dart.                                    
                                                                                                                    
  ──────                                                                                                            
  ### 3. 🚀 Peningkatan Fitur Aplikasi (Feature Enhancements)                                                       
                                                                                              
                                                                             
                                                                                           
  • Ekspor Laporan Presensi (PDF / Excel)                                                                           
      • Tambahkan fitur ekspor rekap presensi bulanan/mingguan untuk Guru dan Admin ke dalam format PDF atau        
      Spreadsheet (.xlsx).                                                                                          
  • Notifikasi Pengingat (Firebase Cloud Messaging - FCM)                                                           
      • Integrasikan FCM untuk mengirimkan push notification pengingat presensi pagi (misal pukul 06.45 WIB) kepada 
      siswa yang belum melakukan check-in.                                                                          
                                                                                                                    
  ──────                                                                                                            
  ### 4. 🔐 Keamanan & Aturan Database (Firestore Security Rules)                                                   
                                                                                                                    
  • Penerapan firestore.rules                                                                                       
      • Saat ini keamanan data bertumpu pada validasi client-side.                                                  
      • Saran: Buat file firestore.rules untuk memverifikasi bahwa:                                                 
          • Siswa hanya dapat membaca dan menulis data presensi milik mereka sendiri (users/{uid}/attendance/{date}).
          • Hanya role guru dan admin yang dapat membaca atau mengubah status presensi seluruh siswa di kelasnya.   
                                                                                                            
  ──────                                                                                                            
  ### 5. 🧪 Pengujian Otomatis (Automated Testing)                                                                  
                                                                                                                    
  • Cakupan Unit Test & Provider Test                                                                               
      • Saat ini pengujian baru mencakup 1 test widget dasar di widget_test.dart.                                   
      • Saran: Tambahkan unit test untuk service & provider utama:                                                  
          • holiday_service.dart (pengujian fetching API hari libur nasional).                                      
          • location_service.dart (pengujian kalkulasi jarak GPS).                                                  
          • attendance_repository_impl.dart (mocking Firestore call).                                               
                                                                                                                    
                                                                                                                    
  ──────                                                                                                            
  ### 6. 🎨 UI/UX & Pengalaman Pengguna                                                                             
                                                                                                                    
                                                                              
                                                                                                    
  Sebagai catatan tambahan, dari hasil eksekusi pengujian otomatis (flutter test), ditemukan juga bahwa pengujian di
  **widget_test.dart** saat ini mengalami kegagalan (error):                                                        
                                                                                                                    
    Tried to use a provider that is in error state:                                                                 
    [core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()                      
                                                                                                                    
  ### 🛠️ Poin Perbaikan Pengujian Tambahan:                                                                         
                                                                                                                    
  • Mocking Firebase pada Unit & Widget Test:                                                                       
      • widget_test.dart mencoba me-render AbsensiApp yang mengakses authProvider -> AuthRepositoryImpl ->          
      FirebaseAuth.instance. Namun, pada environment unit/widget test Flutter, instance Firebase belum              
      diinisialisasi atau di-mock.                                                                                  
      • Solusi: Lakukakan override provider authRepositoryProvider di unit/widget test dengan MockAuthRepository    
      atau berikan mock implementation (seperti fake_cloud_firestore dan firebase_auth_mocks) agar pengujian        
      tampilan UI tidak bergantung pada Firebase SDK asli.     