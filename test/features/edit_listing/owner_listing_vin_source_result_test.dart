import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_source_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OwnerListingVinSourceResult', () {
    test('tryParse maps RPC row and tolerates unknown enum-ish strings', () {
      final r = OwnerListingVinSourceResult.tryParse({
        'source_id': 'nhtsa_vpic',
        'region': 'international',
        'access_mode': 'unknown_mode',
        'status': 'weird_status',
        'visibility': 'owner',
        'confidence': 'lowish',
        'normalized_summary': {
          'make': ' TOYOTA ',
          'year': 2020,
        },
        'limitation_codes': ['basic_decode_only', 'other'],
        'requires_user_consent': false,
        'consent_required_reason': null,
        'source_label': 'NHTSA vPIC',
        'provider_version': '1',
        'fetched_at': '2026-01-01T00:00:00.000Z',
        'ttl_until': null,
        'updated_at': '2026-01-02T00:00:00.000Z',
      });
      expect(r, isNotNull);
      expect(r!.sourceId, 'nhtsa_vpic');
      expect(r.accessModeRaw, 'unknown_mode');
      expect(r.statusRaw, 'weird_status');
      expect(r.normalizedSummary?['make'], ' TOYOTA ');
      expect(r.limitationCodes, ['basic_decode_only', 'other']);
      expect(r.isNhtsaBasicDecodeEligible, isFalse);
    });

    test('isNhtsaBasicDecodeEligible is true for succeeded + summary keys', () {
      final r = OwnerListingVinSourceResult.tryParse({
        'source_id': 'nhtsa_vpic',
        'status': 'succeeded',
        'normalized_summary': {'model': 'Camry'},
      });
      expect(r, isNotNull);
      expect(r!.isNhtsaBasicDecodeEligible, isTrue);
    });

    test('isNhtsaBasicDecodeEligible allows partial status', () {
      final r = OwnerListingVinSourceResult.tryParse({
        'source_id': 'nhtsa_vpic',
        'status': 'partial',
        'normalized_summary': {'fuel_type': 'Gasoline'},
      });
      expect(r, isNotNull);
      expect(r!.isNhtsaBasicDecodeEligible, isTrue);
    });

    test('tryParse returns null on missing source_id and does not throw', () {
      expect(OwnerListingVinSourceResult.tryParse({}), isNull);
    });
  });
}
