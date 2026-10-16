import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';

/// PetalGrid combo / clear vocabulary (visual only — scoring unchanged).
class PetalFxCopy {
  PetalFxCopy._();

  static String? forClear({required int lines, required int combo}) {
    if (lines >= 4) return 'PETAL STORM';
    if (lines == 3) return 'TRIPLE BLOOM';
    if (lines == 2) return 'DOUBLE BLOOM';
    if (combo >= 4) return 'COMBO x$combo';
    if (combo >= 3) return 'BLOOM STREAK';
    if (combo == 2) return 'BLOOM';
    if (lines == 1) return null; // keep single clears quiet
    return null;
  }
}

/// Brief celebration banner for multi-clears and combos.
class FxBanner extends StatefulWidget {
  const FxBanner({
    super.key,
    required this.text,
    required this.token,
    this.reducedMotion = false,
    this.onFinished,
  });

  final String text;
  final int token;
  final bool reducedMotion;
  final VoidCallback? onFinished;

  @override
  State<FxBanner> createState() => _FxBannerState();
}

class _FxBannerState extends State<FxBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    final duration = widget.reducedMotion
        ? PetalMotion.bannerReduced
        : PetalMotion.banner;
    _c = AnimationController(vsync: this, duration: duration);
    _scale = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.35, curve: PetalMotion.settle),
      reverseCurve: Curves.easeIn,
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
    ]).animate(_c);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished?.call();
    });
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant FxBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(_scale),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: surfaces.panel.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: surfaces.accentSoft, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: surfaces.accentSoft.withValues(alpha: 0.28),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Text(
              widget.text,
              style: PetalText.section(context)
                  .copyWith(letterSpacing: 0.4, color: surfaces.accentSoft),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating score delta near the board.
class ScoreFloat extends StatefulWidget {
  const ScoreFloat({
    super.key,
    required this.points,
    required this.token,
    this.reducedMotion = false,
  });

  final int points;
  final int token;
  final bool reducedMotion;

  @override
  State<ScoreFloat> createState() => _ScoreFloatState();
}

class _ScoreFloatState extends State<ScoreFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.reducedMotion
          ? PetalMotion.tap
          : PetalMotion.scoreFloat,
    )..forward();
  }

  @override
  void didUpdateWidget(covariant ScoreFloat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -28 * t),
              child: Text(
                '+${widget.points}',
                style: PetalText.score(context).copyWith(
                  fontSize: 18,
                  color: surfaces.accent,
                  shadows: [
                    Shadow(
                      color: surfaces.shadow.withValues(
                        alpha: isLight ? 0.25 : 0.55,
                      ),
                      blurRadius: isLight ? 2 : 6,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sequenced line-clear effect: recognize → anticipate → sweep → settle.
/// Game state is already updated; this is visual only.
class LineClearFx extends StatefulWidget {
  const LineClearFx({
    super.key,
    required this.boardSize,
    required this.clearedRows,
    required this.clearedCols,
    required this.token,
    this.reducedMotion = false,
    this.onFinished,
  });

  final int boardSize;
  final List<int> clearedRows;
  final List<int> clearedCols;
  final int token;
  final bool reducedMotion;
  final VoidCallback? onFinished;

  @override
  State<LineClearFx> createState() => _LineClearFxState();
}

class _LineClearFxState extends State<LineClearFx>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.reducedMotion
          ? PetalMotion.clearReduced
          : PetalMotion.clearTotal,
    );
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished?.call();
    });
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant LineClearFx oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _c
        ..duration = widget.reducedMotion
            ? PetalMotion.clearReduced
            : PetalMotion.clearTotal
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _LineClearPainter(
              progress: _c.value,
              boardSize: widget.boardSize,
              rows: widget.clearedRows,
              cols: widget.clearedCols,
              flash: surfaces.clearFlash,
              accent: surfaces.accentSoft,
              reduced: widget.reducedMotion,
            ),
          );
        },
      ),
    );
  }
}

