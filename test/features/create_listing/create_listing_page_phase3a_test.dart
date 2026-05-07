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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockCreateCubit extends MockCubit<CreateListingState>
    implements CreateListingCubit {}

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

  Widget wrap() => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: const CreateListingPage(),
    ),
  );

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
}
