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
    final index = steps.indexOf(value).clamp(0, steps.length - 1);

    Widget buildSlider({required double trackHeight, required double thumbRadius}) {
      return SliderTheme(
        data: SliderThemeData(
          activeTrackColor: ZoneColors.primary,
          // Noticeably darker than the map/paper background so the groove
          // reads clearly even with no card behind it.
          inactiveTrackColor: ZoneColors.textMuted.withOpacity(0.35),
          thumbColor: ZoneColors.primary,
          overlayColor: ZoneColors.primary.withOpacity(0.15),
          trackHeight: trackHeight,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: thumbRadius,
            elevation: 4,
            pressedElevation: 6,
          ),
          valueIndicatorColor: ZoneColors.primary,
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small elevated pill so the current value stays legible over the
          // map without wrapping the whole dragger in a background card.
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                labelBuilder(value),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: ZoneColors.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: buildSlider(trackHeight: 4, thumbRadius: 8),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSlider(trackHeight: 4, thumbRadius: 9),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: steps.map((s) {
              final selected = s == value;
              // Shrink-to-fit: with up to 8 stops (radius goes to 5km,
              // expiry to 6hr) a plain Row can overflow narrow screens.
              return Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labelBuilder(s),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          selected ? ZoneColors.primary : ZoneColors.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
