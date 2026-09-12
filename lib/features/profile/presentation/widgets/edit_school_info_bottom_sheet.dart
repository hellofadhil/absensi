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
import '../../../../shared/widgets/app_toast.dart';
import '../../../school/domain/entities/school_info.dart';
import '../../../school/presentation/providers/school_provider.dart';

class EditSchoolInfoBottomSheet extends ConsumerStatefulWidget {
  final SchoolInfo schoolInfo;

  const EditSchoolInfoBottomSheet({super.key, required this.schoolInfo});

  static Future<void> show(BuildContext context, SchoolInfo schoolInfo) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditSchoolInfoBottomSheet(schoolInfo: schoolInfo),
    );
  }

  @override
  ConsumerState<EditSchoolInfoBottomSheet> createState() =>
      _EditSchoolInfoBottomSheetState();
}

class _EditSchoolInfoBottomSheetState
    extends ConsumerState<EditSchoolInfoBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _npsnController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _lateTimeController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _addressController;
  late final TextEditingController _radiusController;

  int _selectedTabIndex = 0; // 0: Profil Sekolah, 1: Lokasi & Radius
  bool _isSaving = false;
  bool _isLocatingCurrent = false;

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

  Future<void> _selectStartTime() async {
    final initialTimeParts = widget.schoolInfo.startTime.split(':');
    var initialHour = 7;
    var initialMinute = 0;
    if (initialTimeParts.length == 2) {
      initialHour = int.tryParse(initialTimeParts[0]) ?? 7;
      initialMinute = int.tryParse(initialTimeParts[1]) ?? 0;
    }
    final initialTime = TimeOfDay(hour: initialHour, minute: initialMinute);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime != null && mounted) {
      final hourStr = selectedTime.hour.toString().padLeft(2, '0');
      final minuteStr = selectedTime.minute.toString().padLeft(2, '0');
      _startTimeController.text = '$hourStr:$minuteStr';
    }
  }

  Future<void> _selectLateTime() async {
    final initialTimeParts = widget.schoolInfo.lateTime.split(':');
    var initialHour = 7;
    var initialMinute = 15;
    if (initialTimeParts.length == 2) {
      initialHour = int.tryParse(initialTimeParts[0]) ?? 7;
      initialMinute = int.tryParse(initialTimeParts[1]) ?? 15;
    }
    final initialTime = TimeOfDay(hour: initialHour, minute: initialMinute);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selectedTime != null && mounted) {
      final hourStr = selectedTime.hour.toString().padLeft(2, '0');
      final minuteStr = selectedTime.minute.toString().padLeft(2, '0');
      _lateTimeController.text = '$hourStr:$minuteStr';
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
          title: 'Sukses',
          message: 'Lokasi saat ini berhasil didapatkan.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal',
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
        final launchedFallback = await launchUrl(url, mode: LaunchMode.platformDefault);
        if (!launchedFallback) {
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
          title: 'Format Salah',
          message: 'Isi clipboard bukan koordinat valid atau link Maps.',
        );
      }
    } else {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Clipboard Kosong',
          message: 'Tidak ada teks untuk ditempel.',
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
              Expanded(
                child: Text(
                  'Parse Link Google Maps',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: dialogContext.appColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan atau tempel link Google Maps (misal: https://maps.app.goo.gl/...)',
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
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
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

      if (_tryParseCoordinatesDirectly(finalUrl)) {
        return;
      }

      if (_tryParseCoordinatesDirectly(response.body)) {
        return;
      }

      throw Exception(
          'Koordinat tidak dapat ditemukan dari link tersebut. Pastikan link Google Maps valid.');
    } catch (e) {
      if (mounted) {
        AppToast.showError(
          context,
          title: 'Gagal Resolusi Link',
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

    final d3Match = RegExp(r'!3d(-?\d+\.\d+)').firstMatch(text);
    final d4Match = RegExp(r'!4d(-?\d+\.\d+)').firstMatch(text);
    if (d3Match != null && d4Match != null) {
      _setCoordinates(d3Match.group(1)!, d4Match.group(1)!);
      return true;
    }

    final atMatch =
        RegExp(r'@(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)').firstMatch(text);
    if (atMatch != null) {
      _setCoordinates(atMatch.group(1)!, atMatch.group(2)!);
      return true;
    }

    final pathMatch =
        RegExp(r'(?:place|dir|search)/(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)')
            .firstMatch(text);
    if (pathMatch != null) {
      _setCoordinates(pathMatch.group(1)!, pathMatch.group(2)!);
      return true;
    }

    final queryMatch = RegExp(
            r'[?&](?:q|query|ll|center|sll)=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)')
        .firstMatch(text);
    if (queryMatch != null) {
      _setCoordinates(queryMatch.group(1)!, queryMatch.group(2)!);
      return true;
    }

    final staticMapMatch = RegExp(
            r'staticmap\?[^"]*center=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)')
        .firstMatch(text);
    if (staticMapMatch != null) {
      _setCoordinates(staticMapMatch.group(1)!, staticMapMatch.group(2)!);
      return true;
    }

    final ogMatch = RegExp(
            r'<meta\s+content="[^"]*staticmap\?[^"]*center=(-?\d+\.\d+)(?:%2C|,)(-?\d+\.\d+)[^"]*"\s+property="og:image"')
        .firstMatch(text);
    if (ogMatch != null) {
      _setCoordinates(ogMatch.group(1)!, ogMatch.group(2)!);
      return true;
    }

    final appStateMatch =
        RegExp(r'\[\[\[(-?\d+\.\d+),(-?\d+\.\d+)\]').firstMatch(text);
    if (appStateMatch != null) {
      _setCoordinates(appStateMatch.group(1)!, appStateMatch.group(2)!);
      return true;
    }

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
        title: 'Sukses',
        message: 'Koordinat ($lat, $lng) berhasil diekstrak.',
      );
    }
  }

  Future<void> _onSave() async {
    // Validasi field Tab 1 (Profil Sekolah)
    if (_nameController.text.trim().isEmpty) {
      setState(() => _selectedTabIndex = 0);
      AppToast.showError(context,
          title: 'Validasi', message: 'Nama sekolah tidak boleh kosong.');
      return;
    }
    if (_npsnController.text.trim().isEmpty) {
      setState(() => _selectedTabIndex = 0);
      AppToast.showError(context,
          title: 'Validasi', message: 'NPSN tidak boleh kosong.');
      return;
    }
    if (_startTimeController.text.trim().isEmpty ||
        _lateTimeController.text.trim().isEmpty) {
      setState(() => _selectedTabIndex = 0);
      AppToast.showError(context,
          title: 'Validasi',
          message: 'Jam masuk dan batas keterlambatan wajib diisi.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      setState(() => _selectedTabIndex = 0);
      AppToast.showError(context,
          title: 'Validasi',
          message: 'Alamat lengkap sekolah tidak boleh kosong.');
      return;
    }

    // Validasi field Tab 2 (Lokasi & Radius)
    final radius = double.tryParse(_radiusController.text.trim());
    if (radius == null || radius <= 0) {
      setState(() => _selectedTabIndex = 1);
      AppToast.showError(context,
          title: 'Validasi',
          message: 'Radius absensi harus berupa angka positif.');
      return;
    }

    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());
    if (lat == null || lng == null) {
      setState(() => _selectedTabIndex = 1);
      AppToast.showError(context,
          title: 'Validasi',
          message: 'Koordinat Latitude dan Longitude harus angka valid.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedInfo = SchoolInfo(
        name: _nameController.text.trim(),
        npsn: _npsnController.text.trim(),
        startTime: _startTimeController.text.trim(),
        lateTime: _lateTimeController.text.trim(),
        latitude: lat,
        longitude: lng,
        address: _addressController.text.trim(),
        radius: radius,
      );

      await ref.read(schoolInfoNotifierProvider.notifier).save(updatedInfo);

      if (mounted) {
        AppToast.showSuccess(
          context,
          title: 'Sukses',
          message: 'Informasi sekolah berhasil diperbarui.',
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
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: AppSpacing.xl + mediaQuery.viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Drag Indicator
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header Title + Close Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Perbarui Informasi Sekolah',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Segmented Tabs Pill
            _buildSegmentedTabBar(),
            const SizedBox(height: AppSpacing.md),

            // Scrollable Tab Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedTabIndex == 0)
                        _buildProfileTabContent()
                      else
                        _buildLocationTabContent(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Action Buttons (Batal & Simpan)
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Batal',
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: _isSaving
                      ? Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.appColors.primary,
                              ),
                            ),
                          ),
                        )
                      : AppPrimaryButton(
                          label: 'Simpan',
                          onPressed: _onSave,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTabBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: context.appColors.border.withAlpha(90),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? context.appColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.button - 4),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: context.appColors.primary.withAlpha(40),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 15,
                      color: _selectedTabIndex == 0
                          ? context.appColors.textInverse
                          : context.appColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Profil Sekolah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 0
                              ? context.appColors.textInverse
                              : context.appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? context.appColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.button - 4),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: context.appColors.primary.withAlpha(40),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: _selectedTabIndex == 1
                          ? context.appColors.textInverse
                          : context.appColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Lokasi & Radius',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 1
                              ? context.appColors.textInverse
                              : context.appColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTabContent() {
    return Column(
      key: const ValueKey<int>(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nama Sekolah
        _buildTextField(
          label: 'Nama Sekolah',
          controller: _nameController,
          icon: Icons.school_outlined,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Nama sekolah tidak boleh kosong'
              : null,
        ),
        const SizedBox(height: AppSpacing.md),

        // NPSN
        _buildTextField(
          label: 'NPSN',
          controller: _npsnController,
          icon: Icons.tag_rounded,
          keyboardType: TextInputType.number,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'NPSN tidak boleh kosong' : null,
        ),
        const SizedBox(height: AppSpacing.md),

        // Jam Masuk & Batas Keterlambatan
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Jam Masuk',
                controller: _startTimeController,
                icon: Icons.access_time_rounded,
                readOnly: true,
                onTap: _selectStartTime,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildTextField(
                label: 'Batas Keterlambatan',
                controller: _lateTimeController,
                icon: Icons.timer_outlined,
                readOnly: true,
                onTap: _selectLateTime,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Alamat Lengkap Sekolah
        _buildTextField(
          label: 'Alamat Lengkap Sekolah',
          controller: _addressController,
          icon: Icons.location_on_outlined,
          maxLines: 2,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Alamat tidak boleh kosong'
              : null,
        ),
      ],
    );
  }

  Widget _buildLocationTabContent() {
    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Radius Absensi (meter)
        _buildTextField(
          label: 'Radius Absensi (meter)',
          controller: _radiusController,
          icon: Icons.radar_rounded,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Radius absensi tidak boleh kosong';
            }
            if (double.tryParse(v.trim()) == null) {
              return 'Radius harus berupa angka';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        _buildRadiusQuickChips(),
        const SizedBox(height: AppSpacing.md),

        // Koordinat Latitude & Longitude
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Latitude',
                controller: _latitudeController,
                icon: Icons.explore_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Harus diisi';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Format salah';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildTextField(
                label: 'Longitude',
                controller: _longitudeController,
                icon: Icons.explore_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Harus diisi';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Format salah';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Helper Action Buttons for Location
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isLocatingCurrent
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, size: 14),
                    label: const Flexible(
                      child: Text(
                        'Lokasi GPS HP',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onPressed:
                        _isLocatingCurrent ? null : _getCurrentLocation,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map_rounded, size: 14),
                    label: const Flexible(
                      child: Text(
                        'Buka Gmaps',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onPressed: _openGoogleMaps,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
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
                    icon: const Icon(Icons.content_paste_rounded, size: 14),
                    label: const Flexible(
                      child: Text(
                        'Tempel Clipboard',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onPressed: _pasteFromClipboard,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.link_rounded, size: 14),
                    label: const Flexible(
                      child: Text(
                        'Parse Link Maps',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onPressed: _showLinkInputDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
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
      ],
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
          label: Text(
            '${radius}m',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? context.appColors.primary
                  : context.appColors.textSecondary,
            ),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
    int? maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
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
          enabled: !_isSaving,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: context.appColors.textSecondary, size: 20),
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
              borderSide:
                  BorderSide(color: context.appColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
