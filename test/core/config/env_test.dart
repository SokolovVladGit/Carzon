import 'package:carzon/core/config/env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Focused tests for `Env` — only cover the launch-readiness contract
/// that other layers rely on:
///   * required keys are exactly what the app refuses to boot without,
///   * `reportEmail` is optional and nullable,
///   * `missingKeys()` never lists optional keys.
void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
  });

  tearDown(() {
    dotenv.testLoad(fileInput: '');
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
      dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''');
      expect(Env.reportEmail, isNull);
    });

    test('is null when the env variable is set but empty', () {
      dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
CARZON_REPORT_EMAIL=
''');
      expect(Env.reportEmail, isNull);
    });

    test('trims whitespace and returns the configured address', () {
      dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
CARZON_REPORT_EMAIL=  reports@carzon.example  
''');
      expect(Env.reportEmail, 'reports@carzon.example');
    });
  });

  group('Env.missingKeys', () {
    test('does not flag a missing CARZON_REPORT_EMAIL as missing', () {
      dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''');
      expect(Env.missingKeys(), isEmpty);
    });

    test('flags missing required Supabase keys', () {
      dotenv.testLoad(fileInput: '''
CARZON_REPORT_EMAIL=reports@example.com
''');
      expect(
        Env.missingKeys(),
        containsAll(<String>['SUPABASE_URL', 'SUPABASE_ANON_KEY']),
      );
    });
  });
}
