import 'package:flutter/material.dart';

/// User-selected app UI language (not device locale).
enum AppLocalePreference { ru, ro }

AppLocalePreference appLocalePreferenceFromStored(String? raw) {
  return switch (raw) {
    'ro' => AppLocalePreference.ro,
    _ => AppLocalePreference.ru,
  };
}

String appLocalePreferenceToStored(AppLocalePreference value) {
  return switch (value) {
    AppLocalePreference.ru => 'ru',
    AppLocalePreference.ro => 'ro',
  };
}

String appLocalePreferenceToLanguageCode(AppLocalePreference value) {
  return appLocalePreferenceToStored(value);
}

Locale appLocalePreferenceToLocale(AppLocalePreference value) {
  return Locale(appLocalePreferenceToLanguageCode(value));
}
