import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import 'radius_slider.dart';

/// A lightweight, dependency-free "map" used until a real Google Maps API key
/// is configured. Draws a stylised street layout, radius rings around the
/// user and places signal pins at their relative bearing/distance. Swap this
/// for GoogleMap in map_screen.dart once you add a key.
class MapPlaceholder extends StatefulWidget {
  const MapPlaceholder({
    super.key,
    required this.center,
    required this.signals,
    required this.selectedRadius,
    required this.onPinTap,
  });

  final ({double lat, double lng}) center;
  final List<Signal> signals;
  final int selectedRadius; // meters
  final void Function(Signal) onPinTap;

  @override
  State<MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<MapPlaceholder>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final origin = Offset(size.width / 2, size.height / 2);

        // Animate the zoom level so changing the radius glides instead of
        // snapping.
        return TweenAnimationBuilder<double>(
          tween: Tween(end: widget.selectedRadius.toDouble()),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, radius, _) {
            // pixels-per-meter so the radius fills ~40% of the shorter side.
            final ppm = (math.min(size.width, size.height) * 0.4) / radius;

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StreetsPainter(
                      background: zc.mapBackground,
                      block: zc.mapBlock,
                      road: zc.mapRoad,
                      park: ZoneColors.help
                          .withValues(alpha: context.isDark ? 0.12 : 0.16),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RingsPainter(
                      origin: origin,
                      radii: radiusStops
                          .where((r) => r <= widget.selectedRadius)
                          .map((r) => r * ppm)
                          .toList(),
                      selectedPx: radius * ppm,
                      color: zc.primary,
                    ),
                  ),
                ),
                // Signal pins.
                ...widget.signals.map((s) {
                  final offset = _project(s, origin, ppm);
                  return Positioned(
                    key: ValueKey(s.id),
                    left: offset.dx - 22,
                    top: offset.dy - 52,
                    child: _Pin(signal: s, onTap: () => widget.onPinTap(s)),
                  );
                }),
                // "You" marker with a pulsing halo, on top.
                Positioned(
                  left: origin.dx - 40,
                  top: origin.dy - 40,
                  child: _YouMarker(pulse: _pulse),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Projects a signal's lat/lng to a screen offset relative to center.
  Offset _project(Signal s, Offset origin, double ppm) {
    // Rough local flat-earth projection (fine at city scale).
    const metersPerDegLat = 111320.0;
    final metersPerDegLng =
        111320.0 * math.cos(widget.center.lat * math.pi / 180.0);
    final dxMeters = (s.lng - widget.center.lng) * metersPerDegLng;
    final dyMeters = (s.lat - widget.center.lat) * metersPerDegLat;
    // Screen y grows downward, so negate dy.
    return Offset(origin.dx + dxMeters * ppm, origin.dy - dyMeters * ppm);
  }
}

class _YouMarker extends StatelessWidget {
  const _YouMarker({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final t = Curves.easeOut.transform(pulse.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 22 + 58 * t,
                height: 22 + 58 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ZoneColors.locationDot
                      .withValues(alpha: 0.35 * (1 - t)),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: ZoneColors.locationDot,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teardrop-style pin that pops in on first build and lifts on hover/press.
class _Pin extends StatefulWidget {
  const _Pin({required this.signal, required this.onTap});
  final Signal signal;
  final VoidCallback onTap;

  @override
  State<_Pin> createState() => _PinState();
}

class _PinState extends State<_Pin> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.signal.type.color;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(
        scale: v,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _active = true),
        onExit: (_) => setState(() => _active = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _active = true),
          onTapCancel: () => setState(() => _active = false),
          onTapUp: (_) => setState(() => _active = false),
          onTap: widget.onTap,
          child: AnimatedSlide(
            offset: Offset(0, _active ? -0.08 : 0),
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: 44,
              height: 52,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Pointer.
                  Positioned(
                    bottom: 2,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(width: 12, height: 12, color: color),
                    ),
                  ),
                  // Ground shadow.
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: _active ? 16 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(widget.signal.type.icon,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static, deterministic street layout: city blocks separated by roads,
/// two arterial roads, and a park. Purely decorative.
class _StreetsPainter extends CustomPainter {
  _StreetsPainter({
    required this.background,
    required this.block,
    required this.road,
    required this.park,
  });

  final Color background;
  final Color block;
  final Color road;
  final Color park;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    // City blocks with irregular widths so it doesn't read as graph paper.
    const colWidths = [86.0, 118.0, 72.0, 104.0, 92.0, 128.0];
    const rowHeights = [78.0, 104.0, 66.0, 96.0, 120.0, 84.0];
    const gap = 10.0;
    final blockPaint = Paint()..color = block;
    final parkPaint = Paint()..color = park;
    var y = -30.0;
    for (var r = 0; y < size.height; r++) {
      final h = rowHeights[r % rowHeights.length];
      var x = -40.0;
      for (var c = 0; x < size.width; c++) {
        final w = colWidths[(c + r * 2) % colWidths.length];
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(6),
        );
        // Sprinkle a few parks.
        final isPark = (r * 7 + c * 3) % 11 == 0;
        canvas.drawRRect(rect, isPark ? parkPaint : blockPaint);
        x += w + gap;
      }
      y += h + gap;
    }

    // Two wide arterial roads crossing the view.
    final arterial = Paint()
      ..color = road
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-20, size.height * 0.28),
      Offset(size.width + 20, size.height * 0.46),
      arterial,
    );
    canvas.drawLine(
      Offset(size.width * 0.68, -20),
      Offset(size.width * 0.52, size.height + 20),
      arterial,
    );
  }

  @override
  bool shouldRepaint(covariant _StreetsPainter old) =>
      old.background != background ||
      old.block != block ||
      old.road != road ||
      old.park != park;
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.origin,
    required this.radii,
    required this.selectedPx,
    required this.color,
  });

  final Offset origin;
  final List<double> radii;
  final double selectedPx;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Selected radius: soft radial fill fading toward the edge.
    final fill = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.04), color.withValues(alpha: 0.14)],
      ).createShader(Rect.fromCircle(center: origin, radius: selectedPx));
    canvas.drawCircle(origin, selectedPx, fill);

    // Inner dashed rings for the smaller stops.
    final ring = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final r in radii) {
      if ((r - selectedPx).abs() < 1) continue;
      _dashedCircle(canvas, origin, r, ring);
    }

    // Solid outer edge for the selected radius.
    canvas.drawCircle(
      origin,
      selectedPx,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint p) {
    const segments = 72;
    for (int i = 0; i < segments; i += 2) {
      final a0 = (i / segments) * 2 * math.pi;
      final a1 = ((i + 1) / segments) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a0,
        a1 - a0,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.selectedPx != selectedPx ||
      old.radii.length != radii.length ||
      old.origin != origin ||
      old.color != color;
}
