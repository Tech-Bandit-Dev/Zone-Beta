import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/google_auth_config.dart';
import '../models/signal.dart';
import '../services/api_service.dart';

/// Thrown when the user closes the Google account picker without choosing
/// one — not a failure, just means "stay on the auth screen".
class GoogleSignInCancelled implements Exception {}

/// Single API client for the app. Override baseUrl here if needed.
final apiProvider = Provider<ApiService>((ref) => ApiService());

/// The signed-in user (null when logged out).
final authProvider =
    StateNotifierProvider<AuthNotifier, UserProfile?>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<UserProfile?> {
  AuthNotifier(this._ref) : super(null);
  final Ref _ref;

  Future<String?> requestOtp({required String phone, String? name}) {
    return _ref.read(apiProvider).requestOtp(phone: phone, name: name);
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    final result =
        await _ref.read(apiProvider).verifyOtp(phone: phone, code: code);
    _ref.read(apiProvider).setToken(result.token);
    state = result.user;
  }

  /// Opens the native Google account picker, then exchanges the resulting
  /// ID token with the backend (which verifies it against Google) for a
  /// Zone session. Requires GOOGLE_SERVER_CLIENT_ID to be set — see
  /// frontend/README.md "Google Sign-In setup".
  Future<void> loginWithGoogle() async {
    if (!GoogleAuthConfig.isConfigured) {
      throw Exception(
        'Google sign-in is not configured. Set GOOGLE_SERVER_CLIENT_ID '
        '(see frontend/README.md "Google Sign-In setup").',
      );
    }

    final googleSignIn =
        GoogleSignIn(serverClientId: GoogleAuthConfig.serverClientId);
    GoogleSignInAccount? account;
    try {
      account = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      // Historically 'sign_in_canceled'; treat any cancel-shaped code the
      // same way rather than surfacing it as an error.
      if (e.code.contains('canceled') || e.code.contains('cancelled')) {
        throw GoogleSignInCancelled();
      }
      rethrow;
    }
    if (account == null) throw GoogleSignInCancelled();

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception(
        'Google did not return an ID token. Check that GOOGLE_SERVER_CLIENT_ID '
        'is the Web client ID (not Android/iOS) from Google Cloud Console.',
      );
    }

    final result = await _ref.read(apiProvider).googleSignIn(idToken: idToken);
    _ref.read(apiProvider).setToken(result.token);
    state = result.user;
  }

  Future<void> submitKyc() async {
    try {
      final updated = await _ref.read(apiProvider).submitKyc();
      state = updated;
    } catch (_) {
      // Offline/mock fallback: upgrade locally so the badge updates.
      final u = state;
      if (u != null) {
        state = UserProfile(
          id: u.id,
          name: u.name,
          phone: u.phone,
          email: u.email,
          avatarUrl: u.avatarUrl,
          rating: u.rating,
          verification: VerificationTier.kyc,
        );
      }
    }
  }

  void logout() {
    _ref.read(apiProvider).setToken(null);
    state = null;
  }
}

/// Signals currently shown on the map. Backed by the API; falls back to an
/// empty list if the backend isn't reachable (so the UI still renders).
final signalsProvider =
    StateNotifierProvider<SignalsNotifier, List<Signal>>((ref) {
  return SignalsNotifier(ref);
});

class SignalsNotifier extends StateNotifier<List<Signal>> {
  SignalsNotifier(this._ref) : super(const []);
  final Ref _ref;

  Future<void> loadNearby({
    required double lat,
    required double lng,
    int range = 1000,
  }) async {
    try {
      final list =
          await _ref.read(apiProvider).nearby(lat: lat, lng: lng, range: range);
      state = list;
    } catch (_) {
      // Keep whatever we have; the map still shows the "you" marker.
    }
  }

  /// Optimistically add a locally created signal so the pin appears instantly.
  void addLocal(Signal s) => state = [s, ...state];

  void replace(Signal s) =>
      state = [for (final x in state) if (x.id == s.id) s else x];
}
