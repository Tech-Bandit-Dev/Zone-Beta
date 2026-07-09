import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import '../state/app_state.dart';
import '../widgets/radius_slider.dart';

/// Compose a new signal: message + category + radius + expiry, then broadcast.
/// Returns the created [Signal] so the map can drop a pin immediately.
class CreateSignalScreen extends ConsumerStatefulWidget {
  const CreateSignalScreen({super.key, required this.center});
  final ({double lat, double lng}) center;

  @override
  ConsumerState<CreateSignalScreen> createState() =>
      _CreateSignalScreenState();
}

class _CreateSignalScreenState extends ConsumerState<CreateSignalScreen>
    with SingleTickerProviderStateMixin {
  final _message = TextEditingController();
  SignalType _type = SignalType.sell;
  int _radius = 500;
  int _expiry = 15;
  bool _loading = false;
  bool _success = false;

  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  @override
  void initState() {
    super.initState();
    _entrance.forward();
  }

  @override
  void dispose() {
    _message.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _broadcast() async {
    if (_message.text.trim().isEmpty || _loading) return;
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
      await _finish(signal);
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
      await _finish(local);
    }
  }

  /// Shows a brief "sent" state so the broadcast feels confirmed, then pops.
  Future<void> _finish(Signal signal) async {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });
    await Future.delayed(const Duration(milliseconds: 520));
    if (mounted) Navigator.of(context).pop(signal);
  }

  /// Fade + rise-in for each section, staggered across [start, end] of the
  /// entrance timeline so the form cascades in rather than popping at once.
  Widget _staggered({
    required double start,
    required double end,
    required Widget child,
  }) {
    final curved = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curved.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 18),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a signal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _staggered(
              start: 0.0,
              end: 0.55,
              child: TextField(
                controller: _message,
                maxLines: 3,
                maxLength: 280,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Sharing cab Delhi to Gurgaon, leaving in 10 min',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _staggered(
              start: 0.08,
              end: 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            _staggered(
              start: 0.16,
              end: 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Broadcast radius'),
                  RadiusSlider(
                    value: _radius,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _staggered(
              start: 0.24,
              end: 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Expires in'),
                  ExpirySlider(
                    value: _expiry,
                    onChanged: (v) => setState(() => _expiry = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _staggered(
              start: 0.32,
              end: 0.9,
              child: _BroadcastButton(
                loading: _loading,
                success: _success,
                onPressed: _broadcast,
              ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
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
                AnimatedScale(
                  scale: selected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    color: selected ? color : ZoneColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Broadcast CTA that crossfades between idle / sending / sent states so
/// tapping it feels like it did something, instead of just popping the
/// screen the instant the request resolves.
class _BroadcastButton extends StatelessWidget {
  const _BroadcastButton({
    required this.loading,
    required this.success,
    required this.onPressed,
  });
  final bool loading;
  final bool success;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: success ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: ElevatedButton(
        onPressed: (loading || success) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor:
              success ? ZoneColors.primary : ZoneColors.primary.withOpacity(0.6),
          disabledForegroundColor: Colors.white,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Row(
            key: ValueKey(success ? 'success' : (loading ? 'loading' : 'idle')),
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (success)
                const Icon(Icons.check_circle, color: Colors.white)
              else if (loading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              else
                const Icon(Icons.podcasts),
              const SizedBox(width: 10),
              Text(success ? 'Sent' : 'Broadcast'),
            ],
          ),
        ),
      ),
    );
  }
}
