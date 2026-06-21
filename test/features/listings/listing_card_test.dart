import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_toggle_button.dart';
import 'package:carzon/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_card.dart';
import 'package:carzon/shared/brands/brand_logo_glyph.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_cover_image.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_tile.dart';
import 'package:carzon/features/listings/presentation/widgets/vin_present_latin_badge.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MemoryCompareRepository implements CompareRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<CompareItem>> loadItems() async => const [];

  @override
  Future<void> saveItems(List<CompareItem> items) async {}
}

Listing _seed({
  String? coverImageUrl,
  ListingType type = ListingType.sale,
  MarketRegion region = MarketRegion.transnistria,
  String make = 'Volkswagen',
  String model = 'Golf',
  String city = 'Tiraspol',
  ListingVinStatus vinStatus = ListingVinStatus.notProvided,
}) {
  return Listing(
    id: 'l1',
    title: 'VW Golf',
    make: make,
    model: model,
    year: 2016,
    priceEur: 8900,
    mileageKm: 120000,
    type: type,
    city: city,
    marketRegion: region,
    createdAt: DateTime.utc(2026, 4, 1),
    status: ListingStatus.active,
    coverImageUrl: coverImageUrl,
    sellerId: 's1',
    vinStatus: vinStatus,
  );
}

void main() {
  final l10n = ruStrings();

  group('ListingCard content', () {
    testWidgets('renders make/model/year, price, mileage, city, region badge, '
        'and no type badge when type is sale', (tester) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(child: ListingCard(listing: _seed())),
        ),
      );

      expect(find.text('Volkswagen Golf'), findsOneWidget);
      expect(find.text('€8 900'), findsOneWidget);
      expect(
        find.text('120 000 ${l10n.commonKilometersShort}'),
        findsOneWidget,
      );
      expect(find.text('2016'), findsOneWidget);
      expect(find.text('Tiraspol'), findsOneWidget);
      expect(find.text(l10n.regionTransnistria), findsOneWidget);
      // Sale listings intentionally do not surface a "Sale" badge —
      // sale is the implicit baseline, so the card only badges the
      // region for a plain sale listing.
      expect(find.text(l10n.formatTypeSale), findsNothing);
    });

    testWidgets(
      'shows the exchange type badge when listing is ListingType.exchange',
      (tester) async {
        await pumpLocalizedWidget(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: ListingCard(listing: _seed(type: ListingType.exchange)),
            ),
          ),
        );

        expect(find.text(l10n.formatTypeExchange), findsOneWidget);
      },
    );

    testWidgets(
      'renders the cover placeholder (car icon) when coverImageUrl is null',
      (tester) async {
        await pumpLocalizedWidget(
          tester,
          Scaffold(
            body: SingleChildScrollView(child: ListingCard(listing: _seed())),
          ),
        );

        expect(find.byType(ListingCoverImage), findsOneWidget);
        expect(find.byIcon(Icons.directions_car_filled_outlined), findsWidgets);
      },
    );

    testWidgets('dark mode shows brand logo contrast well for dark SVG marks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListingCard(listing: _seed(make: 'Toyota')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(brandLogoDarkWellKey), findsOneWidget);
      expect(find.byKey(brandLogoDarkTintKey), findsOneWidget);
    });

    testWidgets('forwards onTap when the card is tapped', (tester) async {
      var tapped = 0;
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ListingCard(listing: _seed(), onTap: () => tapped += 1),
          ),
        ),
      );

      await tester.tap(find.byType(ListingCard));
      expect(tapped, 1);
    });

    testWidgets('wraps the cover image in a Hero tagged with the listing id', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(child: ListingCard(listing: _seed())),
        ),
      );

      final heroes = tester.widgetList<Hero>(find.byType(Hero));
      expect(
        heroes.any((h) => h.tag == listingCoverHeroTag('l1')),
        isTrue,
        reason:
            'ListingCard cover must be wrapped in a Hero with the '
            'listing-id-derived tag so feed→details animates the photo.',
      );
    });
  });

  group('ListingCard variant rhythm', () {
    /// Measures the laid-out aspect ratio of the cover image by
    /// walking up from the [Hero] that wraps the [ListingCoverImage]
    /// to the nearest [ListingCoverImage] render box, then dividing
    /// its actual width by its actual height. The card now lays its
    /// children out via a custom render box (no [AspectRatio]
    /// widget), so we assert the observable geometry directly rather
    /// than a widget property.
    double coverAspectRatio(WidgetTester tester) {
      final size = tester.getSize(
        find.byWidgetPredicate(
          (w) => w is Hero && w.tag == listingCoverHeroTag('l1'),
        ),
      );
      return size.width / size.height;
    }

    testWidgets(
      'regular variant renders a 16:9 cover and keeps the region badge',
      (tester) async {
        await pumpLocalizedWidget(
          tester,
          Scaffold(
            body: SingleChildScrollView(child: ListingCard(listing: _seed())),
          ),
        );

        expect(coverAspectRatio(tester), closeTo(16 / 9, 1e-9));
        expect(find.text(l10n.regionTransnistria), findsOneWidget);
      },
    );

    testWidgets('featured variant renders a 4:3 cover, keeps the region badge, '
        'and still drops the exchange/type badge', (tester) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ListingCard(
              listing: _seed(type: ListingType.exchange),
              variant: ListingCardVariant.featured,
            ),
          ),
        ),
      );

      expect(coverAspectRatio(tester), closeTo(4 / 3, 1e-9));
      expect(find.text(l10n.regionTransnistria), findsOneWidget);
      expect(find.text(l10n.formatTypeExchange), findsNothing);
      // Price, title and meta (mileage + city) still render — the
      // hierarchy is stronger, not poorer.
      expect(find.text('€8 900'), findsOneWidget);
      expect(find.text('Volkswagen Golf'), findsOneWidget);
      expect(
        find.text('120 000 ${l10n.commonKilometersShort}'),
        findsOneWidget,
      );
      expect(find.text('2016'), findsOneWidget);
      expect(find.text('Tiraspol'), findsOneWidget);
    });

    testWidgets(
      'featured variant with VIN shows market region badge and VIN stamp',
      (tester) async {
        await pumpLocalizedWidget(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: ListingCard(
                listing: _seed(vinStatus: ListingVinStatus.formatValid),
                variant: ListingCardVariant.featured,
                trailing: const Icon(Icons.favorite_border),
                trailingWide: true,
              ),
            ),
          ),
        );

        expect(find.text(l10n.regionTransnistria), findsOneWidget);
        expect(
          find.byKey(const ValueKey('vin_present_latin_badge')),
          findsOneWidget,
        );

        final vinRect = tester.getRect(
          find.byKey(const ValueKey('vin_present_latin_badge')),
        );
        final actionRect = tester.getRect(find.byIcon(Icons.favorite_border));
        expect(vinRect.top, lessThan(actionRect.top));
      },
    );
  });

  group('ListingCard VIN badge', () {
    testWidgets('hides VIN badge when vinStatus is notProvided', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ListingCard(
              listing: _seed(),
              trailing: const Icon(Icons.favorite_border),
              trailingWide: true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('vin_present_latin_badge')),
        findsNothing,
      );
    });

    testWidgets('shows card-stamp VIN badge when vinStatus is formatValid', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ListingCard(
              listing: _seed(vinStatus: ListingVinStatus.formatValid),
              trailing: const Icon(Icons.favorite_border),
              trailingWide: true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('vin_present_latin_badge')),
        findsOneWidget,
      );
      expect(find.byType(VinPresentLatinBadge), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vin_present_latin_badge_v')),
        findsOneWidget,
      );
    });

    testWidgets('VIN stamp anchors top-right above trailing actions', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ListingCard(
              listing: _seed(vinStatus: ListingVinStatus.formatValid),
              trailing: const Icon(Icons.favorite_border),
              trailingWide: true,
            ),
          ),
        ),
      );

      final badgeRect = tester.getRect(
        find.byKey(const ValueKey('vin_present_latin_badge')),
      );
      final actionRect = tester.getRect(find.byIcon(Icons.favorite_border));
      expect(badgeRect.top, lessThan(actionRect.top));
      expect(badgeRect.right, greaterThan(actionRect.left));
    });

    Future<double> metaRowWidth(
      WidgetTester tester, {
      required bool withVin,
      double cardWidth = 360,
    }) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: cardWidth,
              child: ListingCard(
                listing: _seed(
                  vinStatus: withVin
                      ? ListingVinStatus.formatValid
                      : ListingVinStatus.notProvided,
                  city: 'Bender / Tighina — Pridnestrovie',
                ),
                trailing: const Icon(Icons.favorite_border),
                trailingWide: true,
              ),
            ),
          ),
        ),
      );
      final rowFinder = find.byWidgetPredicate((w) {
        if (w is! Row) return false;
        var hasYear = false;
        var hasFlexibleChild = false;
        for (final child in w.children) {
          if (child is Text && child.data == '2016') hasYear = true;
          if (child is Flexible) hasFlexibleChild = true;
        }
        return hasYear && hasFlexibleChild;
      });
      return tester.getSize(rowFinder).width;
    }

    testWidgets('VIN badge does not reserve inline width for metadata', (
      tester,
    ) async {
      final withoutVin = await metaRowWidth(tester, withVin: false);
      final withVin = await metaRowWidth(tester, withVin: true);
      expect(withVin, equals(withoutVin));
    });

    testWidgets('metadata stays visible with VIN on narrow card', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 375,
              child: ListingCard(
                listing: _seed(
                  vinStatus: ListingVinStatus.formatValid,
                  make: 'Mercedes-Benz',
                  model: 'E-Class AMG Line Premium Plus',
                  city: 'Bender / Tighina — Pridnestrovie',
                ),
                trailing: const Icon(Icons.favorite_border),
                trailingWide: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('2016'), findsOneWidget);
      expect(
        find.text('120 000 ${l10n.commonKilometersShort}'),
        findsOneWidget,
      );
      expect(find.textContaining('Bender'), findsOneWidget);
    });

    testWidgets('VIN badge does not overlap compare/favorite hit targets', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ListingCard(
              listing: _seed(vinStatus: ListingVinStatus.formatValid),
              trailing: const Icon(Icons.favorite_border),
              trailingWide: true,
            ),
          ),
        ),
      );

      final badgeRect = tester.getRect(
        find.byKey(const ValueKey('vin_present_latin_badge')),
      );
      final actionRect = tester.getRect(find.byIcon(Icons.favorite_border));
      expect(badgeRect.bottom, lessThanOrEqualTo(actionRect.top + 2));
    });

    testWidgets('VIN badge sits in info panel, not on cover image', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ListingCard(
              listing: _seed(vinStatus: ListingVinStatus.formatValid),
              trailing: const Icon(Icons.favorite_border),
              trailingWide: true,
            ),
          ),
        ),
      );

      final badgeRect = tester.getRect(
        find.byKey(const ValueKey('vin_present_latin_badge')),
      );
      final coverRect = tester.getRect(find.byType(ListingCoverImage));
      expect(badgeRect.top, greaterThan(coverRect.bottom - 40));
    });
  });

  group('ListingTile compare and favorite actions', () {
    late _MockAuthCubit auth;
    late _MockFavoritesCubit favorites;
    late CompareCubit compareCubit;

    setUp(() {
      auth = _MockAuthCubit();
      favorites = _MockFavoritesCubit();
      compareCubit = CompareCubit(repository: _MemoryCompareRepository());
      when(() => auth.state).thenReturn(const AuthState.unauthenticated());
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.unauthenticated(),
      );
      when(() => favorites.state).thenReturn(const FavoritesState());
      whenListen(
        favorites,
        const Stream<FavoritesState>.empty(),
        initialState: const FavoritesState(),
      );
    });

    tearDown(() => compareCubit.close());

    testWidgets('public ListingTile exposes compare and favorite actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        localizedApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<FavoritesCubit>.value(value: favorites),
              BlocProvider<CompareCubit>.value(value: compareCubit),
            ],
            child: Scaffold(
              body: SingleChildScrollView(child: ListingTile(listing: _seed())),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CompareToggleButton), findsOneWidget);
      expect(find.byType(FavoriteToggleButton), findsOneWidget);
    });

    testWidgets('tapping compare does not trigger card onTap', (tester) async {
      var cardTaps = 0;
      await tester.pumpWidget(
        localizedApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<FavoritesCubit>.value(value: favorites),
              BlocProvider<CompareCubit>.value(value: compareCubit),
            ],
            child: Scaffold(
              body: SingleChildScrollView(
                child: ListingTile(
                  listing: _seed(),
                  onTap: () => cardTaps += 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('compare_toggle_l1')));
      await tester.pump();
      expect(cardTaps, 0);
      expect(compareCubit.state.containsListing('l1'), isTrue);
    });

    testWidgets('tapping card body still invokes onTap', (tester) async {
      var cardTaps = 0;
      await tester.pumpWidget(
        localizedApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<FavoritesCubit>.value(value: favorites),
              BlocProvider<CompareCubit>.value(value: compareCubit),
            ],
            child: Scaffold(
              body: SingleChildScrollView(
                child: ListingTile(
                  listing: _seed(),
                  onTap: () => cardTaps += 1,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Volkswagen Golf'));
      expect(cardTaps, 1);
    });
  });

  group('ListingCard.hero shuttle radius', () {
    test('matches regular vs featured cover top radii', () {
      expect(
        ListingCard.coverHeroFlightTopRadius(ListingCardVariant.regular),
        20,
      );
      expect(
        ListingCard.coverHeroFlightTopRadius(ListingCardVariant.featured),
        16,
      );
    });
  });
}
