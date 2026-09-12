import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_toggle_button.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/models/listing_preview_data.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/listing_submit_title.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_card.dart';
import 'package:carzon/features/listings/presentation/widgets/vin_present_latin_badge.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/brands/brand_logo_glyph.dart';
import 'package:carzon/shared/ui/carzon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/create_listing_test_stubs.dart';
import '../../helpers/fake_vehicle_model_catalog_repository.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockCreateCubit extends MockCubit<CreateListingState>
    implements CreateListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

const _pngA = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

const _pngB = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xDE,
  0x00,
  0x00,
  0x00,
  0x0C,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xD7,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x03,
  0x01,
  0x01,
  0x00,
  0x18,
  0xDD,
  0x8D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  final ru = ruStrings();
  final ro = roStrings();

  group('listingPreviewDataFromCreateForm', () {
    test('uses resolvedListingTitleForSubmit and does not invent price', () {
      final data = listingPreviewDataFromCreateForm(
        l10n: ru,
        make: 'BMW',
        model: 'X5',
        variant: 'xDrive40i',
        year: 2020,
        priceText: '8900',
        currency: ListingCurrency.eur,
        mileageText: '120000',
        marketRegion: MarketRegion.transnistria,
        city: 'Тирасполь',
        listingType: ListingType.sale,
        vinText: '1HGBH41JXMN109186',
      );

      expect(
        data.submissionTitle,
        resolvedListingTitleForSubmit(
          trimmedUserTitle: '',
          make: 'BMW',
          model: 'X5',
          year: 2020,
          l10n: ru,
          variant: 'xDrive40i',
        ),
      );
      expect(data.priceAmount, 8900);
      expect(data.mileageKm, 120000);
      expect(data.hasValidVin, isTrue);
      expect(data.coverBytes, isNull);
      expect(data.bodyType, isNull);
      expect(data.fuelType, isNull);
    });

    test('maps optional form specs and drops invalid displacement', () {
      final data = listingPreviewDataFromCreateForm(
        l10n: ru,
        make: 'Ram',
        model: '1500',
        year: 2021,
        priceText: '64000',
        currency: ListingCurrency.eur,
        mileageText: '23500',
        marketRegion: MarketRegion.transnistria,
        city: 'Тирасполь',
        listingType: ListingType.sale,
        bodyType: ListingBodyType.pickup,
        fuelType: ListingFuelType.petrol,
        transmissionType: ListingTransmissionType.automatic,
        drivetrain: ListingDrivetrain.fourWheel,
        engineDisplacementLiters: 6.2,
      );
      expect(data.bodyType, ListingBodyType.pickup);
      expect(data.fuelType, ListingFuelType.petrol);
      expect(data.transmissionType, ListingTransmissionType.automatic);
      expect(data.drivetrain, ListingDrivetrain.fourWheel);
      expect(data.engineDisplacementLiters, 6.2);
      expect(listingPreviewDisplacementLiters(0), isNull);
      expect(listingPreviewDisplacementLiters(31), isNull);
    });

    test('listingPreviewJoin omits empty fragments and separators', () {
      expect(listingPreviewJoin(const [null, '', '  ']), isEmpty);
      expect(listingPreviewJoin(const ['2021']), '2021');
      expect(
        listingPreviewJoin(const ['2021', null, 'Тирасполь']),
        '2021 · Тирасполь',
      );
      expect(
        listingPreviewJoin(const [null, '23 500 км', '2021', '']),
        '23 500 км · 2021',
      );
    });

    test('empty and invalid price stay null (never zero)', () {
      expect(
        listingPreviewDataFromCreateForm(
          l10n: ru,
          make: '',
          model: '',
          priceText: '',
          currency: ListingCurrency.eur,
          mileageText: '',
          marketRegion: MarketRegion.moldova,
          city: '',
          listingType: ListingType.sale,
        ).priceAmount,
        isNull,
      );
      expect(parseListingPreviewPrice('0'), isNull);
      expect(parseListingPreviewPrice('abc'), isNull);
      expect(parseListingPreviewMileage(''), isNull);
      expect(parseListingPreviewMileage('0'), 0);
    });
  });

  group('ListingPreviewCard', () {
    Widget host(ListingPreviewData data, {Locale locale = const Locale('ru')}) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListingPreviewCard(
              data: data,
              l10n: locale.languageCode == 'ro' ? ro : ru,
            ),
          ),
        ),
      );
    }

    testWidgets('renders without a persisted Listing and without actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'BMW',
            model: 'X5',
            year: 2020,
            priceText: '8900',
            currency: ListingCurrency.eur,
            mileageText: '120000',
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ListingPreviewCard), findsOneWidget);
      expect(find.byType(ListingCard), findsNothing);
      expect(find.byType(FavoriteToggleButton), findsNothing);
      expect(find.byType(CompareToggleButton), findsNothing);
      expect(find.byType(VinPresentLatinBadge), findsNothing);
      expect(
        find.text(formatListingPrice(8900, ListingCurrency.eur)),
        findsOneWidget,
      );
      expect(find.text('BMW X5'), findsOneWidget);
      expect(
        find.text('${formatKm(ru, 120000)} · 2020 · Тирасполь'),
        findsOneWidget,
      );
      expect(find.text(ru.formatTypeSale), findsNothing);
      expect(find.textContaining('— ·'), findsNothing);
      expect(
        find.byKey(ListingPreviewCard.coverPlaceholderKey),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(find.byKey(ListingPreviewCard.coverPlaceholderKey))
            .height,
        ListingPreviewCard.compactCoverHeight,
      );
    });

    testWidgets('empty preview uses semantic placeholders and stays compact', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: '',
            model: '',
            priceText: '',
            currency: ListingCurrency.eur,
            mileageText: '',
            marketRegion: MarketRegion.transnistria,
            city: '',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(ru.createListingPreviewVehiclePlaceholder),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.priceKey)).data,
        ru.createListingPreviewEnterPrice,
      );
      expect(find.textContaining('€0'), findsNothing);
      expect(find.text(kListingPreviewMissingValue), findsNothing);
      expect(find.byKey(ListingPreviewCard.metaKey), findsNothing);
      expect(find.byKey(ListingPreviewCard.specsKey), findsNothing);
      expect(find.byKey(ListingPreviewCard.variantKey), findsNothing);
      expect(
        find.byKey(ListingPreviewCard.coverPlaceholderKey),
        findsOneWidget,
      );
      expect(find.text(ru.createListingPreviewAddPhotoHint), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(ListingPreviewCard.coverPlaceholderKey))
            .height,
        ListingPreviewCard.compactCoverHeight,
      );
    });

    testWidgets('partial meta lines omit missing values and separators', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'Ram',
            model: '1500',
            year: 2021,
            priceText: '',
            currency: ListingCurrency.eur,
            mileageText: '',
            marketRegion: MarketRegion.transnistria,
            city: '',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.metaKey)).data,
        '2021 · ${ru.regionTransnistria}',
      );
      expect(find.textContaining('—'), findsNothing);

      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'Ram',
            model: '1500',
            year: 2021,
            priceText: '',
            currency: ListingCurrency.eur,
            mileageText: '',
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.metaKey)).data,
        '2021 · Тирасполь',
      );

      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'Ram',
            model: '1500',
            year: 2021,
            priceText: '64000',
            currency: ListingCurrency.eur,
            mileageText: '23500',
            marketRegion: MarketRegion.transnistria,
            city: '',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.metaKey)).data,
        '${formatKm(ru, 23500)} · 2021 · ${ru.regionTransnistria}',
      );

      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'Ram',
            model: '1500',
            year: 2021,
            priceText: '64000',
            currency: ListingCurrency.eur,
            mileageText: '23500',
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.metaKey)).data,
        '${formatKm(ru, 23500)} · 2021 · Тирасполь',
      );
    });

    testWidgets('variant is secondary; empty variant leaves no row', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'Ram',
            model: '1500',
            variant: 'TRX',
            year: 2021,
            priceText: '1',
            currency: ListingCurrency.eur,
            mileageText: '1',
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.variantKey)).data,
        'TRX',
      );

      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'Ram',
            model: '1500',
            year: 2021,
            priceText: '1',
            currency: ListingCurrency.eur,
            mileageText: '1',
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(ListingPreviewCard.variantKey), findsNothing);
    });

    testWidgets('form specs render localized and disappear when cleared', (
      tester,
    ) async {
      final withSpecs = listingPreviewDataFromCreateForm(
        l10n: ru,
        make: 'Ram',
        model: '1500',
        year: 2021,
        priceText: '64000',
        currency: ListingCurrency.eur,
        mileageText: '23500',
        marketRegion: MarketRegion.transnistria,
        city: 'Тирасполь',
        listingType: ListingType.sale,
        bodyType: ListingBodyType.pickup,
        fuelType: ListingFuelType.petrol,
        transmissionType: ListingTransmissionType.automatic,
        drivetrain: ListingDrivetrain.fourWheel,
        engineDisplacementLiters: 6.2,
      );
      await tester.pumpWidget(host(withSpecs));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).data,
        listingPreviewJoin([
          ru.listingFuelTypePetrol,
          ru.listingTransmissionAutomatic,
          ru.listingDrivetrainFourWheel,
          formatEngineDisplacementForDisplay(ru, 6.2),
          ru.listingBodyTypePickup,
        ]),
      );
      expect(find.text('Gasoline'), findsNothing);
      expect(find.text('Automatic'), findsNothing);

      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'Ram',
            model: '1500',
            year: 2021,
            priceText: '64000',
            currency: ListingCurrency.eur,
            mileageText: '23500',
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
            listingType: ListingType.sale,
            fuelType: ListingFuelType.diesel,
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).data,
        ru.listingFuelTypeDiesel,
      );
    });

    testWidgets(
      'known brand glyph stays beside identity; unknown stays clean',
      (tester) async {
        await tester.pumpWidget(
          host(
            listingPreviewDataFromCreateForm(
              l10n: ru,
              make: 'BMW',
              model: 'X5',
              year: 2020,
              priceText: '1',
              currency: ListingCurrency.eur,
              mileageText: '1',
              marketRegion: MarketRegion.transnistria,
              city: 'Тирасполь',
              listingType: ListingType.sale,
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(BrandLogoGlyph), findsOneWidget);
        expect(find.text('BMW X5'), findsOneWidget);

        await tester.pumpWidget(
          host(
            listingPreviewDataFromCreateForm(
              l10n: ru,
              make: 'NoSuchBrandZZ',
              model: 'Custom',
              year: 2020,
              priceText: '1',
              currency: ListingCurrency.eur,
              mileageText: '1',
              marketRegion: MarketRegion.transnistria,
              city: 'Тирасполь',
              listingType: ListingType.sale,
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(BrandLogoGlyph), findsNothing);
        expect(find.text('NoSuchBrandZZ Custom'), findsOneWidget);
      },
    );

    testWidgets('exchange badge appears; sale stays quiet', (tester) async {
      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            make: 'Audi',
            model: 'A6',
            year: 2019,
            priceText: '1',
            currency: ListingCurrency.usd,
            mileageText: '1',
            marketRegion: MarketRegion.moldova,
            city: 'Chișinău',
            listingType: ListingType.exchange,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(ListingPreviewCard.typeBadgeKey), findsOneWidget);
      expect(find.text(ru.formatTypeExchange), findsOneWidget);
    });

    testWidgets('local cover uses first bytes and survives decode failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            coverBytes: Uint8List.fromList(_pngA),
            make: 'BMW',
            model: 'X5',
            year: 2020,
            priceText: '1000',
            currency: ListingCurrency.eur,
            mileageText: '10',
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(ListingPreviewCard.coverKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(ListingPreviewCard.coverKey)).height,
        greaterThan(ListingPreviewCard.compactCoverHeight + 40),
      );

      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ru,
            coverBytes: Uint8List.fromList([1, 2, 3]),
            make: 'BMW',
            model: 'X5',
            year: 2020,
            priceText: '1000',
            currency: ListingCurrency.eur,
            mileageText: '10',
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
            listingType: ListingType.sale,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(ListingPreviewCard.coverPlaceholderKey),
        findsOneWidget,
      );
    });

    testWidgets('RO heading and narrow width do not overflow', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        host(
          listingPreviewDataFromCreateForm(
            l10n: ro,
            make: 'Mercedes-Benz',
            model: 'S-Class',
            year: 2021,
            priceText: '25000',
            currency: ListingCurrency.eur,
            mileageText: '999999',
            marketRegion: MarketRegion.moldova,
            city: 'Ceadîr-Lunga',
            listingType: ListingType.both,
          ),
          locale: const Locale('ro'),
        ),
      );
      await tester.pump();

      expect(find.text(ro.createListingPreviewHeading), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 RU/RO and large text do not overflow', (tester) async {
      Future<void> pumpAt({
        required Size size,
        required double textScale,
        required Locale locale,
        required ListingPreviewData data,
      }) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: host(data, locale: locale),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ruData = listingPreviewDataFromCreateForm(
        l10n: ru,
        make: 'Mercedes-Benz',
        model: 'S-Class',
        variant: 'AMG Line Long',
        year: 2021,
        priceText: '25000',
        currency: ListingCurrency.eur,
        mileageText: '999999',
        marketRegion: MarketRegion.moldova,
        city: 'Ceadîr-Lunga',
        listingType: ListingType.both,
        fuelType: ListingFuelType.petrol,
        transmissionType: ListingTransmissionType.automatic,
        drivetrain: ListingDrivetrain.awd,
        engineDisplacementLiters: 3.0,
      );
      final roData = listingPreviewDataFromCreateForm(
        l10n: ro,
        make: 'Mercedes-Benz',
        model: 'S-Class',
        variant: 'AMG Line Long',
        year: 2021,
        priceText: '25000',
        currency: ListingCurrency.eur,
        mileageText: '999999',
        marketRegion: MarketRegion.moldova,
        city: 'Ceadîr-Lunga',
        listingType: ListingType.both,
        fuelType: ListingFuelType.petrol,
        transmissionType: ListingTransmissionType.automatic,
        drivetrain: ListingDrivetrain.awd,
        engineDisplacementLiters: 3.0,
      );

      await pumpAt(
        size: const Size(320, 568),
        textScale: 1,
        locale: const Locale('ru'),
        data: ruData,
      );
      await pumpAt(
        size: const Size(375, 812),
        textScale: 1.3,
        locale: const Locale('ru'),
        data: ruData,
      );
      await pumpAt(
        size: const Size(320, 568),
        textScale: 1.3,
        locale: const Locale('ro'),
        data: roData,
      );
      expect(
        find.text(formatListingPrice(25000, ListingCurrency.eur)),
        findsOneWidget,
      );
    });
  });

  group('CreateListingPage preview', () {
    late _MockCreateCubit createCubit;
    late _MockAuthCubit authCubit;
    late FakeVehicleModelCatalogRepository catalog;

    setUp(() async {
      await sl.reset();
      catalog = FakeVehicleModelCatalogRepository();
      createCubit = _MockCreateCubit();
      authCubit = _MockAuthCubit();
      when(() => createCubit.state).thenReturn(const CreateListingState.idle());
      whenListen(
        createCubit,
        const Stream<CreateListingState>.empty(),
        initialState: const CreateListingState.idle(),
      );
      const user = AuthUser(id: 'u1', email: 'seller@example.com');
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.authenticated(user));
      whenListen(
        authCubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );
      stubCreateListingVinResolve(createCubit);
      sl.registerFactory<CreateListingCubit>(() => createCubit);
    });

    tearDown(() async {
      await sl.reset();
    });

    Widget wrap({
      CreateListingImagePicker? imagePicker,
      Locale locale = const Locale('ru'),
    }) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: CreateListingPage(
          imagePicker: imagePicker,
          vehicleModelCatalog: catalog,
        ),
      ),
    );

    testWidgets('live price/mileage and type badge follow form state', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.byType(ListingPreviewCard), findsOneWidget);
      expect(find.byType(ListingCard), findsNothing);
      expect(find.byType(FavoriteToggleButton), findsNothing);
      expect(find.byType(CompareToggleButton), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('create_listing_price_field')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_price_field')),
        '8900',
      );
      await tester.enterText(
        find.byKey(const ValueKey('create_listing_mileage_field')),
        '0',
      );
      await tester.pump();

      expect(
        find.text(formatListingPrice(8900, ListingCurrency.eur)),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.metaKey)).data,
        '${formatKm(ru, 0)} · ${ru.regionTransnistria}',
      );
      expect(find.textContaining('—'), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('create_listing_type_section')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(ru.formatTypeExchange));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byType(ListingPreviewCard),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.byKey(ListingPreviewCard.typeBadgeKey), findsOneWidget);
    });

    testWidgets('Advanced spec edits update preview immediately', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      expect(find.byKey(ListingPreviewCard.specsKey), findsNothing);
      await expandCreateListingAdditionalDetails(tester);
      final fuel = find.byKey(const ValueKey('create_listing_fuel_field'));
      await tester.scrollUntilVisible(
        fuel,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(fuel);
      await tester.tap(fuel);
      await tester.pumpAndSettle();
      await tester.tap(find.text(ru.listingFuelTypeDiesel));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(ListingPreviewCard.specsKey),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<Text>(find.byKey(ListingPreviewCard.specsKey)).data,
        ru.listingFuelTypeDiesel,
      );
    });

    testWidgets(
      'first local photo is preview cover; removing it promotes next',
      (tester) async {
        var picks = 0;
        await tester.pumpWidget(
          wrap(
            imagePicker:
                ({
                  required source,
                  required maxWidth,
                  required imageQuality,
                }) async {
                  picks += 1;
                  final bytes = Uint8List.fromList(picks == 1 ? _pngA : _pngB);
                  return XFile.fromData(
                    bytes,
                    name: 'car$picks.png',
                    mimeType: 'image/png',
                  );
                },
          ),
        );
        await tester.pump();

        tester.testTextInput.hide();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
        await tester.pumpAndSettle();
        final media = find.byKey(
          const ValueKey('create_listing_media_section'),
        );
        await tester.ensureVisible(media);
        await tester.pumpAndSettle();
        await tester.tap(media);
        await tester.pumpAndSettle();

        expect(find.byKey(ListingPreviewCard.coverKey), findsOneWidget);
        final firstCover =
            tester.widget<Image>(find.byKey(ListingPreviewCard.coverKey)).image
                as MemoryImage;
        expect(firstCover.bytes, Uint8List.fromList(_pngA));

        await tester.ensureVisible(find.text(ru.createListingAddMorePhotos));
        await tester.tap(find.text(ru.createListingAddMorePhotos));
        await tester.pumpAndSettle();
        final removeFirst = find.byIcon(CarzonIcons.close).first;
        await tester.ensureVisible(removeFirst);
        await tester.pumpAndSettle();
        await tester.tap(removeFirst);
        await tester.pump();

        final nextCover =
            tester.widget<Image>(find.byKey(ListingPreviewCard.coverKey)).image
                as MemoryImage;
        expect(nextCover.bytes, Uint8List.fromList(_pngB));
      },
    );
  });

  test('RU/RO preview keys stay in parity and non-English', () {
    final ruArb =
        jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync())
            as Map<String, dynamic>;
    final roArb =
        jsonDecode(File('lib/l10n/app_ro.arb').readAsStringSync())
            as Map<String, dynamic>;
    const keys = [
      'createListingPreviewHeading',
      'createListingPreviewVehiclePlaceholder',
      'createListingPreviewCoverLabel',
      'createListingPreviewCoverEmptyLabel',
      'createListingPreviewAddPhotoHint',
      'createListingPreviewEnterPrice',
    ];
    for (final key in keys) {
      expect(ruArb[key], isA<String>());
      expect(roArb[key], isA<String>());
    }
    expect(ru.createListingPreviewHeading, isNot('Listing preview'));
    expect(ro.createListingPreviewHeading, isNot('Listing preview'));
    expect(ru.createListingPreviewHeading, 'Предпросмотр объявления');
    expect(ro.createListingPreviewHeading, 'Previzualizarea anunțului');
  });
}
