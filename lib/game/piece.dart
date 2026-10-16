import 'package:flutter/foundation.dart';

/// A placeable polyomino defined by relative (row, col) offsets from origin.
@immutable
class PieceShape {
  const PieceShape({
    required this.id,
    required this.cells,
    this.displayName = '',
  });

  final String id;
  final List<(int, int)> cells;
  final String displayName;

  int get width {
    if (cells.isEmpty) return 0;
    final cols = cells.map((c) => c.$2);
    return cols.reduce((a, b) => a > b ? a : b) -
        cols.reduce((a, b) => a < b ? a : b) +
        1;
  }

  int get height {
    if (cells.isEmpty) return 0;
    final rows = cells.map((c) => c.$1);
    return rows.reduce((a, b) => a > b ? a : b) -
        rows.reduce((a, b) => a < b ? a : b) +
        1;
  }

  int get cellCount => cells.length;

  /// Normalize so minimum row/col is 0.
  PieceShape normalized() {
    if (cells.isEmpty) return this;
    final minR = cells.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    final minC = cells.map((c) => c.$2).reduce((a, b) => a < b ? a : b);
    return PieceShape(
      id: id,
      displayName: displayName,
      cells: cells.map((c) => (c.$1 - minR, c.$2 - minC)).toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieceShape &&
          id == other.id &&
          listEquals(
            cells.map((e) => '${e.$1},${e.$2}').toList(),
            other.cells.map((e) => '${e.$1},${e.$2}').toList(),
          );

  @override
  int get hashCode => Object.hash(id, Object.hashAll(cells));
}

/// An instance of a shape in the player's tray.
@immutable
class TrayPiece {
  const TrayPiece({
    required this.uid,
    required this.shape,
    required this.colorIndex,
    this.used = false,
  });

  final String uid;
  final PieceShape shape;
  final int colorIndex;
  final bool used;

  TrayPiece copyWith({bool? used}) => TrayPiece(
    uid: uid,
    shape: shape,
    colorIndex: colorIndex,
    used: used ?? this.used,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'shapeId': shape.id,
    'color': colorIndex,
    'used': used,
  };
}
