import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../listings/data/models/listing_model.dart';
import '../../domain/entities/new_listing_input.dart';

/// Only this class talks to Supabase for create-listing.
abstract interface class CreateListingRemoteDataSource {
  Future<ListingModel> insert(NewListingInput input);
}

class SupabaseCreateListingRemoteDataSource
    implements CreateListingRemoteDataSource {
  SupabaseCreateListingRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const String _table = 'listings';

  @override
  Future<ListingModel> insert(NewListingInput input) async {
    try {
      final row = await _supabase.client
          .from(_table)
          .insert({
            'title': input.title,
            'make': input.make,
            'model': input.model,
            'year': input.year,
            'price_eur': input.priceEur,
            'mileage_km': input.mileageKm,
            'type': input.type.name,
            'city': input.city,
            'seller_id': input.sellerId,
            // status & created_at use DB defaults ('active', now()).
          })
          .select()
          .single();

      return ListingModel.fromJson(row);
    } on sb.PostgrestException catch (e, st) {
      // RLS rejection surfaces as PostgrestException with a 4xx code.
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException('Failed to create listing', cause: e, stackTrace: st);
    }
  }
}
