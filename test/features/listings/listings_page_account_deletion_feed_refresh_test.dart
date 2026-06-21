import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
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

import '../../helpers/browse_catalog_filter_alerts_sl.dart';
import '../../helpers/noop_last_applied_listing_discovery_repository.dart';

class _MockListingsBloc extends MockBloc<ListingsEvent, ListingsState>
    implements ListingsBloc {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MockSellersRepository extends Mock implements SellersRepository {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

const _testUser = AuthUser(
  id: 'user-1',
  email: 'seller@example.com',
  fullName: 'Test Seller',
);

Widget _host({
  required ListingsBloc listingsBloc,
  required AuthCubit authCubit,
  required FavoritesCubit favoritesCubit,
  required SellersRepository sellersRepo,
  required MessagingRepository messagingRepo,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
      BlocProvider(
        create: (_) => SelfSellerVisualCubit(GetMySellerProfile(sellersRepo)),
      ),
      BlocProvider(create: (_) => MessagingUnreadSummaryCubit(messagingRepo)),
    ],
    child: MaterialApp.router(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [GoRoute(path: '/', builder: (_, _) => const ListingsPage())],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ListingsRequested());
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  late _MockListingsBloc listingsBloc;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late _MockSellersRepository sellersRepo;
  late _MockMessagingRepository messagingRepo;

  late MockSavedSearchesRepository browseSavedSearchesRepo;
  late MockNotificationsRepository browseNotificationsRepo;
  late MockPushNotificationRegistrationService browsePushRegistration;

  setUp(() async {
    await sl.reset();
    listingsBloc = _MockListingsBloc();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    sellersRepo = _MockSellersRepository();
    messagingRepo = _MockMessagingRepository();

    when(() => sellersRepo.getMySellerProfile()).thenAnswer(
      (_) async => Success(
        MySellerProfileModel(
          displayName: 'S',
          avatarUrl: null,
          avatarPath: null,
          memberSince: DateTime.utc(2026, 4, 1),
          publicVisibility: true,
        ),
      ),
    );
    when(
      () => messagingRepo.getUnreadConversationCount(),
    ).thenAnswer((_) async => const Success(0));

    when(() => listingsBloc.state).thenReturn(const ListingsState());
    whenListen(
      listingsBloc,
      const Stream<ListingsState>.empty(),
      initialState: const ListingsState(),
    );

    when(() => favoritesCubit.state).thenReturn(const FavoritesState());
    whenListen(
      favoritesCubit,
      const Stream<FavoritesState>.empty(),
      initialState: const FavoritesState(),
    );

    when(
      () => authCubit.state,
    ).thenReturn(const AuthState.authenticated(_testUser));

    sl.registerLazySingleton<LastAppliedListingDiscoveryRepository>(
      () => const NoopLastAppliedListingDiscoveryRepository(),
    );

    browseSavedSearchesRepo = MockSavedSearchesRepository();
    browseNotificationsRepo = MockNotificationsRepository();
    browsePushRegistration = MockPushNotificationRegistrationService();
    primeListingBrowseFilterAlertsDeps(
      sl,
      savedSearchesRepo: browseSavedSearchesRepo,
      notificationsRepo: browseNotificationsRepo,
      pushRegistration: browsePushRegistration,
    );

    sl.registerFactory<ListingsBloc>(() => listingsBloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('account deletion signal dispatches an extra listings reload', (
    tester,
  ) async {
    whenListen(
      authCubit,
      Stream.fromIterable([
        const AuthState.unauthenticated(publicFeedRefreshNonce: 1),
      ]),
      initialState: const AuthState.authenticated(_testUser),
    );

    await tester.pumpWidget(
      _host(
        listingsBloc: listingsBloc,
        authCubit: authCubit,
        favoritesCubit: favoritesCubit,
        sellersRepo: sellersRepo,
        messagingRepo: messagingRepo,
      ),
    );
    await tester.pump();
    await tester.pump();

    verify(() => listingsBloc.add(const ListingsRequested())).called(2);
  });

  testWidgets(
    'sign-out without account deletion only seeds the initial feed load',
    (tester) async {
      whenListen(
        authCubit,
        Stream.fromIterable([const AuthState.unauthenticated()]),
        initialState: const AuthState.authenticated(_testUser),
      );

      await tester.pumpWidget(
        _host(
          listingsBloc: listingsBloc,
          authCubit: authCubit,
          favoritesCubit: favoritesCubit,
          sellersRepo: sellersRepo,
          messagingRepo: messagingRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      verify(() => listingsBloc.add(const ListingsRequested())).called(1);
    },
  );
}
