/// Tokens from the native Google Sign-In SDK. Never obtained via browser OAuth.
class GoogleNativeTokens {
  const GoogleNativeTokens({required this.idToken, required this.accessToken});

  final String idToken;
  final String accessToken;
}

/// Platform adapter. Presentation and use cases never call the SDK.
abstract interface class GoogleNativeAuth {
  Future<GoogleNativeTokens> authenticate();
}
