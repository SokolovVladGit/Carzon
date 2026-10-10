import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/social/apple_native_auth.dart';
import '../../domain/social/apple_nonce.dart';
import '../../domain/social/social_auth_error_mapper.dart';

typedef AppleCredentialRequest =
    Future<AuthorizationCredentialAppleID> Function({required String nonce});

/// Native Sign in with Apple. Hashes a raw nonce for Apple, returns the raw
/// nonce for Supabase `signInWithIdToken`.
class AppleSignInAdapter implements AppleNativeAuth {
  AppleSignInAdapter({
    String Function()? generateRawNonce,
    AppleCredentialRequest? requestCredential,
  }) : _generateRawNonce = generateRawNonce ?? AppleNonce.generateRaw,
       _requestCredential = requestCredential ?? _defaultRequest;

  final String Function() _generateRawNonce;
  final AppleCredentialRequest _requestCredential;

  static Future<AuthorizationCredentialAppleID> _defaultRequest({
    required String nonce,
  }) {
    return SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
  }

  @override
  Future<AppleNativeAuthResult> authenticate() async {
    final rawNonce = _generateRawNonce();
    final hashedNonce = AppleNonce.sha256Hash(rawNonce);

    try {
      final credential = await _requestCredential(nonce: hashedNonce);
      final idToken = credential.identityToken?.trim() ?? '';
      if (idToken.isEmpty) {
        throw AuthException(SocialAuthMessages.appleMissingToken);
      }
      return AppleNativeAuthResult(
        idToken: idToken,
        rawNonce: rawNonce,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on AuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e, st) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthCancelledException();
      }
      throw AuthException(
        SocialAuthMessages.appleFailed,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is AuthCancelledException) rethrow;
      throw AuthException(
        SocialAuthMessages.appleFailed,
        cause: e,
        stackTrace: st,
      );
    }
  }
}
