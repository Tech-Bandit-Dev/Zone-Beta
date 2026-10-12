import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Selectable radius stops, in meters, from 250m up to 5km. Must match the
/// backend's `radiusMeters` / `range` allow-list (signal.dto.ts).
const radiusStops = <int>[250, 500, 1000, 2000, 3000, 4000, 5000];

String formatRadius(int meters) =>
    meters < 1000 ? '${meters}m' : '${(meters / 1000).toStringAsFixed(0)}km';

/// Selectable signal expiry stops, in minutes, up to 6 hours. Must match the
/// backend's `expiresInMinutes` allow-list (signal.dto.ts).
const expiryStops = <int>[15, 30, 60, 120, 180, 240, 300, 360];

String formatExpiry(int minutes) =>
    minutes < 60 ? '$minutes min' : '${minutes ~/ 60} hr';

/// A draggable "line" slider for picking a broadcast radius, snapping to
/// [radiusStops]. Thin wrapper around [_StepSlider].
///
/// [compact] hides the tick labels row (used in the map's floating overlay,
/// where space is tight) and shows just the current value instead.
class RadiusSlider extends StatelessWidget {
  const RadiusSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => _StepSlider(
        steps: radiusStops,
        value: value,
        onChanged: onChanged,
        labelBuilder: formatRadius,
        compact: compact,
      );
}

/// Same dragger format as [RadiusSlider], for picking how long a signal
/// stays live before it expires. Snaps to [expiryStops].
class ExpirySlider extends StatelessWidget {
  const ExpirySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => _StepSlider(
        steps: expiryStops,
        value: value,
        onChanged: onChanged,
        labelBuilder: formatExpiry,
        compact: compact,
      );
}

/// Shared dragger implementation: a slider that snaps to a fixed list of
/// [steps], with a value label and (in full mode) tick labels underneath.
class _StepSlider extends StatelessWidget {
  const _StepSlider({
    required this.steps,
    required this.value,
    required this.onChanged,
    required this.labelBuilder,
    required this.compact,
  });

  final List<int> steps;
  final int value;
  final ValueChanged<int> onChanged;
  final String Function(int) labelBuilder;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    final index = steps.indexOf(value).clamp(0, steps.length - 1);

    Widget buildSlider({required double trackHeight, required double thumbRadius}) {
      return SliderTheme(
        data: SliderThemeData(
          activeTrackColor: zc.primary,
          inactiveTrackColor: zc.primary.withValues(alpha: 0.16),
          thumbColor: Colors.white,
          overlayColor: zc.primary.withValues(alpha: 0.12),
          trackHeight: trackHeight,
          thumbShape: _RingThumb(radius: thumbRadius, ring: zc.primary),
          tickMarkShape: SliderTickMarkShape.noTickMark,
          valueIndicatorColor: zc.textPrimary,
          valueIndicatorTextStyle: TextStyle(
            color: zc.background,
            fontWeight: FontWeight.w700,
          ),
          valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
          showValueIndicator: ShowValueIndicator.onlyForDiscrete,
        ),
        child: Slider(
          min: 0,
          max: (steps.length - 1).toDouble(),
          divisions: steps.length - 1,
          value: index.toDouble(),
          label: labelBuilder(value),
          onChanged: (v) => onChanged(steps[v.round()]),
        ),
      );
    }

    if (compact) {
      // Single row: current value on the left, dragger filling the rest.
      // Lives inside the map's frosted chip, so no background of its own.
      return Row(
        children: [
          Icon(Icons.radar_rounded, size: 18, color: zc.primary),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Text(
                labelBuilder(value),
                key: ValueKey(value),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: zc.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 36,
              child: buildSlider(trackHeight: 5, thumbRadius: 9),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      decoration: BoxDecoration(
        color: zc.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSlider(trackHeight: 6, thumbRadius: 11),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: steps.map((s) {
                final selected = s == value;
                // Shrink-to-fit: with up to 8 stops (radius goes to 5km,
                // expiry to 6hr) a plain Row can overflow narrow screens.
                return Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? zc.primary : zc.textMuted,
                      ),
                      child: Text(labelBuilder(s)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// White thumb with a colored ring and soft shadow.
class _RingThumb extends SliderComponentShape {
  const _RingThumb({required this.radius, required this.ring});
  final double radius;
  final Color ring;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final r = radius * (1 + 0.15 * activationAnimation.value);
    canvas.drawCircle(
      center + const Offset(0, 1.5),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, r, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      r - 1.5,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
