import 'package:flutter/widgets.dart';

import '../../game/board.dart';
import '../../game/piece.dart';

/// Result of mapping a pointer to a board anchor cell.
@immutable
class PlacementTarget {
  const PlacementTarget({
    required this.row,
    required this.col,
    required this.valid,
    required this.overBoard,
  });

  /// Top-left anchor row for the piece shape.
  final int row;

  /// Top-left anchor column for the piece shape.
  final int col;

  /// True when the shape fits (in-bounds + no overlap/blocked).
  final bool valid;

  /// True when the aim point lies over the board widget.
  final bool overBoard;
}

/// Single shared pointer → grid mapping used for preview and final placement.
///
/// Board widgets must use [BoardPlacementMapper.innerPadding] so visual cells
/// and hit-testing agree.
class BoardPlacementMapper {
  BoardPlacementMapper._();

  /// Must match the board's inner padding around the cell grid.
  static const double innerPadding = 6;

  /// Lift aim point above the finger (in cell heights) so the piece stays
  /// visible and the ghost matches where the player expects.
  static const double defaultFingerLiftCells = 0.85;

  /// Soft margin around the board that still counts as "over board".
  static const double edgeSlackCells = 0.35;

  /// Convert a global pointer position into a placement anchor.
  static PlacementTarget? fromGlobalPointer({
    required GlobalKey boardKey,
    required Offset globalPointer,
    required Board board,
    required PieceShape shape,
    double fingerLift = defaultFingerLiftCells,
  }) {
    final box = boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return null;

    final local = box.globalToLocal(globalPointer);
    return fromLocalOffset(
      local: local,
      boardSizePx: box.size,
      board: board,
      shape: shape,
      fingerLift: fingerLift,
    );
  }

  /// Pure geometry — unit-testable without a widget tree.
  static PlacementTarget fromLocalOffset({
    required Offset local,
    required Size boardSizePx,
    required Board board,
    required PieceShape shape,
    double fingerLift = defaultFingerLiftCells,
  }) {
    final pad = innerPadding;
    final usableW = (boardSizePx.width - pad * 2).clamp(1.0, double.infinity);
    final usableH = (boardSizePx.height - pad * 2).clamp(1.0, double.infinity);
    final cellW = usableW / board.size;
    final cellH = usableH / board.size;

    // Aim above the finger so the piece preview stays visible.
    final aim = Offset(local.dx, local.dy - cellH * fingerLift);
    final slackX = cellW * edgeSlackCells;
    final slackY = cellH * edgeSlackCells;

    final overBoard =
        aim.dx >= -slackX &&
        aim.dy >= -slackY &&
        aim.dx <= boardSizePx.width + slackX &&
        aim.dy <= boardSizePx.height + slackY;

    // Center the shape's bounding box on the aim point, then snap to grid.
    final shapeW = shape.width * cellW;
    final shapeH = shape.height * cellH;
    final topLeftX = aim.dx - shapeW / 2;
    final topLeftY = aim.dy - shapeH / 2;

    var col = ((topLeftX - pad) / cellW).round();
    var row = ((topLeftY - pad) / cellH).round();

    final maxCol = board.size - shape.width;
    final maxRow = board.size - shape.height;
    col = col.clamp(0, maxCol < 0 ? 0 : maxCol);
    row = row.clamp(0, maxRow < 0 ? 0 : maxRow);

    final valid = overBoard && board.canPlace(shape, row, col);
    return PlacementTarget(
      row: row,
      col: col,
      valid: valid,
      overBoard: overBoard,
    );
  }

  /// Tap-to-place: prefer an anchor where the shape covers the tapped cell.
  static PlacementTarget fromCellTap({
    required Board board,
    required PieceShape shape,
    required int tappedRow,
    required int tappedCol,
  }) {
    // Try every cell of the shape as the one covering the tap.
    for (final (dr, dc) in shape.cells) {
      final row = tappedRow - dr;
      final col = tappedCol - dc;
      if (row < 0 || col < 0) continue;
      if (row + shape.height > board.size || col + shape.width > board.size) {
        continue;
      }
      if (board.canPlace(shape, row, col)) {
        return PlacementTarget(
          row: row,
          col: col,
          valid: true,
          overBoard: true,
        );
      }
    }

    // Fallback: clamp top-left to tapped cell (legacy behaviour).
    final maxCol = board.size - shape.width;
    final maxRow = board.size - shape.height;
    final col = tappedCol.clamp(0, maxCol < 0 ? 0 : maxCol);
    final row = tappedRow.clamp(0, maxRow < 0 ? 0 : maxRow);
    return PlacementTarget(
      row: row,
      col: col,
      valid: board.canPlace(shape, row, col),
      overBoard: true,
    );
  }
}
