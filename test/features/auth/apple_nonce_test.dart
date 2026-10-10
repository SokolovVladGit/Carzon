import 'dart:convert';

import 'package:carzon/features/auth/domain/social/apple_nonce.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generateRaw produces a unique 32-char nonce', () {
    final a = AppleNonce.generateRaw();
    final b = AppleNonce.generateRaw();
    expect(a.length, 32);
    expect(b.length, 32);
    expect(a, isNot(b));
  });

  test('sha256Hash is hex SHA-256 of the raw nonce', () {
    const raw = 'carzon-apple-nonce';
    expect(
      AppleNonce.sha256Hash(raw),
      sha256.convert(utf8.encode(raw)).toString(),
    );
  });
}
