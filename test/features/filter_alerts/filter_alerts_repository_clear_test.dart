import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/data/datasources/filter_alerts_remote_datasource.dart';
import 'package:carzon/features/filter_alerts/data/models/filter_alert_settings_model.dart';
import 'package:carzon/features/filter_alerts/data/repositories/filter_alerts_repository_impl.dart';
import 'package:carzon/features/filter_alerts/domain/entities/filter_alert_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';

class _MockRemote extends Mock implements FilterAlertsRemoteDataSource {}

void main() {
  late _MockRemote remote;

  setUpAll(() {
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  setUp(() {
    remote = _MockRemote();
  });

  test('clearPersistedCriteria uses upsertClearsCriteria, not upsertCriteria', () async {
    final model = FilterAlertSettingsModel(
      userId: 'u1',
      criteria: null,
      notificationsEnabled: false,
      createdAt: DateTime.utc(2026, 6, 1),
      updatedAt: DateTime.utc(2026, 6, 2),
    );
    when(() => remote.upsertClearsCriteria()).thenAnswer((_) async => model);

    final impl = FilterAlertsRepositoryImpl(remote);
    final r = await impl.clearPersistedCriteria();

    expect(r, isA<Success<FilterAlertSettings>>());
    final v = (r as Success<FilterAlertSettings>).value;
    expect(v.criteria, isNull);
    expect(v.notificationsEnabled, isFalse);

    verify(() => remote.upsertClearsCriteria()).called(1);
    verifyNever(() => remote.upsertCriteria(any()));
  });
}
