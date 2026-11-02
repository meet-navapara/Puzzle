import '../game/rng.dart';
import 'level_models.dart';

/// Builds campaign levels 11–500 from a small recipe. Pure and deterministic:
/// the same id always yields the same level, so saves only store progress.
///
/// `test/campaign/level_solvability_test.dart` plays every level this produces
/// on its in-game seed. Retune here and re-run that test together.
class LevelGenerator {
  LevelGenerator._();

  static const starter = ['mono', 'duo_h', 'duo_v', 'trio_h', 'corner'];
  static const easy = [
    'mono',
    'duo_h',
    'duo_v',
    'trio_h',
    'trio_v',
    'corner',
    'square',
  ];
  static const standard = [
    ...easy,
    'tee',
    'long_h',
    'long_v',
    'l',
    'j',
    's',
    'z',
  ];
  static const advanced = [...standard, 'plus', 'big_l', 'u'];

  /// Drops the smallest fillers, so late boards can't be patched one cell at a time.
  static const expert = [
    'duo_h',
    'duo_v',
    'trio_h',
    'trio_v',
    'corner',
    'square',
    'tee',
    'long_h',
    'long_v',
    'l',
    'j',
    's',
    'z',
    'plus',
    'big_l',
    'u',
  ];

  static const levelsPerWorld = 50;

  /// First level with overgrown cells, which earns a one-time tip.
  static const firstWeedsLevel = 102;

  /// Section id -> alternate piece sequence, for the few deals the solver test
  /// could not win. Regenerate with test/campaign/calibration_report.dart.
  static const Map<String, int> seedOverrides = {
    '20a': 1,
    '20c': 1,
    '116a': 2,
    '120b': 2,
    '123b': 1,
    '130a': 1,
    '134a': 1,
    '135a': 1,
    '135b': 1,
    '160c': 1,
    '162a': 1,
    '186b': 1,
    '188a': 1,
    '197a': 1,
    '200b': 2,
    '204a': 1,
    '207a': 1,
    '208a': 1,
    '215a': 2,
    '216b': 1,
    '222b': 1,
    '229a': 2,
    '234b': 1,
    '240b': 1,
    '245a': 3,
    '264b': 1,
    '266b': 1,
    '274a': 1,
    '282b': 1,
    '284a': 2,
    '298b': 1,
    '306a': 1,
    '310b': 1,
    '316b': 1,
    '317a': 2,
    '326a': 1,
    '328a': 1,
    '329a': 1,
    '339a': 4,
    '342a': 1,
    '344a': 2,
    '344b': 3,
    '346a': 3,
    '352b': 1,
    '353a': 3,
    '354b': 1,
    '356a': 1,
    '358b': 1,
    '366b': 1,
    '369a': 1,
    '370a': 1,
    '380c': 1,
    '382a': 1,
    '383a': 1,
    '388b': 1,
    '390a': 1,
    '391a': 3,
    '395a': 1,
    '396a': 1,
    '398b': 1,
    '400c': 4,
    '400d': 1,
    '402a': 1,
    '402b': 1,
    '405a': 2,
    '406a': 1,
    '410a': 2,
    '410b': 5,
    '414b': 1,
    '415a': 1,
    '416a': 4,
    '420b': 5,
    '421a': 2,
    '426a': 3,
    '426b': 2,
    '427a': 2,
    '430b': 1,
    '433a': 1,
    '434b': 1,
    '440b': 1,
    '442b': 5,
    '447a': 1,
    '448b': 1,
    '450b': 1,
    '450c': 1,
    '450d': 6,
    '452b': 1,
    '454a': 1,
    '456b': 4,
    '460a': 1,
    '461a': 4,
    '462b': 1,
    '466a': 1,
    '467a': 1,
    '472a': 2,
    '479a': 3,
    '480b': 6,
    '482b': 1,
    '483a': 2,
    '487a': 2,
    '490c': 9,
    '494b': 2,
    '495a': 1,
    '499a': 1,
    '302a': 1,
    '388a': 2,
    '480c': 1,
    '482a': 1,
  };

