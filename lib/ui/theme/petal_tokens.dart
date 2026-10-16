import 'package:flutter/material.dart';

/// Spacing, radius, elevation, and motion tokens for PetalGrid.
class PetalSpace {
  PetalSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class PetalRadius {
  PetalRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double cell = 6;
  static const double block = 5;
}

/// Shared motion language — keep gameplay snappy, menus soft.
class PetalMotion {
  PetalMotion._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration tap = Duration(milliseconds: 120);
  static const Duration place = Duration(milliseconds: 160);
  static const Duration reject = Duration(milliseconds: 180);
  static const Duration clearRecognize = Duration(milliseconds: 100);
  static const Duration clearAnticipate = Duration(milliseconds: 110);
  static const Duration clearSweep = Duration(milliseconds: 320);
  static const Duration clearTotal = Duration(milliseconds: 520);
  static const Duration clearReduced = Duration(milliseconds: 140);
  static const Duration banner = Duration(milliseconds: 900);
  static const Duration bannerReduced = Duration(milliseconds: 280);
  static const Duration dialog = Duration(milliseconds: 220);
  static const Duration screen = Duration(milliseconds: 280);
  static const Duration scoreFloat = Duration(milliseconds: 700);

  static const Curve snappy = Curves.easeOutCubic;
  static const Curve settle = Curves.easeOutBack;
  static const Curve soft = Curves.easeInOutCubic;
  static const Curve emphasize = Curves.easeOutQuad;
}

class PetalShadows {
  PetalShadows._();

  static List<BoxShadow> panel(Color shadow, {bool light = false}) => [
    BoxShadow(
      color: shadow.withValues(alpha: light ? 0.14 : 0.36),
      blurRadius: light ? 14 : 20,
      offset: Offset(0, light ? 6 : 8),
    ),
  ];

  static List<BoxShadow> blockDepth(Color shadow, {bool light = false}) => [
    BoxShadow(
      color: shadow.withValues(alpha: light ? 0.18 : 0.4),
      blurRadius: light ? 0 : 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> lift(Color shadow, {bool light = false}) => [
    BoxShadow(
      color: shadow.withValues(alpha: light ? 0.22 : 0.45),
      blurRadius: light ? 4 : 10,
      offset: Offset(0, light ? 2 : 4),
    ),
  ];
}
