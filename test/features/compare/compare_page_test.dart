import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_page_cubit.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/features/compare/presentation/pages/compare_page.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_by_id.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_images.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MemoryCompareRepository implements CompareRepository {
  List<CompareItem> items = const [];

  @override
  Future<void> clear() async => items = const [];

  @override
  Future<List<CompareItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<CompareItem> value) async => items = value;
}

class _MockGetListingById extends Mock implements GetListingById {}

class _MockGetListingImages extends Mock implements GetListingImages {}

CompareListingSnapshot _snap(String id, {int price = 15000, int year = 2018}) {
  return CompareListingSnapshot(
    listingId: id,
    addedAt: DateTime.utc(2026, 5, 22),
    make: 'BMW',
    model: '3',
    year: year,
    priceEur: price,
    priceCurrency: ListingCurrency.eur,
  );
}

Listing _listing(
  String id, {
  int price = 15000,
  int year = 2018,
  int mileage = 80000,
}) {
  return Listing(
    id: id,
    title: 'Test',
    make: 'BMW',
    model: '3',
    year: year,
    priceEur: price,
    mileageKm: mileage,
    type: ListingType.sale,
    city: 'Chișinău',
    marketRegion: MarketRegion.moldova,
    createdAt: DateTime.utc(2026, 4, 1),
    status: ListingStatus.active,
    sellerId: 's1',
  );
}

