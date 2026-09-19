import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/seller_listing_defaults.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/models/listing_preview_data.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_picker_field.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/listing_submit_title.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/create_listing_test_stubs.dart';
import '../../helpers/fake_vehicle_model_catalog_repository.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockCreateCubit extends MockCubit<CreateListingState>
    implements CreateListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockCreateCubit createCubit;
  late _MockAuthCubit authCubit;
  late FakeVehicleModelCatalogRepository catalog;
  final ru = ruStrings();
  final ro = roStrings();

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
    stubCreateListingVinResolve(createCubit);
    sl.registerFactory<CreateListingCubit>(() => createCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap({
    Locale locale = const Locale('ru'),
    CreateListingState? resolveState,
  }) {
    if (resolveState != null) {
      when(() => createCubit.state).thenReturn(resolveState);
      whenListen(
        createCubit,
        const Stream<CreateListingState>.empty(),
        initialState: resolveState,
      );
    }
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: CreateListingPage(vehicleModelCatalog: catalog),
      ),
    );
  }

  CreateListingState resolveOf({
    required CreateListingVinResolveStatus status,
    VehicleResolveResult? suggestion,
    bool confirmed = false,
    int applyRevision = 0,
    ConfirmedVehicleIdentity? identity,
    VehicleResolveFailureKind? failureKind,
    String normalizedVin = '1HGBH41JXMN109186',
  }) {
    return CreateListingState(
      vehicleResolve: CreateListingVehicleResolve(
        status: status,
        normalizedVin: normalizedVin,
        suggestion: suggestion,
        confirmed: confirmed,
        applyRevision: applyRevision,
        confirmedIdentity: identity,
        failureKind: failureKind,
      ),
    );
  }

  const bmw = VehicleResolveResult(
    resolution: VehicleResolveResolution.resolved,
    vehicle: VehicleResolveSuggestion(
      make: 'BMW',
      model: 'X5',
      year: 2020,
      trim: 'xDrive30d',
    ),
    completeness: 0.9,
    warnings: [],
  );

  Future<StreamController<CreateListingState>> adoptBmw(
    WidgetTester tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    controller.add(
      resolveOf(
        status: CreateListingVinResolveStatus.resolved,
        suggestion: bmw,
        confirmed: true,
        applyRevision: 1,
        identity: const ConfirmedVehicleIdentity(
          make: 'BMW',
          model: 'X5',
          year: 2020,
          variant: 'xDrive30d',
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Offstage identityEditors(WidgetTester tester) {
    return tester.widget<Offstage>(
      find.byKey(const ValueKey('create_listing_identity_editors')),
    );
  }

  Finder confirmedSummary() =>
      find.byKey(const ValueKey('create_listing_vehicle_confirmed_summary'));

  Future<void> tapChangeConfirmed(
    WidgetTester tester,
    StreamController<CreateListingState> controller, {
    ConfirmedVehicleIdentity identity = const ConfirmedVehicleIdentity(
      make: 'BMW',
      model: 'X5',
      year: 2020,
      variant: 'xDrive30d',
    ),
  }) async {
    final change = find.byKey(
      const ValueKey('create_listing_change_confirmed_vehicle'),
    );
    await tester.scrollUntilVisible(
      change,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(change);
    verify(createCubit.enterManualMode).called(1);
    final next = resolveOf(
      status: CreateListingVinResolveStatus.manual,
      confirmed: false,
      applyRevision: 1,
      identity: identity,
    );
    when(() => createCubit.state).thenReturn(next);
    controller.add(next);
    await tester.pumpAndSettle();
  }

  Future<void> changeToVinB(
    WidgetTester tester,
    StreamController<CreateListingState> controller,
  ) async {
    controller.add(
      resolveOf(
        status: CreateListingVinResolveStatus.idle,
        normalizedVin: 'WBAAA1308H2321234',
        applyRevision: 1,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('changing VIN clears only untouched adopted identity', (
    tester,
  ) async {
    final controller = await adoptBmw(tester);
    await tapChangeConfirmed(tester, controller);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_manual_model')),
      'Seller model',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_variant_field')),
      'Seller trim',
    );
    await changeToVinB(tester, controller);

    expect(find.text('BMW'), findsNothing);
    expect(find.text('2020'), findsNothing);
    expect(find.text('Seller model'), findsWidgets);
    expect(find.text('Seller trim'), findsWidgets);
    expect(find.text('xDrive30d'), findsNothing);
  });

  testWidgets('changing VIN clears all unedited adopted fields', (
    tester,
  ) async {
    final controller = await adoptBmw(tester);
    await changeToVinB(tester, controller);
    for (final value in ['BMW', 'X5', '2020', 'xDrive30d']) {
      expect(find.text(value), findsNothing);
    }
  });

  testWidgets(
    'manual make model and year remain authoritative after VIN change',
    (tester) async {
      final controller = await adoptBmw(tester);
      await tapChangeConfirmed(tester, controller);
      final brand = find.byKey(const ValueKey('create_listing_brand_field'));
      await tester.ensureVisible(brand);
      await tester.tap(brand);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Toyota');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
      await tester.pumpAndSettle();
      final model = find.byKey(const ValueKey('create_listing_model_field'));
      await tester.ensureVisible(model);
      await tester.tap(model);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('listing_model_Corolla')));
      await tester.pumpAndSettle();
      final year = find.byKey(const ValueKey('create_listing_year_field'));
      await tester.ensureVisible(year);
      await tester.tap(year);
      await tester.pumpAndSettle();
      await tester.tap(find.text(ru.commonDone));
      await tester.pumpAndSettle();

      await changeToVinB(tester, controller);
      expect(find.text('Toyota'), findsWidgets);
      expect(find.text('Corolla'), findsWidgets);
      expect(
        find.descendant(of: year, matching: find.text('2020')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'optional engine limits block submission; blank and maxima publish',
    (tester) async {
      await adoptBmw(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, ru.createListingPricePlaceholder),
        '9000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, ru.createListingMileagePlaceholder),
        '100000',
      );
      final city = find.byKey(const ValueKey('create_listing_city_field'));
      await tester.ensureVisible(city);
      await tester.tap(city);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тирасполь'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, ru.fieldPhone),
        '+37369000001',
      );
      final additional = find.text(ru.createListingEditCharacteristics);
      await tester.ensureVisible(additional);
      await tester.tap(additional);
      await tester.pumpAndSettle();
      final liters = find.widgetWithText(
        TextFormField,
        ru.createListingEngineLitersPlaceholder,
      );
      final power = find.widgetWithText(
        TextFormField,
        ru.createListingEnginePowerPlaceholder,
      );
      Future<void> publishWith(String displacement, String hp) async {
        await tester.ensureVisible(liters);
        await tester.enterText(liters, displacement);
        await tester.ensureVisible(power);
        await tester.enterText(power, hp);
        final publish = find.text(ru.publishListing).last;
        await tester.ensureVisible(publish);
        await tester.tap(publish);
        await tester.pumpAndSettle();
      }

      for (final invalid in [
        ('30.1', '3000'),
        ('30', '3001'),
        ('0', '1'),
        ('1', '0'),
      ]) {
        await publishWith(invalid.$1, invalid.$2);
        verifyNever(
          () => createCubit.submit(
            listingInput: any(named: 'listingInput'),
            orderedPhotos: any(named: 'orderedPhotos'),
          ),
        );
      }
      for (final valid in [('', ''), ('30', '3000')]) {
        await publishWith(valid.$1, valid.$2);
        final submitted =
            verify(
                  () => createCubit.submit(
                    listingInput: captureAny(named: 'listingInput'),
                    orderedPhotos: any(named: 'orderedPhotos'),
                  ),
                ).captured.single
                as NewListingInput;
        expect(
          submitted.engineDisplacementLiters,
          valid.$1.isEmpty ? null : 30,
        );
        expect(submitted.enginePowerHp, valid.$2.isEmpty ? null : 3000);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('narrow iPhone keeps polish chrome without overflow', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 700)),
        child: wrap(
          resolveState: resolveOf(
            status: CreateListingVinResolveStatus.resolved,
            suggestion: bmw,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('BMW X5 · 2020'), findsOneWidget);
    expect(find.text('xDrive30d'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_confirm_vehicle')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingChangeManually), findsOneWidget);
    expect(find.text(ru.createListingEditCharacteristics), findsOneWidget);
    expect(find.text(ru.publishListing), findsWidgets);
    expect(find.text(ru.fieldPhone), findsOneWidget);
    expect(find.text(ru.createListingWhatsAppTitle), findsOneWidget);

    for (final key in const [
      'create_listing_vehicle_section',
      'create_listing_photos_section',
      'create_listing_type_section',
      'create_listing_location_section',
      'create_listing_contact_section',
      'create_listing_publish_section',
      'create_listing_additional_details',
    ]) {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('title field is absent from normal Create flow', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text(ru.fieldTitle), findsNothing);
    expect(find.text(ru.fieldTitleOptional), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_title_field')),
      findsNothing,
    );
  });

  testWidgets('VIN appears before manual specs', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final vin = tester.getTopLeft(
      find.byKey(const ValueKey('create_listing_vin_field')),
    );
    final manual = tester.getTopLeft(
      find.byKey(const ValueKey('create_listing_enter_manually')),
    );
    final photos = tester.getTopLeft(
      find.byKey(const ValueKey('create_listing_photos_section')),
    );
    expect(vin.dy, lessThan(manual.dy));
    expect(manual.dy, lessThan(photos.dy));
    expect(find.text(ru.createListingVinAutofillHint), findsOneWidget);
    expect(find.text(ru.createListingEnterManually), findsNothing);
    expect(find.text(ru.createListingOrSeparator), findsOneWidget);
    expect(find.text(ru.createListingManualVehicleTitle), findsOneWidget);
    expect(find.text(ru.createListingManualVehicleSubtitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsNothing,
    );
    expect(identityEditors(tester).offstage, isTrue);
  });

  Finder identityRequired(Finder field) {
    return find.descendant(
      of: find.ancestor(
        of: field,
        matching: find.byType(CreateListingPickerField),
      ),
      matching: find.text(ru.validationRequired),
    );
  }

  testWidgets('manual identity fields stay neutral on first load', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text(ru.validationRequired), findsNothing);
    await openCreateListingManualIdentity(tester);
    final brand = find.byKey(const ValueKey('create_listing_brand_field'));
    final year = find.byKey(const ValueKey('create_listing_year_field'));
    expect(identityRequired(brand), findsNothing);
    expect(identityRequired(year), findsNothing);
  });

  testWidgets(
    'interacting with other fields does not redden unused identity fields',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, ru.createListingPricePlaceholder),
        '9000',
      );
      await tester.pumpAndSettle();
      await openCreateListingManualIdentity(tester);
      final brand = find.byKey(const ValueKey('create_listing_brand_field'));
      final year = find.byKey(const ValueKey('create_listing_year_field'));
      expect(identityRequired(brand), findsNothing);
      expect(identityRequired(year), findsNothing);
    },
  );

  testWidgets('fresh Deal fields stay neutral until touch or publish', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final price = find.byKey(const ValueKey('create_listing_price_field'));
    final mileage = find.byKey(const ValueKey('create_listing_mileage_field'));
    expect(
      find.descendant(of: price, matching: find.text(ru.validationRequired)),
      findsNothing,
    );
    expect(
      find.descendant(of: mileage, matching: find.text(ru.validationRequired)),
      findsNothing,
    );
  });

  testWidgets('invalid touched price shows validation', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final price = find.byKey(const ValueKey('create_listing_price_field'));
    await tester.enterText(price, '0');
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: price, matching: find.text(ru.validationPositive)),
      findsOneWidget,
    );
  });

  testWidgets('cleared touched mileage shows required', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final mileage = find.byKey(const ValueKey('create_listing_mileage_field'));
    await tester.enterText(mileage, '1');
    await tester.enterText(mileage, '');
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: mileage, matching: find.text(ru.validationRequired)),
      findsOneWidget,
    );
  });

  testWidgets('publish attempt reveals required Deal errors', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final publish = find.text(ru.publishListing).last;
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pumpAndSettle();
    final price = find.byKey(const ValueKey('create_listing_price_field'));
    final mileage = find.byKey(const ValueKey('create_listing_mileage_field'));
    await tester.ensureVisible(price);
    expect(
      find.descendant(of: price, matching: find.text(ru.validationRequired)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: mileage, matching: find.text(ru.validationRequired)),
      findsOneWidget,
    );
    verifyNever(
      () => createCubit.submit(
        listingInput: any(named: 'listingInput'),
        orderedPhotos: any(named: 'orderedPhotos'),
      ),
    );
  });

  testWidgets('valid price and mileage stay quiet', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final price = find.byKey(const ValueKey('create_listing_price_field'));
    final mileage = find.byKey(const ValueKey('create_listing_mileage_field'));
    await tester.enterText(price, '9000');
    await tester.enterText(mileage, '100000');
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: price, matching: find.text(ru.validationRequired)),
      findsNothing,
    );
    expect(
      find.descendant(of: price, matching: find.text(ru.validationPositive)),
      findsNothing,
    );
    expect(
      find.descendant(of: mileage, matching: find.text(ru.validationRequired)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: mileage,
        matching: find.text(ru.validationNonNegative),
      ),
      findsNothing,
    );
  });

  Finder cityField() => find.byKey(const ValueKey('create_listing_city_field'));

  Finder phoneField() =>
      find.byKey(const ValueKey('create_listing_phone_field'));

  Finder cityRequiredError() => find.descendant(
    of: cityField(),
    matching: find.text(ru.validationRequired),
  );

  Finder phoneRequiredError() =>
      find.descendant(of: phoneField(), matching: find.text(ru.phoneRequired));

  Future<void> typeVin(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109186',
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fresh page keeps city and phone visually neutral', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(cityRequiredError(), findsNothing);
    expect(phoneRequiredError(), findsNothing);
    expect(find.text(ru.phoneInvalid), findsNothing);
  });

  testWidgets('VIN confirm does not redden untouched city or phone', (
    tester,
  ) async {
    await adoptBmw(tester);
    await typeVin(tester);
    expect(cityRequiredError(), findsNothing);
    expect(phoneRequiredError(), findsNothing);
  });

  testWidgets('VIN partial keeps untouched city and phone neutral', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.partial,
          suggestion: const VehicleResolveResult(
            resolution: VehicleResolveResolution.partial,
            vehicle: VehicleResolveSuggestion(make: 'Ford'),
            completeness: 0.2,
            warnings: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await typeVin(tester);
    expect(cityRequiredError(), findsNothing);
    expect(phoneRequiredError(), findsNothing);
  });

  testWidgets('touched invalid city shows required after interaction', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      cityField(),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(cityField());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listing_city_manual_option')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_manual_city_field')),
        matching: find.text(ru.validationRequired),
      ),
      findsOneWidget,
    );
  });

  testWidgets('touched invalid phone shows validation', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      phoneField(),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(phoneField(), '12');
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: phoneField(), matching: find.text(ru.phoneInvalid)),
      findsOneWidget,
    );
  });

  testWidgets('publish reveals untouched city and phone and blocks submit', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final publish = find.text(ru.publishListing).last;
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pumpAndSettle();
    await tester.ensureVisible(cityField());
    expect(cityRequiredError(), findsOneWidget);
    await tester.ensureVisible(phoneField());
    expect(phoneRequiredError(), findsOneWidget);
    verifyNever(
      () => createCubit.submit(
        listingInput: any(named: 'listingInput'),
        orderedPhotos: any(named: 'orderedPhotos'),
      ),
    );
  });

  testWidgets('publish attempt reveals required identity errors', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final publish = find.text(ru.publishListing).last;
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pumpAndSettle();
    final brand = find.byKey(const ValueKey('create_listing_brand_field'));
    final year = find.byKey(const ValueKey('create_listing_year_field'));
    await tester.ensureVisible(brand);
    expect(identityRequired(brand), findsOneWidget);
    expect(identityRequired(year), findsOneWidget);
  });

  testWidgets('VIN-first helper is the recommended path in RU and RO', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Введите или отсканируйте VIN. Carzon автоматически определит марку, модель и год.',
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(wrap(locale: const Locale('ro')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Introduceți sau scanați VIN-ul. Carzon va identifica automat marca, modelul și anul.',
      ),
      findsOneWidget,
    );
    expect(find.text(ro.createListingEnterManually), findsNothing);
    expect(find.text(ro.createListingOrSeparator), findsOneWidget);
    expect(find.text(ro.createListingManualVehicleTitle), findsOneWidget);
    expect(find.text(ro.createListingManualVehicleSubtitle), findsOneWidget);
  });

  testWidgets('confirmed VIN identity does not show required errors', (
    tester,
  ) async {
    await adoptBmw(tester);
    expect(identityEditors(tester).offstage, isTrue);
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsNothing,
    );
  });

  testWidgets('shows resolving state', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.resolving,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('create_listing_vin_resolving')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingVinResolving), findsOneWidget);
  });

  testWidgets('shows resolved confirmation card', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.resolved,
          suggestion: bmw,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_vehicle_found_card')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingVehicleFound), findsOneWidget);
    expect(find.text('BMW X5 · 2020'), findsOneWidget);
    expect(find.text('xDrive30d'), findsOneWidget);
    expect(find.text(ru.createListingConfirmVehicle), findsOneWidget);
    expect(find.text(ru.createListingChangeManually), findsOneWidget);
    expect(identityEditors(tester).offstage, isTrue);
    expect(confirmedSummary(), findsNothing);
  });

  testWidgets('manual fallback remains visible', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('create_listing_enter_manually'));
    expect(action, findsOneWidget);
    expect(find.text(ru.createListingEnterManually), findsNothing);
    expect(find.text(ru.createListingManualVehicleTitle), findsOneWidget);
    expect(find.text(ru.createListingManualVehicleSubtitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_vin_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_scan_vin')),
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
    final actionSize = tester.getSize(action);
    expect(actionSize.height, greaterThanOrEqualTo(44));
    expect(actionSize.width, greaterThanOrEqualTo(44));
    expect(
      tester.getSemantics(action).label,
      contains(ru.createListingManualVehicleTitle),
    );
    expect(
      tester.getSemantics(action).label,
      contains(ru.createListingManualVehicleSubtitle),
    );
    await openCreateListingManualIdentity(tester);
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_year_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_vin_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_scan_vin')),
      findsOneWidget,
    );
  });

  testWidgets('likely checksum error is distinct from syntax and provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.likelyInputError,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_vin_checksum')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingVinChecksumHint), findsOneWidget);
    expect(find.text(ru.createListingVehicleFound), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_vin_partial')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_vin_failure')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsNothing,
    );
    expect(find.text(ru.createListingEnterManually), findsNothing);
    expect(find.text(ru.createListingManualVehicleTitle), findsOneWidget);
  });

  testWidgets('typed checksum-invalid VIN shows correction and can recover', (
    tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109187',
    );
    await tester.pump();
    verify(() => createCubit.onVinChanged('1HGBH41JXMN109187')).called(1);
    controller.add(
      resolveOf(status: CreateListingVinResolveStatus.likelyInputError),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.createListingVinChecksumHint), findsWidgets);
    expect(
      find.byKey(const ValueKey('create_listing_vin_resolving')),
      findsNothing,
    );

    controller.add(
      resolveOf(
        status: CreateListingVinResolveStatus.resolved,
        suggestion: bmw,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.createListingVehicleFound), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_vin_checksum')),
      findsNothing,
    );
  });

  testWidgets('partial make-only is not a found card', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.partial,
          suggestion: const VehicleResolveResult(
            resolution: VehicleResolveResolution.partial,
            vehicle: VehicleResolveSuggestion(make: 'Ford'),
            completeness: 0.2,
            warnings: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.createListingVinPartialTitle), findsOneWidget);
    expect(find.text(ru.createListingVinPartial), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_vin_partial')),
        matching: find.text('Ford'),
      ),
      findsOneWidget,
    );
    expect(find.text(ru.createListingVehicleFound), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_confirm_vehicle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_year_field')),
      findsOneWidget,
    );
  });

  testWidgets('partial make and model without year stays manual', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.partial,
          suggestion: const VehicleResolveResult(
            resolution: VehicleResolveResolution.partial,
            vehicle: VehicleResolveSuggestion(make: 'Ford', model: 'Focus'),
            completeness: 0.4,
            warnings: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ford Focus'), findsOneWidget);
    expect(find.text(ru.createListingVinPartialTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_confirm_vehicle')),
      findsNothing,
    );
  });

  testWidgets('no_data state is non-blocking', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(status: CreateListingVinResolveStatus.noData),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_vin_no_data')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingVinNoData), findsOneWidget);
    expect(find.text(ru.createListingEnterManually), findsNothing);
    expect(find.text(ru.createListingManualVehicleTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsOneWidget,
    );
  });

  testWidgets('recoverable failure shows retry', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.failure,
          failureKind: VehicleResolveFailureKind.upstreamUnavailable,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_vin_failure')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingVinResolverFailed), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_vin_retry')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('create_listing_vin_retry')));
    verify(createCubit.retryResolve).called(1);
  });

  testWidgets('edit characteristics editor stays collapsed', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_additional_details')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingEditCharacteristics), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_body_type_field')),
      findsNothing,
    );
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.byKey(const ValueKey('create_listing_body_type_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_fuel_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_transmission_field')),
      findsOneWidget,
    );
  });

  testWidgets('RU and RO expose VIN-first copy', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text(ru.createListingVinAutofillHint), findsOneWidget);
    expect(find.text(ru.createListingEnterManually), findsNothing);
    expect(find.text(ru.createListingManualVehicleTitle), findsOneWidget);
    expect(find.text(ru.createListingManualVehicleSubtitle), findsOneWidget);
    expect(find.text(ru.createListingOrSeparator), findsOneWidget);
    expect(find.text(ru.createListingEditCharacteristics), findsOneWidget);

    await tester.pumpWidget(wrap(locale: const Locale('ro')));
    await tester.pumpAndSettle();
    expect(find.text(ro.createListingVinAutofillHint), findsOneWidget);
    expect(find.text(ro.createListingEnterManually), findsNothing);
    expect(find.text(ro.createListingManualVehicleTitle), findsOneWidget);
    expect(find.text(ro.createListingManualVehicleSubtitle), findsOneWidget);
    expect(find.text(ro.createListingOrSeparator), findsOneWidget);
    expect(find.text(ro.createListingEditCharacteristics), findsOneWidget);
  });

  testWidgets('confirm applies identity without overwriting variant', (
    tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await openCreateListingManualIdentity(tester);

    await tester.enterText(
      find.byKey(const ValueKey('create_listing_variant_field')),
      'M Sport',
    );
    await tester.pump();

    final confirmed = resolveOf(
      status: CreateListingVinResolveStatus.resolved,
      suggestion: bmw,
      confirmed: true,
      applyRevision: 1,
      identity: const ConfirmedVehicleIdentity(
        make: 'BMW',
        model: 'X5',
        year: 2020,
        variant: 'xDrive30d',
      ),
    );
    when(() => createCubit.state).thenReturn(confirmed);
    controller.add(confirmed);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: confirmedSummary(), matching: find.text('M Sport')),
      findsOneWidget,
    );
    final variantField = tester.widget<TextFormField>(
      find.byKey(
        const ValueKey('create_listing_variant_field'),
        skipOffstage: false,
      ),
    );
    expect(variantField.controller?.text, 'M Sport');
    expect(identityEditors(tester).offstage, isTrue);
  });

  testWidgets(
    'generated title uses seller identity, not unconfirmed suggestion',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          resolveState: resolveOf(
            status: CreateListingVinResolveStatus.resolved,
            suggestion: bmw,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(ru.createListingChangeManually));
      await tester.pumpAndSettle();

      final brand = find.byKey(const ValueKey('create_listing_brand_field'));
      await tester.scrollUntilVisible(
        brand,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(brand);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Toyota');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
      await tester.pumpAndSettle();

      final modelField = find.byKey(
        const ValueKey('create_listing_model_field'),
      );
      await tester.ensureVisible(modelField);
      await tester.tap(modelField);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('listing_model_Corolla')));
      await tester.pumpAndSettle();

      final year = find.byKey(const ValueKey('create_listing_year_field'));
      await tester.ensureVisible(year);
      await tester.tap(year);
      await tester.pumpAndSettle();
      await tester.tap(find.text(ru.commonDone));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, ru.createListingPricePlaceholder),
        '9000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, ru.createListingMileagePlaceholder),
        '100000',
      );

      final city = find.byKey(const ValueKey('create_listing_city_field'));
      await tester.scrollUntilVisible(
        city,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(city);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тирасполь'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, ru.fieldPhone),
        '+37369000001',
      );

      final publish = find.text(ru.publishListing).last;
      await tester.ensureVisible(publish);
      await tester.tap(publish);
      await tester.pump();

      final submitted =
          verify(
                () => createCubit.submit(
                  listingInput: captureAny(named: 'listingInput'),
                  orderedPhotos: any(named: 'orderedPhotos'),
                ),
              ).captured.single
              as NewListingInput;
      expect(submitted.make, 'Toyota');
      expect(submitted.model, 'Corolla');
      expect(submitted.title, isNot(contains('BMW')));
      expect(
        submitted.title,
        resolvedListingTitleForSubmit(
          trimmedUserTitle: '',
          make: 'Toyota',
          model: 'Corolla',
          year: submitted.year,
          l10n: ru,
        ),
      );
      expect(submitted.bodyType, isNull);
      expect(submitted.fuelType, isNull);
      expect(submitted.drivetrain, isNull);
      expect(submitted.transmissionType, isNull);
    },
  );

  testWidgets('confirmed VIN identity hides primary selectors', (tester) async {
    await adoptBmw(tester);
    expect(confirmedSummary(), findsOneWidget);
    expect(
      find.descendant(
        of: confirmedSummary(),
        matching: find.text('BMW X5 · 2020'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: confirmedSummary(), matching: find.text('xDrive30d')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: confirmedSummary(),
        matching: find.text(ru.createListingVehicleIdentifiedFromVin),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_change_confirmed_vehicle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_confirm_vehicle')),
      findsNothing,
    );
    expect(identityEditors(tester).offstage, isTrue);
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.identityKey)).data,
      'BMW X5',
    );
  });

  testWidgets('Change restores identity editors and keeps values', (
    tester,
  ) async {
    final controller = await adoptBmw(tester);
    await tapChangeConfirmed(tester, controller);
    expect(confirmedSummary(), findsNothing);
    expect(identityEditors(tester).offstage, isFalse);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('create_listing_manual_model')),
          )
          .controller
          ?.text,
      'X5',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('create_listing_variant_field')),
          )
          .controller
          ?.text,
      'xDrive30d',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_year_field')),
        matching: find.text('2020'),
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_manual_model')),
      'X6',
    );
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.identityKey)).data,
      'BMW X6',
    );
    controller.add(
      resolveOf(
        status: CreateListingVinResolveStatus.resolved,
        suggestion: bmw,
        applyRevision: 1,
        identity: const ConfirmedVehicleIdentity(
          make: 'BMW',
          model: 'X5',
          year: 2020,
          variant: 'xDrive30d',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('create_listing_manual_model')),
          )
          .controller
          ?.text,
      'X6',
    );
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.identityKey)).data,
      'BMW X6',
    );
  });

  testWidgets('VIN change drops compact VIN-A confirmed state', (tester) async {
    final controller = await adoptBmw(tester);
    expect(confirmedSummary(), findsOneWidget);
    expect(identityEditors(tester).offstage, isTrue);
    await changeToVinB(tester, controller);
    expect(confirmedSummary(), findsNothing);
    expect(identityEditors(tester).offstage, isTrue);
    expect(
      find.byKey(const ValueKey('create_listing_enter_manually')),
      findsOneWidget,
    );
    expect(find.text('BMW X5 · 2020'), findsNothing);
    expect(find.text(ru.createListingVehicleIdentifiedFromVin), findsNothing);
  });

  testWidgets('variant is editable again after Change', (tester) async {
    final controller = await adoptBmw(tester);
    expect(
      find.descendant(of: confirmedSummary(), matching: find.text('xDrive30d')),
      findsOneWidget,
    );
    await tapChangeConfirmed(tester, controller);
    final variant = find.byKey(const ValueKey('create_listing_variant_field'));
    await tester.ensureVisible(variant);
    await tester.enterText(variant, 'M Sport');
    await tester.pump();
    expect(tester.widget<TextFormField>(variant).controller?.text, 'M Sport');
  });

  testWidgets('RU and RO expose confirmed VIN identity copy', (tester) async {
    final confirmed = resolveOf(
      status: CreateListingVinResolveStatus.resolved,
      suggestion: bmw,
      confirmed: true,
      applyRevision: 1,
      identity: const ConfirmedVehicleIdentity(
        make: 'BMW',
        model: 'X5',
        year: 2020,
        variant: 'xDrive30d',
      ),
    );
    await tester.pumpWidget(wrap(resolveState: confirmed));
    await tester.pumpAndSettle();
    expect(find.text(ru.createListingVehicleIdentifiedFromVin), findsOneWidget);
    expect(find.text(ru.createListingChangeManually), findsOneWidget);

    await tester.pumpWidget(
      wrap(locale: const Locale('ro'), resolveState: confirmed),
    );
    await tester.pumpAndSettle();
    expect(find.text(ro.createListingVehicleIdentifiedFromVin), findsOneWidget);
    expect(find.text(ro.createListingChangeManually), findsOneWidget);
    expect(find.text(ru.createListingVehicleIdentifiedFromVin), findsNothing);
  });

  testWidgets(
    'confirmed VIN and hydrated defaults keep the short primary path',
    (tester) async {
      final controller = StreamController<CreateListingState>();
      addTearDown(controller.close);
      whenListen(
        createCubit,
        controller.stream,
        initialState: const CreateListingState.idle(),
      );
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      final next = CreateListingState(
        vehicleResolve: CreateListingVehicleResolve(
          status: CreateListingVinResolveStatus.resolved,
          normalizedVin: '1HGBH41JXMN109186',
          suggestion: bmw,
          confirmed: true,
          applyRevision: 1,
          confirmedIdentity: const ConfirmedVehicleIdentity(
            make: 'BMW',
            model: 'X5',
            year: 2020,
            variant: 'xDrive30d',
          ),
        ),
        listingDefaults: const CreateListingListingDefaults(
          status: CreateListingDefaultsStatus.ready,
          applyRevision: 1,
          values: SellerListingDefaults(
            contactPhone: '+373 690 00001',
            telegramUsername: 'seller_md',
            whatsappEnabled: true,
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
          ),
          prefill: SellerListingDefaultsPrefill(
            contactPhone: '+373 690 00001',
            telegramUsername: 'seller_md',
            whatsappEnabled: true,
            marketRegion: MarketRegion.transnistria,
            city: 'Тирасполь',
          ),
        ),
      );
      when(() => createCubit.state).thenReturn(next);
      controller.add(next);
      await tester.pumpAndSettle();

      const sectionKeys = [
        'create_listing_vehicle_section',
        'create_listing_photos_section',
        'create_listing_type_section',
        'create_listing_location_section',
        'create_listing_contact_section',
        'create_listing_characteristics_section',
        'create_listing_description_section',
        'create_listing_publish_section',
      ];
      for (var i = 1; i < sectionKeys.length; i++) {
        expect(
          tester.getTopLeft(find.byKey(ValueKey(sectionKeys[i - 1]))).dy,
          lessThan(tester.getTopLeft(find.byKey(ValueKey(sectionKeys[i]))).dy),
        );
      }
      expect(confirmedSummary(), findsOneWidget);
      expect(identityEditors(tester).offstage, isTrue);
      expect(
        tester
            .widget<Offstage>(
              find.byKey(const ValueKey('create_listing_location_editors')),
            )
            .offstage,
        isTrue,
      );
      expect(
        tester
            .widget<Offstage>(
              find.byKey(const ValueKey('create_listing_contact_editors')),
            )
            .offstage,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('create_listing_body_type_field')),
        findsNothing,
      );
      expect(
        tester.getTopLeft(find.byKey(ListingPreviewCard.headingKey)).dy,
        lessThan(tester.getTopLeft(find.text(ru.publishListing).last).dy),
      );
    },
  );

  const ram = VehicleResolveResult(
    resolution: VehicleResolveResolution.resolved,
    vehicle: VehicleResolveSuggestion(
      make: 'Ram',
      model: '1500',
      year: 2021,
      trim: 'TRX',
      bodyType: 'Pickup',
      fuelType: 'Gasoline',
      engine: 'Supercharged 6.2',
      transmission: 'Automatic',
      driveType: '4WD/4-Wheel Drive/4x4',
      displacement: '6.2 L',
      cylinders: '8',
    ),
    completeness: 0.83,
    warnings: [],
  );

  testWidgets('resolved VIN specs are visible before confirm', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.resolved,
          suggestion: ram,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final card = find.byKey(
      const ValueKey('create_listing_vehicle_found_card'),
    );
    expect(
      find.descendant(of: card, matching: find.text('Ram 1500 · 2021')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('TRX')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_vin_spec_line1')),
      findsOneWidget,
    );
    expect(find.text('Бензин · Автомат'), findsOneWidget);
    expect(find.text('4×4 · 6.2 л'), findsOneWidget);
    expect(find.text('Пикап'), findsOneWidget);
    expect(find.text('Gasoline'), findsNothing);
    expect(find.text('Automatic'), findsNothing);
    expect(find.text('Pickup'), findsNothing);
    expect(find.text('Supercharged 6.2'), findsNothing);
    expect(find.text('8'), findsNothing);
    expect(find.text('0.83'), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_vin_spec_caution')),
      findsNothing,
    );
    expect(find.text(ru.createListingConfirmVehicle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_body_type_field')),
      findsNothing,
    );
  });

  testWidgets('confirmed VIN keeps detected specs', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.resolved,
          suggestion: ram,
          confirmed: true,
          applyRevision: 1,
          identity: const ConfirmedVehicleIdentity(
            make: 'Ram',
            model: '1500',
            year: 2021,
            variant: 'TRX',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: confirmedSummary(),
        matching: find.text('Бензин · Автомат'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: confirmedSummary(), matching: find.text('Пикап')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingVehicleIdentifiedFromVin), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_confirm_vehicle')),
      findsNothing,
    );
  });

  testWidgets('partial extra fields omit empty spec separators', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.resolved,
          suggestion: const VehicleResolveResult(
            resolution: VehicleResolveResolution.resolved,
            vehicle: VehicleResolveSuggestion(
              make: 'Honda',
              model: 'Civic',
              year: 2019,
              fuelType: 'Gasoline',
            ),
            completeness: 0.4,
            warnings: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Бензин'), findsOneWidget);
    expect(find.text('Бензин ·'), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_vin_spec_line2')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_vin_spec_body')),
      findsNothing,
    );
  });

  testWidgets('unknown provider spec values are omitted', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.resolved,
          suggestion: const VehicleResolveResult(
            resolution: VehicleResolveResolution.resolved,
            vehicle: VehicleResolveSuggestion(
              make: 'Honda',
              model: 'Civic',
              year: 2019,
              fuelType: 'Flexible Fuel',
              transmission: 'Automated Manual',
              driveType: '4x2',
              bodyType: 'Incomplete - Cutaway',
            ),
            completeness: 0.5,
            warnings: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flexible Fuel'), findsNothing);
    expect(find.text('Automated Manual'), findsNothing);
    expect(find.text('4x2'), findsNothing);
    expect(find.text('Incomplete - Cutaway'), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_vin_spec_summary')),
      findsNothing,
    );
  });

  testWidgets('safe resolver warning shows generic caution', (tester) async {
    await tester.pumpWidget(
      wrap(
        resolveState: resolveOf(
          status: CreateListingVinResolveStatus.resolved,
          suggestion: const VehicleResolveResult(
            resolution: VehicleResolveResolution.resolved,
            vehicle: VehicleResolveSuggestion(
              make: 'Ram',
              model: '1500',
              year: 2021,
              fuelType: 'Gasoline',
            ),
            completeness: 0.7,
            warnings: ['nhtsa_catalog_decode_caution'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_vin_spec_caution')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingVinSpecCaution), findsOneWidget);
    expect(find.text('nhtsa_catalog_decode_caution'), findsNothing);
  });

  testWidgets('VIN change drops previous technical summary', (tester) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: resolveOf(
        status: CreateListingVinResolveStatus.resolved,
        suggestion: ram,
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Бензин · Автомат'), findsOneWidget);
    final next = resolveOf(
      status: CreateListingVinResolveStatus.resolved,
      suggestion: bmw,
      normalizedVin: 'WBAAA1308H2321234',
    );
    when(() => createCubit.state).thenReturn(next);
    controller.add(next);
    await tester.pumpAndSettle();
    expect(find.text('Бензин · Автомат'), findsNothing);
    expect(find.text('Пикап'), findsNothing);
    expect(find.text('BMW X5 · 2020'), findsOneWidget);
  });

  testWidgets('manual flow does not show VIN spec summary', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_vin_spec_summary')),
      findsNothing,
    );
    expect(find.text(ru.createListingVinSpecCaution), findsNothing);
  });

  const ramIdentity = ConfirmedVehicleIdentity(
    make: 'Ram',
    model: '1500',
    year: 2021,
    variant: 'TRX',
  );

  Future<StreamController<CreateListingState>> adoptRam(
    WidgetTester tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    controller.add(
      resolveOf(
        status: CreateListingVinResolveStatus.resolved,
        suggestion: ram,
        confirmed: true,
        applyRevision: 1,
        identity: ramIdentity,
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Finder bodyTypeField() =>
      find.byKey(const ValueKey('create_listing_body_type_field'));
  Finder fuelField() => find.byKey(const ValueKey('create_listing_fuel_field'));
  Finder transmissionField() =>
      find.byKey(const ValueKey('create_listing_transmission_field'));
  Finder drivetrainField() =>
      find.byKey(const ValueKey('create_listing_drivetrain_field'));
  Finder displacementField() =>
      find.byKey(const ValueKey('create_listing_engine_displacement_field'));

  Future<void> expectPrefillVisible(
    WidgetTester tester, {
    required String body,
    required String fuel,
    required String transmission,
    required String drivetrain,
    required String displacement,
  }) async {
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(of: bodyTypeField(), matching: find.text(body)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: fuelField(), matching: find.text(fuel)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: transmissionField(),
        matching: find.text(transmission),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: drivetrainField(), matching: find.text(drivetrain)),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      displacement,
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pickFuel(WidgetTester tester, String label) async {
    await tapVisible(tester, fuelField());
    final option = find.text(label);
    await tester.scrollUntilVisible(
      option,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(option);
    await tester.pumpAndSettle();
  }

  Future<void> fillRequiredDeal(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, ru.createListingPricePlaceholder),
      '9000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, ru.createListingMileagePlaceholder),
      '100000',
    );
    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.scrollUntilVisible(
      city,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тирасполь'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, ru.fieldPhone),
      '+37369000001',
    );
  }

  testWidgets('confirm prefills empty optional specs from VIN', (tester) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    controller.add(
      resolveOf(
        status: CreateListingVinResolveStatus.resolved,
        suggestion: ram,
      ),
    );
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsNothing,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      isEmpty,
    );

    controller.add(
      resolveOf(
        status: CreateListingVinResolveStatus.resolved,
        suggestion: ram,
        confirmed: true,
        applyRevision: 1,
        identity: ramIdentity,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: fuelField(),
        matching: find.text(ru.listingFuelTypePetrol),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: transmissionField(),
        matching: find.text(ru.listingTransmissionAutomatic),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: drivetrainField(),
        matching: find.text(ru.listingDrivetrainFourWheel),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      '6.2',
    );
  });

  testWidgets('confirm does not overwrite seller optional values', (
    tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    await tapVisible(tester, bodyTypeField());
    await tester.tap(find.text(ru.listingBodyTypeSedan));
    await tester.pumpAndSettle();
    await pickFuel(tester, ru.listingFuelTypeDiesel);

    controller.add(
      resolveOf(
        status: CreateListingVinResolveStatus.resolved,
        suggestion: ram,
        confirmed: true,
        applyRevision: 1,
        identity: ramIdentity,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypeSedan),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: fuelField(),
        matching: find.text(ru.listingFuelTypeDiesel),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: transmissionField(),
        matching: find.text(ru.listingTransmissionAutomatic),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      '6.2',
    );
  });

  testWidgets('Advanced Details shows VIN-prefilled values after confirm', (
    tester,
  ) async {
    await adoptRam(tester);
    expect(bodyTypeField(), findsNothing);
    await expectPrefillVisible(
      tester,
      body: ru.listingBodyTypePickup,
      fuel: ru.listingFuelTypePetrol,
      transmission: ru.listingTransmissionAutomatic,
      drivetrain: ru.listingDrivetrainFourWheel,
      displacement: '6.2',
    );
  });

  testWidgets('seller edit after VIN prefill becomes seller-owned', (
    tester,
  ) async {
    final controller = await adoptRam(tester);
    await expandCreateListingAdditionalDetails(tester);
    await pickFuel(tester, ru.listingFuelTypeDiesel);
    await changeToVinB(tester, controller);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: fuelField(),
        matching: find.text(ru.listingFuelTypeDiesel),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsNothing,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      isEmpty,
    );
  });

  testWidgets('VIN A to VIN B clears untouched VIN-owned optional specs', (
    tester,
  ) async {
    final controller = await adoptRam(tester);
    await expandCreateListingAdditionalDetails(tester);
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      '6.2',
    );
    await changeToVinB(tester, controller);
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: fuelField(),
        matching: find.text(ru.listingFuelTypePetrol),
      ),
      findsNothing,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      isEmpty,
    );
  });

  testWidgets('clearing VIN keeps seller-owned optional specs', (tester) async {
    final controller = await adoptRam(tester);
    await expandCreateListingAdditionalDetails(tester);
    await pickFuel(tester, ru.listingFuelTypeDiesel);
    controller.add(const CreateListingState.idle());
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: fuelField(),
        matching: find.text(ru.listingFuelTypeDiesel),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsNothing,
    );
  });

  testWidgets('Change identity keeps VIN-prefilled optional specs', (
    tester,
  ) async {
    final controller = await adoptRam(tester);
    await tapChangeConfirmed(tester, controller, identity: ramIdentity);
    await expectPrefillVisible(
      tester,
      body: ru.listingBodyTypePickup,
      fuel: ru.listingFuelTypePetrol,
      transmission: ru.listingTransmissionAutomatic,
      drivetrain: ru.listingDrivetrainFourWheel,
      displacement: '6.2',
    );
  });

  testWidgets('unknown provider specs do not prefill optional fields', (
    tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    const unknown = VehicleResolveResult(
      resolution: VehicleResolveResolution.resolved,
      vehicle: VehicleResolveSuggestion(
        make: 'Honda',
        model: 'Civic',
        year: 2019,
        fuelType: 'Flexible Fuel',
        transmission: 'Automated Manual',
        driveType: '4x2',
        bodyType: 'Incomplete - Cutaway',
        displacement: 'huge',
      ),
      completeness: 0.5,
      warnings: [],
    );
    final confirmed = resolveOf(
      status: CreateListingVinResolveStatus.resolved,
      suggestion: unknown,
      confirmed: true,
      applyRevision: 1,
      identity: const ConfirmedVehicleIdentity(
        make: 'Honda',
        model: 'Civic',
        year: 2019,
      ),
    );
    controller.add(confirmed);
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsNothing,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      isEmpty,
    );
  });

  testWidgets('submitted NewListingInput uses VIN-prefilled optional specs', (
    tester,
  ) async {
    await adoptRam(tester);
    await fillRequiredDeal(tester);
    final publish = find.text(ru.publishListing).last;
    await tester.ensureVisible(publish);
    await tester.tap(publish);
    await tester.pump();
    final submitted =
        verify(
              () => createCubit.submit(
                listingInput: captureAny(named: 'listingInput'),
                orderedPhotos: any(named: 'orderedPhotos'),
              ),
            ).captured.single
            as NewListingInput;
    expect(submitted.bodyType, ListingBodyType.pickup);
    expect(submitted.fuelType, ListingFuelType.petrol);
    expect(submitted.transmissionType, ListingTransmissionType.automatic);
    expect(submitted.drivetrain, ListingDrivetrain.fourWheel);
    expect(submitted.engineDisplacementLiters, 6.2);
    expect(submitted.enginePowerHp, isNull);
  });

  testWidgets('VIN confirm reflects form specs on preview', (tester) async {
    await adoptRam(tester);
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.identityKey)).data,
      'Ram 1500',
    );
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
    expect(find.text('Pickup'), findsNothing);
  });

  testWidgets('catalog decode caution does not prefill optional specs', (
    tester,
  ) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final caution = VehicleResolveResult(
      resolution: VehicleResolveResolution.resolved,
      vehicle: ram.vehicle,
      completeness: ram.completeness,
      warnings: const ['nhtsa_catalog_decode_caution'],
    );
    final confirmed = resolveOf(
      status: CreateListingVinResolveStatus.resolved,
      suggestion: caution,
      confirmed: true,
      applyRevision: 1,
      identity: ramIdentity,
    );
    controller.add(confirmed);
    await tester.pumpAndSettle();
    await expandCreateListingAdditionalDetails(tester);
    expect(
      find.descendant(
        of: bodyTypeField(),
        matching: find.text(ru.listingBodyTypePickup),
      ),
      findsNothing,
    );
    expect(
      tester.widget<TextFormField>(displacementField()).controller?.text,
      isEmpty,
    );
  });
}
