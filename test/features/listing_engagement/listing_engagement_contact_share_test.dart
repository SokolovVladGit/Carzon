import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/listing_engagement/domain/entities/listing_engagement_event_type.dart';
import 'package:carzon/features/listing_engagement/domain/usecases/record_listing_engagement.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_contact.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_details_contact_bar.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_share_button.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockDetailsCubit extends MockCubit<ListingDetailsState>
    implements ListingDetailsCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockRecorder extends Mock implements RecordListingEngagement {}

Listing _listing() => Listing(
  id: 'listing-1',
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
);

void main() {
  final l10n = ruStrings();
  late _MockDetailsCubit details;
  late _MockAuthCubit auth;
  late _MockRecorder recorder;
  late List<Uri> launched;
  late List<ListingEngagementEventType> recorded;

  setUpAll(() {
    registerFallbackValue(ListingEngagementEventType.phone);
  });

  setUp(() {
    details = _MockDetailsCubit();
    auth = _MockAuthCubit();
    recorder = _MockRecorder();
    launched = <Uri>[];
    recorded = <ListingEngagementEventType>[];

    when(() => auth.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
    when(
      () => details.state,
    ).thenReturn(ListingDetailsState.success(_listing()));
    whenListen(
      details,
      const Stream<ListingDetailsState>.empty(),
      initialState: ListingDetailsState.success(_listing()),
    );
    when(
      () => recorder.recordFireAndForget(
        listingId: any(named: 'listingId'),
        eventType: any(named: 'eventType'),
      ),
    ).thenAnswer((invocation) {
      recorded.add(
        invocation.namedArguments[#eventType] as ListingEngagementEventType,
      );
    });
  });

  Widget wrapBar({ListingContact? contact}) {
    when(
      () => details.revealPublicContact(any()),
    ).thenAnswer((_) async => Success(contact ?? const ListingContact()));
    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<ListingDetailsCubit>.value(value: details),
        ],
        child: Scaffold(
          body: ListingDetailsContactBar(
            listing: _listing(),
            recordEngagement: recorder,
            uriLauncher: (uri) async {
              launched.add(uri);
              return true;
            },
          ),
        ),
      ),
    );
  }

  testWidgets('phone reveal does not record; call records once then launches', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapBar(contact: const ListingContact(phone: '+373 690 00001')),
    );
    await tester.pump();
    await tester.tap(find.text(l10n.contactShowPhone));
    await tester.pumpAndSettle();
    expect(recorded, isEmpty);
    expect(launched, isEmpty);

    await tester.tap(find.text('+373 690 00001'));
    await tester.pump();

    expect(recorded, [ListingEngagementEventType.phone]);
    expect(launched, hasLength(1));
    expect(launched.single.scheme, 'tel');
  });

  testWidgets('WhatsApp records one telemetry request then launches', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapBar(
        contact: const ListingContact(
          phone: '+373 690 00001',
          whatsappEnabled: true,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(l10n.contactShowPhone));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.contactWhatsapp));
    await tester.pump();

    expect(recorded, [ListingEngagementEventType.whatsapp]);
    expect(launched.single.toString(), contains('wa.me'));
  });

  testWidgets('Telegram records one telemetry request then launches', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapBar(
        contact: const ListingContact(
          phone: '+373 690 00001',
          telegramUsername: 'ana_seller',
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(l10n.contactShowPhone));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.contactTelegram));
    await tester.pump();

    expect(recorded, [ListingEngagementEventType.telegram]);
    expect(launched.single.toString(), contains('t.me/ana_seller'));
  });

  testWidgets('invalid phone after reveal does not record a false action', (
    tester,
  ) async {
    await tester.pumpWidget(wrapBar(contact: const ListingContact()));
    await tester.pump();
    await tester.tap(find.text(l10n.contactShowPhone));
    await tester.pumpAndSettle();
    expect(find.text(l10n.phoneNotProvided), findsOneWidget);
    expect(recorded, isEmpty);
    expect(launched, isEmpty);
  });

  testWidgets('telemetry failure does not block phone launch', (tester) async {
    when(
      () => recorder.recordFireAndForget(
        listingId: any(named: 'listingId'),
        eventType: any(named: 'eventType'),
      ),
    ).thenThrow(StateError('rpc down'));

    await tester.pumpWidget(
      wrapBar(contact: const ListingContact(phone: '+373 690 00001')),
    );
    await tester.pump();
    await tester.tap(find.text(l10n.contactShowPhone));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+373 690 00001'));
    await tester.pump();

    expect(launched, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('share opens the launcher and records share once', (
    tester,
  ) async {
    var shared = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListingShareButton(
            listing: _listing(),
            recordEngagement: recorder,
            shareUrlBuilder: (_) => 'https://carzon.md/listings/listing-1',
            shareLauncher: (_) async {
              shared += 1;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.listingShareAction));
    await tester.pump();

    expect(shared, 1);
    expect(recorded, [ListingEngagementEventType.share]);
  });

  testWidgets('share still opens when telemetry throws', (tester) async {
    when(
      () => recorder.recordFireAndForget(
        listingId: any(named: 'listingId'),
        eventType: any(named: 'eventType'),
      ),
    ).thenThrow(StateError('rpc down'));
    var shared = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListingShareButton(
            listing: _listing(),
            recordEngagement: recorder,
            shareUrlBuilder: (_) => 'https://carzon.md/listings/listing-1',
            shareLauncher: (_) async {
              shared += 1;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip(l10n.listingShareAction));
    await tester.pump();
    expect(shared, 1);
    expect(tester.takeException(), isNull);
  });
}
