import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._(super.value, this._preferenceStore);

  @visibleForTesting
  factory ThemeController.inMemory({ThemeMode mode = ThemeMode.system}) {
    return ThemeController._(mode, _InMemoryThemePreferenceStore());
  }

  static const _preferenceKey = 'theme_mode';
  final _ThemePreferenceStore _preferenceStore;

  static Future<ThemeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final preferenceStore = _SharedPreferencesThemeStore(preferences);
    final savedMode = preferenceStore.getString(_preferenceKey);
    final mode = switch (savedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return ThemeController._(mode, preferenceStore);
  }

  Future<void> toggle(Brightness currentBrightness) async {
    final nextMode = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    value = nextMode;
    await _preferenceStore.setString(_preferenceKey, nextMode.name);
  }
}

abstract interface class _ThemePreferenceStore {
  String? getString(String key);

  Future<bool> setString(String key, String value);
}

class _SharedPreferencesThemeStore implements _ThemePreferenceStore {
  const _SharedPreferencesThemeStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);
}

class _InMemoryThemePreferenceStore implements _ThemePreferenceStore {
  final Map<String, Object> _values = {};

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope was not found.');
    return scope!.notifier!;
  }
}
