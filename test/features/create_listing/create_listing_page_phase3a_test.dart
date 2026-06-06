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
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_media_section.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/widgets/public_contact_notice.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

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
  final l10n = ruStrings();

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
      child: CreateListingPage(imagePicker: imagePicker),
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
      find.widgetWithText(TextFormField, l10n.fieldModel),
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
}
