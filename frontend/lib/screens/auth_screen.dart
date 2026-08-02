import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';
import 'map_screen.dart';

/// Pulls the backend's actual validation/error message out of an
/// [ApiException] instead of showing a generic "server unreachable" message
/// for what's really a 400 (e.g. missing name, malformed email). Also
/// surfaces plain [Exception] messages (e.g. Google sign-in config errors)
/// rather than flattening everything to the same connectivity message.
String describeAuthError(Object e) {
  if (e is ApiException) {
    try {
      final body = jsonDecode(e.body) as Map<String, dynamic>;
      final message = body['message'];
      if (message is List && message.isNotEmpty) return message.first.toString();
      if (message is String) return message;
    } catch (_) {
      // Fall through to the generic message below.
    }
    return 'Request failed (${e.status}). Please try again.';
  }
  if (e is SocketException || e is TimeoutException) {
    return 'Could not reach server. Is the backend running?';
  }
  if (e is Exception) {
    final msg = e.toString();
    return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
  }
  return 'Could not reach server. Is the backend running?';
}

enum AuthMode { login, signup }

/// Collects email (and name on signup), requests an OTP, then routes to
/// [OtpScreen]. Shared by both log in and sign up.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode});
  final AuthMode mode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _isSignup => widget.mode == AuthMode.signup;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    if (_isSignup && _name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your name');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final devCode = await ref.read(authProvider.notifier).requestOtp(
            email: email,
            name: _isSignup ? _name.text.trim() : null,
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(email: email, devCode: devCode),
        ),
      );
    } catch (e) {
      setState(() => _error = describeAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on GoogleSignInCancelled {
      // User closed the account picker — not an error, nothing to show.
    } catch (e) {
      setState(() => _error = describeAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _skip() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignup ? 'Sign up' : 'Log in'),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('Skip',
                style: TextStyle(
                    color: ZoneColors.textMuted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isSignup ? 'Create your account' : 'Welcome back',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ZoneColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We will email you a 6-digit code to verify.',
                style: TextStyle(color: ZoneColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 28),
              if (_isSignup) ...[
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14)),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _continue,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: ZoneColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(color: ZoneColors.textMuted)),
                  ),
                  Expanded(child: Divider(color: ZoneColors.border)),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _loading ? null : _continueWithGoogle,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const _GoogleMark(),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZoneColors.textPrimary,
                  side: const BorderSide(color: ZoneColors.border),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small four-color "G" mark so the Google button reads as Google without
/// pulling in a real OAuth SDK or a network-fetched logo asset.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final stroke = r * 0.72;
    final rect = Rect.fromCircle(center: center, radius: r - stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    const twoPi = 6.283185307;
    paint.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, -0.35, twoPi / 4, false, paint);
    paint.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, twoPi / 4 - 0.35, twoPi / 4, false, paint);
    paint.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, twoPi / 2 - 0.35, twoPi / 4, false, paint);
    paint.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, 3 * twoPi / 4 - 0.35, twoPi / 4, false, paint);

    // Horizontal bar of the "G".
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - stroke * 0.22, r - stroke * 0.1,
          stroke * 0.44),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
