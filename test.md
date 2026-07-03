Ya, saya sangat memahami struktur dari proyek ini.                                                                              
                                                                                                                                  
  Berdasarkan analisis saya, proyek ini menggunakan arsitektur Feature-First (khas Flutter modular) yang memisahkan aplikasi      
  berdasarkan fitur-fitur utamanya. Saat ini, template tersebut dikonfigurasi sebagai aplikasi belajar bahasa Inggris dengan      
  beberapa bagian penting:                                                                                                        
                                                                                                                                  
  ### 1. Struktur Folder & Kode Saat Ini:                                                                                         
                                                                                                                                  
  •  lib/main.dart : Titik masuk utama aplikasi yang memanggil  EnglishLearningApp  dengan pengaturan tema ( ThemeController ) dan
  Text-to-Speech ( TtsService ).                                                                                                  
  •  lib/core/ : Berisi konfigurasi global seperti rute ( lib/core/router/app_router.dart  &  route_names.dart ) serta tema       
  warna/tipografi.                                                                                                                
  •  lib/features/ : Saat ini berisi fitur bertema bahasa Inggris seperti  ai_coach ,  listening_lab ,  mock_interview ,          
  role_play ,  tiny_lesson , dll.                                                                                                 
  •  lib/shared/ : Berisi widget kustom yang bisa dipakai di mana saja (seperti  AppBottomNavBar ,  AppCard ,  AppScaffold ).     
  ──────                                                                                                                          
  ### Rencana Migrasi ke Sistem Absensi Sekolah (Sistem Absensi)                                                                  
                                                                                                                                  
  Kita bisa memodifikasi template ini agar sesuai dengan kebutuhan sistem absensi sekolah. Berikut adalah langkah-langkah yang    
  saya sarankan:                                                                                                                  
                                                                                                                                  
  #### Langkah 1: Pembersihan & Umbi (Cleanup & Rename)                                                                           
                                                                                                                                  
  1. Ubah identitas aplikasi di  pubspec.yaml  (dari  name: english  menjadi  name: absensi  atau nama lain).                     
  2. Bersihkan dependencies yang tidak diperlukan (seperti  flutter_tts  atau  speech_to_text  jika tidak digunakan untuk absensi)
  dan tambahkan package baru jika diperlukan (seperti  qr_code_scanner ,  geolocator  untuk presensi berbasis lokasi/GPS, atau    
  camera  jika ingin absensi swafoto).                                                                                            
  3. Hapus fitur bertema bahasa Inggris yang tidak diperlukan di  lib/features/  dan ganti dengan folder fitur baru.              
                                                                                                                                  
  #### Langkah 2: Buat Fitur Baru untuk Absensi                                                                                   
                                                                                                                                  
  Sesuai dengan arsitektur Feature-First, kita akan membagi sistem absensi ke beberapa fitur di dalam  lib/features/ :            
                                                                                                                                  
  1.  auth : Halaman masuk (Login) untuk Guru, Siswa, atau Admin.                                                                 
  2.  home : Dashboard utama untuk Guru/Siswa (menampilkan status hari ini, riwayat singkat, dan tombol pintas absensi).          
  3.  attendance : Halaman untuk melakukan absensi (bisa berupa tombol scan QR, absensi manual, absensi dengan validasi           
  GPS/koordinat sekolah, atau kamera/swafoto).                                                                                    
  4.  history : Riwayat presensi (Sakit, Izin, Hadir, Alfa) dalam bentuk kalender atau list.                                      
  5.  class_management  (Khusus Guru/Admin): Mengelola data kelas dan siswa yang hadir hari ini.                                  
                                                                                                                                  
  #### Langkah 3: Integrasi Database & Autentikasi                                                                                
                                                                                                                                  
  Sesuai aturan di AGENTS.md, kita akan menggunakan:                                                                         
                                                                                                                                  
  • Firebase Auth: Untuk login guru dan murid.                                                                                    
  • Cloud Firestore: Database untuk menyimpan riwayat kehadiran, data siswa, kelas, dan jadwal pelajaran.                         
  • State Management (Riverpod): Untuk mengatur state halaman absensi agar reaktif dan bersih dari business logic di bagian UI.   
  ──────                                                                                                                          
  ### Bagaimana Kita Ingin Memulainya?                                                                                            
                                                                                                                                  
  Untuk memulainya, boleh tolong konfirmasikan beberapa hal berikut:                                                              
                                                                                                                                  
  1. Metode Presensi: Bagaimana cara siswa melakukan absensi? Apakah mereka memindai QR code, divalidasi dengan GPS/Lokasi,       
  menggunakan swafoto (selfie), atau guru yang mencentang kehadirannya secara manual di aplikasi?                                 
  2. Peran Pengguna (Roles): Apakah aplikasi ini akan digunakan oleh Siswa saja, Guru saja, atau Keduanya (dengan tampilan        
  dashboard yang berbeda setelah login)?                                                                                          
  3. Langkah Pertama: Apakah Anda ingin kita mulai dengan membersihkan kode-kode bahasa Inggris lama di  lib/features/  terlebih  
  dahulu dan menyiapkan struktur folder baru?  