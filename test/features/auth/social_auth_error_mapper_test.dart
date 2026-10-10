import 'package:carzon/features/auth/domain/social/social_auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps known identity collision wording', () {
    expect(
      SocialAuthMessages.isIdentityCollision(
        'A user with this email address has already been registered',
      ),
      isTrue,
    );
    expect(
      SocialAuthMessages.isIdentityCollision(
        'identity_already_exists: email taken',
      ),
      isTrue,
    );
    expect(
      SocialAuthMessages.isIdentityCollision('Identity is already linked'),
      isTrue,
    );
    expect(
      SocialAuthMessages.isIdentityCollision('invalid login credentials'),
      isFalse,
    );
  });
}
