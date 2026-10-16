import 'package:flutter/material.dart';

import 'petal_theme.dart';

/// Semantic text styles — always no decoration, capped sizes, theme-aware colors.
class PetalText {
  PetalText._();

  static const double _maxScale = 1.2;

  static TextStyle _base(
    BuildContext context, {
    required double size,
    required FontWeight weight,
    Color? color,
    double height = 1.25,
  }) {
    final surfaces = PetalSurfaces.of(context);
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? surfaces.onPanel,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
      decorationThickness: 0,
      fontFamily: null,
      letterSpacing: 0,
    );
  }

  static TextStyle display(BuildContext context) =>
      _base(context, size: 28, weight: FontWeight.w800, height: 1.15);

  static TextStyle screenTitle(BuildContext context) =>
      _base(context, size: 20, weight: FontWeight.w800);

  static TextStyle section(BuildContext context) =>
      _base(context, size: 16, weight: FontWeight.w700);

  static TextStyle body(BuildContext context) =>
      _base(context, size: 14, weight: FontWeight.w500);

  static TextStyle supporting(BuildContext context) => _base(
    context,
    size: 13,
    weight: FontWeight.w500,
    color: PetalSurfaces.of(context).muted,
  );

  static TextStyle score(BuildContext context) =>
      _base(context, size: 16, weight: FontWeight.w800);

  static TextStyle scoreLabel(BuildContext context) => _base(
    context,
    size: 10,
    weight: FontWeight.w600,
    color: PetalSurfaces.of(context).muted,
  );

  static TextStyle button(BuildContext context) =>
      _base(context, size: 15, weight: FontWeight.w800);

  static TextStyle caption(BuildContext context) => _base(
    context,
    size: 12,
    weight: FontWeight.w600,
    color: PetalSurfaces.of(context).muted,
  );

  static TextStyle accent(BuildContext context) => _base(
    context,
    size: 13,
    weight: FontWeight.w700,
    color: PetalSurfaces.of(context).accent,
  );

  /// Clamp system accessibility text scale so UI does not explode.
  static Widget scaleGuard({required Widget child}) {
    return Builder(
      builder: (context) {
        final scaler = MediaQuery.textScalerOf(context);
        final clamped = scaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: _maxScale,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clamped),
          child: child,
        );
      },
    );
  }
}
