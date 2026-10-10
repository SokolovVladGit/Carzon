/// Stable failure tokens for social auth. Never shown raw in the UI.
abstract final class SocialAuthMessages {
  static const identityAlreadyExists = 'identity_already_exists';
  static const googleMissingToken = 'google_missing_token';
  static const appleMissingToken = 'apple_missing_token';
  static const googleFailed = 'google_sign_in_failed';
  static const appleFailed = 'apple_sign_in_failed';
  static const googleNotConfigured = 'google_not_configured';
  static const appleNotConfigured = 'apple_not_configured';

  static bool isIdentityCollision(String message) {
    final raw = message.toLowerCase();
    return raw.contains('identity_already_exists') ||
        raw.contains('identity is already linked') ||
        raw.contains('already linked to another') ||
        raw.contains('already registered') ||
        raw.contains('already been registered') ||
        raw.contains('user already exists') ||
        raw.contains('email address is already') ||
        raw.contains('a user with this email') ||
        (raw.contains('already exists') &&
            (raw.contains('provider') || raw.contains('identity')));
  }
}
