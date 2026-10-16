import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../theme/petal_theme.dart';
import '../widgets/brand_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final reduced = MediaQuery.of(context).disableAnimations;
    return GardenBackdrop(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: reduced ? PetalMotion.tap : PetalMotion.screen,
          curve: PetalMotion.soft,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, reduced ? 0 : 12 * (1 - t)),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 96),
              const SizedBox(height: 20),
              Text(AppConfig.appName, style: PetalText.display(context)),
              const SizedBox(height: 8),
              Text(
                AppConfig.appTagline,
                style: PetalText.supporting(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: surfaces.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
