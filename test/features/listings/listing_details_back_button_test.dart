import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_cover_image.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Listing _seed() => Listing(
      id: 'l1',
      title: 'VW Golf',
      make: 'Volkswagen',
      model: 'Golf',
      year: 2016,
      priceEur: 8900,
      mileageKm: 120000,
      type: ListingType.sale,
      city: 'Chișinău',
      marketRegion: MarketRegion.moldova,
      createdAt: DateTime.utc(2026, 4, 1),
      status: ListingStatus.active,
      sellerId: 's1',
    );

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  final l10n = ruStrings();

  setUp(() async {
    await sl.reset();
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();

    when(() => detailsCubit.load(any())).thenAnswer((_) async {});
    when(() => detailsCubit.state)
        .thenReturn(ListingDetailsState.success(_seed()));
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: ListingDetailsState.success(_seed()),
    );

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

    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrapWithRouter({
    required String initialLocation,
    String? initialCoverImageUrl,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('home-feed-stub')),
          ),
        ),
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) => ListingDetailsPage(
            id: state.pathParameters['id']!,
            initialCoverImageUrl: initialCoverImageUrl,
          ),
        ),
      ],
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('ListingDetailsPage AppBar', () {
    testWidgets(
      'renders a visible back button and favorite action without a '
      'generic "Объявление" page label',
      (tester) async {
        await tester.pumpWidget(
          wrapWithRouter(initialLocation: '/listings/l1'),
        );
        await tester.pump();

        expect(find.byType(AppBackButton), findsOneWidget);
        expect(find.byType(BackButtonIcon), findsOneWidget);
        expect(find.byType(FavoriteToggleButton), findsOneWidget);
        // The page intentionally no longer shows the
        // `listingDetailsTitle` overline — the brand identity row
        // replaces it so the header reads as an automotive marker,
        // not a generic "Listing" page label.
        expect(find.text(l10n.listingDetailsTitle), findsNothing);
      },
    );

    testWidgets(
      'deep-linked details tap of back falls back to the listings feed',
      (tester) async {
        await tester.pumpWidget(
          wrapWithRouter(initialLocation: '/listings/l1'),
        );
        await tester.pump();

        expect(find.text('home-feed-stub'), findsNothing);

        await tester.tap(find.byType(BackButtonIcon));
        await tester.pumpAndSettle();

        expect(find.byType(FavoriteToggleButton), findsNothing);
        expect(find.text('home-feed-stub'), findsOneWidget);
      },
    );

    testWidgets(
      'listing details is a secondary page and does not render the top-level '
      'NavigationBar',
      (tester) async {
        await tester.pumpWidget(wrapWithRouter(initialLocation: '/listings/l1'));
        await tester.pump();

        expect(find.byType(NavigationBar), findsNothing);
      },
    );

    testWidgets(
      'cover image area wraps the photo in a Hero tagged with the listing id '
      'so feed→details animates the same cover',
      (tester) async {
        await tester.pumpWidget(wrapWithRouter(initialLocation: '/listings/l1'));
        await tester.pump();

        expect(find.byType(ListingCoverImage), findsOneWidget);
        final heroes = tester.widgetList<Hero>(find.byType(Hero));
        expect(
          heroes.any((h) => h.tag == listingCoverHeroTag('l1')),
          isTrue,
          reason:
              'ListingDetailsPage cover must share the same Hero tag as the '
              'ListingCard to enable the shared-element transition.',
        );
      },
    );

    testWidgets(
      'cover Hero is mounted during loading so the push transition has a '
      'destination on its first frame',
      (tester) async {
        // Override the default `success` state from setUp with a pure
        // `loading` state — no listing payload, no cover URL yet.
        when(() => detailsCubit.state)
            .thenReturn(const ListingDetailsState.loading());
        whenListen(
          detailsCubit,
          const Stream<ListingDetailsState>.empty(),
          initialState: const ListingDetailsState.loading(),
        );

        await tester.pumpWidget(wrapWithRouter(initialLocation: '/listings/l1'));
        await tester.pump();

        // Existing loading UI is still rendered.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // And critically: the cover Hero with the id-based tag is
        // already in the tree even though the cubit hasn't resolved.
        expect(find.byType(ListingCoverImage), findsOneWidget);
        final heroes = tester.widgetList<Hero>(find.byType(Hero));
        final matches =
            heroes.where((h) => h.tag == listingCoverHeroTag('l1')).toList();
        expect(
          matches,
          hasLength(1),
          reason:
              'Exactly one destination Hero with the listing-cover-<id> tag '
              'must be mounted on ListingDetailsPage in the loading state so '
              'the push transition can find it.',
        );
      },
    );

    testWidgets(
      'during loading the cover uses the initial cover URL passed via route '
      'extra so the Hero flight animates the real tapped photo',
      (tester) async {
        when(() => detailsCubit.state)
            .thenReturn(const ListingDetailsState.loading());
        whenListen(
          detailsCubit,
          const Stream<ListingDetailsState>.empty(),
          initialState: const ListingDetailsState.loading(),
        );

        const seededCover = 'https://cdn.example.com/cover-l1.jpg';
        await tester.pumpWidget(
          wrapWithRouter(
            initialLocation: '/listings/l1',
            initialCoverImageUrl: seededCover,
          ),
        );
        await tester.pump();

        final cover = tester.widget<ListingCoverImage>(
          find.byType(ListingCoverImage),
        );
        expect(
          cover.imageUrl,
          seededCover,
          reason:
              'While the cubit is loading, ListingDetailsPage must render the '
              'cover URL passed via GoRouter extra so the push Hero flight '
              'shows the tapped photo, not the placeholder.',
        );

        final heroes = tester.widgetList<Hero>(find.byType(Hero));
        expect(
          heroes.where((h) => h.tag == listingCoverHeroTag('l1')),
          hasLength(1),
          reason:
              'The seeded initial cover URL must not create a second Hero — '
              'only one destination Hero with the listing-cover-<id> tag is '
              'allowed on the details page.',
        );
      },
    );

    testWidgets(
      'after load completes the listing\'s own cover URL takes over and the '
      'initial route-extra URL is no longer used',
      (tester) async {
        // Default setUp state is `success(_seed())`; _seed() has no
        // coverImageUrl set, so the ListingCoverImage should receive
        // null even when an initial URL was passed via route extra.
        const seededCover = 'https://cdn.example.com/stale-cover.jpg';
        await tester.pumpWidget(
          wrapWithRouter(
            initialLocation: '/listings/l1',
            initialCoverImageUrl: seededCover,
          ),
        );
        await tester.pump();

        final cover = tester.widget<ListingCoverImage>(
          find.byType(ListingCoverImage),
        );
        expect(
          cover.imageUrl,
          isNull,
          reason:
              'Once the cubit resolves, the loaded listing.coverImageUrl '
              '(null in this fixture) must take precedence over the seeded '
              'initial URL.',
        );
      },
    );

    testWidgets(
      'deep-linked details (no route extra) still renders the cover Hero '
      'with a null image URL during loading — placeholder fallback',
      (tester) async {
        when(() => detailsCubit.state)
            .thenReturn(const ListingDetailsState.loading());
        whenListen(
          detailsCubit,
          const Stream<ListingDetailsState>.empty(),
          initialState: const ListingDetailsState.loading(),
        );

        await tester.pumpWidget(
          wrapWithRouter(initialLocation: '/listings/l1'),
        );
        await tester.pump();

        final cover = tester.widget<ListingCoverImage>(
          find.byType(ListingCoverImage),
        );
        expect(cover.imageUrl, isNull);
        expect(
          tester
              .widgetList<Hero>(find.byType(Hero))
              .where((h) => h.tag == listingCoverHeroTag('l1'))
              .length,
          1,
        );
      },
    );
  });
}
