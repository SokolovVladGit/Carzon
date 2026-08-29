import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client-safe compile-time configuration.
///
/// Values must be passed via `--dart-define` or
/// `--dart-define-from-file=.env.client` (see `.env.client.example`).
/// Each key uses a **literal** [String.fromEnvironment] — dynamic key lookup
/// does not receive compile-time defines.
///
/// Widget tests may call [dotenv.testLoad] when compile-time defines are empty;
/// that path is never used at app startup.
class Env {
  Env._();

  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _passwordResetRedirectUrl = String.fromEnvironment(
    'SUPABASE_PASSWORD_RESET_REDIRECT_URL',
  );
  static const String _reportEmail = String.fromEnvironment(
    'CARZON_REPORT_EMAIL',
  );
  static const String _supportEmail = String.fromEnvironment(
    'CARZON_SUPPORT_EMAIL',
  );
  static const String _privacyPolicyUrl = String.fromEnvironment(
    'CARZON_PRIVACY_POLICY_URL',
  );
  static const String _termsOfServiceUrl = String.fromEnvironment(
    'CARZON_TERMS_OF_SERVICE_URL',
  );
  static const String _supportUrl = String.fromEnvironment(
    'CARZON_SUPPORT_URL',
  );
  static const String _privacyChoicesUrl = String.fromEnvironment(
    'CARZON_PRIVACY_CHOICES_URL',
  );
  static const String _pushNotificationsEnabled = String.fromEnvironment(
    'PUSH_NOTIFICATIONS_ENABLED',
  );
  static const String _listingShareBaseUrl = String.fromEnvironment(
    'CARZON_LISTING_SHARE_BASE_URL',
  );

  /// Keys the app cannot run without.
  static const List<String> requiredKeys = <String>[
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
  ];

  static String get supabaseUrl => _required(_supabaseUrl, 'SUPABASE_URL');

  static String get supabaseAnonKey =>
      _required(_supabaseAnonKey, 'SUPABASE_ANON_KEY');

  /// Optional deep-link target for password-reset / email-confirmation emails.
  static String? get passwordResetRedirectUrl => _optionalNonEmpty(
    _passwordResetRedirectUrl,
    'SUPABASE_PASSWORD_RESET_REDIRECT_URL',
  );

