import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/my_seller_profile_model.dart';
import '../models/seller_public_profile_model.dart';

abstract interface class SellersRemoteDataSource {
  /// Returns `null` when the RPC yields no visible profile row.
  Future<SellerPublicProfileModel?> fetchPublicProfile(String sellerId);

  /// Authenticated: own row for account editing (ensures row exists).
  Future<MySellerProfileModel> fetchMySellerProfile();

  /// Authenticated: updates own `display_name` only.
  Future<MySellerProfileModel> updateMySellerDisplayName(String? displayName);

  /// Authenticated: sets own avatar columns after Storage upload.
  Future<MySellerProfileModel> updateMySellerAvatar({
    required String avatarPath,
    required String avatarUrl,
  });

  /// Authenticated: clears own avatar columns (Storage cleanup is client-side).
  Future<MySellerProfileModel> clearMySellerAvatar();
}

class SupabaseSellersRemoteDataSource implements SellersRemoteDataSource {
  SupabaseSellersRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static MySellerProfileModel _asMySellerProfileRow(dynamic rows) {
    if (rows is! List || rows.isEmpty) {
      throw ServerException('Unexpected my seller profile RPC payload');
    }
    final first = rows.first;
    if (first is! Map) {
      throw ServerException('Unexpected my seller profile RPC payload');
    }
    return MySellerProfileModel.fromJson(Map<String, dynamic>.from(first));
  }

  @override
  Future<SellerPublicProfileModel?> fetchPublicProfile(String sellerId) async {
    try {
      final dynamic rows = await _supabase.client.rpc(
        'get_seller_public_profile',
        params: {'p_seller_id': sellerId},
      );
      if (rows is! List || rows.isEmpty) {
        return null;
      }
      final first = rows.first;
      if (first is! Map) {
        throw ServerException('Unexpected seller profile RPC payload');
      }
      return SellerPublicProfileModel.fromJson(
        Map<String, dynamic>.from(first),
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to load seller profile',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<MySellerProfileModel> fetchMySellerProfile() async {
    try {
      final dynamic rows = await _supabase.client.rpc('get_my_seller_profile');
      return _asMySellerProfileRow(rows);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to load seller profile settings',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<MySellerProfileModel> updateMySellerDisplayName(
    String? displayName,
  ) async {
    try {
      final dynamic rows = await _supabase.client.rpc(
        'update_my_seller_display_name',
        params: {'p_display_name': displayName},
      );
      return _asMySellerProfileRow(rows);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to update seller display name',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<MySellerProfileModel> updateMySellerAvatar({
    required String avatarPath,
    required String avatarUrl,
  }) async {
    try {
      final dynamic rows = await _supabase.client.rpc(
        'update_my_seller_avatar',
        params: {'p_avatar_path': avatarPath, 'p_avatar_url': avatarUrl},
      );
      return _asMySellerProfileRow(rows);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to update seller avatar',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<MySellerProfileModel> clearMySellerAvatar() async {
    try {
      final dynamic rows = await _supabase.client.rpc('clear_my_seller_avatar');
      return _asMySellerProfileRow(rows);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to clear seller avatar',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
