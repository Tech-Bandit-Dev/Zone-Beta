import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';

/// Bottom sheet shown when a signal pin is tapped. Poster info + trust badge +
/// message + distance + expiry + Accept. Returns true from the sheet when the
/// user taps Accept.
class SignalBottomSheet extends StatelessWidget {
  const SignalBottomSheet({super.key, required this.signal});
  final Signal signal;

  static Future<bool?> show(BuildContext context, Signal signal) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => SignalBottomSheet(signal: signal),
    );
  }

  String get _expiry {
    final left = signal.expiresAt.difference(DateTime.now());
    if (left.isNegative) return 'Expired';
    if (left.inMinutes < 60) return 'Expires in ${left.inMinutes} min';
    return 'Expires in ${left.inHours} hr';
  }

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    final type = signal.type;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: zc.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: zc.border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: zc.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: type.tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(type.icon, color: type.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Aarav',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: zc.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded,
                              size: 17, color: zc.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: ZoneColors.star),
                          const SizedBox(width: 3),
                          Text('4.8 · 23 matches',
                              style: TextStyle(
                                  color: zc.textMuted, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: type.tint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type.label,
                    style: TextStyle(
                      color: type.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              signal.message,
              style: TextStyle(
                  fontSize: 17, height: 1.45, color: zc.textPrimary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.near_me_rounded,
                  label: signal.distanceMeters != null
                      ? '${signal.distanceMeters} m away'
                      : 'Nearby',
                ),
                _InfoChip(icon: Icons.schedule_rounded, label: _expiry),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: zc.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: zc.textMuted),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: zc.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
