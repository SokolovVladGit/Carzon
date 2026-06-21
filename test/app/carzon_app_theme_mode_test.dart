import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/app.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/l10n/app_locale_cubit.dart';
import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/theme/theme_mode_cubit.dart';
import 'package:carzon/core/theme/theme_mode_local_datasource.dart';
import 'package:carzon/core/theme/theme_mode_preference.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_state.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_feedback_controller.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_state.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
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

final class _InMemoryThemeModeLocalDataSource
    implements ThemeModeLocalDataSource {
  _InMemoryThemeModeLocalDataSource(this.preference);

  final ThemeModePreference preference;

  @override
  Future<ThemeModePreference> loadPreference() async => preference;

  @override
  Future<void> savePreference(ThemeModePreference preference) async {}
}

final class _InMemoryAppLocaleLocalDataSource
    implements AppLocaleLocalDataSource {
  @override
  Future<AppLocalePreference> loadPreference() async => AppLocalePreference.ru;

  @override
  Future<void> savePreference(AppLocalePreference preference) async {}
}

void main() {
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late _MockCompareCubit compareCubit;
  late _MockSelfSellerVisualCubit selfSellerVisualCubit;
  late _MockMessagingUnreadSummaryCubit messagingUnreadSummaryCubit;

  setUpAll(() {
    registerFallbackValue(const AuthState.unauthenticated());
    registerFallbackValue(const AuthUser(id: 'u1', email: 'test@example.com'));
  });

  setUp(() async {
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    compareCubit = _MockCompareCubit();
    selfSellerVisualCubit = _MockSelfSellerVisualCubit();
    messagingUnreadSummaryCubit = _MockMessagingUnreadSummaryCubit();
    await sl.reset();

    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
    when(() => favoritesCubit.state).thenReturn(const FavoritesState());
    whenListen(
      favoritesCubit,
      const Stream<FavoritesState>.empty(),
      initialState: const FavoritesState(),
    );
    when(() => compareCubit.state).thenReturn(const CompareState());
    whenListen(
      compareCubit,
      const Stream<CompareState>.empty(),
      initialState: const CompareState(),
    );
    when(
      () => selfSellerVisualCubit.state,
    ).thenReturn(const SelfSellerVisualState());
    whenListen(
      selfSellerVisualCubit,
      const Stream<SelfSellerVisualState>.empty(),
      initialState: const SelfSellerVisualState(),
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
      () => favoritesCubit.syncWithAuth(any<AuthUser?>()),
    ).thenAnswer((_) async {});
    when(
      () => selfSellerVisualCubit.prime(any<AuthState>()),
    ).thenAnswer((_) async {});
    when(
      () => messagingUnreadSummaryCubit.sync(any<AuthState>()),
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
    registerCarzonAppLocalHistoryCubitStubs(sl);
    sl.registerLazySingleton<ThemeModeLocalDataSource>(
      () => _InMemoryThemeModeLocalDataSource(ThemeModePreference.light),
    );
    sl.registerLazySingleton<AppLocaleLocalDataSource>(
      () => _InMemoryAppLocaleLocalDataSource(),
    );
    sl.registerSingleton(
      ThemeModeCubit(localDataSource: sl<ThemeModeLocalDataSource>()),
    );
    sl.registerSingleton(
      AppLocaleCubit(localDataSource: sl<AppLocaleLocalDataSource>()),
    );
    sl.registerSingleton<GoRouter>(
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        ],
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('applies dark theme mode from ThemeModeCubit', (tester) async {
    await sl<ThemeModeCubit>().setDarkEnabled(true);
    await sl<AppLocaleCubit>().load();

    await tester.pumpWidget(const CarzonApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('applies light theme mode from ThemeModeCubit', (tester) async {
    await sl<ThemeModeCubit>().setDarkEnabled(false);
    await sl<AppLocaleCubit>().load();

    await tester.pumpWidget(const CarzonApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });
}
