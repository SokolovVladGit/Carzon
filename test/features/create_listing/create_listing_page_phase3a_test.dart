import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/core/widgets/floating_capsule_nav.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/market_placement_selector.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_media_section.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_type_deal_selector.dart';
import 'package:carzon/features/listings/domain/catalog/listing_brands.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_brand_pick_sheet.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_compose_layout.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_characteristics_facts.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_contact_notice.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_mmy_row.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_picker_field.dart';
import 'package:carzon/features/create_listing/presentation/widgets/premium_listing_controls.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_segmented_control.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/ui/carzon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

const _transparentPng = <int>[
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

void main() {
  setUpAll(() {
    registerFallbackValue(
      NewListingInput(
        sellerId: 'fallback',
        title: '-',
        make: '-',
        model: '-',
        year: 2000,
        priceEur: 1,
        mileageKm: 0,
        type: ListingType.sale,
        city: '-',
        marketRegion: MarketRegion.transnistria,
        contactPhone: '+000',
      ),
    );
    registerFallbackValue(<CoverImageUpload>[]);
  });

  late _MockCreateCubit createCubit;
  late _MockAuthCubit authCubit;
  late FakeVehicleModelCatalogRepository catalog;
  final l10n = ruStrings();

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
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    when(
      () => createCubit.submit(
        listingInput: any(named: 'listingInput'),
        orderedPhotos: any(named: 'orderedPhotos'),
      ),
    ).thenAnswer((_) async {});
    stubCreateListingVinResolve(createCubit);

    sl.registerFactory<CreateListingCubit>(() => createCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap({
    CreateListingImagePicker? imagePicker,
    Locale locale = const Locale('ru'),
    ThemeData? theme,
  }) => MaterialApp(
    locale: locale,
    theme: theme,
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

  Future<void> tapEmptyPhotoHero(WidgetTester tester) async {
    tester.testTextInput.hide();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    final addPhoto = find.byKey(const ValueKey('create_listing_add_photo'));
    await tester.ensureVisible(addPhoto);
    await tester.pumpAndSettle();
    await tester.tap(addPhoto);
    await tester.pump();
  }

  Future<void> openCityPicker(WidgetTester tester) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.ensureVisible(city);
    await tester.pumpAndSettle();
    await tester.tap(city);
    await tester.pumpAndSettle();
  }

  Future<void> chooseRegion(WidgetTester tester, String regionLabel) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final region = find.byKey(const ValueKey('create_listing_region_selector'));
    await tester.ensureVisible(region);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: region, matching: find.text(regionLabel)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillRequiredFieldsExceptCity(WidgetTester tester) async {
    await openCreateListingManualIdentity(tester);
    final brand = find.byKey(const ValueKey('create_listing_brand_field'));
    await tester.scrollUntilVisible(
      brand,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(brand);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Toyota');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
    await tester.pumpAndSettle();

    final modelField = find.byKey(const ValueKey('create_listing_model_field'));
    await tester.ensureVisible(modelField);
    await tester.tap(modelField);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listing_model_Corolla')));
    await tester.pumpAndSettle();
    final year = find.byKey(const ValueKey('create_listing_year_field'));
    await tester.ensureVisible(year);
    await tester.tap(year);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonDone));
    await tester.pumpAndSettle();

    final price = find.widgetWithText(
      TextFormField,
      l10n.createListingPricePlaceholder,
    );
    await tester.scrollUntilVisible(
      price,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(price, '9000');
    await revealCreateListingMileageField(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.createListingMileagePlaceholder),
      '100000',
    );

    final phone = find.widgetWithText(TextFormField, l10n.fieldPhone);
    await tester.scrollUntilVisible(
      phone,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(phone, '+37369000001');
  }

  Future<NewListingInput> submitAndCapture(WidgetTester tester) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final publish = find.text(l10n.publishListing).last;
    await tester.ensureVisible(publish);
    await tester.pumpAndSettle();
    await tester.tap(publish);
    await tester.pump();
    return verify(
          () => createCubit.submit(
            listingInput: captureAny(named: 'listingInput'),
            orderedPhotos: any(named: 'orderedPhotos'),
          ),
        ).captured.single
        as NewListingInput;
  }

  testWidgets(
    'Phase 3A form shell: media, currency, brand, year, publish, disclosure',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.byType(FloatingCapsuleNav), findsNothing);
      expect(
        find.byKey(CreateListingMediaSection.phase3TestKey),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_currency_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_enter_manually')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_brand_field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_year_field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_vin_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_additional_details')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_body_type_field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('create_listing_edit_characteristics')),
        findsOneWidget,
      );
      expect(find.text(l10n.createListingChooseBrand), findsNothing);
      expect(find.text(l10n.createListingEnterManually), findsNothing);
      expect(find.text(l10n.createListingManualVehicleTitle), findsOneWidget);
      expect(find.text(l10n.createListingManualVehicleSubtitle), findsNothing);
      expect(find.text(l10n.createListingOrSeparator), findsNothing);
      expect(find.text(l10n.createListingVinCardHelper), findsOneWidget);
      expect(find.text(l10n.createListingVehicleDataTitle), findsOneWidget);
      expect(find.text(l10n.listingBodyTypeNotSpecified), findsNothing);
      expect(find.text(l10n.createListingPricePlaceholder), findsOneWidget);
      expect(find.text(l10n.createListingMileagePlaceholder), findsOneWidget);
      expect(find.text(l10n.createListingVinPrivacyHelper), findsNothing);
      expect(find.text(l10n.listingVinFieldHelper), findsNothing);
      expect(find.text(l10n.fieldTitleOptional), findsNothing);
      expect(find.byType(CreateListingContactNotice), findsOneWidget);
      expect(find.text(l10n.createListingContactNotice), findsOneWidget);
      expect(find.text(l10n.publishListing), findsWidgets);

      final noticeAppearsAbovePhone =
          tester.getCenter(find.byType(CreateListingContactNotice)).dy <
          tester
              .getCenter(find.widgetWithText(TextFormField, l10n.fieldPhone))
              .dy;
      expect(noticeAppearsAbovePhone, isTrue);

      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'primary sections follow photo-first characteristics-and-description-before-publish order',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      const sectionKeys = [
        'create_listing_photos_section',
        'create_listing_vehicle_section',
        'create_listing_characteristics_section',
        'create_listing_contact_section',
        'create_listing_location_section',
        'create_listing_type_section',
        'create_listing_description_section',
        'create_listing_publish_section',
      ];
      final sections = [
        for (final key in sectionKeys) find.byKey(ValueKey(key)),
      ];

      for (final section in sections) {
        expect(section, findsOneWidget);
      }
      for (var i = 1; i < sections.length; i++) {
        expect(
          tester.getTopLeft(sections[i - 1]).dy,
          lessThan(tester.getTopLeft(sections[i]).dy),
        );
      }

      final vehicle = sections[0];
      final contact = sections[3];
      final location = sections[4];
      final type = sections[5];
      final characteristics = sections[2];
      final publish = sections[7];
      final city = find.byKey(const ValueKey('create_listing_city_field'));
      final region = find.byKey(
        const ValueKey('create_listing_region_selector'),
      );
      final preview = find.byKey(ListingPreviewCard.headingKey);
      final price = find.byKey(const ValueKey('create_listing_price_field'));
      final dealType = find.byType(ListingTypeDealSelector);

      expect(find.text(l10n.createListingSectionLocation), findsOneWidget);
      expect(city, findsOneWidget);
      expect(region, findsOneWidget);
      expect(find.byType(MarketPlacementSelector), findsOneWidget);
      expect(find.descendant(of: vehicle, matching: city), findsNothing);
      expect(find.descendant(of: type, matching: region), findsNothing);
      expect(find.descendant(of: location, matching: region), findsOneWidget);
      expect(find.descendant(of: location, matching: city), findsOneWidget);
      expect(
        find.descendant(
          of: contact,
          matching: find.byType(CreateListingContactNotice),
        ),
        findsOneWidget,
      );
      expect(find.descendant(of: publish, matching: preview), findsOneWidget);
      expect(
        tester.getTopLeft(region).dy,
        lessThan(tester.getTopLeft(city).dy),
      );
      expect(
        tester.getTopLeft(price).dy,
        lessThan(tester.getTopLeft(dealType).dy),
      );
      expect(
        tester.getTopLeft(characteristics).dy,
        lessThan(tester.getTopLeft(preview).dy),
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('create_listing_vin_field')))
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('create_listing_photos_section')),
              )
              .dy,
        ),
      );
      expect(find.text('05'), findsNothing);
      expect(find.text('06'), findsNothing);
      expect(find.text('07'), findsNothing);
    },
  );

  testWidgets('city picker follows region and region change clears selection', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await openCityPicker(tester);
    expect(find.text('Тирасполь'), findsOneWidget);
    expect(find.text('Chișinău'), findsNothing);
    await tester.tap(find.text('Тирасполь'));
    await tester.pumpAndSettle();
    expect(find.text('Тирасполь'), findsWidgets);

    await chooseRegion(tester, l10n.regionMoldova);
    expect(find.text(l10n.listingCitySelectPlaceholder), findsOneWidget);
    await openCityPicker(tester);
    expect(find.text('Chișinău'), findsOneWidget);
    expect(find.text('Тирасполь'), findsNothing);
  });

  testWidgets('manual city mode is revealed and cleared by region change', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await openCityPicker(tester);
    await tester.tap(find.byKey(const ValueKey('listing_city_manual_option')));
    await tester.pumpAndSettle();
    final manual = find.byKey(
      const ValueKey('create_listing_manual_city_field'),
    );
    expect(manual, findsOneWidget);
    await tester.enterText(manual, 'Valea Mare');

    await chooseRegion(tester, l10n.regionMoldova);
    expect(manual, findsNothing);
    expect(find.text('Valea Mare'), findsNothing);
    expect(find.text(l10n.listingCitySelectPlaceholder), findsOneWidget);
  });

  testWidgets('blank city shows one logical city error and skips submit', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final publish = find.text(l10n.publishListing).last;
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pumpAndSettle();

    final city = find.byKey(const ValueKey('create_listing_city_field'));
    expect(
      find.descendant(of: city, matching: find.text(l10n.validationRequired)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_manual_city_field')),
      findsNothing,
    );
    verifyNever(
      () => createCubit.submit(
        listingInput: any(named: 'listingInput'),
        orderedPhotos: any(named: 'orderedPhotos'),
      ),
    );
  });

  testWidgets('manual custom city is trimmed on create submission', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await fillRequiredFieldsExceptCity(tester);
    await openCityPicker(tester);
    await tester.tap(find.byKey(const ValueKey('listing_city_manual_option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_manual_city_field')),
      '  Valea Mare  ',
    );

    final submitted = await submitAndCapture(tester);
    expect(submitted.city, 'Valea Mare');
    expect(submitted.marketRegion, MarketRegion.transnistria);
  });

  testWidgets('manual alias is canonicalized on create submission', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await fillRequiredFieldsExceptCity(tester);
    await chooseRegion(tester, l10n.regionMoldova);
    await openCityPicker(tester);
    await tester.tap(find.byKey(const ValueKey('listing_city_manual_option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_manual_city_field')),
      '  Chisinau  ',
    );

    final submitted = await submitAndCapture(tester);
    expect(submitted.city, 'Chișinău');
    expect(submitted.marketRegion, MarketRegion.moldova);
  });

  testWidgets(
    'empty photo hero: no layout overflow on narrow phone + bumped text scale',
    (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      await binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async {
        await binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.34)),
          child: wrap(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(CreateListingMediaSection.phase3TestKey),
        findsOneWidget,
      );
      expect(find.text(l10n.createListingAddPhoto), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create_listing_photo_placeholder')),
        findsNWidgets(4),
      );
      expect(find.text(l10n.createListingPhotoSlotFront), findsNothing);
      expect(find.text(l10n.createListingPhotoSlotBack), findsNothing);
      expect(find.text(l10n.createListingPhotoSlotInterior), findsNothing);
      expect(find.text(l10n.createListingMediaCoverHint), findsNothing);
    },
  );

  testWidgets('compact form: no overflow at 320 and 375 with text scale 1.3', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    const sectionKeys = [
      'create_listing_photos_section',
      'create_listing_vehicle_section',
      'create_listing_type_section',
      'create_listing_location_section',
      'create_listing_contact_section',
      'create_listing_characteristics_section',
      'create_listing_description_section',
      'create_listing_publish_section',
    ];

    for (final size in const [Size(320, 568), Size(375, 667)]) {
      await binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: const TextScaler.linear(1.3),
          ),
          child: wrap(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (final key in sectionKeys) {
        await tester.ensureVisible(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('compact form: no overflow in RO at 320 with text scale 1.3', (
    tester,
  ) async {
    final ro = roStrings();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.3),
        ),
        child: wrap(locale: const Locale('ro')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const ValueKey('create_listing_vehicle_section')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const ValueKey('create_listing_publish_section')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text(ro.createListingVinCardHelper), findsOneWidget);
    expect(find.text(ro.createListingVehicleDataTitle), findsOneWidget);
  });

  testWidgets('price mileage and phone stack full width at 390 and 320', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    Future<void> pumpAt(Size size) async {
      await binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: wrap(),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpAt(const Size(390, 844));
    final contact = find.byKey(
      const ValueKey('create_listing_contact_section'),
    );
    final phone = tester.getRect(
      find.byKey(const ValueKey('create_listing_phone_field')),
    );
    final mileage = tester.getRect(
      find.byKey(const ValueKey('create_listing_mileage_field')),
    );
    final price = tester.getRect(
      find.byKey(const ValueKey('create_listing_price_field')),
    );
    expect(price.bottom, lessThan(mileage.top));
    expect(mileage.bottom, lessThan(phone.top));
    expect((phone.left - price.left).abs(), lessThan(8));
    expect((mileage.left - price.left).abs(), lessThan(8));
    expect((phone.width - price.width).abs(), lessThan(12));
    expect((mileage.width - price.width).abs(), lessThan(12));
    expect(phone.width, greaterThan(280));
    expect(
      find.descendant(
        of: contact,
        matching: find.byKey(const ValueKey('create_listing_mileage_field')),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await pumpAt(const Size(375, 812));
    final midPhone = tester.getRect(
      find.byKey(const ValueKey('create_listing_phone_field')),
    );
    final midMileage = tester.getRect(
      find.byKey(const ValueKey('create_listing_mileage_field')),
    );
    final midPrice = tester.getRect(
      find.byKey(const ValueKey('create_listing_price_field')),
    );
    expect(midPrice.bottom, lessThan(midMileage.top));
    expect(midMileage.bottom, lessThan(midPhone.top));
    expect((midPhone.left - midPrice.left).abs(), lessThan(8));
    expect((midPhone.width - midPrice.width).abs(), lessThan(12));
    expect(midPhone.width, greaterThan(260));
    final currency = tester.getRect(
      find.byKey(const ValueKey('create_listing_currency_selector')),
    );
    expect(currency.left, greaterThan(midPrice.left + midPrice.width * 0.45));
    expect(tester.takeException(), isNull);

    await pumpAt(const Size(320, 568));
    final narrowPhone = tester.getRect(
      find.byKey(const ValueKey('create_listing_phone_field')),
    );
    final narrowMileage = tester.getRect(
      find.byKey(const ValueKey('create_listing_mileage_field')),
    );
    final narrowPrice = tester.getRect(
      find.byKey(const ValueKey('create_listing_price_field')),
    );
    expect(narrowPrice.bottom, lessThan(narrowMileage.top));
    expect(narrowMileage.bottom, lessThan(narrowPhone.top));
    expect((narrowPhone.left - narrowPrice.left).abs(), lessThan(8));
    expect((narrowPhone.width - narrowPrice.width).abs(), lessThan(12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('optional picker placeholder is replaced by the selected value', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await expandCreateListingAdditionalDetails(tester);
    expect(find.text(l10n.listingFuelType), findsOneWidget);
    expect(find.text(l10n.listingBodyTypeNotSpecified), findsNothing);

    final fuel = find.byKey(const ValueKey('create_listing_fuel_field'));
    await tester.ensureVisible(fuel);
    await tester.tap(fuel);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.listingFuelTypePetrol));
    await tester.pumpAndSettle();

    expect(find.text(l10n.listingFuelTypePetrol), findsWidgets);
    expect(
      find.descendant(of: fuel, matching: find.text(l10n.listingFuelType)),
      findsNothing,
    );
  });

  testWidgets('price mileage and phone stack as full-width rows', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: wrap(),
      ),
    );
    await tester.pumpAndSettle();
    final phone = tester.getRect(
      find.byKey(const ValueKey('create_listing_phone_field')),
    );
    final mileage = tester.getRect(
      find.byKey(const ValueKey('create_listing_mileage_field')),
    );
    final price = tester.getRect(
      find.byKey(const ValueKey('create_listing_price_field')),
    );
    expect(price.bottom, lessThan(mileage.top));
    expect(mileage.bottom, lessThan(phone.top));
    expect((phone.left - price.left).abs(), lessThan(8));
    expect((phone.width - price.width).abs(), lessThan(12));
    expect(phone.width, greaterThan(280));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_contact_section')),
        matching: find.byKey(const ValueKey('create_listing_mileage_field')),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.formatTypeSale), findsOneWidget);
    expect(find.text(l10n.formatTypeExchange), findsOneWidget);
    expect(find.text(l10n.createListingDealBothShort), findsOneWidget);
    expect(find.text(l10n.createListingDealTypeLabel), findsOneWidget);
    expect(find.text(l10n.createListingPhoneCaption), findsWidgets);
    expect(find.byIcon(kCreateListingIconPrice), findsOneWidget);
    expect(find.byIcon(CarzonIcons.phone), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_type_section')),
        matching: find.byIcon(kCreateListingIconListingType),
      ),
      findsOneWidget,
    );
    final dealLabel = tester.getRect(
      find.text(l10n.createListingDealTypeLabel),
    );
    final dealSelector = tester.getRect(find.byType(ListingTypeDealSelector));
    expect(dealSelector.top - dealLabel.bottom, greaterThanOrEqualTo(8));
    expect(dealSelector.top - dealLabel.bottom, lessThan(12));
    expect(find.byType(PremiumWhatsAppToggleRow), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_telegram_field')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('price error sits under the full-width field', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 700),
          textScaler: TextScaler.linear(1.3),
        ),
        child: wrap(),
      ),
    );
    await tester.pumpAndSettle();
    final price = find.byKey(const ValueKey('create_listing_price_field'));
    await tester.enterText(price, '0');
    await tester.pump();
    final error = find.descendant(
      of: price,
      matching: find.text(l10n.validationPositive),
    );
    expect(error, findsOneWidget);
    final field = tester.getRect(price);
    final errorBox = tester.getRect(error);
    final currency = tester.getRect(
      find.byKey(const ValueKey('create_listing_currency_selector')),
    );
    expect(errorBox.top, greaterThan(currency.top));
    expect(errorBox.left, greaterThanOrEqualTo(field.left));
    expect(errorBox.right, lessThanOrEqualTo(field.right + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone and price render in dark mode', (tester) async {
    await tester.pumpWidget(wrap(theme: AppTheme.dark()));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_phone_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_price_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_currency_selector')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual row stays collapsed until tap reveals make model year', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: wrap(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.createListingManualVehicleTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_model_field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_year_field')),
      findsNothing,
    );

    await openCreateListingManualIdentity(tester);

    expect(find.text(l10n.createListingManualVehicleTitle), findsOneWidget);
    final title = tester.getRect(
      find.text(l10n.createListingManualVehicleTitle),
    );
    final brand = tester.getRect(
      find.byKey(const ValueKey('create_listing_brand_field')),
    );
    final model = tester.getRect(
      find.byKey(const ValueKey('create_listing_model_field')),
    );
    final year = tester.getRect(
      find.byKey(const ValueKey('create_listing_year_field')),
    );
    expect(title.bottom, lessThan(brand.top + 4));
    expect((brand.top - model.top).abs(), lessThan(1));
    expect((brand.top - year.top).abs(), lessThan(1));
    expect((brand.height - model.height).abs(), lessThan(1));
    expect((brand.height - year.height).abs(), lessThan(1));
    expect(brand.left, lessThan(model.left));
    expect(model.left, lessThan(year.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('make model year stay one row at 390', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: wrap(),
      ),
    );
    await tester.pumpAndSettle();
    await openCreateListingManualIdentity(tester);

    final brand = tester.getRect(
      find.byKey(const ValueKey('create_listing_brand_field')),
    );
    final model = tester.getRect(
      find.byKey(const ValueKey('create_listing_model_field')),
    );
    final year = tester.getRect(
      find.byKey(const ValueKey('create_listing_year_field')),
    );
    expect((brand.top - model.top).abs(), lessThan(1));
    expect((model.top - year.top).abs(), lessThan(1));
    expect(brand.left, lessThan(model.left));
    expect(model.left, lessThan(year.left));
    expect((brand.width - model.width).abs(), lessThan(12));
    expect((model.width - year.width).abs(), lessThan(12));
    expect((brand.height - model.height).abs(), lessThan(1));
    expect((brand.height - year.height).abs(), lessThan(1));
    final modelValue = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_model_field')),
        matching: find.text(l10n.createListingMmyValuePlaceholder),
      ),
    );
    expect(modelValue.maxLines, 1);
    expect(modelValue.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toyota Auris 2023 stay one line in equal MMY cells', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await binding.setSurfaceSize(const Size(390, 200));
    final l10n = ruStrings();
    Widget cell(String key, String caption, String value) {
      return CreateListingPickerField(
        fieldKey: ValueKey(key),
        compact: true,
        caption: caption,
        label: l10n.createListingMmyValuePlaceholder,
        value: value,
        empty: false,
        enabled: true,
        onTap: () {},
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CreateListingMmyRow(
              make: cell('make', l10n.createListingBrandLabel, 'Toyota'),
              model: cell('model', l10n.fieldModel, 'Auris'),
              year: cell('year', l10n.fieldYear, '2023'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final make = tester.getRect(find.byKey(const ValueKey('make')));
    final model = tester.getRect(find.byKey(const ValueKey('model')));
    final year = tester.getRect(find.byKey(const ValueKey('year')));
    expect((make.top - model.top).abs(), lessThan(2));
    expect((make.width - year.width).abs(), lessThan(8));
    expect((make.height - year.height).abs(), lessThan(2));
    for (final value in ['Toyota', 'Auris', '2023']) {
      final text = tester.widget<Text>(find.text(value));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: CreateListingCharacteristicsFacts(
            facts: const [
              CreateListingCharacteristicFact(
                icon: Icons.directions_car_outlined,
                label: 'Кузов',
                value: 'Минивэн',
              ),
              CreateListingCharacteristicFact(
                icon: Icons.local_gas_station_outlined,
                label: 'Двигатель',
                value: '1.8 л · Бензин',
              ),
              CreateListingCharacteristicFact(
                icon: Icons.bolt_outlined,
                label: 'Мощность',
                value: '99 л.с.',
              ),
              CreateListingCharacteristicFact(
                icon: Icons.settings_outlined,
                label: 'Коробка',
                value: 'Вариатор',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final body = tester.getRect(find.text('Минивэн'));
    final engine = tester.getRect(find.text('1.8 л · Бензин'));
    final power = tester.getRect(find.text('99 л.с.'));
    expect((body.top - engine.top).abs(), lessThan(4));
    expect(body.left, lessThan(engine.left));
    expect(body.bottom, lessThan(power.top));
    expect(
      find.byKey(CreateListingCharacteristicsFacts.summaryKey),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('deal selector uses a composed compact shell at 320', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 568)),
        child: wrap(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('create_listing_type_section')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_type_section')),
        matching: find.byKey(CreateListingSegmentedControl.compactLayoutKey),
      ),
      findsOneWidget,
    );
    _expectDealLabelsFullyReadable(
      tester,
      sale: l10n.formatTypeSale,
      exchange: l10n.formatTypeExchange,
      both: l10n.createListingDealBothShort,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deal selector compact fallback keeps RO labels readable at 320',
    (tester) async {
      final ro = roStrings();
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      addTearDown(() async {
        await binding.setSurfaceSize(null);
      });

      await binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 568)),
          child: wrap(locale: const Locale('ro')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('create_listing_type_section')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_type_section')),
          matching: find.byKey(CreateListingSegmentedControl.compactLayoutKey),
        ),
        findsOneWidget,
      );
      _expectDealLabelsFullyReadable(
        tester,
        sale: ro.formatTypeSale,
        exchange: ro.formatTypeExchange,
        both: ro.createListingDealBothShort,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('deal selector stays compact and untruncated at 375 and 390', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    for (final width in const [375.0, 390.0]) {
      await binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: wrap(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('create_listing_type_section')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_type_section')),
          matching: find.byKey(CreateListingSegmentedControl.rowLayoutKey),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('create_listing_type_section')),
          matching: find.byKey(CreateListingSegmentedControl.compactLayoutKey),
        ),
        findsNothing,
      );
      _expectDealLabelsFullyReadable(
        tester,
        sale: l10n.formatTypeSale,
        exchange: l10n.formatTypeExchange,
        both: l10n.createListingDealBothShort,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'gallery upload failure shows localized snackbar, not raw backend text',
    (tester) async {
      whenListen(
        createCubit,
        Stream<CreateListingState>.fromIterable(const [
          CreateListingState.submitting(),
          CreateListingState.failure(CreateListingFailureKind.upload),
        ]),
        initialState: const CreateListingState.idle(),
      );

      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(l10n.createListingPhotosUploadFailed), findsOneWidget);
      expect(find.textContaining('PGRST'), findsNothing);
      expect(find.textContaining('PostgREST'), findsNothing);
      expect(find.textContaining('listing-images'), findsNothing);
      expect(find.text('rls'), findsNothing);
    },
  );

  testWidgets('picker cancellation is neutral and keeps form state', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        imagePicker:
            ({
              required source,
              required maxWidth,
              required imageQuality,
            }) async => null,
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109186',
    );

    await tapEmptyPhotoHero(tester);
    await tester.pumpAndSettle();

    expect(find.text(l10n.imagePickerLoadFailed), findsNothing);
    expect(find.text('1HGBH41JXMN109186'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(CreateListingMediaSection.phase3TestKey),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('picker failure shows localized recoverable error', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        imagePicker:
            ({
              required source,
              required maxWidth,
              required imageQuality,
            }) async {
              throw PlatformException(code: 'photo_access_denied');
            },
      ),
    );
    await tester.pump();

    await tapEmptyPhotoHero(tester);
    await tester.pumpAndSettle();

    expect(find.text(l10n.imagePickerLoadFailed), findsOneWidget);
  });

  testWidgets(
    'upload failure keeps selected media preview available for retry',
    (tester) async {
      final states = Stream<CreateListingState>.fromIterable(const [
        CreateListingState.submitting(),
        CreateListingState.failure(CreateListingFailureKind.upload),
      ]);
      whenListen(
        createCubit,
        states,
        initialState: const CreateListingState.idle(),
      );
      await tester.pumpWidget(
        wrap(
          imagePicker:
              ({
                required source,
                required maxWidth,
                required imageQuality,
              }) async => XFile.fromData(
                Uint8List.fromList(_transparentPng),
                name: 'car.png',
                mimeType: 'image/png',
              ),
        ),
      );
      await tester.pump();

      await tapEmptyPhotoHero(tester);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(CreateListingMediaSection.phase3TestKey),
          matching: find.byType(Image),
        ),
        findsWidgets,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(l10n.createListingPhotosUploadFailed), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(CreateListingMediaSection.phase3TestKey),
          matching: find.byType(Image),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'Other with empty custom make shows validation and skips submit',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await openCreateListingManualIdentity(tester);

      final brandField = find.byKey(
        const ValueKey('create_listing_brand_field'),
      );
      await tester.scrollUntilVisible(
        brandField,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(brandField);
      await tester.pumpAndSettle();

      final otherLabel = localizedListingBrandCatalogLabel(
        l10n,
        kListingBrandCatalogOther,
      );
      await tester.enterText(
        find.byType(TextField).last,
        otherLabel.substring(0, 2),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(otherLabel));
      await tester.pumpAndSettle();

      final publishButton = find.text(l10n.publishListing).last;
      await tester.ensureVisible(publishButton);
      await tester.pumpAndSettle();
      await tester.tap(publishButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.validationRequired), findsWidgets);
      verifyNever(
        () => createCubit.submit(
          listingInput: any(named: 'listingInput'),
          orderedPhotos: any(named: 'orderedPhotos'),
        ),
      );
    },
  );

  testWidgets('manual brand pick prefills custom make display', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await openCreateListingManualIdentity(tester);

    const customMake = 'Zaporozhets';
    final brandField = find.byKey(const ValueKey('create_listing_brand_field'));
    await tester.scrollUntilVisible(
      brandField,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(brandField);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, customMake);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.brandPickUseMake(customMake)));
    await tester.pumpAndSettle();

    expect(find.text(customMake), findsWidgets);
  });

  testWidgets('mileage sits in the commercial block and uses one field', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final vehicleData = find.byKey(
      const ValueKey('create_listing_characteristics_section'),
    );
    final contact = find.byKey(
      const ValueKey('create_listing_contact_section'),
    );
    final mileage = find.byKey(const ValueKey('create_listing_mileage_field'));
    expect(mileage, findsOneWidget);
    expect(find.descendant(of: contact, matching: mileage), findsOneWidget);
    expect(find.descendant(of: vehicleData, matching: mileage), findsNothing);

    await revealCreateListingMileageField(tester);
    await tester.enterText(mileage, '45000');
    await tester.pump();

    expect(tester.widget<TextFormField>(mileage).controller?.text, '45000');
    expect(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      findsOneWidget,
    );
  });
}

void _expectDealLabelsFullyReadable(
  WidgetTester tester, {
  required String sale,
  required String exchange,
  required String both,
}) {
  expect(find.text(sale), findsOneWidget);
  expect(find.text(exchange), findsOneWidget);
  expect(find.text(both), findsOneWidget);

  final saleText = tester.widget<Text>(find.text(sale));
  final bothText = tester.widget<Text>(find.text(both));
  expect(bothText.style?.fontSize, saleText.style?.fontSize);
  expect(saleText.overflow, isNot(TextOverflow.ellipsis));
  expect(bothText.overflow, isNot(TextOverflow.ellipsis));

  for (final label in [sale, exchange, both]) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    expect(paragraph.didExceedMaxLines, isFalse);
  }
}
