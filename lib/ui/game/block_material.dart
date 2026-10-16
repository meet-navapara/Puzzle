import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';

/// Shared filled-block look for board cells and tray pieces.
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
    final borderColor = borderOverride ??
        (isLight
            ? Color.lerp(color, const Color(0xFF1A1A1A), 0.24)!
            : Color.lerp(color, Colors.white, 0.18)!);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, isLight ? 0.14 : 0.12)!,
          color,
          Color.lerp(color, Colors.black, isLight ? 0.08 : 0.16)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ),
      boxShadow: placing && !isLight
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ]
          : lifted
          ? PetalShadows.lift(surfaces.shadow, light: isLight)
          : PetalShadows.blockDepth(surfaces.shadow, light: isLight),
    );
  }

  static BoxDecoration empty({
    required PetalSurfaces surfaces,
    required bool isLight,
    required double radius,
  }) {
    return BoxDecoration(
      color: surfaces.emptyCell,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: surfaces.cellBorder),
    );
  }
}
