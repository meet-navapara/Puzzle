import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One-pass copper guide. It traces empty cells and never accepts touches.
class GuideLight extends StatefulWidget {
  const GuideLight({
    super.key,
    required this.boardSize,
    required this.cells,
    required this.onFinished,
  });

  final int boardSize;
  final List<(int, int)> cells;
  final VoidCallback onFinished;

  static const duration = Duration(milliseconds: 1680);
  static const copper = Color(0xFFE0975C);
  static const ivory = Color(0xFFFFF6EA);

  @override
  State<GuideLight> createState() => _GuideLightState();
}

class _GuideLightState extends State<GuideLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<(int, int)> _cells;
  bool _finished = false;

  void _scheduleFinish() {
    if (_finished) return;
    _finished = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void initState() {
    super.initState();
    _cells = List<(int, int)>.of(widget.cells);
    _controller = AnimationController(vsync: this, duration: GuideLight.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _scheduleFinish();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.value >= 1) _scheduleFinish();
          return CustomPaint(
            painter: _GuideLightPainter(
              boardSize: widget.boardSize,
              cells: _cells,
              t: _controller.value,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _GuideLightPainter extends CustomPainter {
  _GuideLightPainter({
    required this.boardSize,
    required this.cells,
    required this.t,
  });

  final int boardSize;
  final List<(int, int)> cells;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (boardSize <= 0 || cells.isEmpty || size.width <= 0) return;
    final cell = size.width / boardSize;
    final centers = <Offset>[
      for (final (r, c) in cells)
        if (r >= 0 && c >= 0 && r < boardSize && c < boardSize)
          Offset((c + 0.5) * cell, (r + 0.5) * cell),
    ];
    if (centers.isEmpty) return;

    final travel = _travel(t, centers);
    if (t >= 0.18 && travel.points.length >= 2) {
      final fade = t < 0.82 ? 1.0 : (1 - ((t - 0.82) / 0.18)).clamp(0.0, 1.0);
      final trail = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = GuideLight.copper.withValues(alpha: 0.38 * fade);
      final path = Path()..moveTo(travel.points.first.dx, travel.points.first.dy);
      for (final point in travel.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, trail);
    }

    final mark = travel.mark;
    final press = t < 0.18 ? (t / 0.18).clamp(0.0, 1.0) : 1.0;
    final lift = t < 0.82 ? 0.0 : ((t - 0.82) / 0.18).clamp(0.0, 1.0);
    final scale = t < 0.18
        ? 1 - 0.08 * math.sin(math.pi * press)
        : t < 0.82
        ? 1.0
        : 1 + 0.14 * lift;
    final opacity = t < 0.82 ? 1.0 : (1 - lift);

    if (t < 0.18) {
      final ripple = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = GuideLight.copper.withValues(alpha: 0.55 * (1 - press));
      canvas.drawCircle(mark, cell * (0.12 + 0.42 * press), ripple);
    }

    final halo = Paint()
      ..color = GuideLight.copper.withValues(alpha: 0.5 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.14);
    canvas.drawCircle(mark, cell * 0.22 * scale, halo);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = GuideLight.copper.withValues(alpha: 0.95 * opacity);
    canvas.drawCircle(mark, cell * 0.16 * scale, ring);

    final core = Paint()
      ..color = GuideLight.ivory.withValues(alpha: opacity);
    canvas.drawCircle(mark, cell * 0.045 * scale, core);
  }

  @override
  bool shouldRepaint(covariant _GuideLightPainter old) =>
      old.t != t || old.boardSize != boardSize || old.cells != cells;
}

class _Travel {
  const _Travel(this.mark, this.points);
  final Offset mark;
  final List<Offset> points;
}

_Travel _travel(double t, List<Offset> centers) {
  if (centers.length == 1 || t < 0.18) {
    return _Travel(centers.first, const []);
  }
  final span = centers.length - 1;
  final raw = t >= 0.82 ? 1.0 : ((t - 0.18) / 0.64).clamp(0.0, 1.0);
  final u = Curves.easeInOutCubic.transform(raw);
  final dist = u * span;
  final index = math.min(dist.floor(), span - 1);
  final local = (dist - index).clamp(0.0, 1.0);
  final mark = Offset.lerp(centers[index], centers[index + 1], local)!;
  return _Travel(mark, [...centers.take(index + 1), mark]);
}