  /// Overall difficulty in 0–1. Climbs across the campaign, ramps within each
  /// ten-level block, and eases right after every milestone so players breathe.
  static double difficulty(int id) {
    final progress = (id - 1) / 499;
    final inBlock = (id - 1) % 10;
    final ramp = 0.05 * (inBlock / 9);
    final breather = inBlock == 0 ? 0.03 : 0.0;
    return (progress * 0.92 + ramp - breather).clamp(0.0, 1.0);
  }

  /// Every tenth level is a milestone with several sections.
  static bool isMilestone(int id) => id % 10 == 0;

  static LevelDefinition build(
    int id, {
    required int worldIndex,
    required String name,
    required int iconCode,
  }) {
    final position = (id - 1) % levelsPerWorld;
    final isWorldGate = position == levelsPerWorld - 1;
    final plan = _sectionPlan(id, worldIndex, isWorldGate);
    final sections = <SectionDefinition>[
      for (var i = 0; i < plan.length; i++)
        _section(
          id: id,
          index: i,
          objective: plan[i],
          worldIndex: worldIndex,
          levelName: name,
          iconCode: iconCode,
          sectionCount: plan.length,
        ),
    ];
    return LevelDefinition(
      id: id,
      worldIndex: worldIndex,
      name: name,
      sections: sections,
      firstClearReward: _reward(id, worldIndex, isWorldGate),
    );
  }

  static int _reward(int id, int worldIndex, bool isWorldGate) {
    if (isWorldGate) return 40 + worldIndex * 10;
    if (isMilestone(id)) return 18 + worldIndex * 2;
    return 8 + worldIndex;
  }

  /// Which objective each section uses. A level never opens on survival, so
  /// every level has moves to rate for stars.
  static List<LevelObjective> _sectionPlan(
    int id,
    int worldIndex,
    bool isWorldGate,
  ) {
    const opening = [
      LevelObjective.reachScore,
      LevelObjective.clearLines,
      LevelObjective.reachScore,
      LevelObjective.comboStreak,
      LevelObjective.clearLines,
      LevelObjective.reachScore,
      LevelObjective.comboStreak,
    ];
    final first = opening[id % opening.length];
    if (isWorldGate) {
      return const [
        LevelObjective.reachScore,
        LevelObjective.clearLines,
        LevelObjective.comboStreak,
        LevelObjective.surviveMoves,
      ];
    }
    if (isMilestone(id)) {
      return [
        first,
        first == LevelObjective.clearLines
            ? LevelObjective.reachScore
            : LevelObjective.clearLines,
        LevelObjective.surviveMoves,
      ];
    }
    // Longer levels arrive gradually: every 5th early, every 2nd from world 6.
    final twoParts = worldIndex >= 5
        ? id.isEven
        : worldIndex >= 2
        ? id % 3 == 0
        : id % 5 == 0;
    if (!twoParts) return [first];
    return [
      first,
      id % 4 == 0
          ? LevelObjective.surviveMoves
          : first == LevelObjective.reachScore
          ? LevelObjective.clearLines
          : LevelObjective.reachScore,
    ];
  }

  static SectionDefinition _section({
    required int id,
    required int index,
    required LevelObjective objective,
    required int worldIndex,
    required String levelName,
    required int iconCode,
    required int sectionCount,
  }) {
    final d = difficulty(id);
    final size = _boardSize(id, worldIndex, index);
    final blocked = _mask(size, id + index * 7, d);
    final goal = _goal(objective, id, index, d, size);
    return SectionDefinition(
      id: '$id${String.fromCharCode(97 + index)}',
      name: sectionCount == 1 ? levelName : '$levelName ${_partName(index)}',
      iconCode: iconCode,
      objective: objective,
      boardSize: size,
      scoreTarget: goal.score,
      lineTarget: goal.lines,
      comboTarget: goal.combo,
      moveLimit: goal.moveLimit,
      parMoves: goal.par,
      blockedCells: blocked,
      prefilledCells: _weeds(size, id, index, worldIndex, blocked),
      shapePoolIds: _pool(d),
      introText: id == firstWeedsLevel && index == 0
          ? 'Overgrown cells start on the board. They clear like anything you plant.'
          : '',
      seedOffset: seedOverrides['$id${String.fromCharCode(97 + index)}'] ?? 0,
    );
  }

