import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/data/datasources/vehicle_model_catalog_remote_datasource.dart';
import 'package:carzon/features/listings/data/repositories/vehicle_model_catalog_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements VehicleModelCatalogRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late VehicleModelCatalogRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    repo = VehicleModelCatalogRepositoryImpl(remote);
  });

  test('maps RPC models and caches per normalized make', () async {
    when(
      () => remote.listVehicleModelsForMake('Honda'),
    ).thenAnswer((_) async => const ['Accord', 'Civic', 'CR-V']);

    final first = await repo.listVehicleModelsForMake(' Honda ');
    final second = await repo.listVehicleModelsForMake('honda');

    expect(first, isA<Success<List<String>>>());
    expect((first as Success<List<String>>).value, ['Accord', 'Civic', 'CR-V']);
    expect((second as Success<List<String>>).value, [
      'Accord',
      'Civic',
      'CR-V',
    ]);
    verify(() => remote.listVehicleModelsForMake('Honda')).called(1);
  });

  test('blank make returns empty without calling remote', () async {
    final out = await repo.listVehicleModelsForMake('   ');
    expect(out, isA<Success<List<String>>>());
    expect((out as Success<List<String>>).value, isEmpty);
    verifyNever(() => remote.listVehicleModelsForMake(any()));
  });

  test('ServerException becomes ServerFailure', () async {
    when(
      () => remote.listVehicleModelsForMake('Honda'),
    ).thenThrow(ServerException('down'));

    final out = await repo.listVehicleModelsForMake('Honda');
    expect(out, isA<FailureResult<List<String>>>());
    expect((out as FailureResult<List<String>>).failure, isA<ServerFailure>());
  });

  test('unknown errors become UnknownFailure', () async {
    when(
      () => remote.listVehicleModelsForMake('Honda'),
    ).thenThrow(StateError('boom'));

    final out = await repo.listVehicleModelsForMake('Honda');
    expect(out, isA<FailureResult<List<String>>>());
    expect((out as FailureResult<List<String>>).failure, isA<UnknownFailure>());
  });
}
