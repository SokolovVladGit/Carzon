import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/data/datasources/filter_alerts_remote_datasource.dart';
import 'package:carzon/features/filter_alerts/data/models/saved_search_model.dart';
import 'package:carzon/features/filter_alerts/data/repositories/filter_alerts_repository_impl.dart';
import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements SavedSearchesRemoteDataSource {}

SavedSearchModel _model({
  String id = 'ss-1',
  ListingDiscoveryCriteria criteria = const ListingDiscoveryCriteria(
    make: 'Audi',
  ),
  bool alertsEnabled = false,
}) {
  return SavedSearchModel(
    id: id,
    name: 'Audi search',
    criteria: criteria,
    alertsEnabled: alertsEnabled,
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 6, 2),
  );
}

void main() {
  late _MockRemote remote;

  setUpAll(() {
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  setUp(() {
    remote = _MockRemote();
  });

  test('create maps max_saved_searches_reached to ServerFailure', () async {
    when(
      () => remote.create(
        name: any(named: 'name'),
        criteria: any(named: 'criteria'),
        alertsEnabled: any(named: 'alertsEnabled'),
      ),
    ).thenThrow(ServerException('max_saved_searches_reached'));

    final impl = SavedSearchesRepositoryImpl(remote);
    final r = await impl.create(
      name: 'New',
      criteria: const ListingDiscoveryCriteria(make: 'BMW'),
      alertsEnabled: false,
    );

    expect(r, isA<FailureResult<SavedSearch>>());
    final failure = (r as FailureResult<SavedSearch>).failure;
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'max_saved_searches_reached');
  });

  test('create maps duplicate_saved_search to ServerFailure', () async {
    when(
      () => remote.create(
        name: any(named: 'name'),
        criteria: any(named: 'criteria'),
        alertsEnabled: any(named: 'alertsEnabled'),
      ),
    ).thenThrow(ServerException('duplicate_saved_search'));

    final impl = SavedSearchesRepositoryImpl(remote);
    final r = await impl.create(
      name: 'Dup',
      criteria: const ListingDiscoveryCriteria(make: 'BMW'),
      alertsEnabled: false,
    );

    expect(r, isA<FailureResult<SavedSearch>>());
    expect(
      (r as FailureResult<SavedSearch>).failure.message,
      'duplicate_saved_search',
    );
  });

  test('delete delegates to remote.delete', () async {
    when(() => remote.delete('ss-9')).thenAnswer((_) async {});

    final impl = SavedSearchesRepositoryImpl(remote);
    final r = await impl.delete('ss-9');

    expect(r, isA<Success<void>>());
    verify(() => remote.delete('ss-9')).called(1);
    verifyNever(
      () => remote.create(
        name: any(named: 'name'),
        criteria: any(named: 'criteria'),
        alertsEnabled: any(named: 'alertsEnabled'),
      ),
    );
  });

  test('create success returns mapped entity', () async {
    final model = _model();
    when(
      () => remote.create(
        name: any(named: 'name'),
        criteria: any(named: 'criteria'),
        alertsEnabled: any(named: 'alertsEnabled'),
      ),
    ).thenAnswer((_) async => model);

    final impl = SavedSearchesRepositoryImpl(remote);
    final r = await impl.create(
      name: 'Audi search',
      criteria: const ListingDiscoveryCriteria(make: 'Audi'),
      alertsEnabled: false,
    );

    expect(r, isA<Success<SavedSearch>>());
    expect((r as Success<SavedSearch>).value.id, 'ss-1');
    expect(r.value.criteria.make, 'Audi');
  });
}
