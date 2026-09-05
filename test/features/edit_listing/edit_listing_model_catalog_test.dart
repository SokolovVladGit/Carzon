import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_cubit.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_state.dart';
import 'package:carzon/features/edit_listing/presentation/models/edit_listing_gallery_slot.dart';
import 'package:carzon/features/edit_listing/presentation/pages/edit_listing_page.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_vehicle_model_catalog_repository.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockEditCubit extends MockCubit<EditListingState>
    implements EditListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

Listing _listing({
  required String make,
  required String model,
  String title = 'Car',
}) => Listing(
  id: 'l1',
  title: title,
  make: make,
  model: model,
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
);

void main() {
  late _MockEditCubit cubit;
  late _MockAuthCubit authCubit;
  late FakeVehicleModelCatalogRepository catalog;
  final ru = ruStrings();

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
    catalog = FakeVehicleModelCatalogRepository();
    cubit = _MockEditCubit();
    authCubit = _MockAuthCubit();
    when(
      () => cubit.load(any(), ownerId: any(named: 'ownerId')),
    ).thenAnswer((_) async {});
    when(
      () => cubit.save(
        input: any(named: 'input'),
        galleryDraft: any(named: 'galleryDraft'),
      ),
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

  Widget app() => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: EditListingPage(listingId: 'l1', vehicleModelCatalog: catalog),
    ),
  );

  void stubReady(Listing listing) {
    final state = EditListingState.ready(listing);
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<EditListingState>.empty(),
      initialState: state,
    );
  }

  Future<EditListingInput> save(WidgetTester tester) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('edit_listing_save_button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    return verify(
          () => cubit.save(
            input: captureAny(named: 'input'),
            galleryDraft: any(named: 'galleryDraft'),
          ),
        ).captured.single
        as EditListingInput;
  }

  testWidgets('hydrates exact canonical model without rewriting it', (
    tester,
  ) async {
    stubReady(_listing(make: 'Volkswagen', model: 'Golf', title: 'VW'));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Golf'), findsOneWidget);
    expect(find.text(ru.listingModelNotListed), findsNothing);
    expect(
      find.byKey(const ValueKey('edit_listing_manual_model')),
      findsNothing,
    );
  });

  testWidgets('unknown historical model stays raw and is not normalized', (
    tester,
  ) async {
    stubReady(_listing(make: 'Audi', model: 'А5', title: 'Audi raw'));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text(ru.listingModelNotListed), findsOneWidget);
    expect(find.text('А5'), findsOneWidget);
    expect(find.text('A5'), findsNothing);

    final price = find.widgetWithText(
      TextFormField,
      ru.createListingPriceAmount,
    );
    await tester.ensureVisible(price);
    await tester.enterText(price, '9100');
    final submitted = await save(tester);
    expect(submitted.make, 'Audi');
    expect(submitted.model, 'А5');
  });

  testWidgets('custom unknown make keeps raw model in manual mode', (
    tester,
  ) async {
    stubReady(_listing(make: 'Homemade', model: 'Special', title: 'DIY'));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('edit_listing_manual_model')),
      findsOneWidget,
    );
    expect(find.text('Special'), findsOneWidget);
    expect(catalog.listCalls, 0);
  });

  testWidgets('stale catalog hydrate cannot overwrite a newer make', (
    tester,
  ) async {
    catalog.gate = Completer<void>();
    stubReady(_listing(make: 'Honda', model: 'Civic', title: 'Honda car'));
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();

    final brand = find.byKey(const ValueKey('edit_listing_brand_field'));
    await tester.ensureVisible(brand);
    await tester.tap(brand);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Toyota');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
    await tester.pumpAndSettle();

    catalog.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text(ru.listingModelSelectPlaceholder), findsOneWidget);
    expect(find.text('Civic'), findsNothing);
  });

  testWidgets('changing make clears model and requires a new one', (
    tester,
  ) async {
    stubReady(_listing(make: 'Honda', model: 'Civic', title: 'Honda car'));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Civic'), findsWidgets);

    final brand = find.byKey(const ValueKey('edit_listing_brand_field'));
    await tester.ensureVisible(brand);
    await tester.tap(brand);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Toyota');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
    await tester.pumpAndSettle();

    expect(find.text(ru.listingModelSelectPlaceholder), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit_listing_manual_model')),
      findsNothing,
    );
  });
}
