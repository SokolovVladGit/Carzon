import 'package:carzon/features/auth/data/models/auth_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing identities keep password-change visible', () {
    final user = AuthUserModel.fromSupabase({
      'id': 'u1',
      'email': 'a@b.c',
      'user_metadata': <String, dynamic>{},
    });
    expect(user.hasEmailPasswordIdentity, isTrue);
  });

  test('email identity is detected from identities', () {
    final user = AuthUserModel.fromSupabase({
      'id': 'u1',
      'email': 'a@b.c',
      'identities': [
        {'provider': 'google'},
        {'provider': 'email'},
      ],
    });
    expect(user.hasEmailPasswordIdentity, isTrue);
  });

  test('google-only identities hide password-change', () {
    final user = AuthUserModel.fromSupabase({
      'id': 'u1',
      'email': 'a@b.c',
      'identities': [
        {'provider': 'google'},
      ],
    });
    expect(user.hasEmailPasswordIdentity, isFalse);
  });
}
