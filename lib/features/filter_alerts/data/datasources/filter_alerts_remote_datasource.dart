import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../listings/domain/listing_discovery_criteria_json.dart';
import '../models/filter_alert_settings_model.dart';

abstract interface class FilterAlertsRemoteDataSource {
  Future<FilterAlertSettingsModel?> fetchMine();

  Future<FilterAlertSettingsModel> upsertCriteria(
    ListingDiscoveryCriteria criteria, {
    required bool notificationsEnabled,
  });

  Future<FilterAlertSettingsModel> upsertClearsCriteria();

  Future<FilterAlertSettingsModel> setNotificationsEnabled(bool enabled);
}

class SupabaseFilterAlertsRemoteDataSource
    implements FilterAlertsRemoteDataSource {
  SupabaseFilterAlertsRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const _table = 'filter_alert_settings';

  static const _cols =
      'user_id, criteria, notifications_enabled, created_at, updated_at';

  @override
  Future<FilterAlertSettingsModel?> fetchMine() async {
    try {
      final uid = _supabase.client.auth.currentUser?.id;
      if (uid == null || uid.isEmpty) {
        throw ServerException('Not authenticated');
      }
      final row = await _supabase.client
          .from(_table)
          .select(_cols)
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;
      return FilterAlertSettingsModel.fromSupabase(
        Map<String, dynamic>.from(row),
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to load filter alert settings',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<FilterAlertSettingsModel> upsertCriteria(
    ListingDiscoveryCriteria criteria, {
    required bool notificationsEnabled,
  }) async {
    try {
      final uid = _supabase.client.auth.currentUser?.id;
      if (uid == null || uid.isEmpty) {
        throw ServerException('Not authenticated');
      }
      final row = await _supabase.client
          .from(_table)
          .upsert({
            'user_id': uid,
            'criteria': listingDiscoveryCriteriaToJson(criteria),
            'notifications_enabled': notificationsEnabled,
          }, onConflict: 'user_id')
          .select(_cols)
          .maybeSingle();

      if (row == null) {
        throw ServerException('Filter alert upsert returned no row.');
      }
      return FilterAlertSettingsModel.fromSupabase(
        Map<String, dynamic>.from(row),
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to save filter alert criteria',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<FilterAlertSettingsModel> upsertClearsCriteria() async {
    try {
      final uid = _supabase.client.auth.currentUser?.id;
      if (uid == null || uid.isEmpty) {
        throw ServerException('Not authenticated');
      }

      final afterUpdate = await _supabase.client
          .from(_table)
          .update({'criteria': null, 'notifications_enabled': false})
          .eq('user_id', uid)
          .select(_cols)
          .maybeSingle();

      final Map<String, dynamic> rowFromUpdate;
      if (afterUpdate != null) {
        rowFromUpdate = Map<String, dynamic>.from(afterUpdate);
      } else {
        final inserted = await _supabase.client
            .from(_table)
            .upsert(<String, dynamic>{
              'user_id': uid,
              'criteria': null,
              'notifications_enabled': false,
            }, onConflict: 'user_id')
            .select(_cols)
            .maybeSingle();
        if (inserted == null) {
          throw ServerException('Filter alert clear/update returned no row.');
        }
        rowFromUpdate = Map<String, dynamic>.from(inserted);
      }

      return FilterAlertSettingsModel.fromSupabase(rowFromUpdate);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to clear filter alert criteria',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<FilterAlertSettingsModel> setNotificationsEnabled(bool enabled) async {
    try {
      final uid = _supabase.client.auth.currentUser?.id;
      if (uid == null || uid.isEmpty) {
        throw ServerException('Not authenticated');
      }

      final afterUpdate = await _supabase.client
          .from(_table)
          .update({'notifications_enabled': enabled})
          .eq('user_id', uid)
          .select(_cols)
          .maybeSingle();

      if (afterUpdate != null) {
        return FilterAlertSettingsModel.fromSupabase(
          Map<String, dynamic>.from(afterUpdate),
        );
      }

      final inserted = await _supabase.client
          .from(_table)
          .upsert(<String, dynamic>{
            'user_id': uid,
            'criteria': null,
            'notifications_enabled': enabled,
          }, onConflict: 'user_id')
          .select(_cols)
          .maybeSingle();

      if (inserted == null) {
        throw ServerException(
          'Filter alert notifications toggle returned no row.',
        );
      }
      return FilterAlertSettingsModel.fromSupabase(
        Map<String, dynamic>.from(inserted),
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to update filter alert notifications toggle',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
