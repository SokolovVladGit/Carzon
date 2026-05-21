import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_browse_filter_alert_sheet_bell.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_filter_alert_ui_constants.dart';
import 'package:carzon/features/listings/presentation/pages/listings_page.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/browse_catalog_filter_alerts_sl.dart';
import '../../helpers/noop_last_applied_listing_discovery_repository.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockSellersRepository extends Mock implements SellersRepository {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

MySellerProfileModel _stubSellerSelf() => MySellerProfileModel(
  displayName: 'S',
  avatarUrl: null,
  avatarPath: null,
  memberSince: DateTime.utc(2026, 4, 1),
  publicVisibility: true,
);

Widget _host({
  required AuthCubit auth,
  required FavoritesCubit favorites,
  required SellersRepository sellersRepo,
  required MessagingRepository messagingRepo,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ListingsPage()),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
    ],
  );
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: auth),
      BlocProvider<FavoritesCubit>.value(value: favorites),
      BlocProvider(
        create: (_) => SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
      ),
      BlocProvider(create: (_) => MessagingUnreadSummaryCubit(messagingRepo)),
    ],
    child: MaterialApp.router(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ListingsQuery());
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  late _MockAuthCubit auth;
  late _MockFavoritesCubit favs;
  late _MockSellersRepository sellersRepo;
  late _MockMessagingRepository messagingRepo;
  late _MockListingsRepository listingsRepo;

  late MockFilterAlertsRepository browseFilterAlertsRepo;
  late MockNotificationsRepository browseNotificationsRepo;
  late MockPushNotificationRegistrationService browsePushReg;

  setUp(() async {
    await sl.reset();
    auth = _MockAuthCubit();
    favs = _MockFavoritesCubit();
    sellersRepo = _MockSellersRepository();
    messagingRepo = _MockMessagingRepository();
    listingsRepo = _MockListingsRepository();

    when(
      () => sellersRepo.getSellerPublicProfile(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => sellersRepo.getMySellerProfile(),
    ).thenAnswer((_) async => Success(_stubSellerSelf()));
    when(
      () => messagingRepo.getUnreadConversationCount(),
    ).thenAnswer((_) async => const Success(0));
    when(
      () => listingsRepo.getListings(any()),
    ).thenAnswer((_) async => const Success([]));
    when(() => listingsRepo.fetchBuyerVinReportSources(any())).thenAnswer(
      (_) async => const Success(BuyerListingVinReportLookupResult()),
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

    sl.registerLazySingleton<LastAppliedListingDiscoveryRepository>(
      () => const NoopLastAppliedListingDiscoveryRepository(),
    );

    browseFilterAlertsRepo = MockFilterAlertsRepository();
    browseNotificationsRepo = MockNotificationsRepository();
    browsePushReg = MockPushNotificationRegistrationService();
    primeListingBrowseFilterAlertsDeps(
      sl,
      filterRepo: browseFilterAlertsRepo,
      notificationsRepo: browseNotificationsRepo,
      pushRegistration: browsePushReg,
    );

    sl.registerFactory<ListingsBloc>(
      () => ListingsBloc(
        getListings: GetListings(listingsRepo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('filters sheet exposes Stage 1 discovery controls', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      _host(
        auth: auth,
        favorites: favs,
        sellersRepo: sellersRepo,
        messagingRepo: messagingRepo,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip(l10n.listingsFiltersTooltip));
    await tester.pumpAndSettle();

    expect(find.text(l10n.filterModel), findsWidgets);
    expect(find.text(l10n.filterYearFromShort), findsOneWidget);
    expect(find.text(l10n.filterYearToShort), findsOneWidget);
    expect(find.text(l10n.filterPriceFrom), findsOneWidget);
    expect(find.text(l10n.filterPriceTo), findsOneWidget);
    expect(find.text(l10n.filterPriceCurrencyAny), findsOneWidget);
    expect(find.text(l10n.filterMaxMileage), findsOneWidget);
    expect(find.text(l10n.filterCity), findsOneWidget);
    expect(find.text(l10n.listingBodyTypeSectionTitle), findsOneWidget);
    expect(find.text(l10n.filterSortLabel), findsWidgets);
    expect(find.text(l10n.filtersSectionMakeModel), findsOneWidget);
    expect(find.text(l10n.filtersSectionBudget), findsOneWidget);
  });

  testWidgets('browse filter sheet header exposes catalog filter-alert bell', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        auth: auth,
        favorites: favs,
        sellersRepo: sellersRepo,
        messagingRepo: messagingRepo,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(ruStrings().listingsFiltersTooltip));
    await tester.pumpAndSettle();

    expect(
      find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
      findsOneWidget,
    );
  });

  testWidgets(
    'regression: tapping the bell on a baseline catalog and then closing '
    'the sheet via "Show cars" does not bleed a too-broad SnackBar onto '
    'the listings page (the feedback stays sheet-local)',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      when(() => auth.state).thenReturn(
        AuthState.authenticated(const AuthUser(id: 'id', email: 'e@m.com')),
      );
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: AuthState.authenticated(
          const AuthUser(id: 'id', email: 'e@m.com'),
        ),
      );

      await tester.pumpWidget(
        _host(
          auth: auth,
          favorites: favs,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
        ),
      );
      await tester.pumpAndSettle();

      final ru = ruStrings();
      await tester.tap(find.byTooltip(ru.listingsFiltersTooltip));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
      await tester.pumpAndSettle();

      // Inline notice is rendered inside the open sheet…
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetTooBroadNoticeKey),
        findsOneWidget,
      );
      // …and no SnackBar is queued — neither the new short copy nor the
      // legacy long sentence.
      expect(find.byType(SnackBar), findsNothing);

      // Close the sheet via "Показать авто" so the criteria-apply path
      // runs end-to-end. The applied criteria is still baseline, but
      // applying must not surface any push/too-broad feedback.
      await tester.tap(find.widgetWithText(FilledButton, ru.filterShowCars));
      await tester.pumpAndSettle();

      // Sheet is dismissed — the inline notice dies with it.
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetTooBroadNoticeKey),
        findsNothing,
      );
      // Listings page must not show the too-broad message in any form:
      // no SnackBar, no leaked inline notice, no legacy long sentence.
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text(ru.catalogBrowseFilterAlertTooBroadInlineTitle),
        findsNothing,
      );
      expect(find.text(ru.catalogBrowseFilterBellTooBroad), findsNothing);
    },
  );
}
