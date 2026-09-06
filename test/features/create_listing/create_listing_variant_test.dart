import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_vehicle_model_catalog_repository.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockCreateCubit extends MockCubit<CreateListingState>
    implements CreateListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockCreateCubit createCubit;
  late _MockAuthCubit authCubit;
  late FakeVehicleModelCatalogRepository catalog;
  final l10n = ruStrings();

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

  Widget wrap() => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: CreateListingPage(vehicleModelCatalog: catalog),
    ),
  );

  Future<void> pickBrand(WidgetTester tester, String query) async {
    final brand = find.byKey(const ValueKey('create_listing_brand_field'));
    await tester.scrollUntilVisible(
      brand,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(brand);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, query);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, query));
    await tester.pumpAndSettle();
  }

  Future<void> pickModel(WidgetTester tester, String model) async {
    final field = find.byKey(const ValueKey('create_listing_model_field'));
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('listing_model_$model')));
    await tester.pumpAndSettle();
  }

  Future<void> fillRest(WidgetTester tester) async {
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
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.createListingMileagePlaceholder),
      '100000',
    );

    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.scrollUntilVisible(
      city,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тирасполь'));
    await tester.pumpAndSettle();

    final phone = find.widgetWithText(TextFormField, l10n.fieldPhone);
    await tester.scrollUntilVisible(
      phone,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(phone, '+37369000001');
  }

  Future<NewListingInput> submit(WidgetTester tester) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final publish = find.text(l10n.publishListing).last;
    await tester.ensureVisible(publish);
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

  testWidgets('variant is optional and helper copy is localized', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text(l10n.listingVariantLabel), findsWidgets);
    await pickBrand(tester, 'BMW');
    await pickModel(tester, '3 Series');
    await fillRest(tester);
    final submitted = await submit(tester);
    expect(submitted.model, '3 Series');
    expect(submitted.variant, isNull);
    expect(submitted.title.startsWith('BMW 3 Series,'), isTrue);
  });

  testWidgets('canonical model + variant submit and auto title', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await pickBrand(tester, 'BMW');
    await pickModel(tester, '3 Series');
    final variant = find.byKey(const ValueKey('create_listing_variant_field'));
    await tester.ensureVisible(variant);
    await tester.enterText(variant, 'M340i');
    await fillRest(tester);
    final submitted = await submit(tester);
    expect(submitted.make, 'BMW');
    expect(submitted.model, '3 Series');
    expect(submitted.variant, 'M340i');
    expect(submitted.title.startsWith('BMW 3 Series M340i,'), isTrue);
  });

  testWidgets('blank variant normalizes to null', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await pickBrand(tester, 'Honda');
    await pickModel(tester, 'CR-V');
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_variant_field')),
      '   ',
    );
    await fillRest(tester);
    final submitted = await submit(tester);
    expect(submitted.variant, isNull);
  });

  testWidgets('make change clears model and variant', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await pickBrand(tester, 'BMW');
    await pickModel(tester, '3 Series');
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_variant_field')),
      'M340i',
    );
    await tester.pump();
    expect(find.text('M340i'), findsWidgets);
    await pickBrand(tester, 'Toyota');
    expect(find.text('3 Series'), findsNothing);
    expect(find.text('M340i'), findsNothing);
  });

  testWidgets('model change clears variant', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await pickBrand(tester, 'BMW');
    await pickModel(tester, '3 Series');
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_variant_field')),
      'M340i',
    );
    await tester.pump();
    await pickModel(tester, '5 Series');
    expect(find.text('M340i'), findsNothing);
    expect(find.text('5 Series'), findsWidgets);
  });

  testWidgets('plug-in hybrid is selectable and submitted', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await pickBrand(tester, 'Honda');
    await pickModel(tester, 'CR-V');
    final fuel = find.byKey(const ValueKey('create_listing_fuel_field'));
    await tester.ensureVisible(fuel);
    await tester.tap(fuel);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.listingFuelTypePlugInHybrid));
    await tester.pumpAndSettle();
    await fillRest(tester);
    final submitted = await submit(tester);
    expect(submitted.fuelType, ListingFuelType.plugInHybrid);
  });
}
