import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_contact.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/ui/carzon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/seller_public_profile_test_mocks.dart';
import '../../helpers/compare_cubit_test_helpers.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Listing _seed({
  String? contactPhone,
  String? telegramUsername,
  bool whatsappEnabled = false,
}) => Listing(
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
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: 's1',
  contactPhone: contactPhone,
  telegramUsername: telegramUsername,
  whatsappEnabled: whatsappEnabled,
);

void main() {
  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late CompareCubit compareCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;
  final l10n = ruStrings();

  setUp(() async {
    await sl.reset();
    detailsCubit = _MockDetailsCubit();
    authCubit = _MockAuthCubit();
    favoritesCubit = _MockFavoritesCubit();
    compareCubit = newInMemoryCompareCubit();
    sellerProfileUseCase = MockGetSellerPublicProfile();
    stubSellerPublicProfileHidden(sellerProfileUseCase);

    when(() => detailsCubit.load(any())).thenAnswer((_) async {});

    when(() => authCubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    when(() => favoritesCubit.state).thenReturn(const FavoritesState());
    whenListen(
      favoritesCubit,
      const Stream<FavoritesState>.empty(),
      initialState: const FavoritesState(),
    );

    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
    sl.registerFactory<GetSellerPublicProfile>(() => sellerProfileUseCase);
  });

  tearDown(() async {
    await compareCubit.close();
    await sl.reset();
  });

  void stubListing(Listing listing) {
    when(
      () => detailsCubit.state,
    ).thenReturn(ListingDetailsState.success(listing));
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: ListingDetailsState.success(listing),
    );
  }

  void stubContact(Result<ListingContact> result) {
    when(
      () => detailsCubit.revealPublicContact(any()),
    ).thenAnswer((_) async => result);
  }

  Widget wrap() => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
        BlocProvider<CompareCubit>.value(value: compareCubit),
      ],
      child: const ListingDetailsPage(id: 'l1'),
    ),
  );

  const phone = '+373 690 00001';

  testWidgets(
    'before reveal: renders the "Show phone" action, does not render the '
    'phone, and shows the public-contact notice',
    (tester) async {
      stubListing(_seed());
      stubContact(const Success(ListingContact(phone: phone)));

      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text(l10n.contactShowPhone), findsOneWidget);
      expect(find.text(phone), findsNothing);
      expect(find.textContaining('373'), findsNothing);
      expect(find.text(l10n.contactPublicNotice), findsOneWidget);
    },
  );

  testWidgets(
    'after tapping the reveal action: renders the formatted phone and '
    'hides the reveal button',
    (tester) async {
      stubListing(_seed());
      stubContact(const Success(ListingContact(phone: phone)));

      await tester.pumpWidget(wrap());
      await tester.pump();

      final revealFinder = find.text(l10n.contactShowPhone);
      await tester.ensureVisible(revealFinder);
      await tester.pumpAndSettle();
      await tester.tap(revealFinder);
      await tester.pumpAndSettle();

      expect(find.text(l10n.contactShowPhone), findsNothing);
      expect(find.text(phone), findsOneWidget);
      expect(find.byIcon(CarzonIcons.phoneCall), findsOneWidget);
      verify(() => detailsCubit.revealPublicContact('l1')).called(1);
    },
  );

  testWidgets(
    'Telegram and WhatsApp actions are added only after contact reveal',
    (tester) async {
      stubListing(_seed());
      stubContact(
        const Success(
          ListingContact(
            phone: phone,
            telegramUsername: 'ana_seller',
            whatsappEnabled: true,
          ),
        ),
      );

      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.byTooltip(l10n.contactTelegram), findsNothing);
      expect(find.textContaining('@ana_seller'), findsNothing);
      expect(find.byTooltip(l10n.contactWhatsapp), findsNothing);
      expect(find.text(phone), findsNothing);
      expect(find.textContaining('373'), findsNothing);

      final revealFinder = find.text(l10n.contactShowPhone);
      await tester.ensureVisible(revealFinder);
      await tester.pumpAndSettle();
      await tester.tap(revealFinder);
      await tester.pumpAndSettle();

      expect(find.byTooltip(l10n.contactTelegram), findsOneWidget);
      expect(find.byTooltip(l10n.contactWhatsapp), findsOneWidget);
      expect(find.text(phone), findsOneWidget);
    },
  );

  testWidgets(
    'when revealed contact has no phone, a recoverable notice appears',
    (tester) async {
      stubListing(_seed());
      stubContact(const Success(ListingContact()));

      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text(l10n.contactShowPhone), findsOneWidget);
      await tester.tap(find.text(l10n.contactShowPhone));
      await tester.pumpAndSettle();
      expect(find.text(l10n.phoneNotProvided), findsOneWidget);
      expect(find.byTooltip(l10n.contactTelegram), findsNothing);
      expect(find.textContaining('@ana_seller'), findsNothing);
    },
  );

  testWidgets('hides Telegram row when telegram username is absent', (
    tester,
  ) async {
    stubListing(_seed());
    stubContact(
      const Success(ListingContact(phone: phone, whatsappEnabled: true)),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.tap(find.text(l10n.contactShowPhone));
    await tester.pumpAndSettle();

    expect(find.byTooltip(l10n.contactTelegram), findsNothing);
    expect(find.byTooltip(l10n.contactWhatsapp), findsOneWidget);
  });

  testWidgets('hides WhatsApp row when whatsapp is disabled', (tester) async {
    stubListing(_seed());
    stubContact(
      const Success(
        ListingContact(phone: phone, telegramUsername: 'ana_seller'),
      ),
    );

    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.tap(find.text(l10n.contactShowPhone));
    await tester.pumpAndSettle();

    expect(find.byTooltip(l10n.contactTelegram), findsOneWidget);
    expect(find.byTooltip(l10n.contactWhatsapp), findsNothing);
  });

  testWidgets('contact fetch failure shows recoverable snackbar', (
    tester,
  ) async {
    stubListing(_seed());
    stubContact(const FailureResult(ServerFailure('down')));

    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.tap(find.text(l10n.contactShowPhone));
    await tester.pumpAndSettle();

    expect(find.text(l10n.contactActionFailed), findsOneWidget);
    expect(find.text(phone), findsNothing);
  });
}
