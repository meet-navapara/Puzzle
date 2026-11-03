import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tutorial/tutorial_copy.dart';
import '../theme/petal_theme.dart';

/// A looping mini garden for a lesson card: a piece travels from the tray,
/// lands, any finished lines flash and bloom away, and the counter updates.
///
/// Pure illustration. It never touches the real board or engine.
class TutorialDemoView extends StatefulWidget {
  const TutorialDemoView({super.key, required this.demo, this.animate = true});

  final TutorialDemo demo;

  /// False shows the finished frame only (reduced motion).
  final bool animate;

  @override
  State<TutorialDemoView> createState() => _TutorialDemoViewState();
}

class _TutorialDemoViewState extends State<TutorialDemoView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
    value: widget.animate ? 0 : 0.95,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(TutorialDemoView old) {
    super.didUpdateWidget(old);
    if (old.demo != widget.demo && widget.animate) {
      _c
        ..value = 0
        ..repeat();
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
    final scenario = _Scenario.of(widget.demo);
    return Semantics(
      label: scenario.description,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.25,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _DemoPainter(
              animation: _c,
              scenario: scenario,
              surfaces: s,
              light: Theme.of(context).brightness == Brightness.light,
              textStyle: PetalText.score(context),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _Cell = (int, int);

/// One scripted move on a 5×5 garden.
class _Scenario {
  const _Scenario({
    required this.filled,
    required this.piece,
    required this.pieceColor,
    required this.target,
    required this.description,
    this.clearRows = const [],
    this.clearCols = const [],
    this.counter,
    this.before = 0,
    this.after = 0,
    this.goal,
  });

  /// Cells already planted, with colour indexes.
  final Map<_Cell, int> filled;

  /// Piece shape as offsets from its top-left.
  final List<_Cell> piece;
  final int pieceColor;

  /// Where the piece's top-left lands.
  final _Cell target;
  final List<int> clearRows;
  final List<int> clearCols;

  /// Counter chip label, e.g. "Goal" or "Lines"; null hides the chip.
  final String? counter;
  final int before;
  final int after;
  final int? goal;
  final String description;

  static _Scenario of(TutorialDemo demo) => switch (demo) {
    TutorialDemo.drag => const _Scenario(
      filled: {(3, 0): 2, (4, 0): 2, (4, 1): 0, (4, 4): 3, (3, 4): 3},
      piece: [(0, 0), (0, 1), (0, 2)],
      pieceColor: 5,
      target: (1, 1),
      description: 'A finger drags a three-block piece onto empty cells.',
    ),
    TutorialDemo.rowBloom => const _Scenario(
      filled: {
        (3, 0): 0,
        (3, 1): 1,
        (3, 3): 2,
        (3, 4): 3,
        (4, 0): 4,
        (4, 1): 4,
        (2, 4): 1,
      },
      piece: [(0, 0)],
      pieceColor: 5,
      target: (3, 2),
      clearRows: [3],
      counter: 'Score',
      before: 6,
      after: 16,
      description: 'One block fills a row and the whole row blooms away.',
    ),
    TutorialDemo.reachGoal => const _Scenario(
      filled: {(4, 0): 3, (4, 1): 3, (4, 2): 0, (3, 0): 2, (2, 0): 2},
      piece: [(0, 0), (0, 1)],
      pieceColor: 1,
      target: (4, 3),
      clearRows: [4],
      counter: 'Goal',
      before: 9,
      after: 18,
      goal: 18,
      description: 'A clear lifts the score to the goal and the level is done.',
    ),
    TutorialDemo.lineGoal => const _Scenario(
      filled: {
        (2, 0): 4,
        (2, 1): 4,
        (2, 2): 0,
        (2, 4): 2,
        (4, 3): 1,
        (3, 3): 1,
      },
      piece: [(0, 0)],
      pieceColor: 3,
      target: (2, 3),
      clearRows: [2],
      counter: 'Lines',
      before: 0,
      after: 1,
      goal: 2,
      description: 'A row blooms and the lines counter goes from 0 to 1 of 2.',
    ),
    TutorialDemo.columnBloom => const _Scenario(
      filled: {(0, 2): 0, (1, 2): 0, (2, 2): 5, (4, 0): 3, (4, 1): 3},
      piece: [(0, 0), (1, 0)],
      pieceColor: 2,
      target: (3, 2),
      clearCols: [2],
      counter: 'Lines',
      before: 1,
      after: 2,
      goal: 2,
      description: 'A vertical piece fills a column and the column blooms.',
    ),
  };
}

class _DemoPainter extends CustomPainter {
  _DemoPainter({
    required this.animation,
    required this.scenario,
    required this.surfaces,
    required this.light,
    required this.textStyle,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final _Scenario scenario;
  final PetalSurfaces surfaces;
  final bool light;
  final TextStyle textStyle;

  static const _n = 5;

  // Timeline (fractions of one loop).
  static const _travelStart = 0.12;
  static const _travelEnd = 0.48;
  static const _flashEnd = 0.66;
  static const _bloomEnd = 0.78;

  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final hasCounter = scenario.counter != null;
    final top = hasCounter ? size.height * 0.16 : size.height * 0.04;
    final trayH = size.height * 0.2;
    final boardSide = math.min(
      size.width * 0.62,
      size.height - top - trayH - 8,
    );
    final cell = boardSide / _n;
    final board = Rect.fromLTWH(
      (size.width - boardSide) / 2,
      top,
      boardSide,
      boardSide,
    );

    // Frame.
    final frame = RRect.fromRectAndRadius(
      board.inflate(5),
      const Radius.circular(14),
    );
    canvas.drawRRect(frame, Paint()..color = surfaces.boardFrame);
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = surfaces.panelBorder,
    );

    // The tray the piece starts from, so the drag has a clear origin.
    final tray = RRect.fromRectAndRadius(
      Rect.fromLTWH(board.left, board.bottom + 12, boardSide, trayH - 6),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      tray,
      Paint()..color = surfaces.panel.withValues(alpha: light ? 0.9 : 0.7),
    );
    canvas.drawRRect(
      tray,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = surfaces.panelBorder.withValues(alpha: 0.7),
    );

    final landed = t >= _travelEnd;
    final flash = landed ? _seg(t, _travelEnd, _flashEnd) : 0.0;
    final bloom = _seg(t, _flashEnd, _bloomEnd);
    final cleared = <_Cell>{
      for (final r in scenario.clearRows)
        for (var c = 0; c < _n; c++) (r, c),
      for (final c in scenario.clearCols)
        for (var r = 0; r < _n; r++) (r, c),
    };
    final placed = {
      for (final (dr, dc) in scenario.piece)
        (scenario.target.$1 + dr, scenario.target.$2 + dc),
    };

    Rect cellRect(int r, int c) => Rect.fromLTWH(
      board.left + c * cell,
      board.top + r * cell,
      cell,
      cell,
    ).deflate(1.6);

    // Empty beds, then planted cells.
    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        _empty(canvas, cellRect(r, c));
      }
    }
    void plant(_Cell rc, int color) {
      var rect = cellRect(rc.$1, rc.$2);
      if (cleared.contains(rc) && bloom > 0) {
        final k = 1 - Curves.easeIn.transform(bloom);
        if (k <= 0.02) return;
        rect = Rect.fromCenter(
          center: rect.center,
          width: rect.width * k,
          height: rect.height * k,
        );
      }
      _block(canvas, rect, _color(color));
    }

    scenario.filled.forEach(plant);
    if (landed) {
      for (final rc in placed) {
        plant(rc, scenario.pieceColor);
      }
    }

    // Line flash before the bloom.
    if (cleared.isNotEmpty && flash > 0 && bloom < 1) {
      final glow = math.sin(flash * math.pi) * (1 - bloom);
      final paint = Paint()
        ..color = surfaces.clearFlash.withValues(alpha: 0.55 * glow);
      for (final r in scenario.clearRows) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(board.left, board.top + r * cell, boardSide, cell),
            const Radius.circular(8),
          ),
          paint,
        );
      }
      for (final c in scenario.clearCols) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(board.left + c * cell, board.top, cell, boardSide),
            const Radius.circular(8),
          ),
          paint,
        );
      }
    }

    // Piece in flight, with landing ghost and a finger.
    if (!landed) {
      final trayCell = cell * 0.8;
      final pw = (scenario.piece.map((p) => p.$2).reduce(math.max) + 1);
      final ph = (scenario.piece.map((p) => p.$1).reduce(math.max) + 1);
      final from = Offset(
        size.width / 2 - pw * trayCell / 2,
        board.bottom + 12 + (trayH - ph * trayCell) / 2,
      );
      final to = Offset(
        board.left + scenario.target.$2 * cell,
        board.top + scenario.target.$1 * cell,
      );
      final k = Curves.easeInOutCubic.transform(
        _seg(t, _travelStart, _travelEnd),
      );
      final unit = trayCell + (cell - trayCell) * k;
      // Arc slightly upward while travelling.
      final lift = math.sin(k * math.pi) * cell * 0.5;
      final origin = Offset.lerp(from, to, k)! - Offset(0, lift);

      if (k > 0.25) {
        final ghost = Paint()
          ..color = _color(scenario.pieceColor).withValues(alpha: 0.28 * k);
        for (final rc in placed) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              cellRect(rc.$1, rc.$2),
              const Radius.circular(6),
            ),
            ghost,
          );
        }
      }
      for (final (dr, dc) in scenario.piece) {
        _block(
          canvas,
          Rect.fromLTWH(
            origin.dx + dc * unit,
            origin.dy + dr * unit,
            unit,
            unit,
          ).deflate(1.6),
          _color(scenario.pieceColor),
          lifted: k > 0 && k < 1,
        );
      }
      // Finger: appears, presses, follows the piece.
      final appear = _seg(t, 0.02, _travelStart);
      if (appear > 0) {
        final tip = origin + Offset(pw * unit / 2, ph * unit + 10);
        final r = 13.0 * (k > 0 ? 0.9 : 1.0);
        canvas.drawCircle(
          tip,
          r + 5,
          Paint()..color = Colors.white.withValues(alpha: 0.12 * appear),
        );
        canvas.drawCircle(
          tip,
          r,
          Paint()..color = Colors.white.withValues(alpha: 0.55 * appear),
        );
      }
    }

    // Score floats up after a bloom.
    if (cleared.isNotEmpty && bloom > 0 && hasCounter) {
      final gain = scenario.after - scenario.before;
      final rise = Curves.easeOut.transform(_seg(t, _flashEnd, 0.95));
      _text(
        canvas,
        '+$gain',
        Offset(board.center.dx, board.center.dy - rise * cell * 1.2),
        surfaces.gold.withValues(alpha: 1 - _seg(t, 0.85, 1)),
        size: 20,
      );
    }

    if (hasCounter) _counter(canvas, size, t);
  }

  void _counter(Canvas canvas, Size size, double t) {
    final done =
        t >= _bloomEnd ||
        scenario.clearRows.isEmpty &&
            scenario.clearCols.isEmpty &&
            t >= _travelEnd;
    final value = done ? scenario.after : scenario.before;
    final goal = scenario.goal;
    final label = goal == null
        ? '${scenario.counter}  $value'
        : '${scenario.counter}  $value / $goal';
    final h = size.height * 0.12;
    final w = math.min(size.width * 0.62, 200.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, h / 2 + 2),
      width: w,
      height: h,
    );
    final reached = goal != null && value >= goal;
    final tone = reached ? surfaces.gold : surfaces.accent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(h / 2)),
      Paint()..color = surfaces.hudChip,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(h / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = reached ? 1.8 : 1
        ..color = reached ? tone : surfaces.panelBorder,
    );
    if (goal != null) {
      final fill = (value / goal).clamp(0.0, 1.0);
      final bar = Rect.fromLTWH(
        rect.left + h * 0.5,
        rect.bottom - 6,
        (rect.width - h) * fill,
        3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(2)),
        Paint()..color = tone,
      );
    }
    _text(
      canvas,
      label,
      rect.center - const Offset(0, 2),
      reached ? tone : surfaces.onPanel,
      size: h * 0.42,
    );
  }

  Color _color(int i) =>
      surfaces.blockPalette[i % surfaces.blockPalette.length];

  void _empty(Canvas canvas, Rect r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(6)),
      Paint()..color = surfaces.emptyCell,
    );
  }

  void _block(Canvas canvas, Rect r, Color c, {bool lifted = false}) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
    if (lifted) {
      canvas.drawRRect(
        rr.shift(const Offset(0, 4)),
        Paint()
          ..color = surfaces.shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.drawRRect(
      rr.shift(const Offset(0, 1.5)),
      Paint()..color = Color.lerp(c, Colors.black, 0.35)!,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(c, Colors.white, 0.22)!, c],
        ).createShader(r),
    );
    canvas.save();
    canvas.clipRRect(rr);
    final band = Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.5);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.34),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    Color color, {
    required double size,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(color: color, fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DemoPainter old) =>
      old.scenario != scenario ||
      old.surfaces != surfaces ||
      old.light != light;
}