  static String _partName(int index) =>
      const ['Dawn', 'Noon', 'Dusk', 'Night'][index];

  static int _boardSize(int id, int worldIndex, int sectionIndex) {
    final alt = (id + sectionIndex).isEven;
    return switch (worldIndex) {
      0 => id <= 20 ? 6 : (id <= 35 ? 7 : (alt ? 8 : 7)),
      1 || 2 => 8,
      3 || 4 => alt ? 9 : 8,
      5 || 6 => 9,
      7 || 8 => alt ? 10 : 9,
      _ => 10,
    };
  }

  static List<String> _pool(double d) {
    if (d < 0.03) return easy;
    if (d < 0.22) return standard;
    if (d < 0.85) return advanced;
    return expert;
  }

  /// Goal, move limit and par for one section. Late goals demand more points
  /// per move and allow less slack, which is where the difficulty comes from.
  static _Goal _goal(
    LevelObjective objective,
    int id,
    int sectionIndex,
    double d,
    int size,
  ) {
    // Small per-level swing keeps neighbouring levels from feeling identical.
    final swing = (id * 37 + sectionIndex * 11) % 7;
    final limited = d >= 0.08 || id % 3 == 0;
    // Slack between par and the move limit shrinks as the campaign goes on.
    final slack = 1.8 - d * 0.5;
    switch (objective) {
      case LevelObjective.reachScore:
        final target = (60 + d * 190).round() + swing * 3;
        final pointsPerMove = 5.5 + d * 4.5;
        final par = (target / pointsPerMove).ceil();
        return _Goal(
          score: target,
          par: par,
          moveLimit: limited ? (par * slack).ceil() : null,
        );
      case LevelObjective.clearLines:
        final lines = (3 + d * 7).round() + swing % 2;
        final par = (lines * (3.4 - d * 0.9)).ceil();
        return _Goal(
          lines: lines,
          score: lines * 12,
          par: par,
          moveLimit: limited ? (par * slack).ceil() : null,
        );
      case LevelObjective.comboStreak:
        final combo = d < 0.6 ? 2 : 3;
        final par = 8 + combo * 2 + swing;
        return _Goal(combo: combo, score: combo * 40, par: par);
      case LevelObjective.surviveMoves:
        final moves = (12 + d * 14).round() + swing;
        return _Goal(moveLimit: moves, score: moves * 5, par: 0);
      case LevelObjective.clearBoard:
        throw UnsupportedError('clearBoard is not generated');
    }
  }

  // ——— Board patterns ———

  /// Picks a symmetric blocked pattern. Density grows with [d]; the catalog test
  /// checks every shape in the pool still fits the opening board.
  static List<(int, int)> _mask(int size, int salt, double d) {
    final depth = d < 0.4 ? 1 : (d < 0.8 ? 2 : 3);
    final variant = salt % 11;
    final cells = switch (variant) {
      0 => const <(int, int)>{},
      1 => _corners(size, depth),
      2 => _center(size, depth + 1),
      3 => _pillars(size, depth),
      4 => _edgeNotches(size, depth),
      5 => _twinBars(size, depth + 1),
      6 => _pinwheel(size, depth + 1),
      7 => {..._corners(size, depth), ..._center(size, depth)},
      8 => _studs(size, depth),
      9 => {..._edgeNotches(size, depth), ..._center(size, depth)},
      _ => {..._corners(size, 1), ..._pillars(size, depth)},
    };
    return cells.toList();
  }

  /// Triangles of [depth] cells cut from each corner.
  static Set<(int, int)> _corners(int n, int depth) {
    final cells = <(int, int)>{};
    for (var r = 0; r < depth; r++) {
      for (var c = 0; c < depth - r; c++) {
        cells.addAll(_mirror(n, r, c));
      }
    }
    return cells;
  }

