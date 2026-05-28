import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'app_ru.arb and app_ro.arb have matching message keys and placeholders',
    () {
      final ru =
          jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync())
              as Map<String, dynamic>;
      final ro =
          jsonDecode(File('lib/l10n/app_ro.arb').readAsStringSync())
              as Map<String, dynamic>;

      bool isMessageKey(String k) => !k.startsWith('@');

      final ruKeys = ru.keys.where(isMessageKey).toSet();
      final roKeys = ro.keys.where(isMessageKey).toSet();
      expect(roKeys, ruKeys);

      for (final key in ruKeys) {
        final ruMeta = ru['@$key'];
        final roMeta = ro['@$key'];
        if (ruMeta is Map && ruMeta.containsKey('placeholders')) {
          expect(roMeta, isA<Map>());
          expect(
            (roMeta as Map)['placeholders'],
            ruMeta['placeholders'],
            reason: key,
          );
        }
      }
    },
  );
}
