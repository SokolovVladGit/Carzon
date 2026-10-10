import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/features/auth/data/social/apple_sign_in_adapter.dart';
import 'package:carzon/features/auth/domain/social/apple_nonce.dart';
import 'package:carzon/features/auth/domain/social/social_auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  test(
    'hashes the raw nonce before calling Apple and returns the raw nonce',
    () async {
      String? sentNonce;
      final adapter = AppleSignInAdapter(
        generateRawNonce: () => 'raw-nonce-value',
        requestCredential: ({required String nonce}) async {
          sentNonce = nonce;
          return const AuthorizationCredentialAppleID(
            userIdentifier: 'user',
            givenName: 'Ion',
            familyName: 'Popescu',
            email: 'a@b.c',
            identityToken: 'identity-token',
            authorizationCode: 'code',
            state: null,
          );
        },
      );

      final result = await adapter.authenticate();

      expect(sentNonce, AppleNonce.sha256Hash('raw-nonce-value'));
      expect(result.idToken, 'identity-token');
      expect(result.rawNonce, 'raw-nonce-value');
      expect(result.fullName, 'Ion Popescu');
    },
  );

  test('missing identity token throws', () async {
    final adapter = AppleSignInAdapter(
      generateRawNonce: () => 'raw',
      requestCredential: ({required String nonce}) async {
        return const AuthorizationCredentialAppleID(
          userIdentifier: 'user',
          givenName: null,
          familyName: null,
          email: null,
          identityToken: null,
          authorizationCode: 'code',
          state: null,
        );
      },
    );

    expect(
      () => adapter.authenticate(),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          SocialAuthMessages.appleMissingToken,
        ),
      ),
    );
  });

  test('user cancellation is not a technical error', () async {
    final adapter = AppleSignInAdapter(
      generateRawNonce: () => 'raw',
      requestCredential: ({required String nonce}) async {
        throw const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'canceled',
        );
      },
    );

    expect(adapter.authenticate(), throwsA(isA<AuthCancelledException>()));
  });
}
