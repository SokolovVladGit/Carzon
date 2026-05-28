import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_locale_local_datasource.dart';
import 'app_locale_preference.dart';

class AppLocaleState {
  const AppLocaleState({required this.preference});

  final AppLocalePreference preference;

  Locale get locale => appLocalePreferenceToLocale(preference);

  String get intlLanguageTag => appLocalePreferenceToLanguageCode(preference);
}

class AppLocaleCubit extends Cubit<AppLocaleState> {
  AppLocaleCubit({required AppLocaleLocalDataSource localDataSource})
    : _localDataSource = localDataSource,
      super(const AppLocaleState(preference: AppLocalePreference.ru));

  final AppLocaleLocalDataSource _localDataSource;

  Future<void> load() async {
    final preference = await _localDataSource.loadPreference();
    emit(AppLocaleState(preference: preference));
  }

  Future<void> setPreference(AppLocalePreference preference) async {
    if (preference == state.preference) {
      return;
    }
    emit(AppLocaleState(preference: preference));
    try {
      await _localDataSource.savePreference(preference);
    } catch (_) {
      // Keep runtime preference even if persistence fails.
    }
  }
}
