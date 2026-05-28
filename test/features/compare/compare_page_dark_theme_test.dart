import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_page_cubit.dart';
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

CompareListingSnapshot _snap(String id) {
  return CompareListingSnapshot(
    listingId: id,
    addedAt: DateTime.utc(2026, 5, 22),
    make: 'BMW',
    model: '3',
    year: 2018,
    priceEur: 15000,
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

  Future<void> pumpCompare(
    WidgetTester tester, {
    required CompareCubit compareCubit,
    required ComparePageCubit pageCubit,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.compare,
      routes: [
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => ComparePage(pageCubit: pageCubit),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: compareCubit,
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('compare page renders key labels in dark theme', (tester) async {
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

    expect(find.text(ru.compareTitle), findsOneWidget);
    expect(find.text(ru.compareVehiclesTitle), findsOneWidget);
    expect(find.text(ru.compareClear), findsOneWidget);
    expect(find.text(ru.compareShowOnlyDifferences), findsOneWidget);
    expect(find.text(ru.compareSectionPriceBasics), findsOneWidget);
    expect(find.byKey(const ValueKey('compare_diff_toggle')), findsOneWidget);
  });

  testWidgets('difference toggle still works in dark theme', (tester) async {
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
}
