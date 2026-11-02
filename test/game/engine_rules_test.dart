import 'package:block_garden/game/bloom_charge.dart';
import 'package:block_garden/game/board.dart';
import 'package:block_garden/game/game_engine.dart';
import 'package:block_garden/game/piece.dart';
import 'package:block_garden/game/shapes.dart';
import 'package:flutter_test/flutter_test.dart';

/// All cells of a board filled except [open], without finishing any line.
List<(int, int)> _allBlockedExcept(int size, Set<(int, int)> open) => [
  for (var r = 0; r < size; r++)
    for (var c = 0; c < size; c++)
      if (!open.contains((r, c))) (r, c),
];

GameEngine _campaign({
  int boardSize = 8,
  int? scoreTarget,
  int? moveLimit,
  List<(int, int)> blocked = const [],
  List<PieceShape>? pool,
  int? lineTarget,
  int? comboTarget,
  bool winOnScore = false,
  bool survive = false,
  bool clearBoardGoal = false,
  int seed = 9,
}) {
  return GameEngine()..startCampaign(
    levelId: 1,
    sectionIndex: 0,
    boardSize: boardSize,
    scoreTarget: scoreTarget,
    moveLimit: moveLimit,
    blocked: blocked,
    prefilled: const [],
    pool: pool ?? [ShapeCatalog.mono],
    seed: seed,
    winOnScoreTarget: winOnScore,
    surviveOnMovesExhausted: survive,
    lineTarget: lineTarget,
    comboTarget: comboTarget,
    clearBoardGoal: clearBoardGoal,
  );
}

TrayPiece _next(GameEngine e) => e.state.tray.firstWhere((p) => !p.used);

