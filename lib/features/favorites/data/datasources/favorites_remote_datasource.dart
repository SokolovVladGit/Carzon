import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../listings/data/models/listing_model.dart';

abstract interface class FavoritesRemoteDataSource {
  Future<Set<String>> fetchIds();
  Future<List<ListingModel>> fetchListings();
  Future<void> add(String listingId);
  Future<void> remove(String listingId);
}

class SupabaseFavoritesRemoteDataSource implements FavoritesRemoteDataSource {
  SupabaseFavoritesRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const String _table = 'favorites';
  static const String _publicListingColumns = '''
id,
title,
make,
model,
year,
price_eur,
price_currency,
mileage_km,
type,
city,
market_region,
body_type,
fuel_type,
engine_displacement_liters,
engine_power_hp,
drivetrain,
transmission_type,
registration,
description,
created_at,
status,
cover_image_url,
seller_id,
vin_status
''';

  String get _uid {
    final user = _supabase.client.auth.currentUser;
    if (user == null) {
      throw AuthException('Not authenticated.');
    }
    return user.id;
  }

  @override
  Future<Set<String>> fetchIds() async {
    try {
      // RLS already restricts to current user, but we keep the query
      // explicit for clarity.
      final rows = await _supabase.client
          .from(_table)
          .select('listing_id')
          .eq('user_id', _uid);
      return rows.map<String>((r) => r['listing_id'] as String).toSet();
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to load favorites',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<ListingModel>> fetchListings() async {
    try {
      final rows = await _supabase.client
          .from(_table)
          .select('created_at, listings($_publicListingColumns)')
          .eq('user_id', _uid)
          .order('created_at', ascending: false);

      return rows
          .map<ListingModel?>((r) {
            final listing = r['listings'];
            if (listing is! Map<String, dynamic>) return null;
            return ListingModel.fromPublicJson(listing);
          })
          .whereType<ListingModel>()
          .toList(growable: false);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to load favorite listings',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> add(String listingId) async {
    try {
      await _supabase.client.from(_table).insert({
        'user_id': _uid,
        'listing_id': listingId,
      });
    } on sb.PostgrestException catch (e, st) {
      // 23505 = unique_violation → already favorited; treat as success.
      if (e.code == '23505') return;
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } catch (e, st) {
      throw ServerException('Failed to add favorite', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> remove(String listingId) async {
    try {
      await _supabase.client
          .from(_table)
          .delete()
          .eq('user_id', _uid)
          .eq('listing_id', listingId);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on AuthException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to remove favorite',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
