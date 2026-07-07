import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/auth_screen.dart';

/// Shown in place of a feature that requires an account (Create, Activity,
/// Profile) when the user reached the map via "Skip" and hasn't signed in.
class SignInGate extends StatelessWidget {
  const SignInGate({super.key, required this.message, this.onBack});
  final String message;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ZoneColors.sellTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.lock_outline,
                    color: ZoneColors.primary, size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign in required',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ZoneColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                    color: ZoneColors.textMuted, fontSize: 15, height: 1.4),
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
