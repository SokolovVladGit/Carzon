import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_report_status.dart';
import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_source_result.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_cubit.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_state.dart';
import 'package:carzon/features/edit_listing/presentation/models/edit_listing_gallery_slot.dart';
import 'package:carzon/features/edit_listing/presentation/pages/edit_listing_page.dart';
import 'package:carzon/features/edit_listing/presentation/utils/edit_listing_gallery_initializer.dart';
import 'package:carzon/features/edit_listing/presentation/widgets/edit_listing_gallery_section.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_image.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_city_pick_sheet.dart';
import 'package:carzon/features/listings/presentation/widgets/public_contact_notice.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockEditCubit extends MockCubit<EditListingState>
    implements EditListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

Listing _listing({
  String? coverUrl,
  String city = 'Chișinău',
  MarketRegion marketRegion = MarketRegion.moldova,
  ListingVinStatus vinStatus = ListingVinStatus.notProvided,
}) => Listing(
  id: 'l1',
  title: 'VW Golf',
  make: 'Volkswagen',
  model: 'Golf',
  year: 2016,
  priceEur: 8900,
  priceCurrency: ListingCurrency.usd,
  mileageKm: 120000,
  type: ListingType.sale,
  city: city,
  marketRegion: marketRegion,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: 's1',
  contactPhone: '+373 690 00001',
  coverImageUrl: coverUrl,
  vinStatus: vinStatus,
);

