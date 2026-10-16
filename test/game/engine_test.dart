import 'package:block_garden/game/game_engine.dart';
import 'package:block_garden/game/scoring.dart';
import 'package:block_garden/game/shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scoring', () {
    test('cells and lines are positive', () {
      final s = ScoreBreakdown.forPlacement(
        placedCells: 4,
        lineCount: 2,
        combo: 2,
      );
      expect(s.cellsPlaced, 4);
      expect(s.linesCleared, 20);
      expect(s.multiLineBonus, greaterThan(0));
      expect(s.comboBonus, greaterThan(0));
      expect(s.totalDelta, greaterThan(0));
    });

    test('no negative totals', () {
      final s = ScoreBreakdown.forPlacement(
        placedCells: 0,
        lineCount: 0,
        combo: 0,
      );
      expect(s.totalDelta, 0);
    });
  });

  group('GameEngine', () {
    test('places and refills tray after three uses', () {
      final engine = GameEngine();
      engine.startClassic(seed: 42, pool: [ShapeCatalog.mono]);
      final firstTray = engine.state.tray.map((p) => p.uid).toList();
      expect(firstTray.length, 3);

      for (var i = 0; i < 3; i++) {
        final piece = engine.state.tray.firstWhere((p) => !p.used);
        final placed = engine.place(piece.uid, 0, i);
        expect(placed, isNotNull);
      }
      // Tray should refill with new uids.
      final nextIds = engine.state.tray.map((p) => p.uid).toList();
      expect(nextIds.length, 3);
      expect(engine.state.tray.every((p) => !p.used), isTrue);
    });

    test('bloom prune spends a charge', () {
      final engine = GameEngine();
      engine.startClassic(seed: 7, pool: [ShapeCatalog.mono]);
      // Manually place and simulate bloom by placing a filled cell then adding charge.
      final p = engine.state.tray.first;
      engine.place(p.uid, 0, 0);
      // Inject charges via restore.
      final st = engine.state;
      engine.restore(st.copyWith(bloom: st.bloom.addClearedCells(40)));
      expect(engine.state.bloom.canPrune, isTrue);
      final pruned = engine.bloomPrune(0, 0);
      expect(pruned, isNotNull);
      expect(engine.state.board.at(0, 0).filled, isFalse);
      expect(
        engine.state.bloom.charges,
        lessThan(st.bloom.addClearedCells(40).charges),
      );
    });

    test('rescue only once and only on game over', () {
      final engine = GameEngine();
      engine.startClassic(seed: 1, pool: [ShapeCatalog.plus]);
      // Force game over state.
      engine.restore(engine.state.copyWith(phase: GamePhase.gameOver));
      final first = engine.applyRescueTray();
      expect(first, isNotNull);
      expect(engine.state.rescueUsed, isTrue);
      engine.restore(engine.state.copyWith(phase: GamePhase.gameOver));
      expect(engine.applyRescueTray(), isNull);
    });

    test('restart classic resets score', () {
      final engine = GameEngine();
      engine.startClassic(seed: 3, bestScore: 100, pool: [ShapeCatalog.mono]);
      final p = engine.state.tray.first;
      engine.place(p.uid, 1, 1);
      expect(engine.state.score, greaterThan(0));
      engine.startClassic(seed: 3, bestScore: 100, pool: [ShapeCatalog.mono]);
      expect(engine.state.score, 0);
      expect(engine.state.bestScore, 100);
    });

    test('score target alone does not complete non-reachScore sections', () {
      final engine = GameEngine();
      engine.startCampaign(
        levelId: 1,
        sectionIndex: 0,
        boardSize: 8,
        scoreTarget: 1,
        moveLimit: null,
        blocked: const [],
        prefilled: const [],
        pool: [ShapeCatalog.mono],
        seed: 9,
        winOnScoreTarget: false,
      );
      final p = engine.state.tray.first;
      engine.place(p.uid, 0, 0);
      expect(engine.state.score, greaterThanOrEqualTo(1));
      expect(engine.state.phase, GamePhase.playing);
    });

    test('surviveMoves completes before dead-board game over', () {
      final engine = GameEngine();
      engine.startCampaign(
        levelId: 1,
        sectionIndex: 0,
        boardSize: 8,
        scoreTarget: null,
        moveLimit: 1,
        blocked: const [],
        prefilled: const [],
        pool: [ShapeCatalog.mono],
        seed: 11,
        surviveOnMovesExhausted: true,
      );
      final p = engine.state.tray.first;
      engine.place(p.uid, 0, 0);
      expect(engine.state.movesRemaining, 0);
      expect(engine.state.phase, GamePhase.levelComplete);
    });
  });
}
