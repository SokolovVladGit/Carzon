import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/domain/validation/listing_publish_numeric.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_step_chrome.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const bmw = VehicleResolveResult(
    resolution: VehicleResolveResolution.resolved,
    vehicle: VehicleResolveSuggestion(
      make: 'BMW',
      model: 'X5',
      year: 2020,
      trim: 'xDrive30d',
      fuelType: 'Gasoline',
      displacement: '3.0',
      transmission: 'Automatic',
    ),
    completeness: 0.9,
    warnings: [],
  );

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
    CreateListingPage.debugRevealAllSteps = false;
    sl.registerFactory<CreateListingCubit>(() => createCubit);
  });

  tearDown(() async {
    CreateListingPage.debugRevealAllSteps = false;
    await sl.reset();
  });

  Widget wrap({CreateListingState? resolveState, ThemeData? theme}) {
    if (resolveState != null) {
      when(() => createCubit.state).thenReturn(resolveState);
      whenListen(
        createCubit,
        const Stream<CreateListingState>.empty(),
        initialState: resolveState,
      );
    }
    return MaterialApp(
      theme: theme,
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: CreateListingPage(vehicleModelCatalog: catalog),
      ),
    );
  }

  CreateListingState confirmedBmw() {
    return const CreateListingState(
      vehicleResolve: CreateListingVehicleResolve(
        status: CreateListingVinResolveStatus.resolved,
        normalizedVin: '1HGBH41JXMN109186',
        suggestion: bmw,
        confirmed: true,
        applyRevision: 1,
        confirmedIdentity: ConfirmedVehicleIdentity(
          make: 'BMW',
          model: 'X5',
          year: 2020,
          variant: 'xDrive30d',
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, {CreateListingState? state}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrap(resolveState: state));
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('create_listing_step_continue'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> fillManualIdentity(WidgetTester tester) async {
    await openCreateListingManualIdentity(tester);
    final brand = find.byKey(const ValueKey('create_listing_brand_field'));
    await tester.tap(brand);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Toyota');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Toyota'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_model_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('listing_model_Corolla')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create_listing_year_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ru.commonDone));
    await tester.pumpAndSettle();
  }

  testWidgets('step 1 hides later sections', (tester) async {
    await pump(tester);
    expect(find.text(ru.createListingVinAutofillHelper), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_step_continue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_price_field')),
      findsNothing,
    );
    expect(find.text(ru.publishListing), findsNothing);
  });

  testWidgets('Continue confirms resolved VIN and opens data', (tester) async {
    await pump(
      tester,
      state: const CreateListingState(
        vehicleResolve: CreateListingVehicleResolve(
          status: CreateListingVinResolveStatus.resolved,
          normalizedVin: '1HGBH41JXMN109186',
          suggestion: bmw,
        ),
      ),
    );
    expect(find.text('BMW X5 · 2020'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsNothing,
    );

    when(() => createCubit.confirmSuggestion()).thenAnswer((_) {
      when(() => createCubit.state).thenReturn(confirmedBmw());
    });

    await tapContinue(tester);

    verify(() => createCubit.confirmSuggestion()).called(1);
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_price_field')),
      findsNothing,
    );
    expect(find.text('BMW X5 · 2020'), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_auto_status')),
      findsOneWidget,
    );
    expect(
      find.textContaining(formatListingFuelType(ru, ListingFuelType.petrol)),
      findsWidgets,
    );
  });

  testWidgets('manual identity Continue reaches data', (tester) async {
    await pump(tester);
    await fillManualIdentity(tester);
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsNothing,
    );
  });

  testWidgets('photos step does not require photos', (tester) async {
    await pump(tester);
    await fillManualIdentity(tester);
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsOneWidget,
    );
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_price_field')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '9000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      '100000',
    );
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsOneWidget,
    );
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_city_field')),
      findsOneWidget,
    );
  });

  testWidgets('offer Continue requires valid price and mileage', (
    tester,
  ) async {
    await pump(tester);
    await fillManualIdentity(tester);
    await tapContinue(tester);
    await tapContinue(tester);

    await tapContinue(tester);
    expect(find.text(ru.validationRequired), findsWidgets);
    expect(
      find.byKey(const ValueKey('create_listing_price_field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '1e6',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      '10',
    );
    await tapContinue(tester);
    expect(find.text(ru.validationPositive), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '${kListingMileageKmMax + 1}',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      '${kListingMileageKmMax + 1}',
    );
    await tapContinue(tester);
    expect(find.textContaining('≤ $kListingMileageKmMax'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '9000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      '100000',
    );
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsNothing,
    );
  });

  testWidgets('contact Continue requires city and phone', (tester) async {
    await pump(tester);
    await fillManualIdentity(tester);
    await tapContinue(tester);
    await tapContinue(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '9000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      '100000',
    );
    await tapContinue(tester);
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_city_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_phone_field')),
      findsOneWidget,
    );

    await tapContinue(tester);
    expect(find.text(ru.publishListing), findsNothing);
    expect(find.text(ru.validationRequired), findsWidgets);

    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.ensureVisible(city);
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тирасполь'));
    await tester.pumpAndSettle();
    final phone = find.byKey(const ValueKey('create_listing_phone_field'));
    await tester.ensureVisible(phone);
    await tester.enterText(phone, '+37369000001');
    await tapContinue(tester);
    expect(find.byKey(ListingPreviewCard.cardKey), findsOneWidget);
    expect(find.text(ru.publishListing), findsOneWidget);
    expect(find.textContaining('Toyota'), findsWidgets);
    expect(find.textContaining('9'), findsWidgets);
  });

  testWidgets('publish submits accumulated state from the review step', (
    tester,
  ) async {
    await pump(tester);
    await fillManualIdentity(tester);
    await tapContinue(tester);
    await tapContinue(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '9000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      '100000',
    );
    await tapContinue(tester);
    await tapContinue(tester);
    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.ensureVisible(city);
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тирасполь'));
    await tester.pumpAndSettle();
    final phone = find.byKey(const ValueKey('create_listing_phone_field'));
    await tester.ensureVisible(phone);
    await tester.enterText(phone, '+37369000001');
    await tapContinue(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_description_field')),
      'Один владелец',
    );
    await tester.tap(find.text(ru.publishListing));
    await tester.pump();

    final input =
        verify(
              () => createCubit.submit(
                listingInput: captureAny(named: 'listingInput'),
                orderedPhotos: any(named: 'orderedPhotos'),
              ),
            ).captured.single
            as NewListingInput;
    expect(input.make, 'Toyota');
    expect(input.model, 'Corolla');
    expect(input.priceEur, 9000);
    expect(input.mileageKm, 100000);
    expect(input.city, 'Тирасполь');
    expect(input.contactPhone, '+37369000001');
    expect(input.description, 'Один владелец');
    expect(input.uploadedGallery, isNull);
  });

  testWidgets('shared shell and progress stay put across steps', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(ru.createListingFlowTitle), findsOneWidget);
    final haze = tester.getRect(
      find.byKey(const ValueKey('create_listing_upper_haze')),
    );
    final titleRect = tester.getRect(find.text(ru.createListingFlowTitle));
    final lastLabel = tester.getRect(find.text(ru.createListingStepDone));
    final imageRectEarly = tester.getRect(
      find.byKey(CreateListingFlowShell.imageKey),
    );
    expect(haze.top, lessThan(titleRect.top));
    expect(haze.bottom, greaterThan(lastLabel.bottom));
    expect(haze.left, lessThanOrEqualTo(titleRect.left));
    expect(haze.right, greaterThanOrEqualTo(lastLabel.right));
    expect(haze.height, lessThan(imageRectEarly.height * 0.42));
    expect(
      tester.widget<Text>(find.text(ru.createListingFlowTitle)).style?.color,
      const Color(0xFF2C261F),
    );
    final doneLabel = tester.widget<Text>(find.text(ru.createListingStepDone));
    expect(doneLabel.style?.fontWeight, FontWeight.w700);
    expect(doneLabel.style?.fontSize, 12);
    expect(doneLabel.style?.color, const Color(0xFF362C24));
    final vinLabel = tester.widget<Text>(find.text(ru.createListingStepVin));
    expect(vinLabel.style?.fontWeight, FontWeight.w600);
    expect(vinLabel.style?.fontSize, 11);
    final photoLabel = tester.widget<Text>(
      find.text(ru.createListingStepPhotos),
    );
    expect(photoLabel.style?.fontWeight, FontWeight.w500);
    expect(photoLabel.style?.fontSize, 11);
    expect(photoLabel.style?.color, const Color(0xFF453E37));
    expect(photoLabel.style?.shadows, isNotEmpty);
    final shell = tester.getSize(find.byType(CreateListingFlowShell));
    expect(shell.width - lastLabel.right, greaterThanOrEqualTo(34));
    expect(
      tester.getRect(find.text(ru.createListingStepContacts)).right,
      lessThan(lastLabel.left + 1),
    );
    final photosX = tester.getCenter(find.text(ru.createListingStepPhotos)).dx;
    final contactsX = tester
        .getCenter(find.text(ru.createListingStepContacts))
        .dx;
    final doneX = tester.getCenter(find.text(ru.createListingStepDone)).dx;
    expect(((doneX - contactsX) - (contactsX - photosX)).abs(), lessThan(4));
    expect(
      tester
          .widget<Text>(find.text(ru.createListingHeaderSubtitle))
          .style
          ?.color,
      const Color(0xFF514A43),
    );
    final image = tester.widget<Image>(
      find.byKey(CreateListingFlowShell.imageKey),
    );
    expect(image.fit, BoxFit.cover);
    expect(
      (image.image as AssetImage).assetName,
      CreateListingFlowShell.backgroundAsset,
    );
    expect(
      tester
          .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .any(
            (region) =>
                region.value.statusBarColor == Colors.transparent &&
                region.value.statusBarIconBrightness == Brightness.dark &&
                region.value.statusBarBrightness == Brightness.light,
          ),
      isTrue,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('create_listing_step_continue')),
          )
          .style
          ?.side,
      isNull,
    );
    expect(image.alignment, Alignment.topCenter);
    final imageRect = tester.getRect(
      find.byKey(CreateListingFlowShell.imageKey),
    );
    expect(imageRect, const Rect.fromLTWH(0, 0, 390, 844));
    expect(
      find.descendant(
        of: find.byType(CreateListingFlowShell),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
    final currentMarker = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_step_marker_current')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final currentDecoration = currentMarker.decoration! as BoxDecoration;
    expect(currentDecoration.shape, BoxShape.rectangle);
    expect(currentDecoration.borderRadius, BorderRadius.circular(13));
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_step_marker_current')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_step_marker_photos')),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    final marker = tester.getCenter(
      find.byKey(const ValueKey('create_listing_step_marker_current')),
    );
    final vin = tester.getCenter(find.text(ru.createListingStepVin));
    expect((marker.dx - vin.dx).abs(), lessThan(18));
    final labelXs = [
      tester.getCenter(find.text(ru.createListingStepVin)).dx,
      tester.getCenter(find.text(ru.createListingStepData)).dx,
      tester.getCenter(find.text(ru.createListingStepDeal)).dx,
      tester.getCenter(find.text(ru.createListingStepPhotos)).dx,
      tester.getCenter(find.text(ru.createListingStepContacts)).dx,
      tester.getCenter(find.text(ru.createListingStepDone)).dx,
    ];
    for (var i = 1; i < labelXs.length; i++) {
      expect(labelXs[i - 1], lessThan(labelXs[i]));
    }

    await fillManualIdentity(tester);
    final shellTop = tester.getTopLeft(
      find.byKey(CreateListingFlowShell.imageKey),
    );
    await tapContinue(tester);
    expect(
      tester.getTopLeft(find.byKey(CreateListingFlowShell.imageKey)),
      shellTop,
    );
    expect(find.text(ru.createListingFlowTitle), findsOneWidget);
    final data = tester.getCenter(find.text(ru.createListingStepData));
    final moved = tester.getCenter(
      find.byKey(const ValueKey('create_listing_step_marker_current')),
    );
    expect((moved.dx - data.dx).abs(), lessThan(18));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_step_marker_current')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    final doneMarker = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_step_marker_identity')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((doneMarker.decoration! as BoxDecoration).boxShadow, isNotEmpty);
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('create_listing_vin_field')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
    await tester.pumpAndSettle();
    expect(find.text('Toyota'), findsWidgets);
    expect(
      find.byKey(const ValueKey('create_listing_vin_field')),
      findsOneWidget,
    );
    final backMarker = tester.getCenter(
      find.byKey(const ValueKey('create_listing_step_marker_current')),
    );
    final vinAgain = tester.getCenter(find.text(ru.createListingStepVin));
    expect((backMarker.dx - vinAgain.dx).abs(), lessThan(18));
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_step_marker_current')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dark hero uses leather, ivory chrome, and a warm CTA edge', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(theme: AppTheme.dark()));
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.byKey(CreateListingFlowShell.imageKey),
    );
    expect(
      (image.image as AssetImage).assetName,
      CreateListingFlowShell.darkBackgroundAsset,
    );
    expect(
      find.byKey(const ValueKey('create_listing_upper_haze')),
      findsNothing,
    );
    expect(
      tester.widget<Text>(find.text(ru.createListingFlowTitle)).style?.color,
      const Color(0xFFF3EBE3),
    );
    expect(
      tester
          .widget<Text>(find.text(ru.createListingHeaderSubtitle))
          .style
          ?.color,
      const Color(0xFFC4B5A4),
    );
    expect(
      tester
          .widget<Text>(find.text(ru.createListingVinAutofillHelper))
          .style
          ?.color,
      AppTheme.dark().colorScheme.onSurface.withValues(alpha: 0.68),
    );
    expect(
      tester
          .widgetList<IconTheme>(
            find.ancestor(
              of: find.byKey(const ValueKey('create_listing_back')),
              matching: find.byType(IconTheme),
            ),
          )
          .any((iconTheme) => iconTheme.data.color == const Color(0xFFF3EBE3)),
      isTrue,
    );
    expect(
      tester
          .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .any(
            (region) =>
                region.value.statusBarColor == Colors.transparent &&
                region.value.statusBarIconBrightness == Brightness.light &&
                region.value.statusBarBrightness == Brightness.dark,
          ),
      isTrue,
    );

    final current = tester.widget<Text>(find.text(ru.createListingStepVin));
    final idle = tester.widget<Text>(find.text(ru.createListingStepPhotos));
    final done = tester.widget<Text>(find.text(ru.createListingStepDone));
    expect(current.style?.color, const Color(0xFFF3EBE3));
    expect(current.style?.fontWeight, FontWeight.w600);
    expect(idle.style?.color, const Color(0xFFC4B5A4));
    expect(idle.style?.fontWeight, FontWeight.w500);
    expect(done.style?.color, const Color(0xFFD8CBBC));
    expect(done.style?.fontWeight, FontWeight.w700);
    expect(done.style?.fontSize, 12);
    expect(done.style?.color, isNot(idle.style?.color));
    expect(done.style?.color, isNot(current.style?.color));
    expect(done.style?.shadows?.single.color, const Color(0x66140F0C));
    expect(done.style?.shadows?.single.blurRadius, 2.5);

    final idleMarker = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_step_marker_photos')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final idleDecoration = idleMarker.decoration! as BoxDecoration;
    expect(idleDecoration.color, const Color(0xFF2A2622));
    expect(
      (idleDecoration.border! as Border).top.color,
      const Color(0xFF8F7D6A),
    );
    final shell = tester.getSize(find.byType(CreateListingFlowShell));
    expect(
      shell.width - tester.getRect(find.text(ru.createListingStepDone)).right,
      greaterThanOrEqualTo(34),
    );

    final side = tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('create_listing_step_continue')),
        )
        .style
        ?.side
        ?.resolve(const <WidgetState>{});
    expect(side, const BorderSide(color: Color(0x47C4B5A4)));

    await openCreateListingManualIdentity(tester);
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('create_listing_enter_manually')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_brand_field')),
      findsNothing,
    );
  });

  testWidgets('progress labels stay on a narrow phone at larger text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(ru.createListingStepContacts), findsOneWidget);
    expect(find.text(ru.createListingStepDone), findsOneWidget);
    expect(find.text(ru.createListingFlowTitle), findsOneWidget);
  });

  testWidgets('back returns to the previous step and keeps offer input', (
    tester,
  ) async {
    await pump(tester);
    await fillManualIdentity(tester);
    await tapContinue(tester);
    await tapContinue(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '1500',
    );
    await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('create_listing_characteristics_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('create_listing_step_continue')),
    );
    await tester.pumpAndSettle();
    expect(find.text('1500'), findsOneWidget);
  });

  testWidgets('state survives forward and back through the reordered steps', (
    tester,
  ) async {
    await pump(tester);
    await fillManualIdentity(tester);
    await tapContinue(tester);
    await tester.tap(
      find.byKey(const ValueKey('create_listing_edit_characteristics')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_engine_power_field')),
      '150',
    );
    await tapContinue(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_price_field')),
      '9000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_mileage_field')),
      '100000',
    );
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsOneWidget,
    );
    await tapContinue(tester);
    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.ensureVisible(city);
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тирасполь'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_phone_field')),
      '+37369000001',
    );
    await tapContinue(tester);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_description_field')),
      'Один владелец',
    );
    expect(find.byKey(ListingPreviewCard.cardKey), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('create_listing_step_back')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Toyota'), findsWidgets);
    expect(
      find.byKey(const ValueKey('create_listing_vin_field')),
      findsOneWidget,
    );

    await tapContinue(tester);
    expect(find.text('150'), findsOneWidget);
    await tapContinue(tester);
    expect(find.text('9000'), findsOneWidget);
    expect(find.text('100000'), findsOneWidget);
    await tapContinue(tester);
    expect(
      find.byKey(const ValueKey('create_listing_photos_section')),
      findsOneWidget,
    );
    await tapContinue(tester);
    expect(find.text('+37369000001'), findsOneWidget);
    await tapContinue(tester);
    expect(find.text('Один владелец'), findsOneWidget);
    expect(find.textContaining('Toyota'), findsWidgets);
    expect(find.textContaining('9'), findsWidgets);
  });
}
