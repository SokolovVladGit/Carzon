import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/app.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/l10n/app_locale_cubit.dart';
import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/theme/theme_mode_cubit.dart';
import 'package:carzon/core/theme/theme_mode_local_datasource.dart';
import 'package:carzon/core/theme/theme_mode_preference.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_state.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_feedback_controller.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_state.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/carzon_app_widget_test_stubs.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockCompareCubit extends MockCubit<CompareState>
    implements CompareCubit {}

class _MockSelfSellerVisualCubit extends MockCubit<SelfSellerVisualState>
    implements SelfSellerVisualCubit {}

class _MockMessagingUnreadSummaryCubit
    extends MockCubit<MessagingUnreadSummaryState>
    implements MessagingUnreadSummaryCubit {}

class _MockBrowseCatalogFilterAlertsCubit
    extends MockCubit<BrowseCatalogFilterAlertsState>
    implements BrowseCatalogFilterAlertsCubit {}

final class _InMemoryThemeModeLocalDataSource
    implements ThemeModeLocalDataSource {
  @override
  Future<ThemeModePreference> loadPreference() async =>
      ThemeModePreference.light;

  @override
  Future<void> savePreference(ThemeModePreference preference) async {}
}

final class _InMemoryAppLocaleLocalDataSource
    implements AppLocaleLocalDataSource {
  _InMemoryAppLocaleLocalDataSource(this.preference);

  AppLocalePreference preference;

  @override
  Future<AppLocalePreference> loadPreference() async => preference;

  @override
  Future<void> savePreference(AppLocalePreference value) async {
    preference = value;
  }
}

void main() {
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late _MockCompareCubit compareCubit;
  late _MockSelfSellerVisualCubit selfSellerVisualCubit;
  late _MockMessagingUnreadSummaryCubit messagingUnreadSummaryCubit;
  late _MockBrowseCatalogFilterAlertsCubit browseFilterAlertsCubit;
  late _InMemoryAppLocaleLocalDataSource localeDataSource;

  setUpAll(() {
    registerFallbackValue(const AuthState.unauthenticated());
  });

  setUp(() async {
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    compareCubit = _MockCompareCubit();
    selfSellerVisualCubit = _MockSelfSellerVisualCubit();
    messagingUnreadSummaryCubit = _MockMessagingUnreadSummaryCubit();
    browseFilterAlertsCubit = _MockBrowseCatalogFilterAlertsCubit();
    localeDataSource = _InMemoryAppLocaleLocalDataSource(
      AppLocalePreference.ru,
    );
    await sl.reset();

    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(authCubit, const Stream<AuthState>.empty());
    when(() => favoritesCubit.state).thenReturn(const FavoritesState());
    whenListen(favoritesCubit, const Stream<FavoritesState>.empty());
    when(() => compareCubit.state).thenReturn(const CompareState());
    whenListen(compareCubit, const Stream<CompareState>.empty());
    when(
      () => selfSellerVisualCubit.state,
    ).thenReturn(const SelfSellerVisualState());
    whenListen(
      selfSellerVisualCubit,
      const Stream<SelfSellerVisualState>.empty(),
    );
    when(() => messagingUnreadSummaryCubit.state).thenReturn(
      const MessagingUnreadSummaryState(
        phase: MessagingUnreadSummaryPhase.initial,
      ),
    );
    whenListen(
      messagingUnreadSummaryCubit,
      const Stream<MessagingUnreadSummaryState>.empty(),
      initialState: const MessagingUnreadSummaryState(
        phase: MessagingUnreadSummaryPhase.initial,
      ),
    );
    when(
      () => browseFilterAlertsCubit.onAuthChanged(any<AuthState>()),
    ).thenAnswer((_) async {});

    sl.registerSingleton<AuthCubit>(authCubit);
    sl.registerSingleton<FavoritesCubit>(favoritesCubit);
    sl.registerSingleton<CompareCubit>(compareCubit);
    sl.registerSingleton<CompareFlyToTrayController>(
      CompareFlyToTrayController(),
    );
    sl.registerSingleton<CompareTrayFeedbackController>(
      CompareTrayFeedbackController(),
    );
    sl.registerSingleton<SelfSellerVisualCubit>(selfSellerVisualCubit);
    sl.registerSingleton<MessagingUnreadSummaryCubit>(
      messagingUnreadSummaryCubit,
    );
    sl.registerSingleton<BrowseCatalogFilterAlertsCubit>(
      browseFilterAlertsCubit,
    );
    registerCarzonAppLocalHistoryCubitStubs(sl);
    sl.registerLazySingleton<ThemeModeLocalDataSource>(
      () => _InMemoryThemeModeLocalDataSource(),
    );
    sl.registerLazySingleton<ThemeModeCubit>(
      () => ThemeModeCubit(localDataSource: sl<ThemeModeLocalDataSource>()),
    );
    sl.registerLazySingleton<AppLocaleLocalDataSource>(() => localeDataSource);
    sl.registerLazySingleton<AppLocaleCubit>(
      () => AppLocaleCubit(localDataSource: sl<AppLocaleLocalDataSource>()),
    );
    sl.registerSingleton<GoRouter>(
      GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => const SizedBox())],
      ),
    );
  });

  testWidgets('MaterialApp uses Romanian locale from cubit', (tester) async {
    localeDataSource.preference = AppLocalePreference.ro;
    await sl<AppLocaleCubit>().load();

    await tester.pumpWidget(const CarzonApp());
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('ro'));
    expect(materialApp.supportedLocales, AppLocalizations.supportedLocales);
  });
}
