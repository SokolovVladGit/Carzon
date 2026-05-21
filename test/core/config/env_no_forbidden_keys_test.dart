import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression: Flutter [Env] must not reference server-only config keys.
void main() {
  const forbiddenPatterns = <String>[
    'SERVICE_ROLE',
    'FCM_SERVICE_ACCOUNT_JSON',
    'FCM_PRIVATE_KEY',
    'FCM_CLIENT_EMAIL',
    'FCM_PROJECT_ID',
    'CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET',
    'CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET',
    'CARZON_PROCESS_VIN_DECODE_JOBS_SECRET',
    'VIN_PROVIDER',
    'INTERNAL_SECRET',
    'FIREBASE_PRIVATE_KEY',
  ];

  test('lib/core/config/env.dart does not reference forbidden key names', () {
    final source = File('lib/core/config/env.dart').readAsStringSync();
    final codeLines = source
        .split('\n')
        .where((l) => !l.trim().startsWith('//'))
        .join('\n');

    for (final pattern in forbiddenPatterns) {
      expect(
        codeLines.toUpperCase(),
        isNot(contains(pattern)),
        reason: 'env.dart must not reference $pattern',
      );
    }
  });
}
