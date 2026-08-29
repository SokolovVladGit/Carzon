import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/pages/listing_details_page.dart';
import 'package:carzon/features/listings/presentation/utils/listing_report_submitter.dart';
import 'package:carzon/features/listings/domain/entities/listing_report_reason.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/sellers/domain/usecases/get_seller_public_profile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/shared/ui/carzon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/listing_details_self_fetch_stubs.dart';
import '../../helpers/seller_public_profile_test_mocks.dart';
import '../../helpers/compare_cubit_test_helpers.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Listing _seed() => Listing(
  id: 'listing-007',
  title: 'Skoda Octavia 1.8 TSI',
  make: 'Skoda',
  model: 'Octavia',
  year: 2017,
  priceEur: 10800,
  mileageKm: 132000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: 's1',
  contactPhone: '+373 000 000 001',
  telegramUsername: 'carzon_demo_01',
  whatsappEnabled: true,
);

void main() {
  final l10n = ruStrings();

  late _MockDetailsCubit detailsCubit;
  late _MockAuthCubit authCubit;
  late _MockFavoritesCubit favoritesCubit;
  late CompareCubit compareCubit;
  late MockGetSellerPublicProfile sellerProfileUseCase;

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

    registerListingDetailsSelfFetchStubs(sl);
    sl.registerFactory<ListingDetailsCubit>(() => detailsCubit);
    sl.registerFactory<GetSellerPublicProfile>(() => sellerProfileUseCase);

    final seeded = _seed();
    when(
      () => detailsCubit.state,
    ).thenReturn(ListingDetailsState.success(seeded));
    whenListen(
      detailsCubit,
      const Stream<ListingDetailsState>.empty(),
      initialState: ListingDetailsState.success(seeded),
    );
  });

  tearDown(() async {
    await compareCubit.close();
    await sl.reset();
  });

  Widget wrap({ListingReportSubmitter? submitter}) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<FavoritesCubit>.value(value: favoritesCubit),
        BlocProvider<CompareCubit>.value(value: compareCubit),
      ],
      child: ListingDetailsPage(
        id: 'listing-007',
        reportSubmitter:
            submitter ??
            ({required listingId, required reason, note}) async =>
                const Success(null),
      ),
    ),
  );

  testWidgets('Report listing is always visible when email config is absent', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    final reportLabel = find.text(l10n.reportListing);
    await tester.ensureVisible(reportLabel);
    await tester.pump();

    expect(reportLabel, findsOneWidget);
    expect(find.byIcon(CarzonIcons.report), findsOneWidget);
    expect(find.text(l10n.reportListingDescription), findsOneWidget);
  });

  testWidgets('guest action explains that sign-in is required', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    final reportLabel = find.text(l10n.reportListing);
    await tester.ensureVisible(reportLabel);
    await tester.tap(reportLabel);
    await tester.pumpAndSettle();

    expect(find.text(l10n.reportListingSignInTitle), findsOneWidget);
    expect(find.text(l10n.reportListingSignInBody), findsOneWidget);
  });

  testWidgets('authenticated user submits one structured native report', (
    tester,
  ) async {
    const user = AuthUser(id: 'buyer-1', email: 'buyer@carzon.test');
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));

    var calls = 0;
    String? capturedListingId;
    ListingReportReason? capturedReason;
    String? capturedNote;
    Future<Result<void>> submit({
      required String listingId,
      required ListingReportReason reason,
      String? note,
    }) async {
      calls += 1;
      capturedListingId = listingId;
      capturedReason = reason;
      capturedNote = note;
      return const Success(null);
    }

    await tester.pumpWidget(wrap(submitter: submit));
    await tester.pump();
    final reportLabel = find.text(l10n.reportListing);
    await tester.ensureVisible(reportLabel);
    await tester.tap(reportLabel);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.reportListingReasonMisleading));
    await tester.enterText(find.byType(TextField).last, 'Цена неверна');
    final submitButton = find.byKey(const ValueKey('listing_report_submit'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(capturedListingId, 'listing-007');
    expect(capturedReason, ListingReportReason.misleading);
    expect(capturedNote, 'Цена неверна');
    expect(find.text(l10n.reportListingSuccess), findsOneWidget);
  });

  testWidgets('server moderation rejection is localized', (tester) async {
    const user = AuthUser(id: 'buyer-1', email: 'buyer@carzon.test');
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));

    await tester.pumpWidget(
      wrap(
        submitter: ({required listingId, required reason, note}) async =>
            const FailureResult(ServerFailure('carzon_content_rejected')),
      ),
    );
    await tester.pump();
    final reportLabel = find.text(l10n.reportListing);
    await tester.ensureVisible(reportLabel);
    await tester.tap(reportLabel);
    await tester.pumpAndSettle();
    final submitButton = find.byKey(const ValueKey('listing_report_submit'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text(l10n.contentModerationRejected), findsOneWidget);
  });
}
