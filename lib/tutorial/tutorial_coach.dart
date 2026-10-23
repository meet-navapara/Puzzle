import '../game/board.dart';
import '../game/game_engine.dart';
import '../game/piece.dart';

/// A legal placement chosen from the live tray and board.
class TutorialMove {
  const TutorialMove({
    required this.pieceUid,
    required this.row,
    required this.col,
    required this.cells,
    required this.lineClears,
    required this.reason,
  });

  final String pieceUid;
  final int row;
  final int col;
  final Set<(int, int)> cells;
  final int lineClears;
  final String reason;

  bool matches(String uid, int anchorRow, int anchorCol) =>
      uid == pieceUid && anchorRow == row && anchorCol == col;
}

/// Picks a teaching move from the current puzzle. Never assumes a fixed board.
class TutorialCoach {
  TutorialCoach._();

  static TutorialMove? bestMove(
    GameState state, {
    bool preferLineClear = false,
  }) {
    if (!state.isPlaying) return null;
    TutorialMove? best;
    var bestScore = -1;

    for (final piece in state.tray) {
      if (piece.used) continue;
      final shape = piece.shape;
      for (var r = 0; r < state.board.size; r++) {
        for (var c = 0; c < state.board.size; c++) {
          if (!state.board.canPlace(shape, r, c)) continue;
          final placed = state.board.tryPlace(shape, r, c, piece.colorIndex);
          if (placed == null) continue;
          final clear = placed.findClears();
          final cells = {
            for (final (dr, dc) in shape.cells) (r + dr, c + dc),
          };
          var score = clear.lineCount * 1000 + clear.cellsCleared * 15;
          score += _lineBuildScore(state.board, shape, r, c);
          score += shape.cellCount;
          if (preferLineClear && clear.lineCount == 0) score -= 40;
          if (score > bestScore) {
            bestScore = score;
            best = TutorialMove(
              pieceUid: piece.uid,
              row: r,
              col: c,
              cells: cells,
              lineClears: clear.lineCount,
              reason: _reason(clear.lineCount, shape),
            );
          }
        }
      }
    }
    return best;
  }

  static int _lineBuildScore(Board board, PieceShape shape, int row, int col) {
    var score = 0;
    final touchedRows = <int>{};
    final touchedCols = <int>{};
    for (final (dr, dc) in shape.cells) {
      touchedRows.add(row + dr);
      touchedCols.add(col + dc);
    }
    for (final r in touchedRows) {
      score += _filledInLine(board, row: r) * 4;
      if (shape.height == 1) score += 8;
    }
    for (final c in touchedCols) {
      score += _filledInLine(board, col: c) * 4;
      if (shape.width == 1) score += 6;
    }
    return score;
  }

  static int _filledInLine(Board board, {int? row, int? col}) {
    var n = 0;
    if (row != null) {
      for (var c = 0; c < board.size; c++) {
        if (board.at(row, c).filled) n++;
      }
    }
    if (col != null) {
      for (var r = 0; r < board.size; r++) {
        if (board.at(r, col).filled) n++;
      }
    }
    return n;
  }

  static String _reason(int lines, PieceShape shape) {
    if (lines >= 2) {
      return 'This plant fills more than one line, so those rows and columns bloom together.';
    }
    if (lines == 1) {
      return 'This plant finishes a full row or column. Those cells bloom away and your score jumps.';
    }
    final name = shape.displayName.isEmpty ? 'piece' : shape.displayName;
    return 'Plant the $name on the glowing cells. You are building toward a full line.';
  }
}
