import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/push_token_platform.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote)
    : _logger = AppLogger('NotificationsRepository');

  final NotificationsRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<NotificationPreferences>> getMyPreferences() async {
    try {
      final v = await _remote.fetchMyPreferences();
      return Success(v);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getMyPreferences failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load notification settings.'),
      );
    }
  }

  @override
  Future<Result<NotificationPreferences>> updateMyPreferences({
    required bool globalEnabled,
    required bool messagesEnabled,
    required bool filterAlertsEnabled,
    required bool priceDropsEnabled,
  }) async {
    try {
      final v = await _remote.updateMyPreferences(
        globalEnabled: globalEnabled,
        messagesEnabled: messagesEnabled,
        filterAlertsEnabled: filterAlertsEnabled,
        priceDropsEnabled: priceDropsEnabled,
      );
      return Success(v);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('updateMyPreferences failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to update notification settings.'),
      );
    }
  }

  @override
  Future<Result<void>> registerPushToken({
    required String token,
    required PushTokenPlatform platform,
    String? appVersion,
    String? deviceId,
    String? locale,
  }) async {
    try {
      await _remote.registerPushToken(
        token: token,
        platform: platform,
        appVersion: appVersion,
        deviceId: deviceId,
        locale: locale,
      );
      return const Success<void>(null);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('registerPushToken failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to register push token.'),
      );
    }
  }

  @override
  Future<Result<void>> deactivatePushToken(String token) async {
    try {
      await _remote.deactivatePushToken(token);
      return const Success<void>(null);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('deactivatePushToken failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to deactivate push token.'),
      );
    }
  }

  @override
  Future<Result<void>> deactivateMyPushTokens() async {
    try {
      await _remote.deactivateMyPushTokens();
      return const Success<void>(null);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('deactivateMyPushTokens failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to deactivate push tokens.'),
      );
    }
  }
}
