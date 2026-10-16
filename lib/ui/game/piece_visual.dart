import 'package:flutter/material.dart';

import '../../game/piece.dart';
import '../theme/petal_theme.dart';
import 'block_material.dart';

/// Shared polyomino painter used in the tray and drag feedback.
class PieceVisual extends StatelessWidget {
  const PieceVisual({
    super.key,
    required this.piece,
    required this.maxExtent,
    this.selected = false,
    this.lifted = false,
    this.dimmed = false,

    /// When true, draw only the blocks (no tray card chrome).
    this.bare = false,
  });

  final TrayPiece piece;
  final double maxExtent;
  final bool selected;
  final bool lifted;
  final bool dimmed;
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final shape = piece.shape;
    final maxR = shape.cells.map((c) => c.$1).fold(0, (a, b) => a > b ? a : b);
    final maxC = shape.cells.map((c) => c.$2).fold(0, (a, b) => a > b ? a : b);
    final rows = maxR + 1;
    final cols = maxC + 1;
    final cell = bare
        ? (maxExtent / (rows > cols ? rows : cols)).clamp(18.0, 36.0)
        : (maxExtent / (rows > cols ? rows : cols)).clamp(12.0, 28.0);
    final color =
        surfaces.blockPalette[piece.colorIndex % surfaces.blockPalette.length];

    final blocks = SizedBox(
      width: cols * cell,
      height: rows * cell,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (r, c) in shape.cells)
            Positioned(
              left: c * cell,
              top: r * cell,
              child: Container(
                width: cell - (bare ? 3 : 2.5),
                height: cell - (bare ? 3 : 2.5),
                decoration: BlockMaterial.filled(
                  color: color,
                  surfaces: surfaces,
                  isLight: isLight,
                  radius: bare ? 7 : PetalRadius.block,
                  lifted: lifted || bare,
                  borderWidth: isLight ? (bare ? 1.4 : 1.15) : (bare ? 1.2 : 0.9),
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label:
          'Block ${shape.displayName.isEmpty ? shape.id : shape.displayName}',
      child: AnimatedOpacity(
        duration: PetalMotion.tap,
        opacity: dimmed ? 0.22 : 1,
        child: bare
            ? blocks
            : AnimatedContainer(
                duration: PetalMotion.tap,
                constraints: BoxConstraints(
                  minWidth: maxExtent + 4,
                  minHeight: maxExtent + 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? surfaces.accent.withValues(alpha: isLight ? 0.1 : 0.12)
                      : surfaces.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? surfaces.accent.withValues(alpha: 0.65)
                        : surfaces.panelBorder,
                    width: selected ? 1.8 : 1,
                  ),
                ),
                child: Center(child: blocks),
              ),
      ),
    );
  }
}
