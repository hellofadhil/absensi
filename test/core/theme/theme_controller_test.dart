import 'package:absensi/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('uses system theme when no preference has been saved', () async {
    final controller = await ThemeController.load();

    expect(controller.value, ThemeMode.system);
  });

  test('persists the selected light and dark theme', () async {
    final controller = await ThemeController.load();

    await controller.toggle(Brightness.light);
    expect(controller.value, ThemeMode.dark);
    expect((await ThemeController.load()).value, ThemeMode.dark);

    await controller.toggle(Brightness.dark);
    expect(controller.value, ThemeMode.light);
    expect((await ThemeController.load()).value, ThemeMode.light);
  });
}
