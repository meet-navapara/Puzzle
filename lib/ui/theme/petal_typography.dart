import 'package:flutter/material.dart';

import 'petal_theme.dart';

/// Semantic text styles — always no decoration, capped sizes, theme-aware colors.
class PetalText {
  PetalText._();

  static const double _maxScale = 1.2;

  /// Null on devices, which use the system font. The store-asset renderer sets
  /// it because Flutter's test environment otherwise draws text as solid blocks.
  static String? renderFontFamily;

  static TextStyle _base(
    BuildContext context, {
    required double size,
    required FontWeight weight,
    Color? color,
    double height = 1.25,
    double letterSpacing = 0,
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
      fontFamily: renderFontFamily,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle display(BuildContext context) => _base(
    context,
    size: 30,
    weight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -0.4,
  );

  static TextStyle screenTitle(BuildContext context) =>
      _base(context, size: 21, weight: FontWeight.w800, letterSpacing: -0.2);

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

  /// Large centered run score (classic / campaign HUD).
  static TextStyle heroScore(BuildContext context) => _base(
    context,
    size: 46,
    weight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -1,
  );

  static TextStyle highScore(BuildContext context) => _base(
    context,
    size: 15,
    weight: FontWeight.w700,
    color: PetalSurfaces.of(context).gold,
  );

  static TextStyle scoreLabel(BuildContext context) => _base(
    context,
    size: 10.5,
    weight: FontWeight.w700,
    letterSpacing: 0.8,
    color: PetalSurfaces.of(context).muted,
  );

  static TextStyle button(BuildContext context) =>
      _base(context, size: 15.5, weight: FontWeight.w800, letterSpacing: 0.2);

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
