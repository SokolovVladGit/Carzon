import 'package:firebase_messaging/firebase_messaging.dart';

/// Test seam for FCM notification open events (background tap + cold start).
abstract class FirebaseMessagingOpenEvents {
  Stream<RemoteMessage> get onMessageOpenedApp;

  Future<RemoteMessage?> getInitialMessage();
}

/// Production wiring to [FirebaseMessaging].
class DefaultFirebaseMessagingOpenEvents
    implements FirebaseMessagingOpenEvents {
  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Future<RemoteMessage?> getInitialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();
}
