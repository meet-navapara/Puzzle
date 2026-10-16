import 'package:flutter/foundation.dart';

/// A single board cell. Immutable; board stores a grid of these.
@immutable
class Cell {
  const Cell({
    this.filled = false,
    this.colorIndex = 0,
    this.blocked = false,
    this.locked = false,
  });

  final bool filled;
  final int colorIndex;
  final bool blocked;
  final bool locked;

  bool get isOccupiable => !blocked && !filled && !locked;
  bool get isEmpty => !filled && !blocked;

  Cell copyWith({bool? filled, int? colorIndex, bool? blocked, bool? locked}) {
    return Cell(
      filled: filled ?? this.filled,
      colorIndex: colorIndex ?? this.colorIndex,
      blocked: blocked ?? this.blocked,
      locked: locked ?? this.locked,
    );
  }

  Map<String, dynamic> toJson() => {
    'f': filled,
    'c': colorIndex,
    'b': blocked,
    'l': locked,
  };

  factory Cell.fromJson(Map<String, dynamic> json) => Cell(
    filled: json['f'] as bool? ?? false,
    colorIndex: json['c'] as int? ?? 0,
    blocked: json['b'] as bool? ?? false,
    locked: json['l'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          filled == other.filled &&
          colorIndex == other.colorIndex &&
          blocked == other.blocked &&
          locked == other.locked;

  @override
  int get hashCode => Object.hash(filled, colorIndex, blocked, locked);
}
