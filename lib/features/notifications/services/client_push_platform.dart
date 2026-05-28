import 'package:flutter/foundation.dart' show kIsWeb;

import '../domain/entities/push_token_platform.dart';
import 'client_push_platform_stub.dart'
    if (dart.library.io) 'client_push_platform_io.dart'
    as native_impl;

/// Resolves [PushTokenPlatform] for RPC `register_push_token` payloads.
///
/// Uses `web` on web, native detection via `dart:io` elsewhere, and
/// [PushTokenPlatform.unknown] when the platform cannot be resolved.
PushTokenPlatform detectClientPushTokenPlatform() {
  if (kIsWeb) return PushTokenPlatform.web;
  return native_impl.nativePushTokenPlatform();
}
