import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/social/google_native_auth.dart';
import '../../domain/social/social_auth_error_mapper.dart';

/// Native Google Sign-In → ID token + access token. No browser OAuth.
class GoogleSignInAdapter implements GoogleNativeAuth {
  GoogleSignInAdapter({
    required this.webClientId,
    this.iosClientId,
    GoogleSignIn? signIn,
  }) : _signIn = signIn ?? GoogleSignIn.instance;

  final String webClientId;
  final String? iosClientId;
  final GoogleSignIn _signIn;

  bool _initialized = false;

  static const _scopes = <String>['email', 'profile'];

  @override
  Future<GoogleNativeTokens> authenticate() async {
    final web = webClientId.trim();
    if (web.isEmpty) {
      throw AuthException(SocialAuthMessages.googleNotConfigured);
    }

    await _ensureInitialized(web);

    try {
      final account = await _signIn.authenticate(scopeHint: _scopes);
      final idToken = account.authentication.idToken?.trim() ?? '';
      if (idToken.isEmpty) {
        throw AuthException(SocialAuthMessages.googleMissingToken);
      }

      final authorization =
          await account.authorizationClient.authorizationForScopes(_scopes) ??
          await account.authorizationClient.authorizeScopes(_scopes);
      final accessToken = authorization.accessToken.trim();
      if (accessToken.isEmpty) {
        throw AuthException(SocialAuthMessages.googleMissingToken);
      }

      return GoogleNativeTokens(idToken: idToken, accessToken: accessToken);
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e, st) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw AuthCancelledException();
      }
      throw AuthException(
        SocialAuthMessages.googleFailed,
        cause: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is AuthCancelledException) rethrow;
      throw AuthException(
        SocialAuthMessages.googleFailed,
        cause: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _ensureInitialized(String web) async {
    if (_initialized) return;
    final ios = iosClientId?.trim();
    await _signIn.initialize(
      clientId: (ios == null || ios.isEmpty) ? null : ios,
      serverClientId: web,
    );
    _initialized = true;
  }
}
