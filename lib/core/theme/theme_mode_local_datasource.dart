import 'package:shared_preferences/shared_preferences.dart';

import 'theme_mode_preference.dart';

abstract interface class ThemeModeLocalDataSource {
  Future<ThemeModePreference> loadPreference();
  Future<void> savePreference(ThemeModePreference preference);
}

final class SharedPreferencesThemeModeLocalDataSource
    implements ThemeModeLocalDataSource {
  static const String storageKey = 'carzon.theme_mode.v1';

  @override
  Future<ThemeModePreference> loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      return themeModePreferenceFromStored(raw);
    } catch (_) {
      return ThemeModePreference.light;
    }
  }

  @override
  Future<void> savePreference(ThemeModePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, themeModePreferenceToStored(preference));
  }
}
