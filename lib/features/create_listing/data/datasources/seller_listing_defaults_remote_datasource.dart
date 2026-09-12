import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/seller_listing_defaults.dart';

abstract interface class SellerListingDefaultsRemoteDataSource {
  Future<SellerListingDefaults> getMyListingDefaults();

  Future<SellerListingDefaults> upsertMyListingDefaults(
    SellerListingDefaults defaults,
  );
}

class SupabaseSellerListingDefaultsRemoteDataSource
    implements SellerListingDefaultsRemoteDataSource {
  SupabaseSellerListingDefaultsRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const _getRpc = 'get_my_listing_defaults';
  static const _upsertRpc = 'upsert_my_listing_defaults';

  @override
  Future<SellerListingDefaults> getMyListingDefaults() async {
    try {
      final session = _supabase.client.auth.currentSession;
      if (session == null) throw ServerException('Not authenticated.');
      final dynamic rows = await _supabase.client
          .rpc(_getRpc)
          .setHeader('Authorization', 'Bearer ${session.accessToken}');
      return parseSellerListingDefaultsResponse(rows);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to load listing defaults.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<SellerListingDefaults> upsertMyListingDefaults(
    SellerListingDefaults defaults,
  ) async {
    try {
      final session = _supabase.client.auth.currentSession;
      if (session == null) throw ServerException('Not authenticated.');
      // The Cubit checks initiating-account authority before invoking this
      // method; pin that account even if SDK token refresh yields afterward.
      final dynamic rows = await _supabase.client
          .rpc(
            _upsertRpc,
            params: sellerListingDefaultsToUpsertParams(defaults),
          )
          .setHeader('Authorization', 'Bearer ${session.accessToken}');
      return parseSellerListingDefaultsResponse(rows);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to save listing defaults.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}

Map<String, dynamic> sellerListingDefaultsToUpsertParams(
  SellerListingDefaults defaults,
) {
  return <String, dynamic>{
    'p_contact_phone': defaults.contactPhone,
    'p_telegram_username': defaults.telegramUsername,
    'p_whatsapp_enabled': defaults.whatsappEnabled,
    'p_market_region': defaults.marketRegion?.name,
    'p_city': defaults.city,
  };
}

SellerListingDefaults parseSellerListingDefaultsResponse(Object? raw) {
  if (raw == null) return const SellerListingDefaults.empty();
  if (raw is List) {
    if (raw.isEmpty) return const SellerListingDefaults.empty();
    final first = raw.first;
    if (first is Map) {
      return sellerListingDefaultsFromMap(Map<String, dynamic>.from(first));
    }
    return const SellerListingDefaults.empty();
  }
  if (raw is Map) {
    return sellerListingDefaultsFromMap(Map<String, dynamic>.from(raw));
  }
  return const SellerListingDefaults.empty();
}

SellerListingDefaults sellerListingDefaultsFromMap(Map<String, dynamic> map) {
  final phone = _optionalText(map['contact_phone']);
  final telegram = _optionalText(map['telegram_username']);
  final city = _optionalText(map['city']);
  final region = parseListingDefaultsMarketRegion(map['market_region']);
  return SellerListingDefaults(
    contactPhone: phone,
    telegramUsername: telegram,
    whatsappEnabled: map['whatsapp_enabled'] == true,
    marketRegion: region,
    city: region == null ? null : city,
  );
}

String? _optionalText(Object? raw) {
  if (raw is! String) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}
