import 'dart:io';

import '../domain/entities/push_token_platform.dart';

PushTokenPlatform nativePushTokenPlatform() {
  if (Platform.isAndroid) return PushTokenPlatform.android;
  if (Platform.isIOS) return PushTokenPlatform.ios;
  return PushTokenPlatform.unknown;
}
