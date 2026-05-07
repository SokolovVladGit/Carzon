import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/features/sellers/presentation/pages/seller_profile_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetSellerPublicProfile extends Mock
    implements GetSellerPublicProfile {}

class _MockGetListings extends Mock implements GetListings {}

void main() {
  late _MockGetSellerPublicProfile getSellerPublicProfile;
  late _MockGetListings getListings;

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(
      ListingsQuery(
        sellerId: 'fallback-sid',
        status: ListingStatus.active,
        page: 0,
        pageSize: 20,
      ),
    );
  });

  setUp(() async {
    await sl.reset();
    getSellerPublicProfile = _MockGetSellerPublicProfile();
    getListings = _MockGetListings();
    when(
      () => getSellerPublicProfile(any()),
    ).thenAnswer((_) async => const Success(null));
    when(() => getListings(any())).thenAnswer((_) async => Success([]));
    sl.registerFactory<GetSellerPublicProfile>(() => getSellerPublicProfile);
    sl.registerFactory<GetListings>(() => getListings);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('/sellers/:sellerId builds SellerProfilePage', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.sellerProfilePath(
        'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      ),
      routes: [
        GoRoute(
          path: AppRoutes.sellerProfile,
          builder: (_, state) =>
              SellerProfilePage(sellerId: state.pathParameters['sellerId']!),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(SellerProfilePage), findsOneWidget);
  });
}
