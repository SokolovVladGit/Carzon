import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
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
import 'package:carzon/features/listings/domain/catalog/listing_brands.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_brand_pick_sheet.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/widgets/public_contact_notice.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

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

    sl.registerFactory<CreateListingCubit>(() => createCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap({CreateListingImagePicker? imagePicker}) => MaterialApp(
    locale: const Locale('ru'),
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
    final media = find.byKey(CreateListingMediaSection.phase3TestKey);
    await tester.ensureVisible(media);
    await tester.pumpAndSettle();
    await tester.tap(media);
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
      l10n.createListingPriceAmount,
    );
    await tester.scrollUntilVisible(
      price,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(price, '9000');
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.fieldMileageKm),
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
        find.byKey(const ValueKey('create_listing_brand_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_year_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create_listing_body_type_field')),
        findsOneWidget,
      );
      expect(find.text(l10n.listingBodyTypeSectionSubtitle), findsOneWidget);
      expect(find.byType(PublicContactNotice), findsOneWidget);
      expect(find.text(l10n.publicContactNotice), findsOneWidget);
      expect(find.text(l10n.publishListing), findsWidgets);

      final noticeAppearsAbovePhone =
          tester.getCenter(find.byType(PublicContactNotice)).dy <
          tester
              .getCenter(find.widgetWithText(TextFormField, l10n.fieldPhone))
              .dy;
      expect(noticeAppearsAbovePhone, isTrue);

      await tester.pumpAndSettle();
    },
  );

  testWidgets('location is a dedicated fifth section between type and price', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    const sectionKeys = [
      'create_listing_photos_section',
      'create_listing_vehicle_section',
      'create_listing_description_section',
      'create_listing_type_section',
      'create_listing_location_section',
      'create_listing_price_section',
      'create_listing_publish_section',
    ];
    final sections = [for (final key in sectionKeys) find.byKey(ValueKey(key))];

    for (final section in sections) {
      expect(section, findsOneWidget);
    }
    for (var i = 1; i < sections.length; i++) {
      expect(
        tester.getTopLeft(sections[i - 1]).dy,
        lessThan(tester.getTopLeft(sections[i]).dy),
      );
    }

    final vehicle = sections[1];
    final type = sections[3];
    final location = sections[4];
    final price = sections[5];
    final publish = sections[6];
    final city = find.byKey(const ValueKey('create_listing_city_field'));
    final region = find.byKey(const ValueKey('create_listing_region_selector'));

    expect(find.text(l10n.createListingSectionLocation), findsOneWidget);
    expect(city, findsOneWidget);
    expect(region, findsOneWidget);
    expect(find.byType(MarketPlacementSelector), findsOneWidget);
    expect(find.descendant(of: vehicle, matching: city), findsNothing);
    expect(find.descendant(of: type, matching: region), findsNothing);
    expect(find.descendant(of: location, matching: region), findsOneWidget);
    expect(find.descendant(of: location, matching: city), findsOneWidget);
    expect(tester.getTopLeft(region).dy, lessThan(tester.getTopLeft(city).dy));
    expect(
      find.descendant(of: location, matching: find.text('05')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: price, matching: find.text('06')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: publish, matching: find.text('07')),
      findsOneWidget,
    );
  });

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
    expect(find.text('Тирасполь'), findsOneWidget);

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
    },
  );

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
      find
          .descendant(
            of: find.byKey(const ValueKey('create_listing_photos_section')),
            matching: find.byType(TextFormField),
          )
          .first,
      'Golf',
    );

    await tapEmptyPhotoHero(tester);
    await tester.pumpAndSettle();

    expect(find.text(l10n.imagePickerLoadFailed), findsNothing);
    expect(find.text('Golf'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
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
      expect(find.byType(Image), findsWidgets);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(l10n.createListingPhotosUploadFailed), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    },
  );

  testWidgets(
    'Other with empty custom make shows validation and skips submit',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

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
}
