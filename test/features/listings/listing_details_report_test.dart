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
import 'package:carzon/features/listings/presentation/utils/listing_details_uri_launcher.dart';
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

  Widget wrap({String? reportEmail, ListingDetailsUriLauncher? launcher}) =>
      MaterialApp(
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
            reportEmail: reportEmail,
            uriLauncher: launcher,
          ),
        ),
      );

  testWidgets('report email unset: Report listing surface is hidden', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text(l10n.reportListing), findsNothing);
    expect(find.byIcon(CarzonIcons.report), findsNothing);
    expect(find.text(l10n.reportListingDescription), findsNothing);
  });

  testWidgets('report email empty string: Report listing surface is hidden', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(reportEmail: ''));
    await tester.pump();

    expect(find.text(l10n.reportListing), findsNothing);
  });

  testWidgets('report email configured: renders the Report listing action with '
      'supporting copy', (tester) async {
    await tester.pumpWidget(wrap(reportEmail: 'reports@carzon.example'));
    await tester.pump();

    final reportLabel = find.text(l10n.reportListing);
    await tester.ensureVisible(reportLabel);
    await tester.pump();

    expect(reportLabel, findsOneWidget);
    expect(find.byIcon(CarzonIcons.report), findsOneWidget);
    expect(find.text(l10n.reportListingDescription), findsOneWidget);
  });

  testWidgets(
    'tapping Report listing launches the mailto URI with correct content',
    (tester) async {
      Uri? launched;
      Future<bool> launcher(Uri uri) async {
        launched = uri;
        return true;
      }

      await tester.pumpWidget(
        wrap(reportEmail: 'reports@carzon.example', launcher: launcher),
      );
      await tester.pump();

      final reportLabel = find.text(l10n.reportListing);
      await tester.ensureVisible(reportLabel);
      await tester.pumpAndSettle();
      await tester.tap(reportLabel);
      await tester.pumpAndSettle();

      expect(launched, isNotNull);
      expect(launched!.scheme, 'mailto');
      expect(launched!.path, 'reports@carzon.example');
      final subject = launched!.queryParameters['subject']!;
      expect(subject, contains(l10n.reportSubjectPrefix));
      expect(subject, contains('listing-007'));
      final body = launched!.queryParameters['body']!;
      expect(body, contains('listing-007'));
      expect(body, contains('Skoda Octavia 1.8 TSI'));
      expect(body, contains('Tiraspol'));
      expect(body, contains(l10n.regionTransnistria));
    },
  );

  testWidgets(
    'when the launcher returns false, a friendly SnackBar is shown and '
    'the app does not crash',
    (tester) async {
      Future<bool> launcher(Uri _) async => false;

      await tester.pumpWidget(
        wrap(reportEmail: 'reports@carzon.example', launcher: launcher),
      );
      await tester.pump();

      final reportLabel = find.text(l10n.reportListing);
      await tester.ensureVisible(reportLabel);
      await tester.pumpAndSettle();
      await tester.tap(reportLabel);
      await tester.pump();

      expect(find.text(l10n.reportListingMailFailed), findsOneWidget);
    },
  );

  testWidgets(
    'when the launcher throws, a friendly SnackBar is shown instead of '
    'propagating the exception',
    (tester) async {
      Future<bool> launcher(Uri _) async => throw StateError('no mail app');

      await tester.pumpWidget(
        wrap(reportEmail: 'reports@carzon.example', launcher: launcher),
      );
      await tester.pump();

      final reportLabel = find.text(l10n.reportListing);
      await tester.ensureVisible(reportLabel);
      await tester.pumpAndSettle();
      await tester.tap(reportLabel);
      await tester.pump();

      expect(find.text(l10n.reportListingMailFailed), findsOneWidget);
    },
  );
}
