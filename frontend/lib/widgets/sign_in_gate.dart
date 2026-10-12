import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/auth_screen.dart';

/// Shown in place of a feature that requires an account (Create, Activity,
/// Chat, Profile) when the user reached the map via "Skip" and hasn't signed
/// in. [showBack] is false when rendered as a tab, true when pushed.
class SignInGate extends StatelessWidget {
  const SignInGate({super.key, required this.message, this.showBack = true});
  final String message;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: showBack),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: zc.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(Icons.lock_outline_rounded,
                      color: zc.primary, size: 32),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: zc.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: zc.textMuted, fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AuthScreen(mode: AuthMode.signup),
                  ),
                ),
                child: const Text('Sign up'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AuthScreen(mode: AuthMode.login),
                  ),
                ),
                child: const Text('Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
