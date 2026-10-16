import 'package:flutter/foundation.dart';

/// Transparent scoring model for PetalGrid.
@immutable
class ScoreBreakdown {
  const ScoreBreakdown({
    this.cellsPlaced = 0,
    this.linesCleared = 0,
    this.multiLineBonus = 0,
    this.comboBonus = 0,
    this.bloomBonus = 0,
    this.totalDelta = 0,
  });

  final int cellsPlaced;
  final int linesCleared;
  final int multiLineBonus;
  final int comboBonus;
  final int bloomBonus;
  final int totalDelta;

  static const int pointsPerCell = 1;
  static const int pointsPerLine = 10;
  static const int multiLineBase = 5;
  static const int comboBase = 8;

  /// Compute score for a placement that cleared [lineCount] lines at [combo].
  /// [combo] is consecutive clear streaks (1 = first clear in streak).
  factory ScoreBreakdown.forPlacement({
    required int placedCells,
    required int lineCount,
    required int combo,
    int bloomBonus = 0,
  }) {
    assert(placedCells >= 0);
    assert(lineCount >= 0);
    assert(combo >= 0);
    assert(bloomBonus >= 0);

    final cells = placedCells * pointsPerCell;
    final lines = lineCount * pointsPerLine;
    final multi = lineCount > 1
        ? multiLineBase * lineCount * (lineCount - 1)
        : 0;
    final comboPts = lineCount > 0 && combo > 1
        ? comboBase * (combo - 1) * lineCount
        : 0;
    final total = cells + lines + multi + comboPts + bloomBonus;
    return ScoreBreakdown(
      cellsPlaced: cells,
      linesCleared: lines,
      multiLineBonus: multi,
      comboBonus: comboPts,
      bloomBonus: bloomBonus,
      totalDelta: total < 0 ? 0 : total,
    );
  }
}

@immutable
class ClearResult {
  const ClearResult({
    required this.clearedRows,
    required this.clearedCols,
    required this.cellsCleared,
  });

  final List<int> clearedRows;
  final List<int> clearedCols;
  final int cellsCleared;

  int get lineCount => clearedRows.length + clearedCols.length;
  bool get hasClears => lineCount > 0;
}
