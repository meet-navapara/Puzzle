import 'package:flutter/foundation.dart';

import 'cell.dart';
import 'piece.dart';
import 'scoring.dart';

/// Immutable square board. Pure logic — no Flutter widgets.
@immutable
class Board {
  Board({required this.size, List<Cell>? cells})
    : cells = List.unmodifiable(
        cells ?? List.generate(size * size, (_) => const Cell()),
      ) {
    assert(size >= 4 && size <= 12);
    assert(this.cells.length == size * size);
  }

  final int size;
  final List<Cell> cells;

  Cell at(int row, int col) {
    assert(row >= 0 && row < size && col >= 0 && col < size);
    return cells[row * size + col];
  }

  bool inBounds(int row, int col) =>
      row >= 0 && row < size && col >= 0 && col < size;

  Board copyWithCells(List<Cell> next) => Board(size: size, cells: next);

  Board withCell(int row, int col, Cell cell) {
    final next = List<Cell>.from(cells);
    next[row * size + col] = cell;
    return copyWithCells(next);
  }

  /// Apply blocked / prefilled pattern from campaign config.
  Board applyPattern({
    List<(int, int)> blocked = const [],
    List<(int, int, int)> prefilled = const [],
  }) {
    var b = this;
    for (final (r, c) in blocked) {
      if (b.inBounds(r, c)) {
        b = b.withCell(r, c, const Cell(blocked: true));
      }
    }
    for (final (r, c, color) in prefilled) {
      if (b.inBounds(r, c)) {
        b = b.withCell(r, c, Cell(filled: true, colorIndex: color));
      }
    }
    return b;
  }

  bool canPlace(PieceShape shape, int anchorRow, int anchorCol) {
    for (final (dr, dc) in shape.cells) {
      final r = anchorRow + dr;
      final c = anchorCol + dc;
      if (!inBounds(r, c)) return false;
      final cell = at(r, c);
      if (!cell.isOccupiable) return false;
    }
    return true;
  }

  /// Returns null if placement illegal.
  Board? tryPlace(
    PieceShape shape,
    int anchorRow,
    int anchorCol,
    int colorIndex,
  ) {
    if (!canPlace(shape, anchorRow, anchorCol)) return null;
    var next = List<Cell>.from(cells);
    for (final (dr, dc) in shape.cells) {
      final i = (anchorRow + dr) * size + (anchorCol + dc);
      next[i] = Cell(filled: true, colorIndex: colorIndex);
    }
    return copyWithCells(next);
  }

  /// Clear a single occupied, non-blocked cell (Bloom Prune).
  Board? pruneCell(int row, int col) {
    if (!inBounds(row, col)) return null;
    final cell = at(row, col);
    if (!cell.filled || cell.blocked) return null;
    return withCell(row, col, const Cell());
  }

  /// Rows/cols that would bloom if [shape] were placed at the anchor.
  ClearResult previewClears(
    PieceShape shape,
    int anchorRow,
    int anchorCol,
    int colorIndex,
  ) {
    final placed = tryPlace(shape, anchorRow, anchorCol, colorIndex);
    if (placed == null) {
      return const ClearResult(
        clearedRows: [],
        clearedCols: [],
        cellsCleared: 0,
      );
    }
    return placed.findClears();
  }

  ClearResult findClears() {
    final rows = <int>[];
    final cols = <int>[];

    for (var r = 0; r < size; r++) {
      var full = true;
      var hasOccupiable = false;
      for (var c = 0; c < size; c++) {
        final cell = at(r, c);
        if (cell.blocked) continue;
        hasOccupiable = true;
        if (!cell.filled) {
          full = false;
          break;
        }
      }
      if (full && hasOccupiable) rows.add(r);
    }

    for (var c = 0; c < size; c++) {
      var full = true;
      var hasOccupiable = false;
      for (var r = 0; r < size; r++) {
        final cell = at(r, c);
        if (cell.blocked) continue;
        hasOccupiable = true;
        if (!cell.filled) {
          full = false;
          break;
        }
      }
      if (full && hasOccupiable) cols.add(c);
    }

    var cleared = 0;
    for (final r in rows) {
      for (var c = 0; c < size; c++) {
        if (!at(r, c).blocked && at(r, c).filled) cleared++;
      }
    }
    for (final c in cols) {
      for (var r = 0; r < size; r++) {
        if (rows.contains(r)) continue;
        if (!at(r, c).blocked && at(r, c).filled) cleared++;
      }
    }

    return ClearResult(
      clearedRows: rows,
      clearedCols: cols,
      cellsCleared: cleared,
    );
  }

  Board applyClears(ClearResult result) {
    if (!result.hasClears) return this;
    final next = List<Cell>.from(cells);
    for (final r in result.clearedRows) {
      for (var c = 0; c < size; c++) {
        final i = r * size + c;
        if (!next[i].blocked) next[i] = const Cell();
      }
    }
    for (final c in result.clearedCols) {
      for (var r = 0; r < size; r++) {
        final i = r * size + c;
        if (!next[i].blocked) next[i] = const Cell();
      }
    }
    return copyWithCells(next);
  }

  bool canFitAnywhere(PieceShape shape) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (canPlace(shape, r, c)) return true;
      }
    }
    return false;
  }

  bool anyPieceFits(Iterable<TrayPiece> pieces) {
    for (final p in pieces) {
      if (!p.used && canFitAnywhere(p.shape)) return true;
    }
    return false;
  }

  int get filledCount => cells.where((c) => c.filled).length;

  Map<String, dynamic> toJson() => {
    'size': size,
    'cells': cells.map((c) => c.toJson()).toList(),
  };

  factory Board.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final raw = (json['cells'] as List)
        .map((e) => Cell.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return Board(size: size, cells: raw);
  }
}
