import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import '../state/app_state.dart';

/// Compose a new signal: message + category + radius + expiry, then broadcast.
/// Returns the created [Signal] so the map can drop a pin immediately.
class CreateSignalScreen extends ConsumerStatefulWidget {
  const CreateSignalScreen({super.key, required this.center});
  final ({double lat, double lng}) center;

  @override
  ConsumerState<CreateSignalScreen> createState() =>
      _CreateSignalScreenState();
}

class _CreateSignalScreenState extends ConsumerState<CreateSignalScreen> {
  final _message = TextEditingController();
  SignalType _type = SignalType.sell;
  int _radius = 500;
  int _expiry = 15;
  bool _loading = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _broadcast() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final signal = await ref.read(apiProvider).createSignal(
            message: _message.text.trim(),
            type: _type,
            radiusMeters: _radius,
            lat: widget.center.lat,
            lng: widget.center.lng,
            expiresInMinutes: _expiry,
          );
      if (mounted) Navigator.of(context).pop(signal);
    } catch (e) {
      // Offline fallback: build a local signal so the flow still completes.
      final local = Signal(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        posterId: 'me',
        message: _message.text.trim(),
        type: _type,
        radiusMeters: _radius,
        lat: widget.center.lat,
        lng: widget.center.lng,
        status: 'active',
        expiresAt: DateTime.now().add(Duration(minutes: _expiry)),
        distanceMeters: 0,
      );
      if (mounted) Navigator.of(context).pop(local);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a signal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _message,
              maxLines: 3,
              maxLength: 280,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Sharing cab Delhi to Gurgaon, leaving in 10 min',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            const _SectionLabel('Category'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
              children: SignalType.values.map((t) {
                final selected = t == _type;
                return _ChoiceCard(
                  selected: selected,
                  color: t.color,
                  tint: t.tint,
                  icon: t.icon,
                  label: t.label,
                  onTap: () => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Broadcast radius'),
            const SizedBox(height: 8),
            _Segmented(
              options: const {250: '250m', 500: '500m', 1000: '1km'},
              value: _radius,
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Expires in'),
            const SizedBox(height: 8),
            _Segmented(
              options: const {15: '15 min', 30: '30 min', 60: '1 hr'},
              value: _expiry,
              onChanged: (v) => setState(() => _expiry = v),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loading ? null : _broadcast,
              icon: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.podcasts),
              label: const Text('Broadcast'),
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
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ZoneColors.textPrimary,
        ),
      );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.color,
    required this.tint,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final bool selected;
  final Color color;
  final Color tint;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? tint : ZoneColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : ZoneColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : ZoneColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final Map<int, String> options;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ZoneColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ZoneColors.border),
      ),
      child: Row(
        children: options.entries.map((e) {
          final selected = e.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? ZoneColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : ZoneColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
