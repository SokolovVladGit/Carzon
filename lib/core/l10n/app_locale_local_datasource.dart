import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale_preference.dart';

abstract interface class AppLocaleLocalDataSource {
  Future<AppLocalePreference> loadPreference();
  Future<void> savePreference(AppLocalePreference preference);
}

final class SharedPreferencesAppLocaleLocalDataSource
    implements AppLocaleLocalDataSource {
  static const String storageKey = 'carzon.app_locale.v1';

  @override
  Future<AppLocalePreference> loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      return appLocalePreferenceFromStored(raw);
    } catch (_) {
      return AppLocalePreference.ru;
    }
  }

  @override
  Future<void> savePreference(AppLocalePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, appLocalePreferenceToStored(preference));
  }
}
