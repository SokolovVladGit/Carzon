import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/features/filter_alerts/data/models/saved_search_model.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/listing_discovery_criteria_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedSearchModel.fromRpcRow', () {
    const id = '550e8400-e29b-41d4-a716-446655440000';

    test('parses full RPC row', () {
      final json = listingDiscoveryCriteriaToJson(
        const ListingDiscoveryCriteria(make: 'Toyota'),
      );

      final m = SavedSearchModel.fromRpcRow({
        'id': id,
        'name': 'Toyota search',
        'criteria': json,
        'alerts_enabled': true,
        'created_at': '2026-05-09T10:00:00.000Z',
        'updated_at': '2026-05-09T11:00:00.000Z',
        'last_notified_at': '2026-05-09T12:00:00.000Z',
      });

      expect(m.id, id);
      expect(m.name, 'Toyota search');
      expect(m.criteria.make?.trim(), 'Toyota');
      expect(m.alertsEnabled, isTrue);
      expect(m.createdAt.toUtc(), DateTime.utc(2026, 5, 9, 10));
      expect(m.updatedAt.toUtc(), DateTime.utc(2026, 5, 9, 11));
      expect(m.lastNotifiedAt?.toUtc(), DateTime.utc(2026, 5, 9, 12));
    });

    test('allows null last_notified_at', () {
      final json = listingDiscoveryCriteriaToJson(
        const ListingDiscoveryCriteria(make: 'Audi'),
      );

      final m = SavedSearchModel.fromRpcRow({
        'id': id,
        'name': 'Audi',
        'criteria': json,
        'alerts_enabled': false,
        'created_at': '2026-05-09T10:00:00.000Z',
        'updated_at': '2026-05-09T11:00:00.000Z',
        'last_notified_at': null,
      });

      expect(m.lastNotifiedAt, isNull);
      expect(m.alertsEnabled, isFalse);
    });

    test('invalid id throws', () {
      final json = listingDiscoveryCriteriaToJson(
        const ListingDiscoveryCriteria(make: 'Toyota'),
      );

      expect(
        () => SavedSearchModel.fromRpcRow({
          'id': '   ',
          'name': 'Toyota',
          'criteria': json,
          'alerts_enabled': false,
          'created_at': '2026-05-09T12:00:00.000Z',
          'updated_at': '2026-05-09T13:00:00.000Z',
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('invalid name throws', () {
      final json = listingDiscoveryCriteriaToJson(
        const ListingDiscoveryCriteria(make: 'Toyota'),
      );

      expect(
        () => SavedSearchModel.fromRpcRow({
          'id': id,
          'name': '',
          'criteria': json,
          'alerts_enabled': false,
          'created_at': '2026-05-09T12:00:00.000Z',
          'updated_at': '2026-05-09T13:00:00.000Z',
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('alerts_enabled must be bool', () {
      final json = listingDiscoveryCriteriaToJson(
        const ListingDiscoveryCriteria(make: 'Toyota'),
      );

      expect(
        () => SavedSearchModel.fromRpcRow({
          'id': id,
          'name': 'Toyota',
          'criteria': json,
          'alerts_enabled': 'yes',
          'created_at': '2026-05-09T12:00:00.000Z',
          'updated_at': '2026-05-09T13:00:00.000Z',
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('criteria must be map', () {
      expect(
        () => SavedSearchModel.fromRpcRow({
          'id': id,
          'name': 'Toyota',
          'criteria': 'not-json',
          'alerts_enabled': false,
          'created_at': '2026-05-09T12:00:00.000Z',
          'updated_at': '2026-05-09T13:00:00.000Z',
        }),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
