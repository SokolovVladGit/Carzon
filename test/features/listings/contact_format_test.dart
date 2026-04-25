import 'package:carzon/features/listings/presentation/utils/contact_format.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  group('validatePhone', () {
    test('rejects empty', () {
      expect(validatePhone(l10n, null), isNotNull);
      expect(validatePhone(l10n, ''), isNotNull);
      expect(validatePhone(l10n, '   '), isNotNull);
    });

    test('rejects non-phone characters', () {
      expect(validatePhone(l10n, 'call me'), isNotNull);
      expect(validatePhone(l10n, '+373abc'), isNotNull);
    });

    test('rejects too-short digit counts', () {
      expect(validatePhone(l10n, '123'), isNotNull);
      expect(validatePhone(l10n, '12-34-56'), isNotNull); // 6 digits
    });

    test('accepts common human formats', () {
      expect(validatePhone(l10n, '+373 690 12345'), isNull);
      expect(validatePhone(l10n, '(069) 000-001'), isNull);
      expect(validatePhone(l10n, '0690.12345'), isNull);
    });
  });

  group('validateTelegramUsername', () {
    test('empty is valid (optional field)', () {
      expect(validateTelegramUsername(l10n, null), isNull);
      expect(validateTelegramUsername(l10n, ''), isNull);
      expect(validateTelegramUsername(l10n, '  '), isNull);
    });

    test('rejects wrong length or invalid chars', () {
      expect(validateTelegramUsername(l10n, 'abc'), isNotNull); // too short
      expect(validateTelegramUsername(l10n, 'a' * 33), isNotNull); // too long
      expect(validateTelegramUsername(l10n, 'has space'), isNotNull);
      expect(validateTelegramUsername(l10n, 'has-dash'), isNotNull);
    });

    test('accepts with or without leading @', () {
      expect(validateTelegramUsername(l10n, 'carzon_dev'), isNull);
      expect(validateTelegramUsername(l10n, '@carzon_dev'), isNull);
      expect(validateTelegramUsername(l10n, 'A1_b2'), isNull);
    });
  });

  group('normalizeTelegramUsername', () {
    test('null/empty returns null', () {
      expect(normalizeTelegramUsername(null), isNull);
      expect(normalizeTelegramUsername(''), isNull);
      expect(normalizeTelegramUsername('   '), isNull);
    });

    test('strips leading @ and trims', () {
      expect(normalizeTelegramUsername('@user_01'), 'user_01');
      expect(normalizeTelegramUsername(' user_01 '), 'user_01');
      expect(normalizeTelegramUsername('@ '), isNull);
    });
  });

  group('whatsappDigits', () {
    test('null/empty/too-short returns null', () {
      expect(whatsappDigits(null), isNull);
      expect(whatsappDigits(''), isNull);
      expect(whatsappDigits('123'), isNull);
    });

    test('preserves international numbers starting with +', () {
      expect(whatsappDigits('+373 690 12345'), '37369012345');
      expect(whatsappDigits('+1 (212) 555-7777'), '12125557777');
    });

    test('keeps number that already starts with default country code', () {
      expect(whatsappDigits('373 690 12345'), '37369012345');
    });

    test('prepends default country code for local numbers, stripping '
        'leading trunk 0', () {
      expect(whatsappDigits('069012345'), '37369012345');
      expect(whatsappDigits('077500004'), '37377500004');
      expect(whatsappDigits('69012345'), '37369012345');
    });

    test('treats 10+ digit numbers as international', () {
      expect(whatsappDigits('12125557777'), '12125557777');
    });
  });

  group('telUriString', () {
    test('empty or unusable returns null', () {
      expect(telUriString(null), isNull);
      expect(telUriString(''), isNull);
      expect(telUriString('123'), isNull);
    });

    test('keeps + when present', () {
      expect(telUriString('+373 690 12345'), 'tel:+37369012345');
    });

    test('bare digits yield bare tel URI', () {
      expect(telUriString('069012345'), 'tel:069012345');
    });
  });
}
