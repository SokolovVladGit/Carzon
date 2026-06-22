import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/fuel_price_snapshot.dart';
import 'fuel_prices_remote_datasource.dart';

class SupabaseFuelPricesRemoteDataSource implements FuelPricesRemoteDataSource {
  SupabaseFuelPricesRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String _rpcGetFuelPricesForApp = 'get_fuel_prices_for_app';

  @override
  Future<List<FuelPriceSnapshot>> fetchFuelPricesForApp() async {
    try {
      final dynamic data = await _supabase.client.rpc(_rpcGetFuelPricesForApp);
      final rows = <FuelPriceSnapshot>[];
      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;
          final row = Map<String, dynamic>.from(item);
          final parsed = FuelPriceSnapshot.tryParse(row);
          if (parsed != null) rows.add(parsed);
        }
      }
      return rows;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to fetch fuel prices',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
