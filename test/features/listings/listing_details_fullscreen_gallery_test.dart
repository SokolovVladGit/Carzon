import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_details_fullscreen_gallery.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/seller_public_profile_test_mocks.dart';
import '../../helpers/listing_details_self_fetch_stubs.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class _MemoryCompareRepository implements CompareRepository {
  @override
  Future<void> clear() async {}

  @override
  Future<List<CompareItem>> loadItems() async => const [];

  @override
  Future<void> saveItems(List<CompareItem> value) async {}
}

class _CountingNavigatorObserver extends NavigatorObserver {
  int galleryPopCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == null && previousRoute != null) {
      galleryPopCount++;
    }
    super.didPop(route, previousRoute);
  }
}

Listing _listing() => Listing(
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

const _debugStateKey = Key('listing-fullscreen-gallery-debug-state');
const _galleryKey = ValueKey<String>('listing-fullscreen-gallery');
const _closeKey = Key('listing-fullscreen-gallery-close');
const _pageViewKey = Key('listing-fullscreen-gallery-pageview');
const _activeViewerKey = Key('listing-fullscreen-gallery-active-viewer');
const _coordinatorKey = Key(
  'listing-fullscreen-gallery-interaction-coordinator',
);

ListingFullscreenGalleryDebugState _debugState(WidgetTester tester) => tester
    .widget<ListingFullscreenGalleryDebugState>(find.byKey(_debugStateKey));

void _expectIdentity(Matrix4 matrix) {
  expect(matrix.getMaxScaleOnAxis(), closeTo(1, 0.001));
  expect(matrix.storage[12], closeTo(0, 0.001));
  expect(matrix.storage[13], closeTo(0, 0.001));
}

Future<void> _openStandaloneGallery(
  WidgetTester tester, {
  List<String> urls = const [
    'https://cdn.example/a.jpg',
    'https://cdn.example/b.jpg',
  ],
  int initialIndex = 0,
  NavigatorObserver? observer,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: observer == null ? const [] : [observer],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => openListingDetailsFullscreenGallery(
                context,
                listingId: 'l1',
                urls: urls,
                initialIndex: initialIndex,
                heroFlightSourceTopRadius: 20,
              ),
              child: const Text('open-gallery'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open-gallery'));
  await tester.pumpAndSettle();
  expect(find.byKey(_galleryKey), findsOneWidget);
}

Future<void> _dragFromGalleryCenter(WidgetTester tester, Offset delta) async {
  final center = tester.getCenter(find.byKey(_pageViewKey));
  await tester.dragFrom(center, delta);
}

Future<void> _doubleTapZoom(WidgetTester tester) async {
  final target = find.byKey(_pageViewKey);
  final center = tester.getCenter(target);
  await tester.tapAt(center);
  await tester.pump(const Duration(milliseconds: 40));
  await tester.tapAt(center);
  await tester.pumpAndSettle();
}

Future<void> _pinchFromBase(WidgetTester tester) async {
  final center = tester.getCenter(find.byKey(_coordinatorKey));
  final first = await tester.startGesture(
    center - const Offset(20, 0),
    pointer: 1,
  );
  final second = await tester.startGesture(
    center + const Offset(20, 0),
    pointer: 2,
  );
  await first.moveTo(center - const Offset(90, 0));
  await second.moveTo(center + const Offset(90, 0));
  await tester.pump();
  await first.up();
  await second.up();
  await tester.pumpAndSettle();
}

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late CompareCubit compareCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;

  setUpAll(() => registerFallbackValue(''));

  setUp(() async {
    await sl.reset();
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    compareCubit = CompareCubit(repository: _MemoryCompareRepository());
    sellerProfileUseCase = MockGetSellerPublicProfile();
    stubSellerPublicProfileHidden(sellerProfileUseCase);

    when(() => detailsCubit.load(any())).thenAnswer((_) async {});

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

    registerListingDetailsSelfFetchStubs(sl);
    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
    sl.registerFactory<GetSellerPublicProfile>(() => sellerProfileUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget app(ListingDetailsState initial) {
    when(() => detailsCubit.state).thenReturn(initial);
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: initial,
    );

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
    return MultiBlocProvider(
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
    );
  }

  testWidgets('tapping gallery opens fullscreen scaffold with close control', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ListingDetailsState.success(
          _listing(),
          heroImageUrls: ['https://cdn.example/a.jpg', 'https://cdn.example/b'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('listing-fullscreen-gallery')),
      findsNothing,
    );

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('listing-fullscreen-gallery')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.close), findsWidgets);

    await tester.tap(find.byKey(_closeKey));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('listing-fullscreen-gallery')),
      findsNothing,
    );
  });

  group('standalone fullscreen gallery gestures', () {
    testWidgets('small downward drag snaps back with full backdrop', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await _dragFromGalleryCenter(tester, const Offset(0, 48));
      await tester.pump();
      expect(_debugState(tester).dismissOffset, greaterThan(0));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(_galleryKey), findsOneWidget);
      final state = _debugState(tester);
      expect(state.dismissOffset, 0);
      expect(state.backdropOpacity, 1);
      expect(state.chromeOpacity, 1);
      expect(state.presentationScale, 1);
      expect(state.phase, 'idle');
      _expectIdentity(state.matrix);
    });

    testWidgets('sufficient downward drag closes route once', (tester) async {
      final observer = _CountingNavigatorObserver();
      await _openStandaloneGallery(tester, observer: observer);
      await _dragFromGalleryCenter(tester, const Offset(0, 160));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(_galleryKey), findsNothing);
      expect(observer.galleryPopCount, 1);
    });

    testWidgets('fast downward fling closes with minimum displacement', (
      tester,
    ) async {
      final observer = _CountingNavigatorObserver();
      await _openStandaloneGallery(tester, observer: observer);
      await tester.fling(
        find.byKey(_coordinatorKey),
        const Offset(0, 80),
        1500,
      );
      await tester.pump();
      final releaseState = _debugState(tester);
      expect(
        releaseState.phase,
        'dismissCommitting',
        reason:
            'dy=${releaseState.dismissOffset}, '
            'velocity=${releaseState.releaseVelocity.dy}',
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(_galleryKey), findsNothing);
      expect(observer.galleryPopCount, 1);
    });

    testWidgets('high velocity below minimum displacement does not dismiss', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await tester.fling(
        find.byKey(_coordinatorKey),
        const Offset(0, 20),
        2000,
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(_galleryKey), findsOneWidget);
      final state = _debugState(tester);
      expect(state.phase, 'idle');
      expect(state.dismissOffset, 0);
      _expectIdentity(state.matrix);
    });

    testWidgets('upward drag does not close and returns to center', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await _dragFromGalleryCenter(tester, const Offset(0, -120));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(_galleryKey), findsOneWidget);
      final state = _debugState(tester);
      expect(state.dismissOffset, 0);
      _expectIdentity(state.matrix);
    });

    testWidgets('horizontal swipe changes page without dismiss offset', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await tester.drag(find.byKey(_coordinatorKey), const Offset(-320, 0));
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(state.page, 1);
      expect(state.dismissOffset, 0);
      _expectIdentity(state.matrix);
    });

    testWidgets('horizontal-dominant diagonal pages without vertical dismiss', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await tester.drag(find.byKey(_coordinatorKey), const Offset(-300, 24));
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(state.page, 1);
      expect(state.dismissOffset, 0);
    });

    testWidgets('vertical-dominant downward diagonal drives dismiss offset', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      final startPage = _debugState(tester).page;
      await _dragFromGalleryCenter(tester, const Offset(18, 90));
      await tester.pump();
      final state = _debugState(tester);
      expect(state.page, startPage);
      expect(state.dismissOffset, greaterThan(40));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(_galleryKey), findsOneWidget);
      expect(_debugState(tester).dismissOffset, 0);
    });

    testWidgets('base-scale drag does not leave zoom matrix translated', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await _dragFromGalleryCenter(tester, const Offset(40, 8));
      await tester.pumpAndSettle();
      _expectIdentity(_debugState(tester).matrix);
    });

    testWidgets('zoomed vertical pan does not dismiss or page', (tester) async {
      await _openStandaloneGallery(tester);
      await _doubleTapZoom(tester);
      var state = _debugState(tester);
      expect(state.phase, 'zoomed');
      final beforeTranslationY = state.matrix.storage[13];
      await tester.drag(find.byKey(_activeViewerKey), const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(find.byKey(_galleryKey), findsOneWidget);
      state = _debugState(tester);
      expect(state.dismissOffset, 0);
      expect(state.page, 0);
      expect(state.matrix.storage[13], isNot(closeTo(beforeTranslationY, 0.1)));
    });

    testWidgets('real two-pointer pinch enters zoom and locks dismissal', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await _pinchFromBase(tester);
      var state = _debugState(tester);
      expect(state.phase, 'zoomed');
      expect(state.matrix.getMaxScaleOnAxis(), greaterThan(1.01));

      await _dragFromGalleryCenter(tester, const Offset(0, 160));
      await tester.pumpAndSettle();
      state = _debugState(tester);
      expect(find.byKey(_galleryKey), findsOneWidget);
      expect(state.page, 0);
      expect(state.dismissOffset, 0);
    });

    testWidgets('second pointer cancels page drag and enters pinch', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      final center = tester.getCenter(find.byKey(_pageViewKey));
      final first = await tester.startGesture(center, pointer: 1);
      await first.moveBy(const Offset(-100, 0));
      final second = await tester.startGesture(
        center + const Offset(30, 0),
        pointer: 2,
      );
      await first.moveTo(center - const Offset(100, 0));
      await second.moveTo(center + const Offset(100, 0));
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(state.page, 0);
      expect(state.dismissOffset, 0);
      expect(state.phase, 'zoomed');
      expect(state.matrix.getMaxScaleOnAxis(), greaterThan(1.01));
    });

    testWidgets('second pointer cancels dismiss drag and enters pinch', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      final center = tester.getCenter(find.byKey(_coordinatorKey));
      final first = await tester.startGesture(center, pointer: 1);
      await first.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(_debugState(tester).dismissOffset, greaterThan(0));
      final second = await tester.startGesture(
        center + const Offset(30, 0),
        pointer: 2,
      );
      await first.moveTo(center - const Offset(100, 0));
      await second.moveTo(center + const Offset(100, 0));
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(find.byKey(_galleryKey), findsOneWidget);
      expect(state.dismissOffset, 0);
      expect(state.phase, 'zoomed');
      expect(state.matrix.getMaxScaleOnAxis(), greaterThan(1.01));
    });

    testWidgets('pointer cancellation clears interaction state', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      final center = tester.getCenter(find.byKey(_coordinatorKey));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(0, 55));
      await gesture.cancel();
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(state.phase, 'idle');
      expect(state.dismissOffset, 0);
      _expectIdentity(state.matrix);
    });

    testWidgets('double tap uses one path and reaches 2.5x', (tester) async {
      await _openStandaloneGallery(tester);
      await _doubleTapZoom(tester);
      final state = _debugState(tester);
      expect(state.phase, 'zoomed');
      expect(state.matrix.getMaxScaleOnAxis(), closeTo(2.5, 0.01));
    });

    testWidgets('zoomed horizontal pan does not page', (tester) async {
      await _openStandaloneGallery(tester);
      await _doubleTapZoom(tester);
      final beforeTranslationX = _debugState(tester).matrix.storage[12];
      await tester.drag(find.byKey(_activeViewerKey), const Offset(280, 0));
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(state.page, 0);
      expect(state.matrix.storage[12], isNot(closeTo(beforeTranslationX, 0.1)));
    });

    testWidgets('zoomed pinch changes scale within supported bounds', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await _doubleTapZoom(tester);
      final before = _debugState(tester).matrix.getMaxScaleOnAxis();
      final center = tester.getCenter(find.byKey(_activeViewerKey));
      final first = await tester.startGesture(
        center - const Offset(30, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(30, 0),
        pointer: 2,
      );
      await tester.pump();
      await first.moveTo(center - const Offset(90, 0));
      await second.moveTo(center + const Offset(90, 0));
      await tester.pump();
      await first.moveTo(center - const Offset(120, 0));
      await second.moveTo(center + const Offset(120, 0));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      final after = _debugState(tester).matrix.getMaxScaleOnAxis();
      expect(after, greaterThan(before));
      expect(after, inInclusiveRange(1.0, 4.0));
      expect(_debugState(tester).phase, 'zoomed');
    });

    testWidgets('zoom out restores dismiss and paging', (tester) async {
      await _openStandaloneGallery(tester);
      await _doubleTapZoom(tester);
      await _doubleTapZoom(tester);
      var state = _debugState(tester);
      expect(state.phase, 'idle');
      _expectIdentity(state.matrix);
      await tester.drag(find.byKey(_coordinatorKey), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(_debugState(tester).page, 1);
      await _dragFromGalleryCenter(tester, const Offset(0, 170));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(_galleryKey), findsNothing);
    });

    testWidgets('cancelled dismiss then horizontal paging works', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      await _dragFromGalleryCenter(tester, const Offset(0, 40));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.drag(find.byKey(_coordinatorKey), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(_debugState(tester).page, 1);
    });

    testWidgets('paging remains locked during dismiss snap-back', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      final center = tester.getCenter(find.byKey(_coordinatorKey));
      final dismiss = await tester.startGesture(center);
      await dismiss.moveBy(const Offset(0, 60));
      await dismiss.up();
      await tester.pump(const Duration(milliseconds: 30));
      expect(_debugState(tester).phase, 'dismissSnappingBack');

      await tester.drag(find.byKey(_coordinatorKey), const Offset(-320, 0));
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(state.page, 0);
      expect(state.phase, 'idle');
      expect(state.dismissOffset, 0);
    });

    testWidgets('close during snap-back resets then performs normal pop', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      final center = tester.getCenter(find.byKey(_coordinatorKey));
      final dismiss = await tester.startGesture(center);
      await dismiss.moveBy(const Offset(0, 60));
      await dismiss.up();
      await tester.pump(const Duration(milliseconds: 30));
      expect(_debugState(tester).phase, 'dismissSnappingBack');
      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_galleryKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('system back during active drag resets and pops safely', (
      tester,
    ) async {
      await _openStandaloneGallery(tester);
      final center = tester.getCenter(find.byKey(_coordinatorKey));
      final dismiss = await tester.startGesture(center);
      await dismiss.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(_debugState(tester).dismissOffset, greaterThan(0));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await dismiss.cancel();
      expect(find.byKey(_galleryKey), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('interactive commit has one pop and no reverse tail', (
      tester,
    ) async {
      final observer = _CountingNavigatorObserver();
      await _openStandaloneGallery(tester, observer: observer);
      await _dragFromGalleryCenter(tester, const Offset(0, 160));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      expect(find.byKey(_galleryKey), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 20));
      final tailPumps = await tester.pumpAndSettle(
        const Duration(milliseconds: 1),
      );
      expect(find.byKey(_galleryKey), findsNothing);
      expect(observer.galleryPopCount, 1);
      expect(tailPumps, lessThan(10));
    });

    testWidgets('middle page can move to both boundaries cleanly', (
      tester,
    ) async {
      await _openStandaloneGallery(
        tester,
        urls: const [
          'https://cdn.example/a.jpg',
          'https://cdn.example/b.jpg',
          'https://cdn.example/c.jpg',
        ],
        initialIndex: 1,
      );
      expect(_debugState(tester).page, 1);
      await tester.drag(find.byKey(_coordinatorKey), const Offset(320, 0));
      await tester.pumpAndSettle();
      expect(_debugState(tester).page, 0);
      await tester.drag(find.byKey(_coordinatorKey), const Offset(-320, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(_coordinatorKey), const Offset(-320, 0));
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(state.page, 2);
      _expectIdentity(state.matrix);
    });

    testWidgets('reopen starts centered with clean metrics', (tester) async {
      await _openStandaloneGallery(tester);
      await _dragFromGalleryCenter(tester, const Offset(0, 55));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open-gallery'));
      await tester.pumpAndSettle();
      final state = _debugState(tester);
      expect(state.dismissOffset, 0);
      expect(state.backdropOpacity, 1);
      _expectIdentity(state.matrix);
    });

    testWidgets('close control closes gallery', (tester) async {
      await _openStandaloneGallery(tester);
      await tester.tap(find.byKey(_closeKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_galleryKey), findsNothing);
    });

    testWidgets('system back closes gallery', (tester) async {
      await _openStandaloneGallery(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(_galleryKey), findsNothing);
    });

    testWidgets('single-photo gallery dismisses and zooms without paging', (
      tester,
    ) async {
      await _openStandaloneGallery(
        tester,
        urls: const ['https://cdn.example/only.jpg'],
      );
      expect(
        find.byKey(const Key('listing-fullscreen-gallery-indicator')),
        findsNothing,
      );
      await _doubleTapZoom(tester);
      expect(_debugState(tester).phase, 'zoomed');
      await _doubleTapZoom(tester);
      await _dragFromGalleryCenter(tester, const Offset(0, 170));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(_galleryKey), findsNothing);
    });
  });
}
