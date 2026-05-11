import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/domain/usecases/add_favorite.dart';
import 'package:carzon/features/favorites/domain/usecases/get_favorite_ids.dart';
import 'package:carzon/features/favorites/domain/usecases/get_favorite_listings.dart';
import 'package:carzon/features/favorites/domain/usecases/remove_favorite.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockGetFavoriteIds extends Mock implements GetFavoriteIds {}

class _MockGetFavoriteListings extends Mock implements GetFavoriteListings {}

class _MockAddFavorite extends Mock implements AddFavorite {}

class _MockRemoveFavorite extends Mock implements RemoveFavorite {}

void main() {
  late _MockAuthCubit auth;
  late _MockGetFavoriteIds mockGetFavoriteIds;
  late _MockGetFavoriteListings mockGetFavoriteListings;
  late _MockAddFavorite mockAddFavorite;
  late _MockRemoveFavorite mockRemoveFavorite;

  const listingId = 'listing-42';
  final user = AuthUser(id: 'user-1', email: 'e@example.com');

  setUp(() {
    auth = _MockAuthCubit();
    when(() => auth.state).thenReturn(AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: AuthState.authenticated(user),
    );

    mockGetFavoriteIds = _MockGetFavoriteIds();
    mockGetFavoriteListings = _MockGetFavoriteListings();
    mockAddFavorite = _MockAddFavorite();
    mockRemoveFavorite = _MockRemoveFavorite();

    when(
      () => mockGetFavoriteIds(),
    ).thenAnswer((_) async => const Success(<String>{}));
    when(
      () => mockGetFavoriteListings(),
    ).thenAnswer((_) async => const Success([]));
  });

  FavoritesCubit buildCubit() {
    return FavoritesCubit(
      getFavoriteIds: mockGetFavoriteIds,
      getFavoriteListings: mockGetFavoriteListings,
      addFavorite: mockAddFavorite,
      removeFavorite: mockRemoveFavorite,
    );
  }

  Future<void> syncReady(FavoritesCubit cubit) async {
    await cubit.syncWithAuth(user);
  }

  testWidgets(
    'unfavorited state shows outline heart; toggling completes with filled '
    'heart; no CircularProgressIndicator while pending',
    (tester) async {
      final completer = Completer<Result<void>>();
      when(
        () => mockAddFavorite(listingId),
      ).thenAnswer((_) async => completer.future);

      final cubit = buildCubit();
      await syncReady(cubit);

      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: auth),
                BlocProvider<FavoritesCubit>.value(value: cubit),
              ],
              child: const Center(
                child: FavoriteToggleButton(listingId: listingId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(FavoriteToggleButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      verify(() => mockAddFavorite(listingId)).called(1);

      completer.complete(const Success(null));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('IconButton ignores repeated taps while add is pending '
      '(toggle / addFavorite once)', (tester) async {
    final completer = Completer<Result<void>>();
    when(
      () => mockAddFavorite(listingId),
    ).thenAnswer((_) async => completer.future);

    final cubit = buildCubit();
    await syncReady(cubit);

    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<FavoritesCubit>.value(value: cubit),
            ],
            child: const Center(
              child: FavoriteToggleButton(listingId: listingId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final buttonFinder = find.descendant(
      of: find.byType(FavoriteToggleButton),
      matching: find.byType(IconButton),
    );

    await tester.tap(buttonFinder);
    await tester.pump();

    await tester.tap(buttonFinder);
    await tester.pump();

    verify(() => mockAddFavorite(listingId)).called(1);

    completer.complete(const Success(null));
    await tester.pumpAndSettle();
  });

  testWidgets('favorited state shows filled heart until remove succeeds', (
    tester,
  ) async {
    when(
      () => mockGetFavoriteIds(),
    ).thenAnswer((_) async => Success(<String>{listingId}));
    final completer = Completer<Result<void>>();
    when(
      () => mockRemoveFavorite(listingId),
    ).thenAnswer((_) async => completer.future);

    final cubit = buildCubit();
    await syncReady(cubit);

    await tester.pumpWidget(
      localizedApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<FavoritesCubit>.value(value: cubit),
            ],
            child: const Center(
              child: FavoriteToggleButton(listingId: listingId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(FavoriteToggleButton));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    verify(() => mockRemoveFavorite(listingId)).called(1);

    completer.complete(const Success(null));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });
}
