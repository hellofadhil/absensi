import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../school/domain/entities/school_info.dart';
import '../../../school/presentation/providers/school_provider.dart';

class EditSchoolInfoPage extends ConsumerStatefulWidget {
  final SchoolInfo schoolInfo;

  const EditSchoolInfoPage({super.key, required this.schoolInfo});

  static Future<void> open(BuildContext context, SchoolInfo schoolInfo) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EditSchoolInfoPage(schoolInfo: schoolInfo),
      ),
    );
  }

  @override
  ConsumerState<EditSchoolInfoPage> createState() => _EditSchoolInfoPageState();
}

class _EditSchoolInfoPageState extends ConsumerState<EditSchoolInfoPage> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _npsnController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _lateTimeController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _addressController;
  late final TextEditingController _radiusController;

  bool _isSaving = false;
  bool _isLocatingCurrent = false;
  int _currentTab = 0; // 0: Profil Sekolah, 1: Lokasi & Presensi

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schoolInfo.name);
    _npsnController = TextEditingController(text: widget.schoolInfo.npsn);
    _startTimeController =
        TextEditingController(text: widget.schoolInfo.startTime);
    _lateTimeController =
        TextEditingController(text: widget.schoolInfo.lateTime);
    _latitudeController =
        TextEditingController(text: widget.schoolInfo.latitude.toString());
    _longitudeController =
        TextEditingController(text: widget.schoolInfo.longitude.toString());
    _addressController = TextEditingController(text: widget.schoolInfo.address);
    _radiusController =
        TextEditingController(text: widget.schoolInfo.radius.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _npsnController.dispose();
    _startTimeController.dispose();
    _lateTimeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _goToTab(int targetTab) {
    if (targetTab == 1) {
      final isValid = _formKey1.currentState?.validate() ?? false;
      if (!isValid) {
        AppToast.showError(
          context,
          title: 'Data Belum Lengkap',
          message: 'Harap lengkapi semua data wajib pada tab profil sekolah.',
        );
        return;
      }
    }
    setState(() => _currentTab = targetTab);
  }

  Future<void> _selectStartTime() async {
    final parts = _startTimeController.text.split(':');
    var hour = 7;
    var minute = 0;
    if (parts.length == 2) {
      hour = int.tryParse(parts[0]) ?? 7;
      minute = int.tryParse(parts[1]) ?? 0;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null && mounted) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => _startTimeController.text = '$h:$m');
    }
  }

  Future<void> _selectLateTime() async {
    final parts = _lateTimeController.text.split(':');
    var hour = 7;
    var minute = 15;
    if (parts.length == 2) {
      hour = int.tryParse(parts[0]) ?? 7;
      minute = int.tryParse(parts[1]) ?? 15;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null && mounted) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => _lateTimeController.text = '$h:$m');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocatingCurrent = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan GPS perangkat dinonaktifkan.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen di pengaturan.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Lokasi Ditemukan',
          message: 'Titik koordinat berhasil diperbarui dari GPS.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal Mendapatkan GPS',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingCurrent = false);
      }
    }
  }

  Future<void> _openGoogleMaps() async {
    final lat = double.tryParse(_latitudeController.text) ?? -6.4682054;
    final lng = double.tryParse(_longitudeController.text) ?? 106.8402422;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = await launchUrl(url, mode: LaunchMode.platformDefault);
        if (!fallback) {
          throw Exception('Gagal membuka link Google Maps.');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal',
          message: 'Tidak dapat membuka Google Maps: $e',
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      final cleanText = text.trim();
      if (cleanText.startsWith('http://') || cleanText.startsWith('https://')) {
        await _resolveCoordinatesFromUrl(cleanText);
        return;
      }
      if (_tryParseCoordinatesDirectly(cleanText)) {
        return;
      }
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Format Tidak Sesuai',
          message: 'Teks clipboard bukan koordinat valid atau link Maps.',
        );
      }
    } else {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Clipboard Kosong',
          message: 'Tidak ada teks pada clipboard untuk ditempel.',
        );
      }
    }
  }

  Future<void> _showLinkInputDialog() async {
    final controller = TextEditingController();
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      final clipText = clipboardData!.text!.trim();
      if (clipText.startsWith('http://') || clipText.startsWith('https://')) {
        controller.text = clipText;
      }
    }

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.appColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: Row(
            children: [
              Icon(Icons.link_rounded, color: dialogContext.appColors.primary),
              const SizedBox(width: 8),
              Text(
                'Parse Link Google Maps',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dialogContext.appColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan link bagikan Google Maps (contoh: https://maps.app.goo.gl/...)',
                style: TextStyle(
                  fontSize: 12,
                  color: dialogContext.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  fontSize: 13,
                  color: dialogContext.appColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'https://maps.app.goo.gl/...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: dialogContext.appColors.textMuted,
                  ),
                  prefixIcon: const Icon(Icons.map_outlined, size: 18),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste, size: 18),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        controller.text = data!.text!.trim();
                      }
                    },
                  ),
                  filled: true,
                  fillColor: dialogContext.appColors.surfaceSoft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogContext.appColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: const Text('Ekstrak Koordinat'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _resolveCoordinatesFromUrl(result);
    }
  }

  Future<void> _resolveCoordinatesFromUrl(String urlString) async {
    final cleanUrl = urlString.trim();
    if (_tryParseCoordinatesDirectly(cleanUrl)) {
      return;
    }

    setState(() => _isLocatingCurrent = true);
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(cleanUrl))
        ..followRedirects = true
        ..maxRedirects = 10
        ..headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        ..headers['Accept-Language'] = 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7';

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      final finalUrl = response.request?.url.toString() ?? cleanUrl;

      if (_tryParseCoordinatesDirectly(finalUrl)) return;
      if (_tryParseCoordinatesDirectly(response.body)) return;

      throw Exception(
          'Koordinat tidak dapat ditemukan dari link tersebut. Pastikan link Google Maps valid.');
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal Memproses Link',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingCurrent = false);
      }
    }
  }

  bool _tryParseCoordinatesDirectly(String text) {
    if (text.isEmpty) return false;

    // 1. !3d (lat) and !4d (lng)
    final d3Match = RegExp(r'!3d(-?\d+\.\d+)').firstMatch(text);
    final d4Match = RegExp(r'!4d(-?\d+\.\d+)').firstMatch(text);
    if (d3Match != null && d4Match != null) {
      _setCoordinates(d3Match.group(1)!, d4Match.group(1)!);
      return true;
    }

    // 2. @lat,lng
    final atMatch =
        RegExp(r'@(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)').firstMatch(text);
    if (atMatch != null) {
      _setCoordinates(atMatch.group(1)!, atMatch.group(2)!);
      return true;
    }

    // 3. place/lat,lng
    final pathMatch =
        RegExp(r'(?:place|dir|search)/(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)')
            .firstMatch(text);
    if (pathMatch != null) {
      _setCoordinates(pathMatch.group(1)!, pathMatch.group(2)!);
      return true;
    }

    // 4. query params
    final queryMatch = RegExp(
            r'[?&](?:q|query|ll|center|sll)=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)')
        .firstMatch(text);
    if (queryMatch != null) {
      _setCoordinates(queryMatch.group(1)!, queryMatch.group(2)!);
      return true;
    }

    // 5. staticmap
    final staticMapMatch = RegExp(
            r'staticmap\?[^"]*center=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)')
        .firstMatch(text);
    if (staticMapMatch != null) {
      _setCoordinates(staticMapMatch.group(1)!, staticMapMatch.group(2)!);
      return true;
    }

    // 6. center=
    final ogMatch = RegExp(r'center=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)')
        .firstMatch(text);
    if (ogMatch != null) {
      _setCoordinates(ogMatch.group(1)!, ogMatch.group(2)!);
      return true;
    }

    // 7. APP_INITIALIZATION_STATE
    final appStateMatch =
        RegExp(r'\[\[\[(-?\d+\.\d+),(-?\d+\.\d+)\]').firstMatch(text);
    if (appStateMatch != null) {
      _setCoordinates(appStateMatch.group(1)!, appStateMatch.group(2)!);
      return true;
    }

    // 8. Plain text lat, lng
    final plainMatch =
        RegExp(r'^\s*(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)\s*$').firstMatch(text);
    if (plainMatch != null) {
      _setCoordinates(plainMatch.group(1)!, plainMatch.group(2)!);
      return true;
    }

    return false;
  }

  void _setCoordinates(String lat, String lng) {
    setState(() {
      _latitudeController.text = lat;
      _longitudeController.text = lng;
    });
    if (mounted) {
      AppToast.showSuccess(
        context,
        title: 'Koordinat Diperbarui',
        message: 'Latitude: $lat, Longitude: $lng',
      );
    }
  }

  Future<void> _onSave() async {
    // Validate Tab 1
    final isValid1 = _formKey1.currentState?.validate() ?? false;
    if (!isValid1) {
      setState(() => _currentTab = 0);
      AppToast.showError(
        context,
        title: 'Profil Sekolah Belum Lengkap',
        message: 'Harap periksa data nama, NPSN, dan jam sekolah pada Tab 1.',
      );
      return;
    }

    // Validate Tab 2
    final isValid2 = _formKey2.currentState?.validate() ?? false;
    if (!isValid2) {
      setState(() => _currentTab = 1);
      AppToast.showError(
        context,
        title: 'Lokasi Belum Lengkap',
        message: 'Harap lengkapi alamat, radius, dan titik koordinat GPS.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedInfo = SchoolInfo(
        name: _nameController.text.trim(),
        npsn: _npsnController.text.trim(),
        startTime: _startTimeController.text.trim(),
        lateTime: _lateTimeController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        address: _addressController.text.trim(),
        radius: double.tryParse(_radiusController.text.trim()) ?? 50.0,
      );

      await ref.read(schoolInfoNotifierProvider.notifier).save(updatedInfo);

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Berhasil Disimpan!',
          message: 'Informasi sekolah dan radius presensi telah diperbarui.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal Menyimpan',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: 'Informasi Sekolah',
        subtitle: 'Pengaturan Profil & Radius Presensi',
        showBackButton: true,
        onBackTap: _isSaving ? null : () => Navigator.pop(context),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card (Style CompleteProfilePage)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.appColors.primary.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 28,
                          color: context.appColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengaturan Sekolah',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kelola identitas, waktu operasional, dan lokasi radius.',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Step Progress Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentTab == 0
                          ? 'Bagian 1: Profil & Jadwal Operasional'
                          : 'Bagian 2: Titik Lokasi & Radius Presensi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    Text(
                      _currentTab == 0 ? '50% Selesai' : '100% Selesai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.appColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _currentTab == 0 ? 0.5 : 1.0,
                    minHeight: 6,
                    backgroundColor: context.appColors.surfaceSoft,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(context.appColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Capsule 2-Tab Bar (Style CompleteProfilePage)
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Tab 1: Profil Sekolah
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _currentTab = 0),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _currentTab == 0
                                  ? context.appColors.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _currentTab == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 16,
                                  color: _currentTab == 0
                                      ? context.appColors.primary
                                      : context.appColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '1. Profil Sekolah',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _currentTab == 0
                                        ? context.appColors.primary
                                        : context.appColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Tab 2: Lokasi & Presensi
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _goToTab(1),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _currentTab == 1
                                  ? context.appColors.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _currentTab == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: _currentTab == 1
                                      ? context.appColors.primary
                                      : context.appColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '2. Lokasi & Presensi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _currentTab == 1
                                        ? context.appColors.primary
                                        : context.appColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Tab View Contents
                if (_currentTab == 0)
                  _buildTab1Profil()
                else
                  _buildTab2Lokasi(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── TAB 1: PROFIL & WAKTU SEKOLAH ───────────────────────────────────────

  Widget _buildTab1Profil() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_rounded,
                  size: 20, color: context.appColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Identitas Utama & Waktu Operasional',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 1. Nama Sekolah
          _buildTextField(
            label: 'Nama Sekolah *',
            controller: _nameController,
            icon: Icons.school_outlined,
            hint: 'Contoh: SMK Negeri 1 Jakarta',
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Nama sekolah wajib diisi';
              }
              if (v.trim().length < 3) {
                return 'Nama sekolah minimal 3 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Nomor NPSN
          _buildTextField(
            label: 'Nomor Pokok Sekolah Nasional (NPSN) *',
            controller: _npsnController,
            icon: Icons.tag,
            hint: 'Contoh: 20101234 (8 digit angka)',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'NPSN wajib diisi';
              }
              if (v.trim().length < 8) {
                return 'NPSN harus 8 digit angka';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Jam Masuk & Batas Keterlambatan
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Jam Masuk Sekolah *',
                  controller: _startTimeController,
                  icon: Icons.access_time_rounded,
                  hint: '07:00',
                  readOnly: true,
                  onTap: _selectStartTime,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  label: 'Batas Terlambat *',
                  controller: _lateTimeController,
                  icon: Icons.access_time_filled_rounded,
                  hint: '07:15',
                  readOnly: true,
                  onTap: _selectLateTime,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Button
          AppPrimaryButton(
            label: 'Lanjut ke Lokasi & Presensi',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _goToTab(1),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              side: BorderSide(color: context.appColors.border),
            ),
            child: Text(
              'Batal',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: LOKASI & RADIUS PRESENSI ─────────────────────────────────────

  Widget _buildTab2Lokasi() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pin_drop_rounded,
                  size: 20, color: context.appColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Alamat, Radius & Titik Koordinat GPS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 1. Alamat Lengkap
          _buildTextField(
            label: 'Alamat Lengkap Sekolah *',
            controller: _addressController,
            icon: Icons.location_on_outlined,
            hint: 'Jl. Nama Jalan No. XX, Kelurahan, Kecamatan, Kota',
            minLines: 3,
            maxLines: null,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Alamat sekolah wajib diisi';
              }
              if (v.trim().length < 5) {
                return 'Alamat sekolah terlalu pendek';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Radius Presensi
          _buildTextField(
            label: 'Radius Presensi (Meter) *',
            controller: _radiusController,
            icon: Icons.track_changes_rounded,
            hint: 'Contoh: 50',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Radius presensi wajib diisi';
              }
              final parsed = double.tryParse(v.trim());
              if (parsed == null || parsed <= 0) {
                return 'Radius harus berupa angka positif';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildRadiusQuickChips(),
          const SizedBox(height: AppSpacing.md),

          // 3. Latitude & Longitude
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Latitude *',
                  controller: _latitudeController,
                  icon: Icons.explore_outlined,
                  hint: '-6.4682054',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Harus diisi';
                    if (double.tryParse(v.trim()) == null) {
                      return 'Format salah';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  label: 'Longitude *',
                  controller: _longitudeController,
                  icon: Icons.explore_outlined,
                  hint: '106.8402422',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Harus diisi';
                    if (double.tryParse(v.trim()) == null) {
                      return 'Format salah';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. Action Tools Card (GPS, Maps, Clipboard, Link)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.appColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: context.appColors.border.withAlpha(80),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alat Bantu Titik Koordinat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isLocatingCurrent
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('GPS Akurat HP',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed:
                            _isLocatingCurrent ? null : _getCurrentLocation,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: const Text('Buka Gmaps',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: _openGoogleMaps,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.content_paste_rounded, size: 16),
                        label: const Text('Tempel Teks',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: _pasteFromClipboard,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.link_rounded, size: 16),
                        label: const Text('Parse Link Maps',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: _showLinkInputDialog,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Save Button
          AppPrimaryButton(
            label: _isSaving ? 'Menyimpan...' : 'Simpan Informasi Sekolah',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _isSaving ? null : _onSave,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Back to Tab 1
          OutlinedButton.icon(
            onPressed: _isSaving ? null : () => setState(() => _currentTab = 0),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Kembali ke Profil Sekolah'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              side: BorderSide(color: context.appColors.border),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusQuickChips() {
    final radiusOptions = [25, 50, 100, 200];
    final currentRadius =
        double.tryParse(_radiusController.text.trim())?.toInt();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: radiusOptions.map((radius) {
        final isSelected = currentRadius == radius;
        return ChoiceChip(
          label: Text('${radius}m',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? context.appColors.primary
                    : context.appColors.textSecondary,
              )),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _radiusController.text = radius.toString();
              });
            }
          },
          selectedColor: context.appColors.primary.withAlpha(30),
          backgroundColor: context.appColors.surfaceSoft,
          side: BorderSide(
            color: isSelected
                ? context.appColors.primary
                : context.appColors.border.withAlpha(80),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int? maxLines = 1,
    int? minLines,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: context.appColors.textMuted,
            ),
            prefixIcon: Icon(icon, size: 20, color: context.appColors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: context.appColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: context.appColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: context.appColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: context.appColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide(color: context.appColors.danger, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
