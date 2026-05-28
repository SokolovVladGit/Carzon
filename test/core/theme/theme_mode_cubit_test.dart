import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/theme/theme_mode_cubit.dart';
import 'package:carzon/core/theme/theme_mode_local_datasource.dart';
import 'package:carzon/core/theme/theme_mode_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockThemeModeLocalDataSource extends Mock
    implements ThemeModeLocalDataSource {}

void main() {
  late _MockThemeModeLocalDataSource localDataSource;

  setUp(() {
    localDataSource = _MockThemeModeLocalDataSource();
  });

  blocTest<ThemeModeCubit, ThemeModeState>(
    'load emits dark when stored preference is dark',
    setUp: () {
      when(
        () => localDataSource.loadPreference(),
      ).thenAnswer((_) async => ThemeModePreference.dark);
    },
    build: () => ThemeModeCubit(localDataSource: localDataSource),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<ThemeModeState>().having(
        (state) => state.preference,
        'preference',
        ThemeModePreference.dark,
      ),
    ],
  );

  blocTest<ThemeModeCubit, ThemeModeState>(
    'setDarkEnabled(true) emits dark and persists',
    setUp: () {
      when(
        () => localDataSource.savePreference(ThemeModePreference.dark),
      ).thenAnswer((_) async {});
    },
    build: () => ThemeModeCubit(localDataSource: localDataSource),
    act: (cubit) => cubit.setDarkEnabled(true),
    expect: () => [
      isA<ThemeModeState>().having(
        (state) => state.preference,
        'preference',
        ThemeModePreference.dark,
      ),
    ],
    verify: (_) {
      verify(
        () => localDataSource.savePreference(ThemeModePreference.dark),
      ).called(1);
    },
  );

  blocTest<ThemeModeCubit, ThemeModeState>(
    'setDarkEnabled(false) emits light and persists',
    seed: () => const ThemeModeState(preference: ThemeModePreference.dark),
    setUp: () {
      when(
        () => localDataSource.savePreference(ThemeModePreference.light),
      ).thenAnswer((_) async {});
    },
    build: () => ThemeModeCubit(localDataSource: localDataSource),
    act: (cubit) => cubit.setDarkEnabled(false),
    expect: () => [
      isA<ThemeModeState>().having(
        (state) => state.preference,
        'preference',
        ThemeModePreference.light,
      ),
    ],
    verify: (_) {
      verify(
        () => localDataSource.savePreference(ThemeModePreference.light),
      ).called(1);
    },
  );
}
