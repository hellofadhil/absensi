import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/services/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = await ThemeController.load();
  final sharedPrefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: AbsensiApp(themeController: themeController),
    ),
  );
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    return ThemeControllerScope(
      controller: themeController,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        builder: (context, themeMode, _) => MaterialApp(
          title: 'Absensi Sekolah',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          themeAnimationDuration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 240),
          themeAnimationCurve: Curves.easeOutCubic,
          initialRoute: RouteNames.home,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