class _LineClearPainter extends CustomPainter {
  _LineClearPainter({
    required this.progress,
    required this.boardSize,
    required this.rows,
    required this.cols,
    required this.flash,
    required this.accent,
    required this.reduced,
  });

  final double progress;
  final int boardSize;
  final List<int> rows;
  final List<int> cols;
  final Color flash;
  final Color accent;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    if (boardSize <= 0) return;
    final cell = size.width / boardSize;

    // Phase A 0–0.2 recognize, B 0.2–0.4 anticipate, C 0.4–0.85 sweep, D settle
    final recognize = (progress / 0.2).clamp(0.0, 1.0);
    final anticipate = ((progress - 0.2) / 0.2).clamp(0.0, 1.0);
    final sweep = ((progress - 0.4) / 0.45).clamp(0.0, 1.0);
    final fade = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);

    final pulse = reduced
        ? 0.7
        : (0.35 + 0.45 * recognize + 0.35 * anticipate * (1 - fade));

    final cellPaint = Paint()
      ..color = flash.withValues(alpha: pulse.clamp(0.0, 0.9));

    for (final r in rows) {
      for (var c = 0; c < boardSize; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cell + 1.5, r * cell + 1.5, cell - 3, cell - 3),
          const Radius.circular(5),
        );
        canvas.drawRRect(rect, cellPaint);
      }
      if (!reduced && sweep > 0 && fade < 1) {
        final x = size.width * sweep;
        final band = Paint()
          ..shader = LinearGradient(
            colors: [
              accent.withValues(alpha: 0),
              accent.withValues(alpha: 0.85),
              flash.withValues(alpha: 0.95),
              accent.withValues(alpha: 0.85),
              accent.withValues(alpha: 0),
            ],
            stops: const [0, 0.35, 0.5, 0.65, 1],
          ).createShader(Rect.fromLTWH(x - cell * 1.2, r * cell, cell * 2.4, cell));
        canvas.drawRect(
          Rect.fromLTWH(0, r * cell + 1, size.width, cell - 2),
          band,
        );
        _petals(canvas, Offset(x, r * cell + cell / 2), accent, sweep);
      }
    }

    for (final c in cols) {
      for (var r = 0; r < boardSize; r++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cell + 1.5, r * cell + 1.5, cell - 3, cell - 3),
          const Radius.circular(5),
        );
        canvas.drawRRect(rect, cellPaint);
      }
      if (!reduced && sweep > 0 && fade < 1) {
        final y = size.height * sweep;
        final band = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0),
              accent.withValues(alpha: 0.85),
              flash.withValues(alpha: 0.95),
              accent.withValues(alpha: 0.85),
              accent.withValues(alpha: 0),
            ],
            stops: const [0, 0.35, 0.5, 0.65, 1],
          ).createShader(Rect.fromLTWH(c * cell, y - cell * 1.2, cell, cell * 2.4));
        canvas.drawRect(
          Rect.fromLTWH(c * cell + 1, 0, cell - 2, size.height),
          band,
        );
        _petals(canvas, Offset(c * cell + cell / 2, y), accent, sweep);
      }
    }
  }

  void _petals(Canvas canvas, Offset center, Color color, double t) {
    final paint = Paint()..color = color.withValues(alpha: 0.55 * (1 - t * 0.4));
    for (var i = 0; i < 5; i++) {
      final a = i * (math.pi * 2 / 5) + t * 2;
      final d = 6.0 + t * 18;
      final p = center + Offset(math.cos(a) * d, math.sin(a) * d);
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 5, height: 8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineClearPainter old) =>
      old.progress != progress ||
      old.boardSize != boardSize ||
      old.rows != rows ||
      old.cols != cols ||
      old.flash != flash ||
      old.accent != accent ||
      old.reduced != reduced;
}
