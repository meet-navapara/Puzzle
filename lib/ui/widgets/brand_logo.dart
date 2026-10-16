import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      label: 'PetalGrid logo',
      child: CustomPaint(
        size: Size(size, size),
        painter: PetalLogoPainter(
          petalColors: [
            surfaces.blockPalette[0],
            surfaces.blockPalette[1],
            surfaces.blockPalette[2],
            surfaces.blockPalette[3],
            surfaces.blockPalette[5],
          ],
          centerFoam: isLight ? surfaces.panel : const Color(0xFFF7FBF8),
          centerMoss: surfaces.accent,
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

  final List<Color> petalColors;
  final Color centerFoam;
  final Color centerMoss;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.18;
    for (var i = 0; i < petalColors.length; i++) {
      final paint = Paint()..color = petalColors[i];
      final angle = i * 1.256637;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -r * 1.4),
          width: r * 1.3,
          height: r * 2.2,
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset(cx, cy), r * 0.9, Paint()..color = centerFoam);
    canvas.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = centerMoss);
  }

  @override
  bool shouldRepaint(covariant PetalLogoPainter oldDelegate) =>
      oldDelegate.centerFoam != centerFoam ||
      oldDelegate.centerMoss != centerMoss ||
      oldDelegate.petalColors != petalColors;
}
