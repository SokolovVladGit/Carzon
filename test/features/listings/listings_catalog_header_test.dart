import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/pages/listings_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockListingsBloc extends MockBloc<ListingsEvent, ListingsState>
    implements ListingsBloc {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

/// Builds a host that mounts [ListingsPage] behind a GoRouter with the
/// same top-level route path as the production router so the shared
/// bottom nav is free to render.
Widget _host({
  required ListingsBloc bloc,
  required AuthCubit auth,
  required FavoritesCubit favorites,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ListingsPage()),
    ],
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: auth),
      BlocProvider<FavoritesCubit>.value(value: favorites),
    ],
    child: MaterialApp.router(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  // The unused parameter `bloc` is consumed via sl registration below.
  // We return the widget tree here so the sl factory wires it in.
  // ignore: dead_code
  // (kept for future extension)
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ListingsRequested());
    registerFallbackValue(
      const ListingsRegionFilterChanged(MarketRegionFilter.both),
    );
  });

  late _MockListingsBloc bloc;
  late _MockAuthCubit auth;
  late _MockFavoritesCubit favs;
  final l10n = ruStrings();

  setUp(() async {
    await sl.reset();
    bloc = _MockListingsBloc();
    auth = _MockAuthCubit();
    favs = _MockFavoritesCubit();

    when(() => bloc.state).thenReturn(
      const ListingsState(
        status: ListingsStatus.success,
        items: [],
        hasReachedEnd: true,
      ),
    );
    whenListen(
      bloc,
      const Stream<ListingsState>.empty(),
      initialState: const ListingsState(
        status: ListingsStatus.success,
        items: [],
        hasReachedEnd: true,
      ),
    );

    when(() => auth.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
    when(() => favs.state).thenReturn(const FavoritesState());
    whenListen(
      favs,
      const Stream<FavoritesState>.empty(),
      initialState: const FavoritesState(),
    );

    sl.registerFactory<ListingsBloc>(() => bloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Listings feed editorial header', () {
    testWidgets(
      'renders the CARZON wordmark as the sole header identity, with '
      'no large catalog title and no marketing subtitle',
      (tester) async {
        await tester.pumpWidget(_host(bloc: bloc, auth: auth, favorites: favs));
        await tester.pump();

        // Pass 1.8 simplifies the editorial header to a centered
        // CARZON wordmark — the large catalog title was pulling the
        // page into "generic app" territory and has been removed.
        expect(find.text('CARZON'), findsOneWidget);
        expect(find.text(l10n.catalogTitle), findsNothing);
        expect(find.text(l10n.catalogSubtitle), findsNothing);
      },
    );

    testWidgets('keeps the localized search hint', (tester) async {
      await tester.pumpWidget(_host(bloc: bloc, auth: auth, favorites: favs));
      await tester.pump();

      expect(find.text(l10n.listingsSearchHint), findsOneWidget);
    });

    testWidgets(
      'does NOT render region chips on the home surface — region lives '
      'in the filters sheet in Pass 1.3',
      (tester) async {
        await tester.pumpWidget(_host(bloc: bloc, auth: auth, favorites: favs));
        await tester.pump();

        // Assert on the widget type, not raw text: the region label
        // "Все" collides with the body-category chip "Все" that now
        // lives on the home surface. The invariant we actually care
        // about is "no region SegmentedButton on the home feed".
        expect(
          find.byType(SegmentedButton<MarketRegionFilter>),
          findsNothing,
        );
        // The two region-specific labels do not collide with any
        // other UI string, so the strict text check is preserved.
        expect(find.text(l10n.regionTransnistria), findsNothing);
        expect(find.text(l10n.regionMoldova), findsNothing);
      },
    );

    testWidgets(
      'filter control is icon-only on the home surface — tooltip + '
      'semantics still expose it, but no visible "Фильтры" label',
      (tester) async {
        await tester.pumpWidget(_host(bloc: bloc, auth: auth, favorites: favs));
        await tester.pump();

        // Pass 1.4 drops the text label to stop the filter button
        // competing with the editorial headline. The localized label
        // must only live in a Tooltip (hover/long-press) and in a
        // Semantics node so a11y/tests can still reach it.
        expect(find.text(l10n.filtersTitle), findsNothing);
        expect(
          find.byTooltip(l10n.listingsFiltersTooltip),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(l10n.listingsFiltersTooltip),
          findsWidgets,
        );
      },
    );
  });
}
