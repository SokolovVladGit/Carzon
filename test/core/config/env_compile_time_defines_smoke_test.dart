import 'package:carzon/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

/// Manual compile-time define smoke test.
///
/// Normal CI/unit runs skip this file. To verify local `.env.client` is passed
/// into the Dart compiler, run:
///
/// ```bash
/// flutter test \
///   --dart-define=RUN_CLIENT_DEFINE_SMOKE=true \
///   --dart-define-from-file=.env.client \
///   test/core/config/env_compile_time_defines_smoke_test.dart
/// ```
void main() {
  const runSmoke = bool.fromEnvironment('RUN_CLIENT_DEFINE_SMOKE');

  test(
    'compile-time client defines present when RUN_CLIENT_DEFINE_SMOKE=true',
    () {
      if (!runSmoke) return;

      expect(
        const bool.hasEnvironment('SUPABASE_URL'),
        isTrue,
        reason: 'SUPABASE_URL not passed to compiler',
      );
      expect(
        const bool.hasEnvironment('SUPABASE_ANON_KEY'),
        isTrue,
        reason: 'SUPABASE_ANON_KEY not passed to compiler',
      );

      const url = String.fromEnvironment('SUPABASE_URL');
      const anon = String.fromEnvironment('SUPABASE_ANON_KEY');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

      expect(url.isNotEmpty, isTrue, reason: 'SUPABASE_URL is empty');
      expect(anon.isNotEmpty, isTrue, reason: 'SUPABASE_ANON_KEY is empty');
      expect(url.startsWith('https://'), isTrue);
      expect(
        iosClientId,
        '68189143516-ahrske7madnpca3jrqtl87sfl3npp2j2.apps.googleusercontent.com',
      );
      expect(
        webClientId,
        '68189143516-o1l6ks0phe0fg6n429023b6k8pbugese.apps.googleusercontent.com',
      );
      expect(Env.googleNativeSignInConfigured, isTrue);
      expect(Env.googleAndroidSignInEnabled, isFalse);
      expect(iosClientId, isNot(webClientId));
    },
    skip: !runSmoke ? 'Set RUN_CLIENT_DEFINE_SMOKE=true to run' : false,
  );
}
