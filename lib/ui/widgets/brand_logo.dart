import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';

/// The PetalGrid mark: four glazed grid tiles whose outer corners round into
/// petals, so it reads as both a 2×2 grid and a four-petal bloom.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Semantics(
      label: 'PetalGrid logo',
      child: CustomPaint(
        size: Size(size, size),
        painter: PetalLogoPainter(
          petalColors: [
            surfaces.blockPalette[5],
            surfaces.blockPalette[0],
            surfaces.blockPalette[2],
            surfaces.blockPalette[3],
          ],
          centerFoam: Colors.white,
          centerMoss: surfaces.gold,
        ),
      ),
    );
  }
}

class PetalLogoPainter extends CustomPainter {
  PetalLogoPainter({
    required this.petalColors,
    required this.centerFoam,
    required this.centerMoss,
  });

  /// Top-left, top-right, bottom-left, bottom-right.
  final List<Color> petalColors;
  final Color centerFoam;
  final Color centerMoss;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final origin = Offset((size.width - s) / 2, (size.height - s) / 2);
    final gap = s * 0.07;
    final tile = (s - gap) / 2;
    final outer = Radius.circular(tile * 0.62);
    final inner = Radius.circular(tile * 0.14);

    for (var i = 0; i < 4; i++) {
      final right = i.isOdd;
      final bottom = i >= 2;
      final rect = Rect.fromLTWH(
        origin.dx + (right ? tile + gap : 0),
        origin.dy + (bottom ? tile + gap : 0),
        tile,
        tile,
      );
      // The corner touching the centre stays tight; the other three bloom.
      final rr = RRect.fromRectAndCorners(
        rect,
        topLeft: !right && !bottom ? inner : outer,
        topRight: right && !bottom ? inner : outer,
        bottomLeft: !right && bottom ? inner : outer,
        bottomRight: right && bottom ? inner : outer,
      );
      final c = petalColors[i % petalColors.length];
      canvas.drawRRect(
        rr.shift(Offset(0, s * 0.025)),
        Paint()..color = Color.lerp(c, Colors.black, 0.32)!,
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(c, Colors.white, 0.28)!, c],
          ).createShader(rect),
      );
      // Gloss across the top of each tile.
      canvas.save();
      canvas.clipRRect(rr);
      // The shader spans only the gloss band, so it fades fully to nothing.
      final band = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width,
        rect.height * 0.5,
      );
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.4),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
      canvas.restore();
    }

    final centre = origin + Offset(s / 2, s / 2);
    canvas.drawCircle(centre, s * 0.13, Paint()..color = centerFoam);
    canvas.drawCircle(centre, s * 0.085, Paint()..color = centerMoss);
  }

  @override
  bool shouldRepaint(covariant PetalLogoPainter oldDelegate) =>
      oldDelegate.centerFoam != centerFoam ||
      oldDelegate.centerMoss != centerMoss ||
      oldDelegate.petalColors != petalColors;
}

/// "PetalGrid" wordmark with a petal-sunset gradient.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: light
            ? [s.onPanel, Color.lerp(s.onPanel, s.ctaStart, 0.55)!]
            : [Colors.white, s.blockPalette[5], s.ctaEnd],
      ).createShader(bounds),
      child: Text(
        'PetalGrid',
        textAlign: TextAlign.center,
        style: PetalText.display(context)
            .copyWith(fontSize: size, letterSpacing: -0.8),
      ),
    );
  }
}
