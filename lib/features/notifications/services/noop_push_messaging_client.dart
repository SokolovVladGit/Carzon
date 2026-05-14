import 'push_messaging_client.dart';
import 'push_messaging_permission_status.dart';

/// [PushMessagingClient] used when `Env.pushNotificationsEnabled` is false.
///
/// Performs no Firebase I/O. Token and permission APIs return empty / unknown
/// values so registration paths remain no-ops.
class NoopPushMessagingClient implements PushMessagingClient {
  @override
  Future<bool> initializeFirebase() async => false;

  @override
  Future<PushMessagingPermissionStatus> getPermissionStatus() async {
    return PushMessagingPermissionStatus.notDetermined;
  }

  @override
  Future<PushMessagingPermissionStatus> requestPermission() async {
    return PushMessagingPermissionStatus.notDetermined;
  }

  @override
  Future<String?> getFcmToken() async => null;

  @override
  Stream<String> watchTokenRefresh() async* {}

  @override
  Future<void> deleteFcmToken() async {}
}
