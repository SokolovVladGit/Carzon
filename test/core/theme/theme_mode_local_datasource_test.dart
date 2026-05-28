import 'package:carzon/core/theme/theme_mode_local_datasource.dart';
import 'package:carzon/core/theme/theme_mode_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesThemeModeLocalDataSource', () {
    late SharedPreferencesThemeModeLocalDataSource dataSource;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dataSource = SharedPreferencesThemeModeLocalDataSource();
    });

    test('defaults to light when no value exists', () async {
      final value = await dataSource.loadPreference();
      expect(value, ThemeModePreference.light);
    });

    test('saves and loads dark preference', () async {
      await dataSource.savePreference(ThemeModePreference.dark);
      final value = await dataSource.loadPreference();
      expect(value, ThemeModePreference.dark);
    });

    test('invalid stored value falls back to light', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesThemeModeLocalDataSource.storageKey: 'invalid',
      });
      final dataSource = SharedPreferencesThemeModeLocalDataSource();
      final value = await dataSource.loadPreference();
      expect(value, ThemeModePreference.light);
    });
  });
}
