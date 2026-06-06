import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/compare_cubit_test_helpers.dart';
import '../../helpers/seller_public_profile_test_mocks.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late CompareCubit compareCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;
  final l10n = ruStrings();

  setUpAll(() {
    registerFallbackValue('fallback-listing-id');
  });

  setUp(() async {
    await sl.reset();
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    compareCubit = newInMemoryCompareCubit();
    sellerProfileUseCase = MockGetSellerPublicProfile();
    stubSellerPublicProfileHidden(sellerProfileUseCase);

    when(() => detailsCubit.load(any())).thenAnswer((_) async {});
    when(
      () => detailsCubit.startConversationForListing(any()),
    ).thenThrow(StateError('unstubbed startConversationForListing'));

    when(() => favoritesCubit.state).thenReturn(const FavoritesState());
    whenListen(
      favoritesCubit,
      const Stream<FavoritesState>.empty(),
      initialState: const FavoritesState(),
    );

    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
    sl.registerFactory<GetSellerPublicProfile>(() => sellerProfileUseCase);
  });

  tearDown(() async {
    await compareCubit.close();
    await sl.reset();
  });

  Listing listingWithSeller({String? sellerId}) => Listing(
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
    sellerId: sellerId,
    contactPhone: '+373 690 00001',
  );

  void stubAuth(AuthState state) {
    when(() => authCubit.state).thenReturn(state);
    whenListen(authCubit, const Stream<AuthState>.empty(), initialState: state);
  }

  void stubListing(Listing listing) {
    when(
      () => detailsCubit.state,
    ).thenReturn(ListingDetailsState.success(listing));
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: ListingDetailsState.success(listing),
    );
  }

  Future<void> pumpDetails(WidgetTester tester, GoRouter router) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
          BlocProvider<CompareCubit>.value(value: compareCubit),
        ],
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('chat tap when unauthenticated shows sign-in snackbar', (
    tester,
  ) async {
    stubAuth(const AuthState.unauthenticated());
    stubListing(listingWithSeller(sellerId: 'seller-a'));

    final router = GoRouter(
      initialLocation: '/listings/l1',
      routes: [
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) =>
              ListingDetailsPage(id: state.pathParameters['id']!),
        ),
      ],
    );
    await pumpDetails(tester, router);

    await tester.tap(find.text(l10n.chatLabel));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(l10n.messagingSignInRequired), findsOneWidget);
    verifyNever(() => detailsCubit.startConversationForListing(any()));
  });

  testWidgets('chat tap when seller_id is null shows unavailable snackbar', (
    tester,
  ) async {
    stubAuth(
      const AuthState.authenticated(AuthUser(id: 'buyer-1', email: 'b@x.com')),
    );
    stubListing(listingWithSeller(sellerId: null));

    final router = GoRouter(
      initialLocation: '/listings/l1',
      routes: [
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) =>
              ListingDetailsPage(id: state.pathParameters['id']!),
        ),
      ],
    );
    await pumpDetails(tester, router);

    await tester.tap(find.text(l10n.chatLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingUnavailableNoSeller), findsOneWidget);
    verifyNever(() => detailsCubit.startConversationForListing(any()));
  });

  testWidgets('chat tap on own listing shows self-message snackbar', (
    tester,
  ) async {
    stubAuth(
      const AuthState.authenticated(AuthUser(id: 'seller-1', email: 's@x.com')),
    );
    stubListing(listingWithSeller(sellerId: 'seller-1'));

    final router = GoRouter(
      initialLocation: '/listings/l1',
      routes: [
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) =>
              ListingDetailsPage(id: state.pathParameters['id']!),
        ),
      ],
    );
    await pumpDetails(tester, router);

    await tester.tap(find.text(l10n.chatLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingCannotMessageSelf), findsOneWidget);
    verifyNever(() => detailsCubit.startConversationForListing(any()));
  });

  testWidgets(
    'authenticated buyer opens conversation via cubit and navigates to thread',
    (tester) async {
      stubAuth(
        const AuthState.authenticated(
          AuthUser(id: 'buyer-1', email: 'b@x.com'),
        ),
      );
      stubListing(listingWithSeller(sellerId: 'seller-99'));
      when(
        () => detailsCubit.startConversationForListing('l1'),
      ).thenAnswer((_) async => const Success<String>('conv-uuid-1'));

      final router = GoRouter(
        initialLocation: '/listings/l1',
        routes: [
          GoRoute(
            path: '/listings/:id',
            builder: (_, state) =>
                ListingDetailsPage(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/messages/:conversationId',
            builder: (_, state) => Scaffold(
              body: Text('thread:${state.pathParameters['conversationId']!}'),
            ),
          ),
        ],
      );

      await pumpDetails(tester, router);

      await tester.tap(find.text(l10n.chatLabel));
      await tester.pumpAndSettle();

      verify(() => detailsCubit.startConversationForListing('l1')).called(1);
      expect(find.text('thread:conv-uuid-1'), findsOneWidget);
    },
  );

  testWidgets('chat tap on RPC failure shows localized snackbar', (
    tester,
  ) async {
    stubAuth(
      const AuthState.authenticated(AuthUser(id: 'buyer-1', email: 'b@x.com')),
    );
    stubListing(listingWithSeller(sellerId: 'seller-99'));
    when(
      () => detailsCubit.startConversationForListing('l1'),
    ).thenAnswer((_) async => FailureResult(NetworkFailure('bad')));

    final router = GoRouter(
      initialLocation: '/listings/l1',
      routes: [
        GoRoute(
          path: '/listings/:id',
          builder: (_, state) =>
              ListingDetailsPage(id: state.pathParameters['id']!),
        ),
      ],
    );
    await pumpDetails(tester, router);

    await tester.tap(find.text(l10n.chatLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.userErrorNetworkCheckConnection), findsOneWidget);
    expect(find.textContaining('bad'), findsNothing);
    verify(() => detailsCubit.startConversationForListing('l1')).called(1);
  });

  testWidgets(
    'chat pill ignores second tap while first get/create is in flight',
    (tester) async {
      stubAuth(
        const AuthState.authenticated(
          AuthUser(id: 'buyer-1', email: 'b@x.com'),
        ),
      );
      stubListing(listingWithSeller(sellerId: 'seller-99'));

      final completer = Completer<Result<String>>();
      when(
        () => detailsCubit.startConversationForListing('l1'),
      ).thenAnswer((_) => completer.future);

      final router = GoRouter(
        initialLocation: '/listings/l1',
        routes: [
          GoRoute(
            path: '/listings/:id',
            builder: (_, state) =>
                ListingDetailsPage(id: state.pathParameters['id']!),
          ),
        ],
      );
      await pumpDetails(tester, router);

      await tester.tap(find.text(l10n.chatLabel));
      await tester.pump();
      await tester.tap(find.text(l10n.chatLabel));
      await tester.pump();

      verify(() => detailsCubit.startConversationForListing('l1')).called(1);

      completer.complete(const Success('c1'));
      await tester.pumpAndSettle();
    },
  );
}
