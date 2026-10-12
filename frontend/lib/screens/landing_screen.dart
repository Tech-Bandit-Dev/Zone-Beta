import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/signal.dart';
import 'auth_screen.dart';

/// Pre-auth home page. Animated radar hero + log in / sign up entry points.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Fade + rise-in, staggered across [start, end] of the entrance timeline.
  Widget _reveal(double start, double end, Widget child) {
    final curved = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 24),
          child: child,
        ),
      ),
    );
  }

  void _open(AuthMode mode) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AuthScreen(mode: mode)),
      );

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              zc.primary.withValues(alpha: context.isDark ? 0.18 : 0.10),
              zc.background,
            ],
            stops: const [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _reveal(
                  0,
                  0.4,
                  Row(
                    children: [
                      const _LogoMark(size: 36),
                      const SizedBox(width: 10),
                      Text(
                        'Zone',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: zc.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _reveal(
                    0.1,
                    0.6,
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _RadarHero(pulse: _pulse),
                      ),
                    ),
                  ),
                ),
                _reveal(
                  0.3,
                  0.75,
                  Text(
                    'What\'s happening\naround you, right now.',
                    style: TextStyle(
                      fontSize: 32,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: zc.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _reveal(
                  0.4,
                  0.85,
                  Text(
                    'Post what you need — a cab to share, an errand, a '
                    'handoff. Anyone nearby can jump in.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: zc.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _reveal(
                  0.5,
                  1,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () => _open(AuthMode.signup),
                        child: const Text('Get started'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _open(AuthMode.login),
                        child: const Text('I already have an account'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient rounded-square logo used on the landing and auth screens.
class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ZoneColors.primaryLight, ZoneColors.primaryDeep],
        ),
      ),
      child: Icon(Icons.radar, color: Colors.white, size: size * 0.58),
    );
  }
}

/// Looping radar: expanding rings from the center with category pins
/// floating at fixed bearings. Pure paint + transforms, no assets.
class _RadarHero extends StatelessWidget {
  const _RadarHero({required this.pulse});
  final Animation<double> pulse;

  static const _pins = [
    (type: SignalType.sell, angle: -0.9, dist: 0.62),
    (type: SignalType.event, angle: 0.5, dist: 0.78),
    (type: SignalType.help, angle: 2.2, dist: 0.55),
    (type: SignalType.housing, angle: 3.4, dist: 0.8),
    (type: SignalType.community, angle: 4.6, dist: 0.48),
  ];

  @override
  Widget build(BuildContext context) {
    final zc = context.zc;
    return LayoutBuilder(builder: (context, c) {
      final r = c.maxWidth / 2;
      return AnimatedBuilder(
        animation: pulse,
        builder: (context, _) {
          final t = pulse.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadarPainter(
                    t: t,
                    color: zc.primary,
                    grid: zc.border,
                  ),
                ),
              ),
              for (var i = 0; i < _pins.length; i++)
                _floatingPin(context, _pins[i], i, r, t),
              Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: ZoneColors.locationDot,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: ZoneColors.locationDot.withValues(alpha: 0.5),
                        blurRadius: 16,
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
    });
  }

  Widget _floatingPin(BuildContext context,
      ({SignalType type, double angle, double dist}) p, int i, double r,
      double t) {
    // Gentle bob, phase-shifted per pin so they don't move in lockstep.
    final bob = math.sin((t * 2 * math.pi) + i * 1.3) * 4;
    final x = r + math.cos(p.angle) * r * p.dist;
    final y = r + math.sin(p.angle) * r * p.dist + bob;
    return Positioned(
      left: x - 20,
      top: y - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.zc.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(p.type.icon, color: p.type.color, size: 20),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.t, required this.color, required this.grid});
  final double t;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // Static guide rings.
    final guide = Paint()
      ..color = grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in [0.33, 0.66, 1.0]) {
      canvas.drawCircle(c, maxR * f, guide);
    }

    // Three expanding pulses, evenly offset in time.
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final paint = Paint()
        ..color = color.withValues(alpha: (1 - p) * 0.16)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(c, maxR * p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.t != t || old.color != color || old.grid != grid;
}
