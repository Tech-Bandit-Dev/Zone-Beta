import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';

/// A lightweight, dependency-free "map" used until a real Google Maps API key
/// is configured. Draws radius rings around the user and places signal pins at
/// their relative bearing/distance. Swap this for GoogleMap in map_screen.dart
/// once you add a key.
class MapPlaceholder extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final origin = Offset(size.width / 2, size.height / 2);
        // pixels-per-meter so selectedRadius fills ~40% of the shorter side.
        final ppm = (math.min(size.width, size.height) * 0.4) /
            selectedRadius.toDouble();

        return Stack(
          children: [
            // Map backdrop + rings.
            Positioned.fill(
              child: CustomPaint(
                painter: _RingsPainter(
                  origin: origin,
                  radii: const [250, 500, 1000]
                      .where((r) => r <= selectedRadius)
                      .map((r) => r * ppm)
                      .toList(),
                  selectedPx: selectedRadius * ppm,
                ),
              ),
            ),
            // Signal pins.
            ...signals.map((s) {
              final offset = _project(s, origin, ppm);
              return Positioned(
                left: offset.dx - 22,
                top: offset.dy - 44,
                child: _Pin(signal: s, onTap: () => onPinTap(s)),
              );
            }),
            // "You" marker on top.
            Positioned(
              left: origin.dx - 11,
              top: origin.dy - 11,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: ZoneColors.locationDot,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: ZoneColors.locationDot.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Projects a signal's lat/lng to a screen offset relative to center.
  Offset _project(Signal s, Offset origin, double ppm) {
    // Rough local flat-earth projection (fine at city scale).
    const metersPerDegLat = 111320.0;
    final metersPerDegLng =
        111320.0 * math.cos(center.lat * math.pi / 180.0);
    final dxMeters = (s.lng - center.lng) * metersPerDegLng;
    final dyMeters = (s.lat - center.lat) * metersPerDegLat;
    // Screen y grows downward, so negate dy.
    return Offset(origin.dx + dxMeters * ppm, origin.dy - dyMeters * ppm);
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.signal, required this.onTap});
  final Signal signal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: signal.type.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(signal.type.icon, color: Colors.white, size: 20),
          ),
          Container(
            width: 3,
            height: 10,
            color: signal.type.color,
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.origin,
    required this.radii,
    required this.selectedPx,
  });

  final Offset origin;
  final List<double> radii;
  final double selectedPx;

  @override
  void paint(Canvas canvas, Size size) {
    // Map background.
    final bg = Paint()..color = ZoneColors.mapBackground;
    canvas.drawRect(Offset.zero & size, bg);

    // Faux street grid for a map-like feel.
    final grid = Paint()
      ..color = const Color(0xFFE2DFD6)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Selected radius fill.
    final fill = Paint()..color = ZoneColors.primary.withOpacity(0.06);
    canvas.drawCircle(origin, selectedPx, fill);

    // Dashed rings.
    final ring = Paint()
      ..color = ZoneColors.primary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final r in radii) {
      _dashedCircle(canvas, origin, r, ring);
    }
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint p) {
    const segments = 60;
    const gap = 2; // draw 1, skip 1 pattern-ish
    for (int i = 0; i < segments; i++) {
      if (i % gap == 0) continue;
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
      old.selectedPx != selectedPx || old.radii.length != radii.length;
}
