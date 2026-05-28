import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_mode_local_datasource.dart';
import 'theme_mode_preference.dart';

class ThemeModeState {
  const ThemeModeState({required this.preference});

  final ThemeModePreference preference;

  ThemeMode get themeMode => switch (preference) {
    ThemeModePreference.light => ThemeMode.light,
    ThemeModePreference.dark => ThemeMode.dark,
  };
}

class ThemeModeCubit extends Cubit<ThemeModeState> {
  ThemeModeCubit({required ThemeModeLocalDataSource localDataSource})
    : _localDataSource = localDataSource,
      super(const ThemeModeState(preference: ThemeModePreference.light));

  final ThemeModeLocalDataSource _localDataSource;

  Future<void> load() async {
    final preference = await _localDataSource.loadPreference();
    emit(ThemeModeState(preference: preference));
  }

  Future<void> setDarkEnabled(bool enabled) async {
    final next = enabled ? ThemeModePreference.dark : ThemeModePreference.light;
    if (next == state.preference) {
      return;
    }
    emit(ThemeModeState(preference: next));
    try {
      await _localDataSource.savePreference(next);
    } catch (_) {
      // Keep runtime preference even if persistence fails.
    }
  }
}
