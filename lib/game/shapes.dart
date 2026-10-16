import 'piece.dart';

/// Original PetalGrid polyomino catalog (not Tetris trademark shapes as a set —
/// common polyomino geometry is public domain; branding/presentation is original).
class ShapeCatalog {
  ShapeCatalog._();

  static final PieceShape mono = PieceShape(
    id: 'mono',
    displayName: 'Seed',
    cells: const [(0, 0)],
  );

  static final PieceShape duoH = PieceShape(
    id: 'duo_h',
    displayName: 'Stem',
    cells: const [(0, 0), (0, 1)],
  );

  static final PieceShape duoV = PieceShape(
    id: 'duo_v',
    displayName: 'Sprout',
    cells: const [(0, 0), (1, 0)],
  );

  static final PieceShape trioH = PieceShape(
    id: 'trio_h',
    displayName: 'Reed',
    cells: const [(0, 0), (0, 1), (0, 2)],
  );

  static final PieceShape trioV = PieceShape(
    id: 'trio_v',
    displayName: 'Reed Tall',
    cells: const [(0, 0), (1, 0), (2, 0)],
  );

  static final PieceShape corner = PieceShape(
    id: 'corner',
    displayName: 'Bud',
    cells: const [(0, 0), (0, 1), (1, 0)],
  );

  static final PieceShape square = PieceShape(
    id: 'square',
    displayName: 'Petal Cluster',
    cells: const [(0, 0), (0, 1), (1, 0), (1, 1)],
  );

  static final PieceShape tee = PieceShape(
    id: 'tee',
    displayName: 'Bloom Tee',
    cells: const [(0, 0), (0, 1), (0, 2), (1, 1)],
  );

  static final PieceShape plus = PieceShape(
    id: 'plus',
    displayName: 'Flower',
    cells: const [(0, 1), (1, 0), (1, 1), (1, 2), (2, 1)],
  );

  static final PieceShape longH = PieceShape(
    id: 'long_h',
    displayName: 'Vine',
    cells: const [(0, 0), (0, 1), (0, 2), (0, 3)],
  );

  static final PieceShape longV = PieceShape(
    id: 'long_v',
    displayName: 'Vine Tall',
    cells: const [(0, 0), (1, 0), (2, 0), (3, 0)],
  );

  static final PieceShape lShape = PieceShape(
    id: 'l',
    displayName: 'Leaf L',
    cells: const [(0, 0), (1, 0), (2, 0), (2, 1)],
  );

  static final PieceShape jShape = PieceShape(
    id: 'j',
    displayName: 'Leaf J',
    cells: const [(0, 1), (1, 1), (2, 0), (2, 1)],
  );

  static final PieceShape sShape = PieceShape(
    id: 's',
    displayName: 'Wave',
    cells: const [(0, 1), (0, 2), (1, 0), (1, 1)],
  );

  static final PieceShape zShape = PieceShape(
    id: 'z',
    displayName: 'Zig',
    cells: const [(0, 0), (0, 1), (1, 1), (1, 2)],
  );

  static final PieceShape bigL = PieceShape(
    id: 'big_l',
    displayName: 'Canopy',
    cells: const [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)],
  );

  static final PieceShape uShape = PieceShape(
    id: 'u',
    displayName: 'Cup',
    cells: const [(0, 0), (1, 0), (1, 1), (1, 2), (0, 2)],
  );

  static final List<PieceShape> all = [
    mono,
    duoH,
    duoV,
    trioH,
    trioV,
    corner,
    square,
    tee,
    plus,
    longH,
    longV,
    lShape,
    jShape,
    sShape,
    zShape,
    bigL,
    uShape,
  ];

  static final Map<String, PieceShape> byId = {for (final s in all) s.id: s};

  static PieceShape? find(String id) => byId[id];

  /// Starter-friendly shapes for early campaign / tutorial.
  static final List<PieceShape> easyPool = [
    mono,
    duoH,
    duoV,
    trioH,
    trioV,
    corner,
    square,
  ];

  static final List<PieceShape> standardPool = [
    ...easyPool,
    tee,
    longH,
    longV,
    lShape,
    jShape,
    sShape,
    zShape,
  ];

  static final List<PieceShape> advancedPool = [
    ...standardPool,
    plus,
    bigL,
    uShape,
  ];
}
