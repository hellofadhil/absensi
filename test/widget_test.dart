import 'package:absensi/main.dart';
import 'package:absensi/core/theme/theme_controller.dart';
import 'package:absensi/core/services/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('theme toggle changes the app theme immediately', (tester) async {
    // Pre-cache mock logged-in user so AuthGate opens HomePage instead of LoginPage
    SharedPreferences.setMockInitialValues({
      'cached_user': '{"uid":"siswa-456","email":"siswa@sekolah.com","displayName":"Fadhil","role":"siswa"}'
    });

    final prefs = await SharedPreferences.getInstance();
    final controller = ThemeController.inMemory(mode: ThemeMode.light);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: AbsensiApp(themeController: controller),
      ),
    );

    // Wait for the auth gate initialization to route to HomePage
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Aktifkan mode gelap'));
    await tester.pumpAndSettle();

    expect(controller.value, ThemeMode.dark);
    expect(find.bySemanticsLabel('Aktifkan mode terang'), findsOneWidget);
  });
}