void main() {
  group('objectives', () {
    test('clearing the line target completes the section', () {
      final e = _campaign(boardSize: 4, lineTarget: 1);
      for (var c = 0; c < 3; c++) {
        e.place(_next(e).uid, 0, c);
        expect(e.state.phase, GamePhase.playing);
      }
      e.place(_next(e).uid, 0, 3);
      expect(e.state.phase, GamePhase.levelComplete);
    });

    test('combo target needs consecutive clears', () {
      // Two open columns of one cell each: every placement clears a line.
      final e = _campaign(
        boardSize: 4,
        comboTarget: 2,
        blocked: _allBlockedExcept(4, {(0, 0), (2, 2)}),
      );
      e.place(_next(e).uid, 0, 0);
      expect(e.state.combo, 1);
      expect(e.state.phase, GamePhase.playing);
      e.place(_next(e).uid, 2, 2);
      expect(e.state.combo, 2);
      expect(e.state.phase, GamePhase.levelComplete);
    });

    test('a score goal is not met by lines, and vice versa', () {
      final e = _campaign(boardSize: 4, scoreTarget: 1, lineTarget: 1);
      e.place(_next(e).uid, 0, 0);
      expect(
        e.state.phase,
        GamePhase.playing,
        reason: 'winOnScoreTarget is off for a clearLines section',
      );
    });

    test('a winning move beats a board that would otherwise be dead', () {
      // The only open cell: the move wins and also leaves no room for anything.
      final e = _campaign(
        boardSize: 4,
        scoreTarget: 1,
        winOnScore: true,
        blocked: _allBlockedExcept(4, {(1, 1)}),
      );
      e.place(_next(e).uid, 1, 1);
      expect(e.state.phase, GamePhase.levelComplete);
    });

    test('running out of moves loses unless the goal was reached', () {
      final lose = _campaign(moveLimit: 1, scoreTarget: 1000, winOnScore: true);
      lose.place(_next(lose).uid, 0, 0);
      expect(lose.state.phase, GamePhase.gameOver);
      expect(lose.state.outOfMoves, isTrue);

      final win = _campaign(moveLimit: 1, scoreTarget: 1, winOnScore: true);
      win.place(_next(win).uid, 0, 0);
      expect(win.state.phase, GamePhase.levelComplete);
    });

    test('an out-of-moves line section is a loss, not a soft lock', () {
      final e = _campaign(boardSize: 8, moveLimit: 1, lineTarget: 5);
      e.place(_next(e).uid, 0, 0);
      expect(e.state.phase, GamePhase.gameOver);
    });

    test('goals survive a save and restore', () {
      final e = _campaign(boardSize: 4, lineTarget: 1, comboTarget: 3);
      final json = e.state.copyWith(levelRunMoves: 7).toJson();
      final again = GameState.fromJson(json);
      expect(again.lineTarget, 1);
      expect(again.comboTarget, 3);
      expect(again.levelRunMoves, 7);
    });
  });

  group('fair deals', () {
    test('a dealt tray always has a piece that fits', () {
      // Only single cells are open, and the pool has nothing that small.
      final engine = _campaign(
        boardSize: 6,
        pool: [ShapeCatalog.plus, ShapeCatalog.bigL],
        blocked: _allBlockedExcept(6, {(0, 0), (3, 3)}),
      );
      expect(engine.state.board.anyPieceFits(engine.state.tray), isTrue);
      expect(engine.state.phase, GamePhase.playing);
    });

    test('deals are repeatable, so a retry can be learned', () {
      List<String> shapes(GameEngine e) =>
          e.state.tray.map((p) => p.shape.id).toList();
      final a = _campaign(pool: ShapeCatalog.advancedPool, seed: 77);
      final b = _campaign(pool: ShapeCatalog.advancedPool, seed: 77);
      expect(shapes(a), shapes(b));
    });
  });

  group('rescue', () {
    test('an out-of-moves rescue actually grants more moves', () {
      final e = _campaign(moveLimit: 1, scoreTarget: 1000, winOnScore: true);
      e.place(_next(e).uid, 0, 0);
      expect(e.state.phase, GamePhase.gameOver);

      expect(e.applyRescueTray(), isNotNull);
      expect(e.state.phase, GamePhase.playing);
      expect(e.state.movesRemaining, GameEngine.rescueExtraMoves);

      e.place(_next(e).uid, 0, 1);
      expect(
        e.state.phase,
        GamePhase.playing,
        reason: 'The reward must not end the run on the very next move',
      );
    });

    test('a dead-board rescue leaves the move count alone', () {
      final e = _campaign(moveLimit: 9);
      e.restore(e.state.copyWith(phase: GamePhase.gameOver));
      e.applyRescueTray();
      expect(e.state.movesRemaining, 9);
    });
  });

  group('bloom revive', () {
    GameEngine stuck({int charges = 1, int? movesLeft}) {
      final filled = Board(size: 4).applyPattern(
        prefilled: [
          for (var r = 0; r < 4; r++)
            for (var c = 0; c < 4; c++)
              if (r != c) (r, c, 0),
        ],
      );
      final e = _campaign(
        boardSize: 4,
        moveLimit: 5,
        pool: [ShapeCatalog.square],
      );
      e.restore(
        e.state.copyWith(
          board: filled,
          phase: GamePhase.gameOver,
          movesRemaining: movesLeft ?? 5,
          bloom: BloomState(charges: charges),
        ),
      );
      return e;
    }

    test('reopens a stuck board when a charge is saved up', () {
      final e = stuck();
      expect(e.canReviveWithBloom, isTrue);
      expect(e.reviveForPrune(), isNotNull);
      expect(e.state.phase, GamePhase.playing);
    });

    test('is not offered without a charge or with no moves left', () {
      expect(stuck(charges: 0).canReviveWithBloom, isFalse);
      expect(stuck(movesLeft: 0).canReviveWithBloom, isFalse);
    });

    test('a prune that does not help ends the run again', () {
      final e = stuck()..reviveForPrune();
      e.bloomPrune(0, 1);
      expect(e.state.bloom.charges, 0);
      expect(e.state.phase, GamePhase.gameOver);
    });
  });
}