  /// Optional mailto destination for in-app listing reports; hidden when absent.
  static String? get reportEmail {
    final value = _optionalNonEmpty(_reportEmail, 'CARZON_REPORT_EMAIL');
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static const String defaultPrivacyPolicyUrl =
      'https://carzon-legal.netlify.app/privacy/';
  static const String defaultTermsOfServiceUrl =
      'https://carzon-legal.netlify.app/terms/';
  static const String defaultSupportUrl =
      'https://carzon-legal.netlify.app/support/';
  static const String defaultPrivacyChoicesUrl =
      'https://carzon-legal.netlify.app/privacy-choices/';
  static const String defaultSupportEmail = 'carzonsupport@gmail.com';

  /// Canonical public legal/support endpoints. Compile-time defines may
  /// override them for another owned production host.
  static String get privacyPolicyUrl => _configuredOrDefault(
    _privacyPolicyUrl,
    'CARZON_PRIVACY_POLICY_URL',
    defaultPrivacyPolicyUrl,
  );

  static String get termsOfServiceUrl => _configuredOrDefault(
    _termsOfServiceUrl,
    'CARZON_TERMS_OF_SERVICE_URL',
    defaultTermsOfServiceUrl,
  );

  static String get supportUrl => _configuredOrDefault(
    _supportUrl,
    'CARZON_SUPPORT_URL',
    defaultSupportUrl,
  );

  static String get privacyChoicesUrl => _configuredOrDefault(
    _privacyChoicesUrl,
    'CARZON_PRIVACY_CHOICES_URL',
    defaultPrivacyChoicesUrl,
  );

  /// Public contact destination used before login and as an email support
  /// route.
  static String get supportEmail => _configuredOrDefault(
    _supportEmail,
    'CARZON_SUPPORT_EMAIL',
    defaultSupportEmail,
  );

  /// Optional public web base for listing share links.
  ///
  /// The first release leaves this unset until an owner-controlled public
  /// listing surface exists. Widgets should use [listingSharingEnabled]
  /// rather than treating a non-empty value as sufficient.
  static String? get listingShareBaseUrl =>
      _optionalNonEmpty(_listingShareBaseUrl, 'CARZON_LISTING_SHARE_BASE_URL');

  /// Whether the build has a production-safe public listing destination.
  static bool get listingSharingEnabled {
    final value = listingShareBaseUrl;
    return value != null && _isProductionListingShareBaseUrl(value);
  }

  /// Client FCM bootstrap flag. Default **false** when unset or empty.
  static bool get pushNotificationsEnabled {
    final raw = _optionalNonEmpty(
      _pushNotificationsEnabled,
      'PUSH_NOTIFICATIONS_ENABLED',
    );
    if (raw == null) return false;
    switch (raw.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }

  /// Required keys missing from compile-time defines (and test dotenv fallback).
  static List<String> missingKeys() {
    final missing = <String>[];
    if (_isMissing(_supabaseUrl, 'SUPABASE_URL')) {
      missing.add('SUPABASE_URL');
    }
    if (_isMissing(_supabaseAnonKey, 'SUPABASE_ANON_KEY')) {
      missing.add('SUPABASE_ANON_KEY');
    }
    return missing;
  }

  /// Deterministic App Store release checks. These are intentionally stricter
  /// than debug startup requirements and contain no secrets.
  static List<String> releaseConfigurationIssues() {
    final issues = <String>[];
    if (!_looksLikeProductionEmail(supportEmail)) {
      issues.add('CARZON_SUPPORT_EMAIL');
    }

    if (!_isProductionLegalUrl(privacyPolicyUrl, '/privacy/')) {
      issues.add('CARZON_PRIVACY_POLICY_URL');
    }
    if (!_isProductionLegalUrl(termsOfServiceUrl, '/terms/')) {
      issues.add('CARZON_TERMS_OF_SERVICE_URL');
    }
    if (!_isProductionLegalUrl(supportUrl, '/support/')) {
      issues.add('CARZON_SUPPORT_URL');
    }
    if (!_isProductionLegalUrl(privacyChoicesUrl, '/privacy-choices/')) {
      issues.add('CARZON_PRIVACY_CHOICES_URL');
    }

    final reset = passwordResetRedirectUrl;
    if (reset == null || !_isAllowedPasswordResetUrl(reset)) {
      issues.add('SUPABASE_PASSWORD_RESET_REDIRECT_URL');
    }

    final share = listingShareBaseUrl;
    if (share != null && !_isProductionListingShareBaseUrl(share)) {
      issues.add('CARZON_LISTING_SHARE_BASE_URL');
    }

    final push = _optionalNonEmpty(
      _pushNotificationsEnabled,
      'PUSH_NOTIFICATIONS_ENABLED',
    )?.trim().toLowerCase();
    if (push != 'true' && push != 'false') {
      issues.add('PUSH_NOTIFICATIONS_ENABLED');
    }

    final legacyReport = reportEmail;
    if (legacyReport != null && !_looksLikeProductionEmail(legacyReport)) {
      issues.add('CARZON_REPORT_EMAIL');
    }
    return issues;
  }

  static bool _looksLikeProductionEmail(String value) {
    final lower = value.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(lower)) {
      return false;
    }
    return !lower.endsWith('.example') &&
        !lower.contains('@example.') &&
        !lower.contains('placeholder');
  }

  static bool _isAllowedPasswordResetUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) return false;
    if (uri.scheme == 'carzon') return uri.host == 'auth-callback';
    return _isProductionHttpsUrl(value);
  }

  static bool _isProductionHttpsUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return host != 'localhost' &&
        host != 'example.com' &&
        !host.endsWith('.example.com') &&
        !host.endsWith('.example') &&
        !host.endsWith('.test') &&
        !host.contains('placeholder');
  }

  static bool _isProductionListingShareBaseUrl(String value) {
    if (!_isProductionHttpsUrl(value)) return false;
    final uri = Uri.parse(value.trim());
    return uri.userInfo.isEmpty && !uri.hasQuery && !uri.hasFragment;
  }

  static bool _isProductionLegalUrl(String value, String expectedPath) {
    if (!_isProductionHttpsUrl(value)) return false;
    final uri = Uri.parse(value.trim());
    return uri.path == expectedPath &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        uri.userInfo.isEmpty;
  }

  static bool _isMissing(String compiled, String dotenvKey) {
    if (compiled.isNotEmpty) return false;
    final test = _testDotenvValue(dotenvKey);
    return test == null || test.isEmpty;
  }

  static String _required(String compiled, String dotenvKey) {
    if (compiled.isNotEmpty) return compiled;
    final test = _testDotenvValue(dotenvKey);
    if (test != null && test.isNotEmpty) return test;
    throw StateError(
      'Missing required environment variable: $dotenvKey. '
      'Copy .env.client.example to .env.client, fill client-safe values, '
      'and run with --dart-define-from-file=.env.client',
    );
  }

  static String? _optionalNonEmpty(String compiled, String dotenvKey) {
    if (compiled.isNotEmpty) return compiled;
    final test = _testDotenvValue(dotenvKey);
    if (test == null || test.isEmpty) return null;
    return test;
  }

  static String _configuredOrDefault(
    String compiled,
    String dotenvKey,
    String fallback,
  ) => _optionalNonEmpty(compiled, dotenvKey)?.trim() ?? fallback;

  static String? _testDotenvValue(String key) {
    try {
      return dotenv.maybeGet(key);
    } catch (_) {
      return null;
    }
  }
}
