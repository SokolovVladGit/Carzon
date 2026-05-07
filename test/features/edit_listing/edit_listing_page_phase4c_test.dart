import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_cubit.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_state.dart';
import 'package:carzon/features/edit_listing/presentation/models/edit_listing_gallery_slot.dart';
import 'package:carzon/features/edit_listing/presentation/pages/edit_listing_page.dart';
import 'package:carzon/features/edit_listing/presentation/utils/edit_listing_gallery_initializer.dart';
import 'package:carzon/features/edit_listing/presentation/widgets/edit_listing_gallery_section.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_image.dart';
import 'package:carzon/features/listings/presentation/widgets/public_contact_notice.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockEditCubit extends MockCubit<EditListingState>
    implements EditListingCubit {}

Listing _listing({String? coverUrl}) => Listing(
  id: 'l1',
  title: 'VW Golf',
  make: 'Volkswagen',
  model: 'Golf',
  year: 2016,
  priceEur: 8900,
  priceCurrency: ListingCurrency.usd,
  mileageKm: 120000,
  type: ListingType.sale,
  city: 'Chișinău',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: 's1',
  contactPhone: '+373 690 00001',
  coverImageUrl: coverUrl,
);

void main() {
  late _MockEditCubit cubit;

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
    when(() => cubit.load(any())).thenAnswer((_) async {});
    sl.registerFactory<EditListingCubit>(() => cubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  final ru = ruStrings();

  Widget app() => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const EditListingPage(listingId: 'l1'),
  );

  void stub(EditListingState s) {
    when(() => cubit.state).thenReturn(s);
    whenListen(cubit, const Stream<EditListingState>.empty(), initialState: s);
  }

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

    verify(
      () => cubit.save(
        input: any(named: 'input'),
        galleryDraft: any(named: 'galleryDraft'),
      ),
    ).called(1);
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
}
