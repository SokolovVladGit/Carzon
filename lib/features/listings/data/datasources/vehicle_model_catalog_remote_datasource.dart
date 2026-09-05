import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';

abstract interface class VehicleModelCatalogRemoteDataSource {
  Future<List<String>> listVehicleModelsForMake(String make);
}

class SupabaseVehicleModelCatalogRemoteDataSource
    implements VehicleModelCatalogRemoteDataSource {
  SupabaseVehicleModelCatalogRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String _rpc = 'list_vehicle_models_for_make';

  @override
  Future<List<String>> listVehicleModelsForMake(String make) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        _rpc,
        params: {'p_make': make.trim()},
      );
      if (data is! List) return const [];
      final seen = <String>{};
      final models = <String>[];
      for (final item in data) {
        final value = switch (item) {
          final String s => s.trim(),
          final Map map => (map['model'] as Object?)?.toString().trim() ?? '',
          _ => '',
        };
        if (value.isEmpty || !seen.add(value)) continue;
        models.add(value);
      }
      return models;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load vehicle models',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
