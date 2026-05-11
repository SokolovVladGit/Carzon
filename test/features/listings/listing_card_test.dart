import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_card.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_cover_image.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Listing _seed({
  String? coverImageUrl,
  ListingType type = ListingType.sale,
  MarketRegion region = MarketRegion.transnistria,
}) {
  return Listing(
    id: 'l1',
    title: 'VW Golf',
    make: 'Volkswagen',
    model: 'Golf',
    year: 2016,
    priceEur: 8900,
    mileageKm: 120000,
    type: type,
    city: 'Tiraspol',
    marketRegion: region,
    createdAt: DateTime.utc(2026, 4, 1),
    status: ListingStatus.active,
    coverImageUrl: coverImageUrl,
    sellerId: 's1',
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
      expect(find.text('120 000 km'), findsOneWidget);
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

    testWidgets(
      'featured variant renders a 4:3 cover and drops the region/type '
      'badges so the image drives the hierarchy',
      (tester) async {
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
        // The region + "exchange" badges belong to the regular rhythm;
        // the feature card trades them for empty air + bigger type.
        expect(find.text(l10n.regionTransnistria), findsNothing);
        expect(find.text(l10n.formatTypeExchange), findsNothing);
        // Price, title and meta (mileage + city) still render — the
        // hierarchy is stronger, not poorer.
        expect(find.text('€8 900'), findsOneWidget);
        expect(find.text('Volkswagen Golf'), findsOneWidget);
        expect(find.text('120 000 km'), findsOneWidget);
        expect(find.text('2016'), findsOneWidget);
        expect(find.text('Tiraspol'), findsOneWidget);
      },
    );
  });

  group('ListingTile favorite toggle integration', () {
    late _MockAuthCubit auth;
    late _MockFavoritesCubit favorites;

    setUp(() {
      auth = _MockAuthCubit();
      favorites = _MockFavoritesCubit();
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

    testWidgets(
      'public ListingTile exposes a FavoriteToggleButton as the overlay action',
      (tester) async {
        await tester.pumpWidget(
          localizedApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: auth),
                BlocProvider<FavoritesCubit>.value(value: favorites),
              ],
              child: Scaffold(
                body: SingleChildScrollView(
                  child: ListingTile(listing: _seed()),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(FavoriteToggleButton), findsOneWidget);
      },
    );
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
