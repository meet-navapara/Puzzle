import 'package:block_garden/campaign/level_models.dart';
import 'package:block_garden/campaign/section_starter.dart';
import 'package:block_garden/game/board.dart';
import 'package:block_garden/game/game_engine.dart';
import 'package:block_garden/game/rng.dart';

/// Result of one bot run through a section.
class BotRun {
  const BotRun({required this.won, required this.moves, required this.score});
  final bool won;
  final int moves;
  final int score;
}

/// Plays campaign sections through the real engine, using only the moves a
/// player has: no Bloom Prune, no petals, no ad rescue.
class LevelBot {
  LevelBot({this.mistakeRate = 0, int rngSeed = 1}) : _rng = SeededRng(rngSeed);

  /// Chance per move of a careless placement, to approximate a casual player.
  final double mistakeRate;
  final SeededRng _rng;

  /// [seed] null plays the exact piece sequence the app deals for this section.
  BotRun playSection(LevelDefinition level, int sectionIndex, {int? seed}) {
    final engine = GameEngine();
    engine.startSection(level, sectionIndex, seed: seed);
    while (engine.state.phase == GamePhase.playing) {
      final move = _chooseMove(engine.state);
      if (move == null) break;
      engine.place(move.uid, move.row, move.col);
    }
    final st = engine.state;
    return BotRun(
      won: st.phase == GamePhase.levelComplete,
      moves: st.moveCount,
      score: st.score,
    );
  }

  /// Plays every section in order. Returns rated moves if all were won.
  ({bool won, int ratedMoves}) playLevel(LevelDefinition level, {int? seed}) {
    var rated = 0;
    for (var i = 0; i < level.sections.length; i++) {
      final run = playSection(level, i, seed: seed == null ? null : seed + i);
      if (!run.won) return (won: false, ratedMoves: rated);
      if (level.sections[i].objective != LevelObjective.surviveMoves) {
        rated += run.moves;
      }
    }
    return (won: true, ratedMoves: rated);
  }

  /// The move the solver would make; lets other tools play through AppState.
  static ({String uid, int row, int col})? bestMoveFor(GameState st) {
    final move = LevelBot()._chooseMove(st);
    return move == null ? null : (uid: move.uid, row: move.row, col: move.col);
  }

  _Move? _chooseMove(GameState st) {
    final moves = <_Move>[];
    for (final piece in st.tray) {
      if (piece.used) continue;
      for (var r = 0; r < st.board.size; r++) {
        for (var c = 0; c < st.board.size; c++) {
          if (!st.board.canPlace(piece.shape, r, c)) continue;
          final placed = st.board.tryPlace(
            piece.shape,
            r,
            c,
            piece.colorIndex,
          )!;
          final clear = placed.findClears();
          final after = placed.applyClears(clear);
          moves.add(
            _Move(
              piece.uid,
              r,
              c,
              clear.lineCount * 200 +
                  piece.shape.cellCount * 2 +
                  _shapeScore(after) +
                  _trayFitScore(st, piece.uid, after),
            ),
          );
        }
      }
    }
    if (moves.isEmpty) return null;
    if (mistakeRate > 0 && _rng.nextInt(1000) < mistakeRate * 1000) {
      return moves[_rng.nextInt(moves.length)];
    }
    moves.sort((a, b) => b.value.compareTo(a.value));
    return moves.first;
  }

  /// A player keeps room for the rest of the tray before anything else.
  int _trayFitScore(GameState st, String placedUid, Board after) {
    var value = 0;
    for (final other in st.tray) {
      if (other.used || other.uid == placedUid) continue;
      if (!after.canFitAnywhere(other.shape)) value -= 400;
    }
    return value;
  }

  /// Rewards rows and columns close to full; punishes isolated empty cells.
  int _shapeScore(Board b) {
    var value = 0;
    final n = b.size;
    for (var i = 0; i < n; i++) {
      var rowOpen = 0, rowFilled = 0, colOpen = 0, colFilled = 0;
      for (var j = 0; j < n; j++) {
        final rc = b.at(i, j);
        if (!rc.blocked) rc.filled ? rowFilled++ : rowOpen++;
        final cc = b.at(j, i);
        if (!cc.blocked) cc.filled ? colFilled++ : colOpen++;
      }
      value += rowFilled + colFilled;
      if (rowOpen == 1) value += 12;
      if (colOpen == 1) value += 12;
      // Fragmentation: every open/closed edge along a line makes pieces harder
      // to fit later. Board edges count as closed.
      var rowClosed = true, colClosed = true;
      for (var j = 0; j <= n; j++) {
        final rowNow = j == n || !b.at(i, j).isOccupiable;
        final colNow = j == n || !b.at(j, i).isOccupiable;
        if (rowNow != rowClosed) value -= 5;
        if (colNow != colClosed) value -= 5;
        rowClosed = rowNow;
        colClosed = colNow;
      }
    }
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final cell = b.at(r, c);
        if (cell.filled || cell.blocked) continue;
        var openSides = 0;
        if (r > 0 && b.at(r - 1, c).isOccupiable) openSides++;
        if (r < n - 1 && b.at(r + 1, c).isOccupiable) openSides++;
        if (c > 0 && b.at(r, c - 1).isOccupiable) openSides++;
        if (c < n - 1 && b.at(r, c + 1).isOccupiable) openSides++;
        if (openSides == 0) value -= 30;
        if (openSides == 1) value -= 6;
      }
    }
    return value;
  }
}

class _Move {
  const _Move(this.uid, this.row, this.col, this.value);
  final String uid;
  final int row;
  final int col;
  final int value;
}
