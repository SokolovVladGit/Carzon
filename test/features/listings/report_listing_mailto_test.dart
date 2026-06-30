import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/report_listing_mailto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

Listing _listing({
  String id = 'abc-123',
  String title = 'VW Golf 7',
  String make = 'Volkswagen',
  String model = 'Golf',
  int year = 2016,
  String city = 'Tiraspol',
  MarketRegion region = MarketRegion.transnistria,
  String? contactPhone = '+373 000 000 001',
  String? telegramUsername = 'carzon_demo_01',
  bool whatsappEnabled = true,
  String? sellerId = 's1',
}) => Listing(
  id: id,
  title: title,
  make: make,
  model: model,
  year: year,
  priceEur: 8900,
  mileageKm: 120000,
  type: ListingType.sale,
  city: city,
  marketRegion: region,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: sellerId,
  contactPhone: contactPhone,
  telegramUsername: telegramUsername,
  whatsappEnabled: whatsappEnabled,
);

void main() {
  final l10n = ruStrings();

  group('buildReportListingMailto', () {
    test('builds a mailto URI with the configured recipient', () {
      final uri = buildReportListingMailto(
        l10n: l10n,
        listing: _listing(),
        recipientEmail: 'reports@carzon.example',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'reports@carzon.example');
    });

    test('trims leading/trailing whitespace in the recipient email', () {
      final uri = buildReportListingMailto(
        l10n: l10n,
        listing: _listing(),
        recipientEmail: '  reports@carzon.example  ',
      );

      expect(uri.path, 'reports@carzon.example');
    });

    test('rejects an empty recipient with ArgumentError', () {
      expect(
        () => buildReportListingMailto(
          l10n: l10n,
          listing: _listing(),
          recipientEmail: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('subject includes the localized Carzon prefix and listing id, '
        'percent-encoded', () {
      final uri = buildReportListingMailto(
        l10n: l10n,
        listing: _listing(id: 'abc-123'),
        recipientEmail: 'reports@carzon.example',
      );

      expect(uri.queryParameters['subject'], isNotNull);
      final decodedSubject = uri.queryParameters['subject']!;
      expect(decodedSubject, contains(l10n.reportSubjectPrefix));
      expect(decodedSubject, contains('abc-123'));
      // The raw URI string must encode spaces as %20 (RFC 6068),
      // not `+`, so the mail client renders a human-readable subject.
      final rawString = uri.toString();
      expect(rawString, contains('subject='));
      expect(rawString, contains('%20'));
      expect(rawString, isNot(contains('subject=Report+')));
    });

    test('body includes listing id, title, make/model/year, city, '
        'localized region and prompt copy', () {
      final uri = buildReportListingMailto(
        l10n: l10n,
        listing: _listing(
          id: 'abc-123',
          title: 'VW Golf 7',
          make: 'Volkswagen',
          model: 'Golf',
          year: 2016,
          city: 'Tiraspol',
          region: MarketRegion.transnistria,
        ),
        recipientEmail: 'reports@carzon.example',
      );

      final body = uri.queryParameters['body'];
      expect(body, isNotNull);
      expect(body, contains('abc-123'));
      expect(body, contains('VW Golf 7'));
      expect(body, contains('Volkswagen'));
      expect(body, contains('Golf'));
      expect(body, contains('2016'));
      expect(body, contains('Tiraspol'));
      expect(body, contains(l10n.regionTransnistria));
      expect(body, contains(l10n.reportBodyPrompt));
    });

    test('make/model/year line dedupes repeated leading make in model', () {
      final uri = buildReportListingMailto(
        l10n: l10n,
        listing: _listing(
          make: 'Toyota',
          model: 'Toyota RAV4 Hybrid',
          year: 2018,
        ),
        recipientEmail: 'reports@carzon.example',
      );

      final body = uri.queryParameters['body']!;
      expect(body, contains('Toyota RAV4 Hybrid 2018'));
      expect(body, isNot(contains('Toyota Toyota RAV4 Hybrid')));
    });

    test(
      'does NOT include seller private data (sellerId, phone, telegram)',
      () {
        final uri = buildReportListingMailto(
          l10n: l10n,
          listing: _listing(
            sellerId: 'secret-seller-uuid',
            contactPhone: '+373 000 000 001',
            telegramUsername: 'carzon_demo_01',
          ),
          recipientEmail: 'reports@carzon.example',
        );

        final raw = uri.toString();
        final body = uri.queryParameters['body']!;
        final subject = uri.queryParameters['subject']!;

        for (final forbidden in <String>[
          'secret-seller-uuid',
          '+373 000 000 001',
          '000 000 001',
          'carzon_demo_01',
        ]) {
          expect(
            body.toLowerCase().contains(forbidden.toLowerCase()) ||
                subject.toLowerCase().contains(forbidden.toLowerCase()) ||
                raw.toLowerCase().contains(
                  Uri.encodeComponent(forbidden).toLowerCase(),
                ),
            isFalse,
            reason:
                'report mailto must not leak seller-private value: $forbidden',
          );
        }
      },
    );

    test('handles special characters in the title safely', () {
      final uri = buildReportListingMailto(
        l10n: l10n,
        listing: _listing(title: 'Škoda & "Octavia" 100%'),
        recipientEmail: 'reports@carzon.example',
      );

      final decodedBody = uri.queryParameters['body']!;
      expect(decodedBody, contains('Škoda & "Octavia" 100%'));
      // The raw URI string must percent-encode the special characters
      // so the mailto stays RFC-compliant.
      final raw = uri.toString();
      expect(raw, contains('%26'));
      expect(raw, contains('%22'));
    });
  });
}
