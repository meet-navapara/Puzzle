import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../campaign/campaign_catalog.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final totalCleared = app.save?.campaign.completedCount ?? 0;

    return GardenBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => app.go(AppScreen.mainMenu),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Campaign', style: PetalText.screenTitle(context)),
                        Text(
                          'Five worlds · $totalCleared / 50 gardens',
                          style: PetalText.caption(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: CampaignCatalog.worlds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final world = CampaignCatalog.worlds[i];
                    final done = world.levelIds
                        .where(
                          (id) => app.save!.campaign.progressOf(id).completed,
                        )
                        .length;
                    final unlocked = world.levelIds.any(
                      (id) => app.save!.campaign.progressOf(id).unlocked,
                    );
                    final accent = Color(world.accentColorValue);
                    final emphasized = unlocked && done < world.levelIds.length;

                    return _WorldCard(
                      index: i + 1,
                      title: world.name,
                      subtitle: world.subtitle,
                      progress: '$done / ${world.levelIds.length} cleared',
                      accent: accent,
                      unlocked: unlocked,
                      emphasized: emphasized,
                      onTap: unlocked ? () => app.selectWorld(i) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Material(
      color: surfaces.panel.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: surfaces.onPanel),
        ),
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.accent,
    required this.unlocked,
    required this.emphasized,
    required this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final String progress;
  final Color accent;
  final bool unlocked;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final dim = !unlocked;

    return Opacity(
      opacity: dim ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(PetalRadius.xl),
          onTap: onTap,
          child: Ink(
            height: emphasized ? 100 : 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PetalRadius.xl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: emphasized ? 0.26 : 0.14),
                  surfaces.panel,
                  surfaces.panel,
                ],
              ),
              border: Border.all(
                color: accent.withValues(alpha: unlocked ? 0.45 : 0.22),
                width: emphasized ? 1.3 : 1.1,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: accent.withValues(
                          alpha: Theme.of(context).brightness ==
                                  Brightness.light
                              ? 0.08
                              : 0.14,
                        ),
                        blurRadius: Theme.of(context).brightness ==
                                Brightness.light
                            ? 10
                            : 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: PetalText.section(context)
                          .copyWith(color: accent, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: PetalText.section(context)
                              .copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: PetalText.supporting(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progress,
                          style: PetalText.caption(context).copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    unlocked ? Icons.arrow_forward_rounded : Icons.lock_rounded,
                    color: unlocked ? accent : surfaces.muted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
