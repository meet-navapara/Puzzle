import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../theme/petal_theme.dart';
import '../widgets/brand_logo.dart';

class CampaignVictoryScreen extends StatelessWidget {
  const CampaignVictoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final surfaces = PetalSurfaces.of(context);
    final reduced = app.save?.settings.reducedEffects ?? false;

    Widget logo = const BrandLogo(size: 110);
    if (!reduced) {
      logo = logo
          .animate()
          .scale(duration: 700.ms)
          .then()
          .shimmer(duration: 1200.ms);
    }

    return GardenBackdrop(
      accent: surfaces.accentSoft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              logo,
              const SizedBox(height: 20),
              Text(
                'Eternal Bloom',
                style: PetalText.display(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You cultivated all fifty gardens across five worlds. The Conservatory remembers your care.',
                textAlign: TextAlign.center,
                style: PetalText.body(context),
              ),
              const SizedBox(height: 8),
              Text(
                '${app.save!.campaign.petals} petals collected',
                style: PetalText.score(context)
                    .copyWith(color: surfaces.accent),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => app.go(AppScreen.mainMenu),
                child: const Text('Return to garden'),
              ),
              TextButton(
                onPressed: () => app.go(AppScreen.worldMap),
                child: const Text('Replay worlds'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
