import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/features/filter_alerts/data/models/filter_alert_settings_model.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/listing_discovery_criteria_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterAlertSettingsModel.fromSupabase', () {
    const uid = '550e8400-e29b-41d4-a716-446655440000';

    test('parses nullable criteria', () {
      final m = FilterAlertSettingsModel.fromSupabase({
        'user_id': uid,
        'criteria': null,
        'notifications_enabled': false,
        'created_at': '2026-05-09T10:00:00.000Z',
        'updated_at': '2026-05-09T11:00:00.000Z',
      });

      expect(m.userId, uid);
      expect(m.criteria, isNull);
      expect(m.notificationsEnabled, isFalse);
      expect(m.createdAt.toUtc(), DateTime.utc(2026, 5, 9, 10));
      expect(m.updatedAt.toUtc(), DateTime.utc(2026, 5, 9, 11));
    });

    test('maps criteria JSON to entity', () {
      final json = listingDiscoveryCriteriaToJson(
        const ListingDiscoveryCriteria(make: 'Toyota'),
      );

      final m = FilterAlertSettingsModel.fromSupabase({
        'user_id': uid,
        'criteria': json,
        'notifications_enabled': false,
        'created_at': '2026-05-09T12:00:00.000Z',
        'updated_at': '2026-05-09T13:00:00.000Z',
      });

      expect(m.criteria?.make?.trim(), 'Toyota');
    });

    test('invalid user id throws', () {
      expect(
        () => FilterAlertSettingsModel.fromSupabase({
          'user_id': '   ',
          'criteria': null,
          'notifications_enabled': false,
          'created_at': '2026-05-09T12:00:00.000Z',
          'updated_at': '2026-05-09T13:00:00.000Z',
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('notifications_enabled must be bool', () {
      expect(
        () => FilterAlertSettingsModel.fromSupabase({
          'user_id': uid,
          'criteria': null,
          'notifications_enabled': 'yes',
          'created_at': '2026-05-09T12:00:00.000Z',
          'updated_at': '2026-05-09T13:00:00.000Z',
        }),
        throwsA(isA<ServerException>()),
      );
    });

    test('criteria must be map when present', () {
      expect(
        () => FilterAlertSettingsModel.fromSupabase({
          'user_id': uid,
          'criteria': 'not-json',
          'notifications_enabled': false,
          'created_at': '2026-05-09T12:00:00.000Z',
          'updated_at': '2026-05-09T13:00:00.000Z',
        }),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