void main() {
  final ru = ruStrings();
  late _MockGetListingById getById;
  late _MockGetListingImages getImages;

  setUp(() {
    getById = _MockGetListingById();
    getImages = _MockGetListingImages();
    registerFallbackValue('');
    when(() => getImages(any())).thenAnswer((_) async => const Success([]));
  });

  Widget compareApp({
    required CompareCubit compareCubit,
    required ComparePageCubit pageCubit,
  }) {
    final router = GoRouter(
      initialLocation: AppRoutes.compare,
      routes: [
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => ComparePage(pageCubit: pageCubit),
        ),
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Scaffold(body: Text('listings-home')),
        ),
      ],
    );
    return MaterialApp.router(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  Future<void> pumpCompare(
    WidgetTester tester, {
    required CompareCubit compareCubit,
    required ComparePageCubit pageCubit,
  }) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: compareCubit,
        child: compareApp(compareCubit: compareCubit, pageCubit: pageCubit),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('empty compare page renders empty state', (tester) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });

    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    expect(find.text(ru.compareVehiclesTitle), findsOneWidget);
    expect(find.text(ru.compareEmptyBody), findsOneWidget);
    expect(
      find.byKey(const ValueKey('compare_browse_listings_button')),
      findsOneWidget,
    );
  });

  testWidgets('one-item compare page renders need-one-more state', (
    tester,
  ) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });
    await cubit.addSnapshot(_snap('only'));

    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    expect(find.text(ru.compareAddOneMoreTitle), findsOneWidget);
    expect(find.text('BMW 3'), findsOneWidget);
  });

  testWidgets('three-item compare page renders spec UI', (tester) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });
    when(() => getById(any())).thenAnswer((_) async => Success(_listing('x')));
    await cubit.addSnapshot(_snap('a'));
    await cubit.addSnapshot(_snap('b'));
    await cubit.addSnapshot(_snap('c'));

    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    expect(find.text(ru.compareVehicleCountShort(3)), findsOneWidget);
    expect(find.text(ru.compareVehicleCountShort(4)), findsNothing);
    expect(find.byKey(const ValueKey('compare_diff_toggle')), findsOneWidget);
  });

  testWidgets('persisted four items are trimmed to three on load', (
    tester,
  ) async {
    final repo = _MemoryCompareRepository()
      ..items = [
        CompareItem(snapshot: _snap('a')),
        CompareItem(snapshot: _snap('b')),
        CompareItem(snapshot: _snap('c')),
        CompareItem(snapshot: _snap('d')),
      ];
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });
    when(() => getById(any())).thenAnswer((_) async => Success(_listing('x')));

    await cubit.loadFromStorage();
    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    expect(cubit.state.count, 3);
    expect(find.text(ru.compareVehicleCountShort(3)), findsOneWidget);
    expect(find.text(ru.compareVehicleCountShort(4)), findsNothing);
    expect(repo.items.length, 3);
  });

  testWidgets('two-item compare page renders spec UI', (tester) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });
    when(() => getById('a')).thenAnswer((_) async => Success(_listing('a')));
    when(() => getById('b')).thenAnswer(
      (_) async =>
          Success(_listing('b', price: 18000, year: 2020, mileage: 50000)),
    );
    await cubit.addSnapshot(_snap('a'));
    await cubit.addSnapshot(_snap('b'));

    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    expect(find.text(ru.compareVehicleCountShort(2)), findsOneWidget);
    expect(find.text(ru.compareSectionPriceBasics), findsOneWidget);
    expect(find.byKey(const ValueKey('compare_diff_toggle')), findsOneWidget);
  });

  testWidgets('difference toggle hides identical rows', (tester) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });
    when(() => getById('a')).thenAnswer((_) async => Success(_listing('a')));
    when(
      () => getById('b'),
    ).thenAnswer((_) async => Success(_listing('b', price: 18000, year: 2020)));
    await cubit.addSnapshot(_snap('a'));
    await cubit.addSnapshot(_snap('b'));

    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    expect(find.text(ru.compareRowMake), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('compare_diff_toggle')));
    await tester.pumpAndSettle();
    expect(find.text(ru.compareRowMake), findsNothing);
  });

  testWidgets('unavailable listing shows muted message', (tester) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });
    when(
      () => getById('gone'),
    ).thenAnswer((_) async => const FailureResult(ServerFailure('x')));
    when(() => getById('ok')).thenAnswer((_) async => Success(_listing('ok')));
    await cubit.addSnapshot(_snap('gone'));
    await cubit.addSnapshot(_snap('ok'));

    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    expect(find.text(ru.compareUnavailableListing), findsOneWidget);
  });

  testWidgets('clear comparison switches to empty state', (tester) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });
    when(() => getById(any())).thenAnswer((_) async => Success(_listing('a')));
    await cubit.addSnapshot(_snap('a'));
    await cubit.addSnapshot(_snap('b'));

    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('compare_clear_button')));
    await tester.pumpAndSettle();

    expect(find.text(ru.compareEmptyBody), findsOneWidget);
  });

  testWidgets('browse CTA navigates to listings route', (tester) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });

    await pumpCompare(tester, compareCubit: cubit, pageCubit: pageCubit);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('compare_browse_listings_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('listings-home'), findsOneWidget);
  });

  testWidgets('back pops when compare was opened via push', (tester) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });

    final router = GoRouter(
      initialLocation: AppRoutes.listings,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Scaffold(
            key: ValueKey('listings-home'),
            body: Text('listings-home'),
          ),
        ),
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => ComparePage(pageCubit: pageCubit),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.push(AppRoutes.compare);
    await tester.pumpAndSettle();
    expect(find.text(ru.compareVehiclesTitle), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listings-home')), findsOneWidget);
  });

  testWidgets('back uses menu fallback when compare has no back stack', (
    tester,
  ) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final pageCubit = ComparePageCubit(
      getListingById: getById,
      getListingImages: getImages,
    );
    addTearDown(() async {
      await cubit.close();
      await pageCubit.close();
    });

    final router = GoRouter(
      initialLocation: AppRoutes.compare,
      routes: [
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => ComparePage(pageCubit: pageCubit),
        ),
        GoRoute(
          path: AppRoutes.menu,
          builder: (_, _) => const Scaffold(
            key: ValueKey('menu-fallback'),
            body: Text('menu-screen'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('menu-fallback')), findsOneWidget);
  });
}
