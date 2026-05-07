import 'package:carzon/features/sellers/domain/entities/seller_public_profile.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:carzon/features/sellers/presentation/widgets/seller_trust_card.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();
  late SellerPublicProfile profile;

  setUp(() {
    profile = SellerPublicProfile(
      userId: 'internal-user-id',
      displayName: 'Jane Vendor',
      avatarUrl: null,
      memberSince: DateTime.utc(2026, 4, 1),
      sellerType: SellerType.private,
      activeListingsCount: 5,
      ratingAverage: null,
      ratingCount: 0,
      reviewCount: 0,
      verifiedPhone: false,
      verifiedEmail: false,
      verifiedDealer: false,
    );
  });

  testWidgets('shows display name and active listings count', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SellerTrustCard(profile: profile, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Jane Vendor'), findsOneWidget);
    expect(find.text(ru.sellerActiveListingsCount(5)), findsOneWidget);

    await tester.tap(find.byType(SellerTrustCard));
    expect(tapped, isTrue);
  });

  testWidgets('fallback name when display name missing', (tester) async {
    profile = SellerPublicProfile(
      userId: 'internal-user-id',
      displayName: null,
      avatarUrl: null,
      memberSince: DateTime.utc(2026, 4, 1),
      sellerType: SellerType.private,
      activeListingsCount: 1,
      ratingAverage: null,
      ratingCount: 0,
      reviewCount: 0,
      verifiedPhone: false,
      verifiedEmail: false,
      verifiedDealer: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SellerTrustCard(profile: profile, onTap: () {}),
        ),
      ),
    );

    expect(find.text(ru.sellerFallbackName), findsOneWidget);
  });
}
