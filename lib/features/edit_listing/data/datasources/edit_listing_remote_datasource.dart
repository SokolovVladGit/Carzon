import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../listings/data/models/listing_model.dart';
import '../../domain/entities/edit_listing_input.dart';

/// Only this class talks to Supabase for edit-listing.
abstract interface class EditListingRemoteDataSource {
  /// Calls the `public.update_listing_details` RPC. Ownership, input
  /// validation, and the allowed column set are enforced in the
  /// function body; the client does not construct an UPDATE itself.
  /// Returns the refreshed row.
  Future<ListingModel> updateDetails(EditListingInput input);

  /// Calls the `public.update_listing_cover_image` RPC. The RPC
  /// updates only `cover_image_url`; ownership, auth, and URL shape
  /// are enforced in the function body. Passing `null` removes the
  /// cover image. Returns the refreshed row.
  Future<ListingModel> updateCoverImage({
    required String listingId,
    required String? coverImageUrl,
  });
}

class SupabaseEditListingRemoteDataSource implements EditListingRemoteDataSource {
  SupabaseEditListingRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const String _rpc = 'update_listing_details';
  static const String _rpcCover = 'update_listing_cover_image';

  @override
  Future<ListingModel> updateDetails(EditListingInput input) async {
    try {
      // Telegram normalization is also performed by the RPC; doing it
      // here keeps the wire payload tidy and makes the expected stored
      // shape obvious at the client boundary.
      final telegram = input.telegramUsername?.trim();
      final normalizedTelegram = (telegram == null || telegram.isEmpty)
          ? null
          : (telegram.startsWith('@') ? telegram.substring(1) : telegram);

      final dynamic data = await _supabase.client.rpc(
        _rpc,
        params: <String, dynamic>{
          'p_listing_id': input.listingId,
          'p_title': input.title.trim(),
          'p_make': input.make.trim(),
          'p_model': input.model.trim(),
          'p_year': input.year,
          'p_price_eur': input.priceEur,
          'p_mileage_km': input.mileageKm,
          'p_type': input.type.name,
          'p_city': input.city.trim(),
          'p_market_region': input.marketRegion.name,
          'p_contact_phone': input.contactPhone.trim(),
          'p_telegram_username': normalizedTelegram,
          'p_whatsapp_enabled': input.whatsappEnabled,
        },
      );
      // Postgrest can return the row as either a JSON object (single-
      // row scalar return) or a single-element list depending on the
      // client version. Both shapes are handled defensively — this
      // matches the pattern used by `set_listing_status`.
      Map<String, dynamic>? row;
      if (data is Map<String, dynamic>) {
        row = data;
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        row = Map<String, dynamic>.from(data.first as Map);
      }
      if (row == null) {
        throw ServerException(
          'Unexpected response from update_listing_details RPC.',
        );
      }
      return ListingModel.fromJson(row);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to update listing ${input.listingId}',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<ListingModel> updateCoverImage({
    required String listingId,
    required String? coverImageUrl,
  }) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        _rpcCover,
        params: <String, dynamic>{
          'p_listing_id': listingId,
          'p_cover_image_url': coverImageUrl,
        },
      );
      // `update_listing_cover_image` returns the refreshed row; the
      // shape matches `update_listing_details` so we defensively
      // accept either a single object or a single-element list.
      Map<String, dynamic>? row;
      if (data is Map<String, dynamic>) {
        row = data;
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        row = Map<String, dynamic>.from(data.first as Map);
      }
      if (row == null) {
        throw ServerException(
          'Unexpected response from update_listing_cover_image RPC.',
        );
      }
      return ListingModel.fromJson(row);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to update cover image for listing $listingId',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
