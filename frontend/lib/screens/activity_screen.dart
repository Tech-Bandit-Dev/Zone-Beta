import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Activity tab. Placeholder until posted/accepted signal history ships —
/// see README "Next milestones". Rendered inside MapScreen's nav (via
/// [onBack]), same pattern as ProfileScreen.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_outlined, size: 40, color: ZoneColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No activity yet',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ZoneColors.textPrimary),
              ),
              SizedBox(height: 6),
              Text(
                'Signals you post or accept will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ZoneColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
