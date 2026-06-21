import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/create_listing/presentation/pages/create_listing_page.dart';
import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_cubit.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_state.dart';
import 'package:carzon/features/edit_listing/presentation/pages/edit_listing_page.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockCreateCubit extends MockCubit<CreateListingState>
    implements CreateListingCubit {}

class _MockEditCubit extends MockCubit<EditListingState>
    implements EditListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

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
      ),
    );
  });

  late _MockCreateCubit createCubit;
  late _MockEditCubit editCubit;
  late _MockAuthCubit authCubit;
  final ru = ruStrings();

  setUp(() async {
    await sl.reset();
    createCubit = _MockCreateCubit();
    editCubit = _MockEditCubit();
    authCubit = _MockAuthCubit();

    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    when(() => createCubit.state).thenReturn(const CreateListingState.idle());
    whenListen(
      createCubit,
      const Stream<CreateListingState>.empty(),
      initialState: const CreateListingState.idle(),
    );

    when(
      () => createCubit.submit(
        listingInput: any(named: 'listingInput'),
        orderedPhotos: any(named: 'orderedPhotos'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => editCubit.load(any(), ownerId: any(named: 'ownerId')),
    ).thenAnswer((_) async {});

    sl.registerFactory<CreateListingCubit>(() => createCubit);
    sl.registerFactory<EditListingCubit>(() => editCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> scrollToField(WidgetTester tester, Key key) async {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('create listing shows transmission picker field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const CreateListingPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollToField(
      tester,
      const ValueKey('create_listing_transmission_field'),
    );
    expect(find.text(ru.listingTransmission), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('create_listing_transmission_field')),
    );
    await tester.pumpAndSettle();
    expect(find.text(ru.listingTransmissionManual), findsOneWidget);
  });

  testWidgets('edit listing preselects transmission and sends on save', (
    tester,
  ) async {
    final listing = Listing(
      id: 'l1',
      title: 'VW Golf',
      make: 'Volkswagen',
      model: 'Golf',
      year: 2016,
      priceEur: 8900,
      mileageKm: 120000,
      type: ListingType.sale,
      city: 'Chișinău',
      marketRegion: MarketRegion.moldova,
      transmissionType: ListingTransmissionType.cvt,
      createdAt: DateTime.utc(2026, 4, 1),
      status: ListingStatus.active,
      sellerId: 'u1',
      contactPhone: '+373 690 00001',
    );

    when(() => editCubit.state).thenReturn(
      EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: const [],
      ),
    );
    whenListen(
      editCubit,
      const Stream<EditListingState>.empty(),
      initialState: EditListingState.ready(
        listing,
        listingGalleryImages: const [],
        galleryLoadSucceeded: true,
        initialGallerySlots: const [],
      ),
    );
    when(
      () => editCubit.save(
        input: any(named: 'input'),
        galleryDraft: any(named: 'galleryDraft'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const EditListingPage(listingId: 'l1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollToField(
      tester,
      const ValueKey('edit_listing_transmission_field'),
    );
    expect(find.text(ru.listingTransmissionCvt), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('edit_listing_transmission_field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(ru.listingTransmissionRobotic).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('edit_listing_save_button')),
    );
    await tester.tap(find.byKey(const ValueKey('edit_listing_save_button')));
    await tester.pump();

    final captured =
        verify(
              () => editCubit.save(
                input: captureAny(named: 'input'),
                galleryDraft: any(named: 'galleryDraft'),
              ),
            ).captured.single
            as EditListingInput;
    expect(captured.transmissionType, ListingTransmissionType.robotic);
  });
}
