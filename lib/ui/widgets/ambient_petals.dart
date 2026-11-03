import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';

/// Slow drifting petals behind menus. One controller, one painter, no
/// rebuilds: the painter repaints from the animation directly.
///
/// Static (but still drawn) when [animate] is false, so reduced-motion
/// players keep the look without the movement.
class AmbientPetals extends StatefulWidget {
  const AmbientPetals({super.key, this.animate = true, this.count = 14});

  final bool animate;
  final int count;

  @override
  State<AmbientPetals> createState() => _AmbientPetalsState();
}

class _AmbientPetalsState extends State<AmbientPetals>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  );
  late List<_Petal> _petals = _seed(widget.count);

  static List<_Petal> _seed(int n) {
    final rng = math.Random(7);
    return List.generate(n, (i) {
      return _Petal(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 7 + rng.nextDouble() * 9,
        speed: 0.6 + rng.nextDouble() * 0.8,
        sway: 0.015 + rng.nextDouble() * 0.03,
        phase: rng.nextDouble() * math.pi * 2,
        spin: (rng.nextBool() ? 1 : -1) * (0.5 + rng.nextDouble()),
        colorIndex: i,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(AmbientPetals old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) _petals = _seed(widget.count);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _PetalPainter(
            animation: _c,
            petals: _petals,
            colors: s.blockPalette,
            alpha: light ? 0.22 : 0.16,
          ),
        ),
      ),
    );
  }
}

class _Petal {
  const _Petal({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.spin,
    required this.colorIndex,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double sway;
  final double phase;
  final double spin;
  final int colorIndex;
}

class _PetalPainter extends CustomPainter {
  _PetalPainter({
    required this.animation,
    required this.petals,
    required this.colors,
    required this.alpha,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Petal> petals;
  final List<Color> colors;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final paint = Paint();
    for (final p in petals) {
      // Drift down and loop; sway sideways on a sine.
      final y = (p.y + t * p.speed) % 1.0;
      final x = p.x + math.sin(t * math.pi * 2 * p.speed + p.phase) * p.sway;
      final cx = x * size.width;
      final cy = y * (size.height + 40) - 20;
      paint.color = colors[p.colorIndex % colors.length].withValues(
        alpha: alpha,
      );
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.phase + t * math.pi * 2 * p.spin);
      // A petal: two arcs meeting at points, like a leaf.
      final w = p.size * 0.62;
      final h = p.size;
      final path = Path()
        ..moveTo(0, -h / 2)
        ..quadraticBezierTo(w, 0, 0, h / 2)
        ..quadraticBezierTo(-w, 0, 0, -h / 2)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalPainter old) =>
      old.colors != colors || old.alpha != alpha || old.petals != petals;
}
