import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import '../state/app_state.dart';

/// Profile tab. Shows the signed-in user, verification tier, a mock KYC
/// upgrade, appearance setting, and logout. Rendered inside MapScreen's nav.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final zc = context.zc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _HeaderCard(user: user),
            const SizedBox(height: 16),
            const _StatsRow(),
            const SizedBox(height: 16),
            _VerificationCard(
              tier: user?.verification ?? VerificationTier.none,
              onVerify: () async {
                await ref.read(authProvider.notifier).submitKyc();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Verification submitted (mock)')),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Appearance'),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded, size: 18),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 18),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 18),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).state = s.first,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              style: OutlinedButton.styleFrom(
                foregroundColor: ZoneColors.danger,
                side: BorderSide(
                    color: ZoneColors.danger.withValues(alpha: 0.4)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Zone v0.1.0',
                  style: TextStyle(color: zc.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.zc.textMuted,
          ),
        ),
      );
}

/// Indigo gradient card with avatar, name and contact.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.user});
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Zone user';
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ZoneColors.primary, ZoneColors.primaryDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: ZoneColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  (user?.phone.isNotEmpty ?? false)
                      ? user!.phone
                      : user?.email ?? '',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.tier, required this.onVerify});
  final VerificationTier tier;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    final isKyc = tier == VerificationTier.kyc;
    final title = switch (tier) {
      VerificationTier.kyc => 'KYC verified',
      VerificationTier.phone => 'Verified',
      VerificationTier.none => 'Not verified',
    };
    final subtitle = switch (tier) {
      VerificationTier.kyc => 'You have the highest trust badge.',
      VerificationTier.phone => 'Complete KYC to earn a trust badge.',
      VerificationTier.none => 'Complete KYC to earn a trust badge.',
    };
    final accent = isKyc ? ZoneColors.success : ZoneColors.sell;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ZoneColors.tintOf(accent),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isKyc ? Icons.verified_user_rounded : Icons.shield_outlined,
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: zc.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: zc.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!isKyc)
              FilledButton.tonal(
                onPressed: onVerify,
                style: FilledButton.styleFrom(
                  backgroundColor: zc.primary.withValues(alpha: 0.12),
                  foregroundColor: zc.primary,
                ),
                child: const Text('Verify'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
            child: _StatTile(
                value: 4.8, decimals: 1, label: 'Rating',
                icon: Icons.star_rounded, color: ZoneColors.star)),
        SizedBox(width: 10),
        Expanded(
            child: _StatTile(
                value: 12, label: 'Signals',
                icon: Icons.podcasts_rounded, color: ZoneColors.primary)),
        SizedBox(width: 10),
        Expanded(
            child: _StatTile(
                value: 9, label: 'Matches',
                icon: Icons.handshake_rounded, color: ZoneColors.success)),
      ],
    );
  }
}

/// Stat with a count-up animation on first build.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.decimals = 0,
  });
  final double value;
  final int decimals;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                v.toStringAsFixed(decimals),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: zc.textPrimary),
              ),
            ),
            Text(label,
                style: TextStyle(color: zc.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
