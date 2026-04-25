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
      final payload = <String, dynamic>{
        'title': input.title,
        'make': input.make,
        'model': input.model,
        'year': input.year,
        'price_eur': input.priceEur,
        'mileage_km': input.mileageKm,
        'type': input.type.name,
        'city': input.city,
        'market_region': input.marketRegion.name,
        'seller_id': input.sellerId,
        'contact_phone': input.contactPhone.trim(),
        'whatsapp_enabled': input.whatsappEnabled,
        // status & created_at use DB defaults ('active', now()).
      };
      final cover = input.coverImageUrl?.trim();
      if (cover != null && cover.isNotEmpty) {
        payload['cover_image_url'] = cover;
      }
      final telegram = input.telegramUsername?.trim();
      if (telegram != null && telegram.isNotEmpty) {
        // Strip any leading `@` as a defensive measure; the UI
        // validator already normalizes, this is belt-and-braces.
        final normalized =
            telegram.startsWith('@') ? telegram.substring(1) : telegram;
        if (normalized.isNotEmpty) {
          payload['telegram_username'] = normalized;
        }
      }

      final row = await _supabase.client
          .from(_table)
          .insert(payload)
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
