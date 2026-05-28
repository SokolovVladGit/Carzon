import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesAppLocaleLocalDataSource', () {
    late SharedPreferencesAppLocaleLocalDataSource dataSource;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dataSource = SharedPreferencesAppLocaleLocalDataSource();
    });

    test('defaults to Russian when no value exists', () async {
      expect(await dataSource.loadPreference(), AppLocalePreference.ru);
    });

    test('saves and loads Romanian preference', () async {
      await dataSource.savePreference(AppLocalePreference.ro);
      expect(await dataSource.loadPreference(), AppLocalePreference.ro);
    });

    test('invalid stored value falls back to Russian', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesAppLocaleLocalDataSource.storageKey: 'invalid',
      });
      final ds = SharedPreferencesAppLocaleLocalDataSource();
      expect(await ds.loadPreference(), AppLocalePreference.ru);
    });
  });
}