void main() {
  late _MockEditCubit cubit;
  late _MockAuthCubit authCubit;

  setUpAll(() {
    registerFallbackValue(
      EditListingInput(
        listingId: 'x',
        title: 'x',
        make: 'x',
        model: 'x',
        year: 2020,
        priceEur: 1,
        mileageKm: 1,
        type: ListingType.sale,
        city: 'x',
        marketRegion: MarketRegion.moldova,
        contactPhone: '+373 000 00000',
        priceCurrency: ListingCurrency.eur,
      ),
    );
    registerFallbackValue(<EditListingGallerySlot>[
      EditListingGalleryRemoteSlot.legacyCover('u'),
    ]);
  });

  setUp(() async {
    await sl.reset();
    cubit = _MockEditCubit();
    authCubit = _MockAuthCubit();
    when(
      () => cubit.load(any(), ownerId: any(named: 'ownerId')),
    ).thenAnswer((_) async {});
    const user = AuthUser(id: 's1', email: 'seller@example.com');
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );
    sl.registerFactory<EditListingCubit>(() => cubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  final ru = ruStrings();

  Widget app({EditListingImagePicker? imagePicker}) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: EditListingPage(listingId: 'l1', imagePicker: imagePicker),
    ),
  );

  void stub(EditListingState s) {
    when(() => cubit.state).thenReturn(s);
    whenListen(cubit, const Stream<EditListingState>.empty(), initialState: s);
  }

  testWidgets('signed-out direct route shows sign-in prompt and skips load', (
    tester,
  ) async {
    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(ru.myListingsSignInRequired), findsOneWidget);
    expect(find.widgetWithText(FilledButton, ru.commonSignIn), findsOneWidget);
    verifyNever(() => cubit.load(any(), ownerId: any(named: 'ownerId')));
  });

  testWidgets('not-allowed load failure renders permission error', (
    tester,
  ) async {
    stub(
      const EditListingState.loadFailure(
        kind: EditListingFailureKind.notAllowed,
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(ru.notAllowedEdit), findsOneWidget);
    expect(find.text(ru.editListingLoadFailed), findsNothing);
  });

  testWidgets('renders gallery section keys, currency selector, brand, year, '
      'contact notice and save affordance', (tester) async {
    final listing = _listing(coverUrl: 'https://cdn.example.com/c.jpg');
    final img = ListingImage(
      id: 'i0',
      listingId: 'l1',
      publicUrl: 'https://cdn.example.com/c.jpg',
      position: 0,
      createdAt: DateTime.utc(2026, 5, 1),
    );
    final initial = buildInitialEditListingGallerySlots(
      listing: listing,
      prefetchedGallery: [img],
      galleryLoadSucceeded: true,
    );
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: [img],
        galleryLoadSucceeded: true,
        initialGallerySlots: initial,
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.byKey(EditListingGallerySection.widgetTestKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit_listing_currency_selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit_listing_brand_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit_listing_year_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit_listing_body_type_field')),
      findsOneWidget,
    );
    expect(find.text(ru.listingBodyTypeSectionSubtitle), findsOneWidget);
    expect(find.byType(PublicContactNotice), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit_listing_save_button')),
      findsOneWidget,
    );

    final vehicle = find.byKey(const ValueKey('edit_listing_vehicle_section'));
    final location = find.byKey(
      const ValueKey('edit_listing_location_section'),
    );
    final price = find.byKey(const ValueKey('edit_listing_price_section'));
    final region = find.byKey(const ValueKey('edit_listing_region_selector'));
    final city = find.byKey(const ValueKey('edit_listing_city_field'));

    expect(vehicle, findsOneWidget);
    expect(location, findsOneWidget);
    expect(price, findsOneWidget);
    expect(region, findsOneWidget);
    expect(city, findsOneWidget);
    expect(find.text(ru.createListingSectionLocation), findsOneWidget);
    expect(find.descendant(of: vehicle, matching: region), findsNothing);
    expect(find.descendant(of: vehicle, matching: city), findsNothing);
    expect(find.descendant(of: location, matching: region), findsOneWidget);
    expect(find.descendant(of: location, matching: city), findsOneWidget);
    expect(
      tester.getTopLeft(vehicle).dy,
      lessThan(tester.getTopLeft(location).dy),
    );
    expect(
      tester.getTopLeft(location).dy,
      lessThan(tester.getTopLeft(price).dy),
    );
    expect(tester.getTopLeft(region).dy, lessThan(tester.getTopLeft(city).dy));

    final regionField = tester.widget<DropdownButtonFormField<MarketRegion>>(
      region,
    );
    final cityField = tester.widget<ListingCitySelectorField>(city);
    expect(regionField.initialValue, MarketRegion.moldova);
    expect(cityField.canonicalCity, 'Chișinău');
    expect(cityField.manualMode, isFalse);
  });

  testWidgets('historical alias hydrates to its canonical known city', (
    tester,
  ) async {
    final listing = _listing(city: '  Chisinau  ');
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    final cityField = tester.widget<ListingCitySelectorField>(
      find.byKey(const ValueKey('edit_listing_city_field')),
    );
    expect(cityField.canonicalCity, 'Chișinău');
    expect(cityField.manualMode, isFalse);
    expect(
      find.byKey(const ValueKey('edit_listing_manual_city_field')),
      findsNothing,
    );
  });

  testWidgets('unknown historical city hydrates in manual mode unchanged', (
    tester,
  ) async {
    const historicalCity = '  Criuleni village  ';
    final listing = _listing(city: historicalCity);
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    final cityField = tester.widget<ListingCitySelectorField>(
      find.byKey(const ValueKey('edit_listing_city_field')),
    );
    expect(cityField.canonicalCity, isNull);
    expect(cityField.manualMode, isTrue);
    final manualField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('edit_listing_manual_city_field')),
    );
    expect(manualField.controller?.text, historicalCity);
  });

  testWidgets('changing region clears hydrated city and manual state', (
    tester,
  ) async {
    final listing = _listing(city: 'Criuleni village');
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    final region = find.byKey(const ValueKey('edit_listing_region_selector'));
    await tester.ensureVisible(region);
    await tester.tap(region);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ru.regionTransnistria).last);
    await tester.pumpAndSettle();

    final cityField = tester.widget<ListingCitySelectorField>(
      find.byKey(const ValueKey('edit_listing_city_field')),
    );
    expect(cityField.canonicalCity, isNull);
    expect(cityField.manualMode, isFalse);
    expect(
      find.byKey(const ValueKey('edit_listing_manual_city_field')),
      findsNothing,
    );
    expect(find.text(ru.listingCitySelectPlaceholder), findsOneWidget);
  });

  testWidgets('cancelling city picker preserves hydrated selection', (
    tester,
  ) async {
    final listing = _listing();
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    final city = find.byKey(const ValueKey('edit_listing_city_field'));
    await tester.ensureVisible(city);
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(ru.commonCancel));
    await tester.pumpAndSettle();

    final cityField = tester.widget<ListingCitySelectorField>(city);
    expect(cityField.canonicalCity, 'Chișinău');
    expect(cityField.manualMode, isFalse);
  });

  testWidgets(
    'owner VIN status block shows conservative copy (no forbidden claims)',
    (tester) async {
      final listing = _listing(vinStatus: ListingVinStatus.formatValid);
      final initial = buildInitialEditListingGallerySlots(
        listing: listing,
        prefetchedGallery: const [],
        galleryLoadSucceeded: true,
      );
      stub(
        EditListingState.ready(
          listing,
          listingGalleryImages: const [],
          galleryLoadSucceeded: true,
          initialGallerySlots: initial,
          ownerVinReportStatus: OwnerListingVinReportStatus(
            listingId: listing.id,
            publicVinStatusRaw: 'format_valid',
            processingStatusRaw: 'succeeded',
            decodeStatusRaw: 'decoded',
            decodedMake: 'HONDA',
            decodedModel: 'Civic',
            decodedYear: 2019,
          ),
        ),
      );

      await tester.pumpWidget(app());
      await tester.pump();

      expect(
        find.byKey(const ValueKey('edit_listing_owner_vin_report_section')),
        findsOneWidget,
      );
      expect(find.text(ru.editListingVinReportSectionTitle), findsOneWidget);
      expect(find.text(ru.editListingVinReportDecodedBody), findsOneWidget);
      expect(
        find.text(ru.editListingVinReportBasicInfoHeading),
        findsOneWidget,
      );
      final sectionFinder = find.byKey(
        const ValueKey('edit_listing_owner_vin_report_section'),
      );
      expect(
        find.descendant(
          of: sectionFinder,
          matching: find.text(ru.editListingVinReportDecodedMakeLabel),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sectionFinder, matching: find.text('HONDA')),
        findsOneWidget,
      );
      expect(find.text(ru.editListingVinReportSourceLine), findsOneWidget);
      for (final phrase in [
        'VIN проверен',
        'официально подтверждён',
        'история проверена',
        'проверено по базе',
        'без ДТП',
        'чистая история',
      ]) {
        expect(find.textContaining(phrase), findsNothing);
      }
    },
  );

  testWidgets(
    'owner basic info uses NHTSA source normalized_summary when legacy decoded '
    'snapshot is empty',
    (tester) async {
      final listing = _listing(vinStatus: ListingVinStatus.formatValid);
      final initial = buildInitialEditListingGallerySlots(
        listing: listing,
        prefetchedGallery: const [],
        galleryLoadSucceeded: true,
      );
      stub(
        EditListingState.ready(
          listing,
          listingGalleryImages: const [],
          galleryLoadSucceeded: true,
          initialGallerySlots: initial,
          ownerVinReportStatus: OwnerListingVinReportStatus(
            listingId: listing.id,
            publicVinStatusRaw: 'format_valid',
            processingStatusRaw: 'succeeded',
            decodeStatusRaw: 'decoded',
          ),
          ownerVinSourceResults: [
            const OwnerListingVinSourceResult(
              sourceId: 'nhtsa_vpic',
              statusRaw: 'succeeded',
              normalizedSummary: {
                'make': 'NISSAN',
                'model': 'Leaf',
                'year': 2021,
              },
            ),
          ],
        ),
      );

      await tester.pumpWidget(app());
      await tester.pump();

      final sectionFinder = find.byKey(
        const ValueKey('edit_listing_owner_vin_report_section'),
      );
      expect(
        find.text(ru.editListingVinReportBasicInfoHeading),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sectionFinder, matching: find.text('NISSAN')),
        findsOneWidget,
      );
      expect(find.text(ru.editListingVinReportSourceLine), findsOneWidget);
    },
  );

  testWidgets(
    'owner VIN block omits decoded summary when decode succeeded but fields empty',
    (tester) async {
      final listing = _listing(vinStatus: ListingVinStatus.formatValid);
      final initial = buildInitialEditListingGallerySlots(
        listing: listing,
        prefetchedGallery: const [],
        galleryLoadSucceeded: true,
      );
      stub(
        EditListingState.ready(
          listing,
          listingGalleryImages: const [],
          galleryLoadSucceeded: true,
          initialGallerySlots: initial,
          ownerVinReportStatus: OwnerListingVinReportStatus(
            listingId: listing.id,
            publicVinStatusRaw: 'format_valid',
            processingStatusRaw: 'succeeded',
            decodeStatusRaw: 'decoded',
          ),
        ),
      );

      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text(ru.editListingVinReportDecodedBody), findsOneWidget);
      expect(find.text(ru.editListingVinReportBasicInfoHeading), findsNothing);
      expect(find.text(ru.editListingVinReportSourceLine), findsNothing);
    },
  );

  testWidgets('save button is disabled while submitting (shows progress)', (
    tester,
  ) async {
    final listing = _listing(coverUrl: 'https://cdn.example.com/c.jpg');
    stub(
      EditListingState.submitting(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    final fb = tester.widget<FilledButton>(
      find.byKey(const ValueKey('edit_listing_save_button')),
    );
    expect(fb.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('save delegates to cubit.save with named parameters', (
    tester,
  ) async {
    final listing = _listing();
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );
    when(
      () => cubit.save(
        input: any(named: 'input'),
        galleryDraft: any(named: 'galleryDraft'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(app());
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const ValueKey('edit_listing_save_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit_listing_save_button')));
    await tester.pump();

    final saved =
        verify(
              () => cubit.save(
                input: captureAny(named: 'input'),
                galleryDraft: any(named: 'galleryDraft'),
              ),
            ).captured.single
            as EditListingInput;
    expect(saved.city, 'Chișinău');
    expect(saved.marketRegion, MarketRegion.moldova);
  });

  testWidgets('manual historical city submits trimmed custom value', (
    tester,
  ) async {
    final listing = _listing(city: '  Criuleni village  ');
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );
    when(
      () => cubit.save(
        input: any(named: 'input'),
        galleryDraft: any(named: 'galleryDraft'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(app());
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('edit_listing_save_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit_listing_save_button')));
    await tester.pump();

    final saved =
        verify(
              () => cubit.save(
                input: captureAny(named: 'input'),
                galleryDraft: any(named: 'galleryDraft'),
              ),
            ).captured.single
            as EditListingInput;
    expect(saved.city, 'Criuleni village');
  });

  testWidgets('failed gallery load shows read-only hint string', (
    tester,
  ) async {
    final listing = _listing(coverUrl: 'https://cdn.example.com/c.jpg');
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: false,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );

    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text(ru.editListingGalleryReadOnlyHint), findsOneWidget);
  });

  testWidgets('picker cancellation is neutral on edit gallery', (tester) async {
    final listing = _listing();
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );

    await tester.pumpWidget(
      app(
        imagePicker:
            ({
              required source,
              required maxWidth,
              required imageQuality,
            }) async => null,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(EditListingGallerySection.widgetTestKey));
    await tester.pumpAndSettle();

    expect(find.text(ru.imagePickerLoadFailed), findsNothing);
    expect(find.byKey(EditListingGallerySection.widgetTestKey), findsOneWidget);
  });

  testWidgets('picker failure shows localized edit gallery error', (
    tester,
  ) async {
    final listing = _listing();
    stub(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: <EditListingGallerySlot>[],
      ),
    );

    await tester.pumpWidget(
      app(
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

    await tester.tap(find.byKey(EditListingGallerySection.widgetTestKey));
    await tester.pumpAndSettle();

    expect(find.text(ru.imagePickerLoadFailed), findsOneWidget);
  });
}
