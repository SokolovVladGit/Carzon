import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';

/// Compile-time / platform gating for social buttons. No network probes.
class SocialAuthAvailability {
  const SocialAuthAvailability({
    required this.googleEnabled,
    required this.appleEnabled,
  });

  factory SocialAuthAvailability.fromEnv({TargetPlatform? platform}) {
    final resolved = platform ?? defaultTargetPlatform;
    final googleIdsReady = Env.googleNativeSignInConfigured;
    final googleEnabled = switch (resolved) {
      TargetPlatform.iOS => googleIdsReady,
      TargetPlatform.android =>
        googleIdsReady && Env.googleAndroidSignInEnabled,
      _ => false,
    };
    return SocialAuthAvailability(
      googleEnabled: googleEnabled,
      appleEnabled: resolved == TargetPlatform.iOS,
    );
  }

  final bool googleEnabled;
  final bool appleEnabled;

  bool get hasAny => googleEnabled || appleEnabled;
}
