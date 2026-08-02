import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import '../state/app_state.dart';

/// Profile tab. Shows the signed-in user, verification tier, a mock KYC
/// upgrade, and logout. Rendered inside MapScreen's nav (via [onBack]).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: ZoneColors.primary.withOpacity(0.15),
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? const Icon(Icons.person,
                          size: 34, color: ZoneColors.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Zone user',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (user?.phone.isNotEmpty ?? false)
                            ? user!.phone
                            : user?.email ?? '',
                        style:
                            const TextStyle(color: ZoneColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
            const _StatsRow(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ZoneColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ZoneColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isKyc ? Icons.verified_user : Icons.shield_outlined,
            color: isKyc ? ZoneColors.help : ZoneColors.textMuted,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: ZoneColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!isKyc)
            TextButton(onPressed: onVerify, child: const Text('Verify')),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _StatTile(value: '4.8', label: 'Rating')),
        SizedBox(width: 12),
        Expanded(child: _StatTile(value: '12', label: 'Signals')),
        SizedBox(width: 12),
        Expanded(child: _StatTile(value: '9', label: 'Matches')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: ZoneColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZoneColors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ZoneColors.primary)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(color: ZoneColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
