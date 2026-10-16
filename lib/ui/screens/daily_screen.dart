import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../theme/petal_theme.dart';

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
                  IconButton(
                    onPressed: () => app.go(AppScreen.mainMenu),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: surfaces.onPanel,
                    ),
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
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: surfaces.panel,
                    shape: BoxShape.circle,
                    border: Border.all(color: surfaces.panelBorder),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    size: 44,
                    color: surfaces.accent,
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
                'Once per UTC day. Reward granted only when the ad SDK confirms completion.',
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
                  color: surfaces.panel,
                  borderRadius: BorderRadius.circular(PetalRadius.md),
                  border: Border.all(color: surfaces.panelBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      '+15 petals',
                      style: PetalText.score(context).copyWith(fontSize: 22),
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
              ElevatedButton(
                onPressed: claimed ? null : () => app.claimDailyBonus(),
                child: Text(
                  claimed ? 'Already claimed today' : 'Watch & Claim',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
