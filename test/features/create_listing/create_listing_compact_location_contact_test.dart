import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/seller_listing_defaults.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_compact_summary.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_contact_notice.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_preview_card.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/create_listing_test_stubs.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockCreateCubit extends MockCubit<CreateListingState>
    implements CreateListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockCreateCubit createCubit;
  late _MockAuthCubit authCubit;
  final ru = ruStrings();
  final ro = roStrings();

  const userA = AuthUser(id: 'user-a', email: 'a@example.com');
  const userB = AuthUser(id: 'user-b', email: 'b@example.com');

  setUp(() async {
    await sl.reset();
    createCubit = _MockCreateCubit();
    authCubit = _MockAuthCubit();
    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      const Stream<CreateListingState>.empty(),
      initialState: const CreateListingState.idle(),
    );
    when(
      () => authCubit.state,
    ).thenReturn(const AuthState.authenticated(userA));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(userA),
    );
    stubCreateListingVinResolve(createCubit);
    sl.registerFactory<CreateListingCubit>(() => createCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget wrap({Locale locale = const Locale('ru'), AuthCubit? auth}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthCubit>.value(
        value: auth ?? authCubit,
        child: const CreateListingPage(),
      ),
    );
  }

  CreateListingState defaultsState({
    String? phone = '+373 690 00001',
    String? telegram = 'seller_md',
    bool? whatsapp = true,
    MarketRegion? region = MarketRegion.transnistria,
    String? city = 'Тирасполь',
    int applyRevision = 1,
  }) {
    return CreateListingState(
      listingDefaults: CreateListingListingDefaults(
        status: CreateListingDefaultsStatus.ready,
        requestedUserId: userA.id,
        applyRevision: applyRevision,
        values: SellerListingDefaults(
          contactPhone: phone,
          telegramUsername: telegram,
          whatsappEnabled: whatsapp ?? false,
          marketRegion: region,
          city: city,
        ),
        prefill: SellerListingDefaultsPrefill(
          contactPhone: phone,
          telegramUsername: telegram,
          whatsappEnabled: whatsapp == true ? true : null,
          marketRegion: region,
          city: city,
        ),
      ),
    );
  }

  Future<StreamController<CreateListingState>> hydrate(
    WidgetTester tester, {
    CreateListingState? next,
    Locale locale = const Locale('ru'),
  }) async {
    final controller = StreamController<CreateListingState>();
    addTearDown(controller.close);
    whenListen(
      createCubit,
      controller.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap(locale: locale));
    await tester.pumpAndSettle();
    final state = next ?? defaultsState();
    when(() => createCubit.state).thenReturn(state);
    controller.add(state);
    await tester.pumpAndSettle();
    return controller;
  }

  Offstage locationEditors(WidgetTester tester) {
    return tester.widget<Offstage>(
      find.byKey(const ValueKey('create_listing_location_editors')),
    );
  }

  Offstage contactEditors(WidgetTester tester) {
    return tester.widget<Offstage>(
      find.byKey(const ValueKey('create_listing_contact_editors')),
    );
  }

  Finder locationSummary() =>
      find.byKey(const ValueKey('create_listing_location_summary'));
  Finder contactSummary() =>
      find.byKey(const ValueKey('create_listing_contact_summary'));

  Future<void> tapChange(WidgetTester tester, Key key) async {
    final change = find.byKey(key);
    await tester.scrollUntilVisible(
      change,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(change);
    await tester.pumpAndSettle();
  }

  test('RU/RO compact location/contact keys stay in parity', () {
    final ruArb =
        jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync())
            as Map<String, dynamic>;
    final roArb =
        jsonDecode(File('lib/l10n/app_ro.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(ruArb['createListingChange'], isA<String>());
    expect(roArb['createListingChange'], isA<String>());
    expect(ru.createListingChange, isNot('Change'));
    expect(ro.createListingChange, isNot('Change'));
    expect(ru.createListingChange, isNot(ro.createListingChange));
    expect(
      createListingContactChannelsSummary(
        l10n: ru,
        hasTelegram: true,
        whatsappEnabled: true,
      ),
      '${ru.contactTelegram} · ${ru.createListingWhatsAppTitle}',
    );
    expect(
      createListingContactChannelsSummary(
        l10n: ro,
        hasTelegram: false,
        whatsappEnabled: false,
      ),
      isNull,
    );
  });

  testWidgets('complete defaults collapse location and contact', (
    tester,
  ) async {
    await hydrate(tester);
    expect(locationSummary(), findsOneWidget);
    expect(
      find.descendant(of: locationSummary(), matching: find.text('Тирасполь')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: locationSummary(),
        matching: find.text(ru.regionTransnistria),
      ),
      findsOneWidget,
    );
    expect(contactSummary(), findsOneWidget);
    expect(
      find.descendant(
        of: contactSummary(),
        matching: find.text('+373 690 00001'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: contactSummary(),
        matching: find.text(
          '${ru.contactTelegram} · ${ru.createListingWhatsAppTitle}',
        ),
      ),
      findsOneWidget,
    );
    expect(locationEditors(tester).offstage, isTrue);
    expect(contactEditors(tester).offstage, isTrue);
    expect(find.byType(CreateListingContactNotice), findsNothing);
    expect(
      find.byKey(const ValueKey('create_listing_change_location')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_change_contact')),
      findsOneWidget,
    );
  });

  testWidgets('minimal phone-only defaults still collapse contact', (
    tester,
  ) async {
    await hydrate(tester, next: defaultsState(telegram: null, whatsapp: false));
    expect(locationSummary(), findsOneWidget);
    expect(contactSummary(), findsOneWidget);
    expect(
      find.descendant(
        of: contactSummary(),
        matching: find.text(ru.contactTelegram),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: contactSummary(),
        matching: find.text(ru.createListingWhatsAppTitle),
      ),
      findsNothing,
    );
    expect(contactEditors(tester).offstage, isTrue);
  });

  testWidgets('first-time seller keeps full editors and notice', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(locationSummary(), findsNothing);
    expect(contactSummary(), findsNothing);
    expect(locationEditors(tester).offstage, isFalse);
    expect(contactEditors(tester).offstage, isFalse);
    expect(find.byType(CreateListingContactNotice), findsOneWidget);
    expect(
      find.byKey(const ValueKey('create_listing_region_selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('create_listing_city_field')),
      findsOneWidget,
    );
    expect(find.text(ru.fieldPhone), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_city_field')),
        matching: find.text(ru.validationRequired),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_phone_field')),
        matching: find.text(ru.phoneRequired),
      ),
      findsNothing,
    );
  });

  testWidgets('VIN interaction does not redden missing-default editors', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109186',
    );
    await tester.pumpAndSettle();
    expect(locationEditors(tester).offstage, isFalse);
    expect(contactEditors(tester).offstage, isFalse);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_city_field')),
        matching: find.text(ru.validationRequired),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_phone_field')),
        matching: find.text(ru.phoneRequired),
      ),
      findsNothing,
    );
  });

  testWidgets('missing phone keeps contact expanded', (tester) async {
    await hydrate(tester, next: defaultsState(phone: null));
    expect(locationSummary(), findsOneWidget);
    expect(contactSummary(), findsNothing);
    expect(contactEditors(tester).offstage, isFalse);
    expect(find.byType(CreateListingContactNotice), findsOneWidget);
  });

  testWidgets('missing city keeps location expanded', (tester) async {
    await hydrate(tester, next: defaultsState(city: null));
    expect(contactSummary(), findsOneWidget);
    expect(locationSummary(), findsNothing);
    expect(locationEditors(tester).offstage, isFalse);
    expect(
      find.byKey(const ValueKey('create_listing_city_field')),
      findsOneWidget,
    );
  });

  testWidgets('late defaults after VIN keep missing phone editor neutral', (
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
      '1HGBH41JXMN109186',
    );
    await tester.pumpAndSettle();
    final lateDefaults = defaultsState(phone: null);
    when(() => createCubit.state).thenReturn(lateDefaults);
    controller.add(lateDefaults);
    await tester.pumpAndSettle();
    expect(contactEditors(tester).offstage, isFalse);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_phone_field')),
        matching: find.text(ru.phoneRequired),
      ),
      findsNothing,
    );
    expect(locationSummary(), findsOneWidget);
  });

  testWidgets('valid defaults stay compact after VIN interaction', (
    tester,
  ) async {
    await hydrate(tester);
    expect(locationSummary(), findsOneWidget);
    expect(contactSummary(), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_vin_field')),
      '1HGBH41JXMN109186',
    );
    await tester.pumpAndSettle();
    expect(locationSummary(), findsOneWidget);
    expect(contactSummary(), findsOneWidget);
    expect(find.text(ru.validationRequired), findsNothing);
    expect(find.text(ru.phoneRequired), findsNothing);
  });

  testWidgets('Change location reveals editors and updates preview', (
    tester,
  ) async {
    await hydrate(tester);
    await tapChange(tester, const ValueKey('create_listing_change_location'));
    expect(locationSummary(), findsNothing);
    expect(locationEditors(tester).offstage, isFalse);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_city_field')),
        matching: find.text('Тирасполь'),
      ),
      findsOneWidget,
    );
    final city = find.byKey(const ValueKey('create_listing_city_field'));
    await tester.tap(city);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бендеры'));
    await tester.pumpAndSettle();
    expect(locationSummary(), findsOneWidget);
    expect(
      find.descendant(of: locationSummary(), matching: find.text('Бендеры')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.metaKey)).data,
      contains('Бендеры'),
    );
    expect(
      tester.widget<Text>(find.byKey(ListingPreviewCard.metaKey)).data,
      isNot(contains('Тирасполь')),
    );
  });

  testWidgets('Change contact reveals fields, notice, and keeps values', (
    tester,
  ) async {
    await hydrate(tester);
    await tapChange(tester, const ValueKey('create_listing_change_contact'));
    expect(contactSummary(), findsNothing);
    expect(contactEditors(tester).offstage, isFalse);
    expect(find.byType(CreateListingContactNotice), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('create_listing_phone_field')),
          )
          .controller
          ?.text,
      '+373 690 00001',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('create_listing_telegram_field')),
          )
          .controller
          ?.text,
      'seller_md',
    );
  });

  testWidgets('late defaults do not overwrite in-progress seller edits', (
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
      find.byKey(const ValueKey('create_listing_phone_field')),
      '+373 777 11111',
    );
    await tester.pump();

    final late = CreateListingState(
      listingDefaults: CreateListingListingDefaults(
        status: CreateListingDefaultsStatus.ready,
        requestedUserId: userA.id,
        applyRevision: 1,
        values: const SellerListingDefaults(
          contactPhone: '+373 690 00001',
          telegramUsername: 'seller_md',
          whatsappEnabled: true,
          marketRegion: MarketRegion.moldova,
          city: 'Chișinău',
        ),
        prefill: const SellerListingDefaultsPrefill(
          telegramUsername: 'seller_md',
          whatsappEnabled: true,
        ),
        phoneEdited: true,
        regionEdited: true,
        cityEdited: true,
      ),
    );
    when(() => createCubit.state).thenReturn(late);
    controller.add(late);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('create_listing_phone_field')),
          )
          .controller
          ?.text,
      '+373 777 11111',
    );
    expect(contactSummary(), findsNothing);
    expect(contactEditors(tester).offstage, isFalse);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_city_field')),
        matching: find.text('Тирасполь'),
      ),
      findsOneWidget,
    );
    expect(find.text('Chișinău'), findsNothing);
    expect(locationSummary(), findsNothing);
  });

  testWidgets('account switch drops previous compact summaries', (
    tester,
  ) async {
    final authController = StreamController<AuthState>();
    final createController = StreamController<CreateListingState>();
    addTearDown(authController.close);
    addTearDown(createController.close);
    whenListen(
      authCubit,
      authController.stream,
      initialState: const AuthState.authenticated(userA),
    );
    whenListen(
      createCubit,
      createController.stream,
      initialState: const CreateListingState.idle(),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    final userAState = defaultsState();
    when(() => createCubit.state).thenReturn(userAState);
    createController.add(userAState);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: contactSummary(),
        matching: find.text('+373 690 00001'),
      ),
      findsOneWidget,
    );

    when(
      () => authCubit.state,
    ).thenReturn(const AuthState.authenticated(userB));
    authController.add(const AuthState.authenticated(userB));
    await tester.pumpAndSettle();
    expect(locationSummary(), findsNothing);
    expect(contactSummary(), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_city_field')),
        matching: find.text(ru.validationRequired),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('create_listing_phone_field')),
        matching: find.text(ru.phoneRequired),
      ),
      findsNothing,
    );

    final userBState = defaultsState(
      phone: '+373 555 00000',
      telegram: null,
      whatsapp: false,
      city: 'Бендеры',
    );
    when(() => createCubit.state).thenReturn(userBState);
    createController.add(userBState);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: contactSummary(),
        matching: find.text('+373 555 00000'),
      ),
      findsOneWidget,
    );
    expect(find.text('+373 690 00001'), findsNothing);
    expect(
      find.descendant(of: locationSummary(), matching: find.text('Бендеры')),
      findsOneWidget,
    );
  });

  testWidgets('cleared phone cannot stay in a completed contact summary', (
    tester,
  ) async {
    await hydrate(tester);
    await tapChange(tester, const ValueKey('create_listing_change_contact'));
    await tester.enterText(
      find.byKey(const ValueKey('create_listing_phone_field')),
      '',
    );
    await tester.pump();
    expect(contactSummary(), findsNothing);
    expect(contactEditors(tester).offstage, isFalse);
    expect(
      find.byKey(const ValueKey('create_listing_done_contact')),
      findsNothing,
    );
  });

  testWidgets('RO compact summary uses localized region and Change', (
    tester,
  ) async {
    await hydrate(
      tester,
      locale: const Locale('ro'),
      next: defaultsState(region: MarketRegion.moldova, city: 'Chișinău'),
    );
    expect(locationSummary(), findsOneWidget);
    expect(find.text(ro.createListingChange), findsWidgets);
    expect(
      find.descendant(
        of: locationSummary(),
        matching: find.text(formatMarketRegion(ro, MarketRegion.moldova)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: locationSummary(), matching: find.text('Chișinău')),
      findsOneWidget,
    );
    expect(find.text(ru.createListingChange), findsNothing);
    expect(find.text(ru.regionTransnistria), findsNothing);
  });
}
