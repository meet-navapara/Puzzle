import 'package:block_garden/game/board.dart';
import 'package:block_garden/game/shapes.dart';
import 'package:block_garden/ui/game/placement_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const boardPx = Size(320, 320); // 8 cells → 38.5px after pad
  final board = Board(size: 8);

  group('BoardPlacementMapper', () {
    test('center of board maps near middle for mono', () {
      final target = BoardPlacementMapper.fromLocalOffset(
        local: const Offset(160, 160),
        boardSizePx: boardPx,
        board: board,
        shape: ShapeCatalog.mono,
        fingerLift: 0,
      );
      expect(target.row, inInclusiveRange(2, 5));
      expect(target.col, inInclusiveRange(2, 5));
      expect(target.valid, isTrue);
    });

    test('preview and place use the same anchor', () {
      final a = BoardPlacementMapper.fromLocalOffset(
        local: const Offset(40, 40),
        boardSizePx: boardPx,
        board: board,
        shape: ShapeCatalog.square,
        fingerLift: 0,
      );
      final b = BoardPlacementMapper.fromLocalOffset(
        local: const Offset(40, 40),
        boardSizePx: boardPx,
        board: board,
        shape: ShapeCatalog.square,
        fingerLift: 0,
      );
      expect(a.row, b.row);
      expect(a.col, b.col);
      expect(a.valid, b.valid);
    });

    test('rejects overlap consistently', () {
      var filled = Board(size: 8);
      filled = filled.tryPlace(ShapeCatalog.square, 0, 0, 0)!;
      final target = BoardPlacementMapper.fromLocalOffset(
        local: const Offset(30, 30),
        boardSizePx: boardPx,
        board: filled,
        shape: ShapeCatalog.square,
        fingerLift: 0,
      );
      // Snaps near top-left; square at 0,0 overlaps → invalid.
      expect(target.valid, isFalse);
      expect(
        filled.canPlace(ShapeCatalog.square, target.row, target.col),
        isFalse,
      );
    });

    test('clamps anchors so shape stays on board', () {
      final target = BoardPlacementMapper.fromLocalOffset(
        local: const Offset(310, 310),
        boardSizePx: boardPx,
        board: board,
        shape: ShapeCatalog.square,
        fingerLift: 0,
      );
      expect(target.row, lessThanOrEqualTo(6));
      expect(target.col, lessThanOrEqualTo(6));
      expect(target.row, greaterThanOrEqualTo(0));
      expect(target.col, greaterThanOrEqualTo(0));
    });

    test('cell tap clamp matches canPlace', () {
      final target = BoardPlacementMapper.fromCellTap(
        board: board,
        shape: ShapeCatalog.longH,
        tappedRow: 7,
        tappedCol: 7,
      );
      expect(target.row, 7);
      expect(target.col, lessThanOrEqualTo(4));
      expect(
        board.canPlace(ShapeCatalog.longH, target.row, target.col),
        target.valid,
      );
    });

    test('edges remain placeable for mono', () {
      for (final local in const [
        Offset(10, 10),
        Offset(310, 10),
        Offset(10, 310),
        Offset(310, 310),
      ]) {
        final target = BoardPlacementMapper.fromLocalOffset(
          local: local,
          boardSizePx: boardPx,
          board: board,
          shape: ShapeCatalog.mono,
          fingerLift: 0,
        );
        expect(target.valid, isTrue, reason: 'local $local');
      }
    });

    test('moving from blocked hover to empty cell becomes valid', () {
      var filled = Board(size: 8);
      filled = filled.tryPlace(ShapeCatalog.square, 0, 0, 0)!;

      final blocked = BoardPlacementMapper.fromLocalOffset(
        local: const Offset(30, 30),
        boardSizePx: boardPx,
        board: filled,
        shape: ShapeCatalog.square,
        fingerLift: 0,
      );
      expect(blocked.valid, isFalse);

      // Far from the occupied corner — must not keep the previous invalid state.
      final open = BoardPlacementMapper.fromLocalOffset(
        local: const Offset(240, 240),
        boardSizePx: boardPx,
        board: filled,
        shape: ShapeCatalog.square,
        fingerLift: 0,
      );
      expect(open.valid, isTrue);
      expect(open.row != blocked.row || open.col != blocked.col, isTrue);
      expect(
        filled.canPlace(ShapeCatalog.square, open.row, open.col),
        isTrue,
      );
    });
  });
}
