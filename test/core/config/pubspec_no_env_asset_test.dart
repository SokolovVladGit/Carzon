import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression: env files must never be bundled as Flutter assets.
void main() {
  test('pubspec.yaml does not list env files under flutter assets', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lines = pubspec.split('\n');
    var inAssets = false;
    final forbidden = <String>[
      '.env',
      '.env.client',
      '.env.local',
      '.env.client.local',
    ];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed == 'assets:') {
        inAssets = true;
        continue;
      }
      if (inAssets) {
        if (trimmed.isNotEmpty &&
            !trimmed.startsWith('-') &&
            !trimmed.startsWith('#')) {
          inAssets = false;
          continue;
        }
        if (trimmed.startsWith('-')) {
          final asset = trimmed.substring(1).trim();
          for (final name in forbidden) {
            expect(
              asset,
              isNot(equals(name)),
              reason: 'Remove $name from pubspec.yaml flutter assets',
            );
          }
          expect(
            asset.contains('.env'),
            isFalse,
            reason: 'Env-like asset "$asset" must not be bundled',
          );
        }
      }
    }
  });
}
