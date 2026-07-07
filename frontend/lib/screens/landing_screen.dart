import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// Pre-auth home page. Branding + log in / sign up entry points.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // Logo mark.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ZoneColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.my_location,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              const Text(
                'Zone',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: ZoneColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The last minute.',
                style: TextStyle(
                  fontSize: 20,
                  color: ZoneColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Post what you need right now — a cab to share, an '
                'errand, a handoff. Anyone nearby can jump in.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: ZoneColors.textMuted,
                ),
              ),
              const Spacer(flex: 3),
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
