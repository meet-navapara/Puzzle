import 'package:flutter/material.dart';

import '../../game/board.dart';
import '../../game/cell.dart';
import '../../game/piece.dart';
import '../theme/petal_theme.dart';
import 'block_material.dart';
import 'game_fx.dart';
import 'placement_mapper.dart';

class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.boardKey,
    required this.board,
    this.ghostShape,
    this.ghostRow,
    this.ghostCol,
    this.ghostValid = false,
    this.ghostColorIndex = 0,
    this.onCellTap,
    this.placePulseCells = const {},
    this.placeScale = 1.0,
    this.pruneMode = false,
    this.clearRows = const [],
    this.clearCols = const [],
    this.clearToken = 0,
    this.clearActive = false,
    this.reducedMotion = false,
    this.onClearFxFinished,
  });

  /// Key of the board's painted bounds — used by [BoardPlacementMapper].
  final GlobalKey boardKey;
  final Board board;
  final PieceShape? ghostShape;
  final int? ghostRow;
  final int? ghostCol;
  final bool ghostValid;
  final int ghostColorIndex;
  final void Function(int row, int col)? onCellTap;
  final Set<(int, int)> placePulseCells;
  final double placeScale;
  final bool pruneMode;
  final List<int> clearRows;
  final List<int> clearCols;
  final int clearToken;
  final bool clearActive;
  final bool reducedMotion;
  final VoidCallback? onClearFxFinished;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Semantics(
            label: 'PetalGrid garden board, ${board.size} by ${board.size}',
            child: DecoratedBox(
              key: boardKey,
              decoration: BoxDecoration(
                color: surfaces.boardFrame,
                borderRadius: BorderRadius.circular(PetalRadius.lg),
                border: Border.all(
                  color: surfaces.panelBorder.withValues(alpha: 0.7),
                ),
                boxShadow: PetalShadows.panel(surfaces.shadow, light: isLight),
              ),
              child: Padding(
                padding: const EdgeInsets.all(
                  BoardPlacementMapper.innerPadding,
                ),
                child: Stack(
                  children: [
                    Column(
                      children: List.generate(board.size, (r) {
                        return Expanded(
                          child: Row(
                            children: List.generate(board.size, (c) {
                              final placing =
                                  placePulseCells.contains((r, c));
                              return Expanded(
                                child: _CellTile(
                                  cell: board.at(r, c),
                                  placing: placing,
                                  placeScale: placing ? placeScale : 1.0,
                                  pruneMode:
                                      pruneMode && board.at(r, c).filled,
                                  onTap: onCellTap == null
                                      ? null
                                      : () => onCellTap!(r, c),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                    if (clearActive &&
                        (clearRows.isNotEmpty || clearCols.isNotEmpty))
                      Positioned.fill(
                        child: LineClearFx(
                          key: ValueKey(clearToken),
                          boardSize: board.size,
                          clearedRows: clearRows,
                          clearedCols: clearCols,
                          token: clearToken,
                          reducedMotion: reducedMotion,
                          onFinished: onClearFxFinished,
                        ),
                      ),
                    if (ghostShape != null &&
                        ghostRow != null &&
                        ghostCol != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _GhostPainter(
                              shape: ghostShape!,
                              row: ghostRow!,
                              col: ghostCol!,
                              size: board.size,
                              valid: ghostValid,
                              softGlow: !isLight,
                              color: ghostValid
                                  ? surfaces
                                        .blockPalette[ghostColorIndex %
                                            surfaces.blockPalette.length]
                                        .withValues(
                                          alpha: isLight ? 0.8 : 0.62,
                                        )
                                  : surfaces.invalidGhost,
                              glow: ghostValid
                                  ? surfaces.accent.withValues(alpha: 0.35)
                                  : surfaces.danger.withValues(alpha: 0.28),
                              stroke: ghostValid
                                  ? surfaces.onPanel.withValues(
                                      alpha: isLight ? 0.72 : 0.55,
                                    )
                                  : surfaces.onPanel.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CellTile extends StatelessWidget {
  const _CellTile({
    required this.cell,
    required this.placing,
    required this.placeScale,
    required this.pruneMode,
    this.onTap,
  });

  final Cell cell;
  final bool placing;
  final double placeScale;
  final bool pruneMode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    BoxDecoration decoration;
    if (cell.blocked) {
      decoration = BoxDecoration(
        color: surfaces.blockedCell,
        borderRadius: BorderRadius.circular(PetalRadius.cell),
        border: Border.all(color: surfaces.cellBorder),
      );
    } else if (cell.filled) {
      final fill = surfaces
          .blockPalette[cell.colorIndex % surfaces.blockPalette.length];
      decoration = BlockMaterial.filled(
        color: placing
            ? Color.lerp(
                fill,
                surfaces.placeFlash,
                isLight ? 0.22 : 0.35,
              )!
            : fill,
        surfaces: surfaces,
        isLight: isLight,
        radius: PetalRadius.cell,
        placing: placing,
        borderWidth: pruneMode ? 2 : (isLight ? 1.15 : 1.0),
        borderOverride: pruneMode ? surfaces.accentSoft : null,
      );
    } else {
      decoration = BlockMaterial.empty(
        surfaces: surfaces,
        isLight: isLight,
        radius: PetalRadius.cell,
      );
    }

    return Semantics(
      button: onTap != null,
      label: cell.blocked
          ? 'Blocked cell'
          : cell.filled
          ? 'Filled petal cell'
          : 'Empty cell',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: placeScale,
          duration: PetalMotion.place,
          curve: PetalMotion.settle,
          child: AnimatedContainer(
            duration: PetalMotion.instant,
            margin: const EdgeInsets.all(1.75),
            decoration: decoration,
            child: !cell.filled && !cell.blocked
                ? Center(
                    child: Container(
                      width: 3.5,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: surfaces.onPanel.withValues(
                          alpha: isLight ? 0.14 : 0.08,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _GhostPainter extends CustomPainter {
  _GhostPainter({
    required this.shape,
    required this.row,
    required this.col,
    required this.size,
    required this.valid,
    required this.color,
    required this.glow,
    required this.stroke,
    this.softGlow = true,
  });

  final PieceShape shape;
  final int row;
  final int col;
  final int size;
  final bool valid;
  final Color color;
  final Color glow;
  final Color stroke;
  final bool softGlow;

  @override
  void paint(Canvas canvas, Size sz) {
    final cell = sz.width / size;
    final fill = Paint()..color = color;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = valid ? (softGlow ? 2.2 : 2.5) : 1.8
      ..color = stroke;
    final aura = Paint()
      ..color = glow
      ..maskFilter =
          softGlow ? const MaskFilter.blur(BlurStyle.normal, 6) : null;

    for (final (dr, dc) in shape.cells) {
      final r = row + dr;
      final c = col + dc;
      if (r < 0 || c < 0 || r >= size || c >= size) continue;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(c * cell + 2.5, r * cell + 2.5, cell - 5, cell - 5),
        const Radius.circular(7),
      );
      if (softGlow) {
        canvas.drawRRect(rect, aura);
      }
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GhostPainter old) =>
      old.row != row ||
      old.col != col ||
      old.valid != valid ||
      old.shape != shape ||
      old.color != color ||
      old.glow != glow ||
      old.stroke != stroke ||
      old.softGlow != softGlow;
}
