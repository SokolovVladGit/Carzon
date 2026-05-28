enum ThemeModePreference { light, dark }

ThemeModePreference themeModePreferenceFromStored(String? raw) {
  return switch (raw) {
    'dark' => ThemeModePreference.dark,
    _ => ThemeModePreference.light,
  };
}

String themeModePreferenceToStored(ThemeModePreference value) {
  return switch (value) {
    ThemeModePreference.light => 'light',
    ThemeModePreference.dark => 'dark',
  };
}
