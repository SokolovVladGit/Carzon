import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/constants/app_constants.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/sellers/domain/entities/seller_public_profile.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/features/sellers/presentation/pages/seller_profile_page.dart';
import 'package:carzon/features/sellers/presentation/widgets/seller_profile_header_card.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockGetSellerPublicProfile extends Mock
    implements GetSellerPublicProfile {}

class _MockGetListings extends Mock implements GetListings {}

void main() {
  late _MockGetSellerPublicProfile getSellerPublicProfile;
  late _MockGetListings getListings;
  final ru = ruStrings();

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(
      ListingsQuery(
        sellerId: 'seller-1',
        status: ListingStatus.active,
        page: 0,
        pageSize: AppConstants.defaultPageSize,
      ),
    );
  });

  setUp(() async {
    await sl.reset();
    getSellerPublicProfile = _MockGetSellerPublicProfile();
    getListings = _MockGetListings();
    sl.registerFactory<GetSellerPublicProfile>(() => getSellerPublicProfile);
    sl.registerFactory<GetListings>(() => getListings);
  });

  tearDown(() async {
    await sl.reset();
  });

  SellerPublicProfile profile() => SellerPublicProfile(
    userId: 'seller-1',
    displayName: 'Premium Motors',
    avatarUrl: null,
    memberSince: DateTime.utc(2026, 3, 1),
    sellerType: SellerType.dealer,
    activeListingsCount: 1,
    ratingAverage: null,
    ratingCount: 0,
    reviewCount: 0,
    verifiedPhone: false,
    verifiedEmail: false,
    verifiedDealer: false,
  );

  Future<void> pumpProfile(
    WidgetTester tester, {
    SellerPublicProfile? seller,
    List<Listing> listings = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(
      () => getSellerPublicProfile(any()),
    ).thenAnswer((_) async => Success(seller));
    when(() => getListings(any())).thenAnswer((_) async => Success(listings));

    final router = GoRouter(
      initialLocation: '/sellers/seller-1',
      routes: [
        GoRoute(
          path: '/sellers/:sellerId',
          builder: (_, state) =>
              SellerProfilePage(sellerId: state.pathParameters['sellerId']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'seller profile renders header and section chrome in dark theme',
    (tester) async {
      await pumpProfile(tester, seller: profile());

      expect(find.text(ru.sellerProfileTitle), findsOneWidget);
      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.text('Premium Motors'), findsOneWidget);
      expect(find.text(ru.sellerListingsSectionTitle), findsOneWidget);
      expect(find.byType(SellerProfileHeaderCard), findsOneWidget);
    },
  );

  testWidgets('seller profile empty listings state renders in dark theme', (
    tester,
  ) async {
    await pumpProfile(tester, seller: profile());

    expect(find.text(ru.sellerNoActiveListingsTitle), findsOneWidget);
    expect(find.text(ru.sellerNoActiveListingsMessage), findsOneWidget);
  });
}
