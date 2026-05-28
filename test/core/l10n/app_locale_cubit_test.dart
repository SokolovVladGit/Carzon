import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/l10n/app_locale_cubit.dart';
import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLocaleLocalDataSource extends Mock
    implements AppLocaleLocalDataSource {}

void main() {
  late _MockAppLocaleLocalDataSource localDataSource;

  setUp(() {
    localDataSource = _MockAppLocaleLocalDataSource();
  });

  test('initial state is Russian', () {
    final cubit = AppLocaleCubit(localDataSource: localDataSource);
    expect(cubit.state.preference, AppLocalePreference.ru);
    expect(cubit.state.locale, const Locale('ru'));
    cubit.close();
  });

  blocTest<AppLocaleCubit, AppLocaleState>(
    'load emits Romanian when stored preference is ro',
    setUp: () {
      when(
        () => localDataSource.loadPreference(),
      ).thenAnswer((_) async => AppLocalePreference.ro);
    },
    build: () => AppLocaleCubit(localDataSource: localDataSource),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AppLocaleState>().having(
        (s) => s.preference,
        'preference',
        AppLocalePreference.ro,
      ),
    ],
  );

  blocTest<AppLocaleCubit, AppLocaleState>(
    'setPreference(ro) emits Romanian and persists',
    setUp: () {
      when(
        () => localDataSource.savePreference(AppLocalePreference.ro),
      ).thenAnswer((_) async {});
    },
    build: () => AppLocaleCubit(localDataSource: localDataSource),
    act: (cubit) => cubit.setPreference(AppLocalePreference.ro),
    expect: () => [
      isA<AppLocaleState>().having(
        (s) => s.locale.languageCode,
        'languageCode',
        'ro',
      ),
    ],
    verify: (_) {
      verify(
        () => localDataSource.savePreference(AppLocalePreference.ro),
      ).called(1);
    },
  );
}
