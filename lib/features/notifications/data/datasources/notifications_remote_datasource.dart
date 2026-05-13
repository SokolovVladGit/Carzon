import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/push_token_platform.dart';

abstract interface class NotificationsRemoteDataSource {
  Future<NotificationPreferences> fetchMyPreferences();

  Future<NotificationPreferences> updateMyPreferences({
    required bool globalEnabled,
    required bool messagesEnabled,
    required bool filterAlertsEnabled,
  });

  Future<void> registerPushToken({
    required String token,
    required PushTokenPlatform platform,
    String? appVersion,
    String? deviceId,
    String? locale,
  });

  Future<void> deactivatePushToken(String token);

  Future<void> deactivateMyPushTokens();
}

class SupabaseNotificationsRemoteDataSource
    implements NotificationsRemoteDataSource {
  SupabaseNotificationsRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static NotificationPreferences _parsePreferencesRow(dynamic raw) {
    dynamic r = raw;
    if (raw is List && raw.isNotEmpty) {
      r = raw.first;
    }
    if (r is! Map) {
      throw ServerException(
        'Unexpected notification_preferences payload '
        '(${raw.runtimeType})',
      );
    }
    final m = r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r);
    final userId = m['user_id']?.toString().trim() ?? '';
    if (userId.isEmpty) {
      throw ServerException('notification_preferences.user_id missing');
    }
    final g = m['global_enabled'];
    final msg = m['messages_enabled'];
    final fa = m['filter_alerts_enabled'];
    if (g is! bool || msg is! bool || fa is! bool) {
      throw ServerException('notification_preferences boolean fields invalid');
    }
    DateTime ts(dynamic v, String label) {
      if (v is String) {
        return DateTime.parse(v.trim());
      }
      throw ServerException('notification_preferences.$label invalid');
    }

    return NotificationPreferences(
      userId: userId,
      globalEnabled: g,
      messagesEnabled: msg,
      filterAlertsEnabled: fa,
      createdAt: ts(m['created_at'], 'created_at'),
      updatedAt: ts(m['updated_at'], 'updated_at'),
    );
  }

  @override
  Future<NotificationPreferences> fetchMyPreferences() async {
    try {
      final dynamic data =
          await _supabase.client.rpc('get_my_notification_preferences');
      return _parsePreferencesRow(data);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    }
  }

  @override
  Future<NotificationPreferences> updateMyPreferences({
    required bool globalEnabled,
    required bool messagesEnabled,
    required bool filterAlertsEnabled,
  }) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        'update_my_notification_preferences',
        params: <String, dynamic>{
          'p_global_enabled': globalEnabled,
          'p_messages_enabled': messagesEnabled,
          'p_filter_alerts_enabled': filterAlertsEnabled,
        },
      );
      return _parsePreferencesRow(data);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> registerPushToken({
    required String token,
    required PushTokenPlatform platform,
    String? appVersion,
    String? deviceId,
    String? locale,
  }) async {
    try {
      await _supabase.client.rpc(
        'register_push_token',
        params: <String, dynamic>{
          'p_token': token,
          'p_platform': pushTokenPlatformToWire(platform),
          'p_app_version': appVersion,
          'p_device_id': deviceId,
          'p_locale': locale,
        },
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deactivatePushToken(String token) async {
    try {
      await _supabase.client.rpc(
        'deactivate_push_token',
        params: <String, dynamic>{'p_token': token},
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deactivateMyPushTokens() async {
    try {
      await _supabase.client.rpc('deactivate_my_push_tokens');
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    }
  }
}
