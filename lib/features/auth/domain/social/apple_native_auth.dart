/// Result of native Sign in with Apple. [fullName] is present only on first auth.
class AppleNativeAuthResult {
  const AppleNativeAuthResult({
    required this.idToken,
    required this.rawNonce,
    this.givenName,
    this.familyName,
  });

  final String idToken;
  final String rawNonce;
  final String? givenName;
  final String? familyName;

  String? get fullName {
    final parts = <String>[
      if (_trimmed(givenName) != null) _trimmed(givenName)!,
      if (_trimmed(familyName) != null) _trimmed(familyName)!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

/// Platform adapter. Presentation and use cases never call the SDK.
abstract interface class AppleNativeAuth {
  Future<AppleNativeAuthResult> authenticate();
}
