import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';

/// Activity tab. Placeholder until posted/accepted signal history ships —
/// see README "Next milestones". Rendered inside MapScreen's nav.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        automaticallyImplyLeading: false,
      ),
      body: const EmptyState(
        icon: Icons.bolt_rounded,
        title: 'No activity yet',
        message: 'Signals you post or accept will show up here.',
      ),
    );
  }
}
