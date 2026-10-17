import 'package:block_garden/game/board.dart';
import 'package:block_garden/game/shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Board placement', () {
    test('places mono inside bounds', () {
      final board = Board(size: 8);
      final next = board.tryPlace(ShapeCatalog.mono, 0, 0, 1);
      expect(next, isNotNull);
      expect(next!.at(0, 0).filled, isTrue);
      expect(next.at(0, 0).colorIndex, 1);
    });

    test('rejects out of bounds', () {
      final board = Board(size: 8);
      expect(board.tryPlace(ShapeCatalog.square, 7, 7, 0), isNull);
    });

    test('rejects overlap', () {
      var board = Board(size: 8);
      board = board.tryPlace(ShapeCatalog.mono, 2, 2, 0)!;
      expect(board.tryPlace(ShapeCatalog.mono, 2, 2, 1), isNull);
    });

    test('rejects blocked cells', () {
      final board = Board(size: 8).applyPattern(blocked: [(1, 1)]);
      expect(board.tryPlace(ShapeCatalog.mono, 1, 1, 0), isNull);
    });
  });

  group('Line clears', () {
    test('clears a full row', () {
      var board = Board(size: 4);
      for (var c = 0; c < 4; c++) {
        board = board.tryPlace(ShapeCatalog.mono, 0, c, 0)!;
      }
      final clear = board.findClears();
      expect(clear.clearedRows, [0]);
      expect(clear.lineCount, 1);
      final after = board.applyClears(clear);
      expect(after.at(0, 0).filled, isFalse);
    });

    test('clears row and column together once', () {
      var board = Board(size: 4);
      // Fill entire board.
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          board = board.tryPlace(ShapeCatalog.mono, r, c, 0)!;
        }
      }
      final clear = board.findClears();
      expect(clear.clearedRows.length, 4);
      expect(clear.clearedCols.length, 4);
      final after = board.applyClears(clear);
      expect(after.filledCount, 0);
    });
  });

  group('Clear preview', () {
    test('previewClears reports row that would bloom', () {
      var board = Board(size: 4);
      for (var c = 0; c < 3; c++) {
        board = board.tryPlace(ShapeCatalog.mono, 0, c, 0)!;
      }
      final preview = board.previewClears(ShapeCatalog.mono, 0, 3, 1);
      expect(preview.clearedRows, [0]);
      expect(preview.hasClears, isTrue);
      // Board itself is unchanged until place.
      expect(board.at(0, 3).filled, isFalse);
    });
  });

  group('Fit detection', () {
    test('detects no moves', () {
      var board = Board(size: 4);
      // Fill all cells so nothing fits.
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          board = board.tryPlace(ShapeCatalog.mono, r, c, 0)!;
        }
      }
      expect(board.canFitAnywhere(ShapeCatalog.mono), isFalse);
    });
  });
}
