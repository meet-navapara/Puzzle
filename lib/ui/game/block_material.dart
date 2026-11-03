import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';

/// Shared glazed-petal look for board cells and tray pieces.
///
/// A filled block is three layers: a vertical colour gradient, a darker
/// base rim underneath (the raised look), and a [gloss] sheen on top.
class BlockMaterial {
  BlockMaterial._();

  static BoxDecoration filled({
    required Color color,
    required PetalSurfaces surfaces,
    required bool isLight,
    required double radius,
    bool lifted = false,
    bool placing = false,
    double borderWidth = 1.1,
    Color? borderOverride,
  }) {
    final borderColor =
        borderOverride ??
        (isLight
            ? Color.lerp(color, Colors.black, 0.16)!
            : Color.lerp(color, Colors.white, 0.28)!);
    final rim = Color.lerp(color, Colors.black, isLight ? 0.26 : 0.38)!;

    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, isLight ? 0.2 : 0.22)!,
          color,
          Color.lerp(color, Colors.black, isLight ? 0.06 : 0.1)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      boxShadow: [
        BoxShadow(color: rim, offset: const Offset(0, 2)),
        if (placing)
          BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 10)
        else if (lifted)
          ...PetalShadows.lift(surfaces.shadow, light: isLight)
        else
          ...PetalShadows.blockDepth(surfaces.shadow, light: isLight),
      ],
    );
  }

  /// Sheen across the top half of a filled block.
  static BoxDecoration gloss(double radius) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.34),
          Colors.white.withValues(alpha: 0),
        ],
      ),
    );
  }

  /// An empty bed, slightly sunken: darker at the top edge.
  static BoxDecoration empty({
    required PetalSurfaces surfaces,
    required bool isLight,
    required double radius,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: surfaces.cellBorder),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(surfaces.emptyCell, Colors.black, isLight ? 0.06 : 0.2)!,
          surfaces.emptyCell,
        ],
        stops: const [0.0, 0.45],
      ),
    );
  }

  /// Stone cell: muted, matte, with a faint top highlight.
  static BoxDecoration stone({
    required PetalSurfaces surfaces,
    required bool isLight,
    required double radius,
  }) {
    final c = surfaces.blockedCell;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Color.lerp(c, Colors.white, 0.12)!),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(c, Colors.white, 0.1)!, c],
      ),
      boxShadow: [
        BoxShadow(
          color: Color.lerp(c, Colors.black, 0.4)!,
          offset: const Offset(0, 1.5),
        ),
      ],
    );
  }
}
