import 'package:carzon/core/config/env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Focused tests for `Env` — only cover the launch-readiness contract
/// that other layers rely on:
///   * required keys are exactly what the app refuses to boot without,
///   * support/release configuration is validated independently,
///   * `reportEmail` remains optional and nullable,
///   * `missingKeys()` never lists optional keys.
void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
  });

  tearDown(() {
    dotenv.testLoad(fileInput: '');
  });

  group('Env.pushNotificationsEnabled', () {
    test('is false when unset', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
      );
      expect(Env.pushNotificationsEnabled, isFalse);
    });

    test('accepts true, 1, yes, on case-insensitively', () {
      for (final v in <String>['true', 'TRUE', '1', 'Yes', 'ON']) {
        dotenv.testLoad(
          fileInput:
              '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=$v
''',
        );
        expect(Env.pushNotificationsEnabled, isTrue, reason: v);
      }
    });

    test('is false for any other string', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=maybe
''',
      );
      expect(Env.pushNotificationsEnabled, isFalse);
    });
  });

  group('Env.requiredKeys', () {
    test('contains Supabase URL and anon key, and nothing else', () {
      expect(
        Env.requiredKeys,
        equals(<String>['SUPABASE_URL', 'SUPABASE_ANON_KEY']),
      );
    });

    test('does NOT include CARZON_REPORT_EMAIL', () {
      expect(Env.requiredKeys, isNot(contains('CARZON_REPORT_EMAIL')));
    });
  });

  group('Env.reportEmail', () {
    test('is null when the env variable is absent', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
      );
      expect(Env.reportEmail, isNull);
    });

    test('is null when the env variable is set but empty', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
CARZON_REPORT_EMAIL=
''',
      );
      expect(Env.reportEmail, isNull);
    });

    test('trims whitespace and returns the configured address', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
CARZON_REPORT_EMAIL=  reports@carzon.example  
''',
      );
      expect(Env.reportEmail, 'reports@carzon.example');
    });
  });

  group('Env public legal configuration', () {
    test('uses the owner-confirmed canonical production defaults', () {
      expect(Env.privacyPolicyUrl, 'https://carzon-legal.netlify.app/privacy/');
      expect(Env.termsOfServiceUrl, 'https://carzon-legal.netlify.app/terms/');
      expect(Env.supportUrl, 'https://carzon-legal.netlify.app/support/');
      expect(
        Env.privacyChoicesUrl,
        'https://carzon-legal.netlify.app/privacy-choices/',
      );
      expect(Env.supportEmail, 'carzonsupport@gmail.com');
    });

    test('allows client-safe compile-time-style test overrides', () {
      dotenv.testLoad(
        fileInput: '''
CARZON_PRIVACY_POLICY_URL=https://legal.carzon.md/privacy/
CARZON_TERMS_OF_SERVICE_URL=https://legal.carzon.md/terms/
CARZON_SUPPORT_URL=https://legal.carzon.md/support/
CARZON_PRIVACY_CHOICES_URL=https://legal.carzon.md/privacy-choices/
CARZON_SUPPORT_EMAIL=support@carzon.md
''',
      );

      expect(Env.privacyPolicyUrl, 'https://legal.carzon.md/privacy/');
      expect(Env.termsOfServiceUrl, 'https://legal.carzon.md/terms/');
      expect(Env.supportUrl, 'https://legal.carzon.md/support/');
      expect(Env.privacyChoicesUrl, 'https://legal.carzon.md/privacy-choices/');
      expect(Env.supportEmail, 'support@carzon.md');
    });
  });

  group('Env listing sharing configuration', () {
    test('is unavailable when the optional base URL is absent', () {
      expect(Env.listingShareBaseUrl, isNull);
      expect(Env.listingSharingEnabled, isFalse);
    });

    test('is available for a production HTTPS base URL', () {
      dotenv.testLoad(
        fileInput: 'CARZON_LISTING_SHARE_BASE_URL=https://carzon.md',
      );

      expect(Env.listingShareBaseUrl, 'https://carzon.md');
      expect(Env.listingSharingEnabled, isTrue);
    });
  });

  group('Env.releaseConfigurationIssues', () {
    test('accepts a complete production release configuration', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://project.supabase.co
SUPABASE_ANON_KEY=anon
SUPABASE_PASSWORD_RESET_REDIRECT_URL=carzon://auth-callback
CARZON_SUPPORT_EMAIL=support@carzon.md
CARZON_LISTING_SHARE_BASE_URL=https://carzon.md
PUSH_NOTIFICATIONS_ENABLED=false
''',
      );

      expect(Env.releaseConfigurationIssues(), isEmpty);
      expect(Env.supportEmail, 'support@carzon.md');
    });

    test('accepts a production release with listing sharing absent', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://project.supabase.co
SUPABASE_ANON_KEY=anon
SUPABASE_PASSWORD_RESET_REDIRECT_URL=carzon://auth-callback
PUSH_NOTIFICATIONS_ENABLED=false
''',
      );

      expect(Env.releaseConfigurationIssues(), isEmpty);
      expect(Env.listingSharingEnabled, isFalse);
    });

    test('canonical legal defaults need no temporary release defines', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://project.supabase.co
SUPABASE_ANON_KEY=anon
''',
      );

      expect(
        Env.releaseConfigurationIssues(),
        containsAll(<String>[
          'SUPABASE_PASSWORD_RESET_REDIRECT_URL',
          'PUSH_NOTIFICATIONS_ENABLED',
        ]),
      );
      expect(
        Env.releaseConfigurationIssues(),
        isNot(contains('CARZON_LISTING_SHARE_BASE_URL')),
      );
      for (final legalKey in <String>[
        'CARZON_SUPPORT_EMAIL',
        'CARZON_PRIVACY_POLICY_URL',
        'CARZON_TERMS_OF_SERVICE_URL',
        'CARZON_SUPPORT_URL',
        'CARZON_PRIVACY_CHOICES_URL',
      ]) {
        expect(Env.releaseConfigurationIssues(), isNot(contains(legalKey)));
      }
    });

    test('rejects placeholder contacts and non-production web URLs', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://project.supabase.co
SUPABASE_ANON_KEY=anon
SUPABASE_PASSWORD_RESET_REDIRECT_URL=https://reset.example/callback
CARZON_SUPPORT_EMAIL=support@example.com
CARZON_PRIVACY_POLICY_URL=http://localhost/privacy/
CARZON_TERMS_OF_SERVICE_URL=https://example.com/terms/
CARZON_SUPPORT_URL=https://placeholder.test/support/
CARZON_PRIVACY_CHOICES_URL=https://legal.carzon.md/wrong-path/
CARZON_REPORT_EMAIL=reports@placeholder.test
CARZON_LISTING_SHARE_BASE_URL=http://localhost:8080
PUSH_NOTIFICATIONS_ENABLED=1
''',
      );

      expect(
        Env.releaseConfigurationIssues(),
        containsAll(<String>[
          'CARZON_SUPPORT_EMAIL',
          'CARZON_PRIVACY_POLICY_URL',
          'CARZON_TERMS_OF_SERVICE_URL',
          'CARZON_SUPPORT_URL',
          'CARZON_PRIVACY_CHOICES_URL',
          'SUPABASE_PASSWORD_RESET_REDIRECT_URL',
          'CARZON_REPORT_EMAIL',
          'CARZON_LISTING_SHARE_BASE_URL',
          'PUSH_NOTIFICATIONS_ENABLED',
        ]),
      );
    });

    test('rejects malformed configured listing share bases', () {
      for (final value in <String>[
        'http://localhost:8080',
        'https://example.com',
        'https://placeholder.test',
        'not-a-url',
        'https://user@carzon.md',
        'https://carzon.md?source=share',
        'https://carzon.md#listings',
      ]) {
        final configuredValue = value.contains('#') ? '"$value"' : value;
        dotenv.testLoad(
          fileInput:
              '''
SUPABASE_PASSWORD_RESET_REDIRECT_URL=carzon://auth-callback
CARZON_LISTING_SHARE_BASE_URL=$configuredValue
PUSH_NOTIFICATIONS_ENABLED=false
''',
        );

        expect(
          Env.releaseConfigurationIssues(),
          contains('CARZON_LISTING_SHARE_BASE_URL'),
          reason: value,
        );
        expect(Env.listingSharingEnabled, isFalse, reason: value);
      }
    });

    test('keeps other release values required when sharing is absent', () {
      expect(
        Env.releaseConfigurationIssues(),
        containsAll(<String>[
          'SUPABASE_PASSWORD_RESET_REDIRECT_URL',
          'PUSH_NOTIFICATIONS_ENABLED',
        ]),
      );
      expect(
        Env.releaseConfigurationIssues(),
        isNot(contains('CARZON_LISTING_SHARE_BASE_URL')),
      );
    });
  });

  group('Env.missingKeys', () {
    test('does not flag a missing CARZON_REPORT_EMAIL as missing', () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
      );
      expect(Env.missingKeys(), isEmpty);
    });

    test('flags missing required Supabase keys', () {
      dotenv.testLoad(
        fileInput: '''
CARZON_REPORT_EMAIL=reports@example.com
''',
      );
      expect(
        Env.missingKeys(),
        containsAll(<String>['SUPABASE_URL', 'SUPABASE_ANON_KEY']),
      );
    });
  });
}
