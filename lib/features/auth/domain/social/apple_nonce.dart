import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Secure Apple nonce. gotrue 2.20 has no `generateRawNonce` helper.
class AppleNonce {
  AppleNonce._();

  static const _charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

  static String generateRaw({int length = 32}) {
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => _charset[random.nextInt(_charset.length)],
    ).join();
  }

  static String sha256Hash(String rawNonce) {
    return sha256.convert(utf8.encode(rawNonce)).toString();
  }
}
