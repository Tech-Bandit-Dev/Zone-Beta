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
    return Container(
      decoration: const BoxDecoration(
        color: ZoneColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD5D9DF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: signal.type.tint,
                child: Icon(signal.type.icon, color: signal.type.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Aarav',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            size: 18, color: ZoneColors.primary),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.star, size: 15, color: Color(0xFFF2C94C)),
                        SizedBox(width: 4),
                        Text('4.8',
                            style: TextStyle(color: ZoneColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: signal.type.tint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  signal.type.label,
                  style: TextStyle(
                    color: signal.type.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            signal.message,
            style: const TextStyle(
                fontSize: 16, height: 1.4, color: ZoneColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.near_me,
                  size: 16, color: ZoneColors.textMuted),
              const SizedBox(width: 6),
              Text(
                signal.distanceMeters != null
                    ? '${signal.distanceMeters} m away'
                    : 'Nearby',
                style: const TextStyle(color: ZoneColors.textMuted),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.schedule,
                  size: 16, color: ZoneColors.textMuted),
              const SizedBox(width: 6),
              Text(_expiry,
                  style: const TextStyle(color: ZoneColors.textMuted)),
            ],
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}
