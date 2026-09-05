import 'dart:async';

import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/repositories/vehicle_model_catalog_repository.dart';

class FakeVehicleModelCatalogRepository
    implements VehicleModelCatalogRepository {
  FakeVehicleModelCatalogRepository({
    Map<String, List<String>>? modelsByMake,
    this.failure,
  }) : modelsByMake = modelsByMake ?? Map<String, List<String>>.from(defaults);

  static const Map<String, List<String>> defaults = {
    'audi': ['A4', 'A5', 'A6', 'Q5', 'e-tron GT'],
    'bmw': ['3 Series', '5 Series', 'M3', 'M4', 'X3', 'X5'],
    'honda': ['Accord', 'Civic', 'CR-V', 'HR-V'],
    'mercedes-benz': [
      'A-Class',
      'C-Class',
      'E-Class',
      'G-Class',
      'GLC',
      'GLE',
      'S-Class',
    ],
    'toyota': ['Camry', 'Corolla', 'Highlander', 'RAV4'],
    'volkswagen': ['Golf', 'Passat', 'Polo'],
  };

  final Map<String, List<String>> modelsByMake;
  Failure? failure;
  Completer<void>? gate;
  int listCalls = 0;
  final listedMakes = <String>[];

  @override
  Future<Result<List<String>>> listVehicleModelsForMake(String make) async {
    listCalls += 1;
    listedMakes.add(make);
    final pending = gate;
    if (pending != null) {
      await pending.future;
    }
    final currentFailure = failure;
    if (currentFailure != null) {
      return FailureResult(currentFailure);
    }
    final models = modelsByMake[make.trim().toLowerCase()] ?? const <String>[];
    return Success(List<String>.from(models));
  }
}
