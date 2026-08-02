import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/signal.dart';

/// Thin HTTP client for the Zone backend.
///
/// [baseUrl] defaults per-platform (Android emulator vs. everything else),
/// since "localhost" means different things to an emulator/simulator than to
/// the machine actually running the backend:
///  - Android emulator: http://10.0.2.2:3000/api (its alias for host loopback)
///  - iOS simulator / web / desktop: http://localhost:3000/api
///  - Physical device (either OS): http://<your-machine-lan-ip>:3000/api —
///    cannot be auto-detected, so pass it explicitly, e.g.:
///    flutter run --dart-define=API_BASE_URL=http://192.168.1.23:3000/api
class ApiService {
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  final String baseUrl;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ---- Auth ---------------------------------------------------------------

  Future<String?> requestOtp({required String email, String? name}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/request-otp'),
      headers: _headers,
      body: jsonEncode({'email': email, if (name != null) 'name': name}),
    );
    _ensureOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['devCode'] as String?; // present in mock mode
  }

  Future<({String token, UserProfile user})> verifyOtp({
    required String email,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _headers,
      body: jsonEncode({'email': email, 'code': code}),
    );
    _ensureOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final token = body['token'] as String;
    _token = token;
    return (
      token: token,
      user: UserProfile.fromJson(body['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, UserProfile user})> googleSignIn({
    required String idToken,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: _headers,
      body: jsonEncode({'idToken': idToken}),
    );
    _ensureOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final token = body['token'] as String;
    _token = token;
    return (
      token: token,
      user: UserProfile.fromJson(body['user'] as Map<String, dynamic>),
    );
  }

  // ---- Identity -----------------------------------------------------------

  Future<UserProfile> submitKyc() async {
    final res = await http.post(
      Uri.parse('$baseUrl/me/kyc'),
      headers: _headers,
    );
    _ensureOk(res);
    return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ---- Signals ------------------------------------------------------------

  Future<List<Signal>> nearby({
    required double lat,
    required double lng,
    int range = 1000,
  }) async {
    final uri = Uri.parse('$baseUrl/signals/nearby').replace(queryParameters: {
      'lat': '$lat',
      'lng': '$lng',
      'range': '$range',
    });
    final res = await http.get(uri, headers: _headers);
    _ensureOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Signal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Signal> createSignal({
    required String message,
    required SignalType type,
    required int radiusMeters,
    required double lat,
    required double lng,
    required int expiresInMinutes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/signals'),
      headers: _headers,
      body: jsonEncode({
        'message': message,
        'type': type.wire,
        'radiusMeters': radiusMeters,
        'lat': lat,
        'lng': lng,
        'expiresInMinutes': expiresInMinutes,
      }),
    );
    _ensureOk(res);
    return Signal.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Signal> acceptSignal(String id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/signals/$id/accept'),
      headers: _headers,
    );
    _ensureOk(res);
    return Signal.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
  }
}

class ApiException implements Exception {
  final int status;
  final String body;
  ApiException(this.status, this.body);
  @override
  String toString() => 'ApiException($status): $body';
}
