import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../listings/domain/listing_discovery_criteria_json.dart';
import '../models/saved_search_model.dart';

abstract interface class SavedSearchesRemoteDataSource {
  Future<List<SavedSearchModel>> listMine();

  Future<SavedSearchModel> create({
    required String name,
    required ListingDiscoveryCriteria criteria,
    required bool alertsEnabled,
  });

  Future<SavedSearchModel> setAlertsEnabled(String id, bool enabled);

  Future<void> delete(String id);

  Future<SavedSearchModel?> findByCriteria(ListingDiscoveryCriteria criteria);
}

class SupabaseSavedSearchesRemoteDataSource
    implements SavedSearchesRemoteDataSource {
  SupabaseSavedSearchesRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  void _requireAuth() {
    final uid = _supabase.client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      throw ServerException('Not authenticated');
    }
  }

  ServerException _mapPostgrest(sb.PostgrestException e, StackTrace st) {
    final msg = e.message;
    if (msg.contains('max_saved_searches_reached')) {
      return ServerException(
        'max_saved_searches_reached',
        cause: e,
        stackTrace: st,
        postgrestCode: e.code,
      );
    }
    if (msg.contains('duplicate_saved_search')) {
      return ServerException(
        'duplicate_saved_search',
        cause: e,
        stackTrace: st,
        postgrestCode: e.code,
      );
    }
    if (msg.contains('not authenticated') ||
        e.code == '28000' ||
        msg.toLowerCase().contains('jwt')) {
      return ServerException(
        'Not authenticated',
        cause: e,
        stackTrace: st,
        postgrestCode: e.code,
      );
    }
    return ServerException(
      'Saved search request failed',
      cause: e,
      stackTrace: st,
      postgrestCode: e.code,
      diagnosticsDetails: e.details?.toString(),
    );
  }

  List<SavedSearchModel> _mapRows(dynamic data) {
    if (data == null) return const [];
    if (data is! List) {
      throw ServerException('saved_searches list returned unexpected shape');
    }
    return data
        .map(
          (row) => SavedSearchModel.fromRpcRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  SavedSearchModel _mapSingle(dynamic data) {
    if (data == null) {
      throw ServerException('Saved search RPC returned no row');
    }
    if (data is List) {
      if (data.isEmpty) {
        throw ServerException('Saved search RPC returned empty list');
      }
      return SavedSearchModel.fromRpcRow(
        Map<String, dynamic>.from(data.first as Map),
      );
    }
    if (data is Map) {
      return SavedSearchModel.fromRpcRow(Map<String, dynamic>.from(data));
    }
    throw ServerException('Saved search RPC returned unexpected shape');
  }

  @override
  Future<List<SavedSearchModel>> listMine() async {
    try {
      _requireAuth();
      final data = await _supabase.client.rpc('list_my_saved_searches');
      return _mapRows(data);
    } on sb.PostgrestException catch (e, st) {
      throw _mapPostgrest(e, st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to load saved searches',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<SavedSearchModel> create({
    required String name,
    required ListingDiscoveryCriteria criteria,
    required bool alertsEnabled,
  }) async {
    try {
      _requireAuth();
      final data = await _supabase.client.rpc(
        'create_saved_search',
        params: {
          'p_name': name,
          'p_criteria': listingDiscoveryCriteriaToJson(criteria),
          'p_alerts_enabled': alertsEnabled,
        },
      );
      return _mapSingle(data);
    } on sb.PostgrestException catch (e, st) {
      throw _mapPostgrest(e, st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to create saved search',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<SavedSearchModel> setAlertsEnabled(String id, bool enabled) async {
    try {
      _requireAuth();
      final data = await _supabase.client.rpc(
        'set_saved_search_alerts_enabled',
        params: {'p_id': id, 'p_enabled': enabled},
      );
      return _mapSingle(data);
    } on sb.PostgrestException catch (e, st) {
      throw _mapPostgrest(e, st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to update saved search alerts',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      _requireAuth();
      await _supabase.client.rpc('delete_saved_search', params: {'p_id': id});
    } on sb.PostgrestException catch (e, st) {
      throw _mapPostgrest(e, st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to delete saved search',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<SavedSearchModel?> findByCriteria(
    ListingDiscoveryCriteria criteria,
  ) async {
    try {
      _requireAuth();
      final data = await _supabase.client.rpc(
        'find_saved_search_by_criteria',
        params: {'p_criteria': listingDiscoveryCriteriaToJson(criteria)},
      );
      if (data == null) return null;
      if (data is List && data.isEmpty) return null;
      return _mapSingle(data);
    } on sb.PostgrestException catch (e, st) {
      throw _mapPostgrest(e, st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to find saved search',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
