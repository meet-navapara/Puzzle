import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../theme/petal_theme.dart';
import '../widgets/petal_button.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final surfaces = PetalSurfaces.of(context);
    final claimed = app.dailyClaimedToday;

    return GardenBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PetalIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => app.go(AppScreen.mainMenu),
                  ),
                  Expanded(
                    child: Text(
                      'Daily Dew',
                      style: PetalText.screenTitle(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                          surfaces.blockPalette[2],
                          Colors.white,
                          0.3,
                        )!,
                        surfaces.blockPalette[2],
                      ],
                    ),
                    border: Border.all(color: surfaces.panel, width: 5),
                    boxShadow: PetalShadows.glow(surfaces.blockPalette[2]),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: PetalSpace.lg),
              Text(
                'Earn 15 petals with an optional rewarded ad.',
                textAlign: TextAlign.center,
                style: PetalText.body(context),
              ),
              const SizedBox(height: PetalSpace.sm),
              Text(
                'Once a day. Petals are added when the ad finishes.',
                textAlign: TextAlign.center,
                style: PetalText.supporting(context),
              ),
              const SizedBox(height: PetalSpace.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: surfaces.panel.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(PetalRadius.xl),
                  border: Border.all(
                    color: claimed
                        ? surfaces.panelBorder
                        : surfaces.accentSoft.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_florist_rounded,
                          color: surfaces.accentSoft,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+15 petals',
                          style: PetalText.score(context)
                              .copyWith(fontSize: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claimed ? 'Claimed for today' : 'Available now',
                      style: PetalText.caption(context).copyWith(
                        color: claimed ? surfaces.muted : surfaces.success,
                      ),
                    ),
                  ],
                ),
              ),
              if (app.statusMessage != null) ...[
                const SizedBox(height: PetalSpace.md),
                Text(
                  app.statusMessage!,
                  textAlign: TextAlign.center,
                  style: PetalText.supporting(context)
                      .copyWith(color: surfaces.accent),
                ),
              ],
              const Spacer(),
              if (app.shouldGuideDaily) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: surfaces.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: surfaces.accentSoft, width: 1.6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your step',
                          style: PetalText.caption(context).copyWith(
                            color: surfaces.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          claimed
                              ? 'You already collected today’s dew. Tap Continue.'
                              : 'Tap Watch & Claim yourself. Petals are added only after the ad finishes. Once a day.',
                          style: PetalText.body(context).copyWith(height: 1.35),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: app.completeDailyTour,
                            child: Text(claimed ? 'Continue' : 'Skip'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              PetalButton(
                label: claimed ? 'Already claimed today' : 'Watch & Claim',
                icon: claimed
                    ? Icons.check_rounded
                    : Icons.ondemand_video_rounded,
                onPressed: claimed
                    ? null
                    : () {
                        app.claimDailyBonus();
                        if (app.shouldGuideDaily) app.completeDailyTour();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
