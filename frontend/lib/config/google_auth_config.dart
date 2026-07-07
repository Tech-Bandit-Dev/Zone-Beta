/// Google Sign-In configuration.
///
/// [serverClientId] must be the **Web application** OAuth client ID from
/// Google Cloud Console (not the Android/iOS client) — it's what makes
/// Google hand back an ID token the backend can verify. Without it,
/// GoogleSignIn still lets the user pick an account, but `idToken` comes
/// back null and sign-in fails.
///
/// Set it at build/run time so the ID never has to be hardcoded here:
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-client-id.apps.googleusercontent.com
///
/// See frontend/README.md "Google Sign-In setup" for the full Cloud Console
/// walkthrough (OAuth consent screen, Android/iOS/Web client IDs, SHA-1).
class GoogleAuthConfig {
  static const serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static bool get isConfigured => serverClientId.isNotEmpty;
}
