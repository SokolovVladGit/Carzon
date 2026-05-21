import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression: `.env.client.example` stays commit-safe (placeholders only).
void main() {
  const forbiddenKeyPatterns = <String>[
    'SERVICE_ROLE',
    'FCM_SERVICE_ACCOUNT_JSON',
    'FCM_PRIVATE_KEY',
    'FCM_CLIENT_EMAIL',
    'FCM_PROJECT_ID',
    'CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET',
    'CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET',
    'CARZON_PROCESS_VIN_DECODE_JOBS_SECRET',
    'PRIVATE_KEY',
    'BEGIN PRIVATE KEY',
    'VIN_PROVIDER',
    'INTERNAL_SECRET',
    'FIREBASE_PRIVATE_KEY',
  ];

  test('.env.client.example has no server-only key assignments', () {
    final file = File('.env.client.example');
    expect(file.existsSync(), isTrue, reason: 'Template must exist in repo');

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final eq = trimmed.indexOf('=');
      expect(eq, greaterThan(0), reason: 'Line ${i + 1}: expected KEY=value');

      final key = trimmed.substring(0, eq).trim();
      final value = trimmed.substring(eq + 1).trim();

      for (final pattern in forbiddenKeyPatterns) {
        expect(
          key.toUpperCase(),
          isNot(contains(pattern)),
          reason: 'Line ${i + 1}: forbidden key pattern $pattern',
        );
      }

      if (key == 'SUPABASE_URL' || key == 'SUPABASE_ANON_KEY') {
        expect(
          value,
          isEmpty,
          reason: 'Line ${i + 1}: $key must be empty placeholder in example',
        );
      }
    }
  });
}