  static Set<(int, int)> _center(int n, int width) {
    final start = (n - width) ~/ 2;
    return {
      for (var r = start; r < start + width; r++)
        for (var c = start; c < start + width; c++) (r, c),
    };
  }

  /// Four small posts, one in each quadrant.
  static Set<(int, int)> _pillars(int n, int depth) {
    final at = n ~/ 4;
    final cells = <(int, int)>{};
    for (var i = 0; i < depth; i++) {
      cells.addAll(_mirror(n, at, at + i));
    }
    return cells;
  }

  /// Bites out of the middle of each edge.
  static Set<(int, int)> _edgeNotches(int n, int depth) {
    final mid = n ~/ 2;
    final cells = <(int, int)>{};
    for (var i = 0; i < depth; i++) {
      cells.addAll(_mirror(n, i, mid));
      cells.addAll(_mirror(n, mid, i));
    }
    return cells;
  }

  static Set<(int, int)> _twinBars(int n, int length) {
    final row = n ~/ 3;
    final start = (n - length) ~/ 2;
    return {
      for (var i = 0; i < length; i++) ...{
        (row, start + i),
        (n - 1 - row, start + i),
      },
    };
  }

  /// Four short bars in rotation around the middle.
  static Set<(int, int)> _pinwheel(int n, int length) {
    final at = n ~/ 3;
    final cells = <(int, int)>{};
    for (var i = 0; i < length; i++) {
      cells.add((at, at + i));
      cells.add((at + i, n - 1 - at));
      cells.add((n - 1 - at, n - 1 - at - i));
      cells.add((n - 1 - at - i, at));
    }
    return cells;
  }

  /// Evenly spaced single stones; closer together at higher depth.
  static Set<(int, int)> _studs(int n, int depth) {
    final step = depth >= 3 ? 3 : 4;
    final cells = <(int, int)>{};
    for (var r = step - 1; r < n - 1; r += step) {
      for (var c = step - 1; c < n - 1; c += step) {
        cells.add((r, c));
      }
    }
    return cells;
  }

  static Set<(int, int)> _mirror(int n, int r, int c) => {
    (r, c),
    (r, n - 1 - c),
    (n - 1 - r, c),
    (n - 1 - r, n - 1 - c),
  };

  /// Overgrown cells already on the board. They clear like any planted cell,
  /// and start from world 3.
  static List<(int, int, int)> _weeds(
    int size,
    int id,
    int sectionIndex,
    int worldIndex,
    List<(int, int)> blocked,
  ) {
    if (worldIndex < 2 || id % 2 != 0) return const [];
    final rng = SeededRng(id * 7919 + sectionIndex);
    final blockedSet = blocked.toSet();
    final count = 2 + worldIndex ~/ 2;
    final placed = <(int, int, int)>[];
    // Cells still open per line. Keeping at least two means no line can start
    // finished or one tap away, whatever the blocked pattern removed.
    final rowOpen = List.filled(size, size);
    final colOpen = List.filled(size, size);
    for (final (r, c) in blockedSet) {
      rowOpen[r]--;
      colOpen[c]--;
    }
    var attempts = 0;
    while (placed.length < count && attempts++ < 80) {
      final r = rng.nextInt(size);
      final c = rng.nextInt(size);
      if (blockedSet.contains((r, c))) continue;
      if (placed.any((p) => p.$1 == r && p.$2 == c)) continue;
      if (rowOpen[r] <= 2 || colOpen[c] <= 2) continue;
      rowOpen[r]--;
      colOpen[c]--;
      placed.add((r, c, rng.nextInt(6)));
    }
    return placed;
  }
}

class _Goal {
  const _Goal({
    this.score,
    this.lines,
    this.combo,
    this.moveLimit,
    required this.par,
  });

  final int? score;
  final int? lines;
  final int? combo;
  final int? moveLimit;
  final int par;
}
