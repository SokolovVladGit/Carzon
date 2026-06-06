import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_cubit.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_state.dart';
import 'package:carzon/features/edit_listing/presentation/pages/edit_listing_page.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/widgets/public_contact_notice.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockEditCubit extends MockCubit<EditListingState>
    implements EditListingCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

Listing _seed() => Listing(
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
  contactPhone: '+373 690 00001',
);

void main() {
  late _MockEditCubit cubit;
  late _MockAuthCubit authCubit;

  setUp(() async {
    await sl.reset();
    cubit = _MockEditCubit();
    authCubit = _MockAuthCubit();
    when(
      () => cubit.load(any(), ownerId: any(named: 'ownerId')),
    ).thenAnswer((_) async {});
    when(() => cubit.state).thenReturn(EditListingState.ready(_seed()));
    whenListen(
      cubit,
      const Stream<EditListingState>.empty(),
      initialState: EditListingState.ready(_seed()),
    );
    const user = AuthUser(id: 's1', email: 'seller@example.com');
    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );
    sl.registerFactory<EditListingCubit>(() => cubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  final l10n = ruStrings();

  testWidgets(
    'renders the PublicContactNotice near the contact fields and keeps it '
    'above the phone input',
    (tester) async {
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
      await tester.pump();

      expect(find.byType(PublicContactNotice), findsOneWidget);
      expect(find.text(l10n.publicContactNotice), findsOneWidget);

      final noticeCenter = tester.getCenter(find.byType(PublicContactNotice));
      final phoneCenter = tester.getCenter(
        find.widgetWithText(TextFormField, l10n.fieldPhone),
      );
      expect(noticeCenter.dy, lessThan(phoneCenter.dy));
    },
  );
}
