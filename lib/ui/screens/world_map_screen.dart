import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../campaign/campaign_catalog.dart';
import '../../state/app_state.dart';
import '../game/block_material.dart';
import '../theme/petal_theme.dart';
import '../widgets/petal_button.dart';

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
                  PetalIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => app.go(AppScreen.mainMenu),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Campaign', style: PetalText.screenTitle(context)),
                        Text(
                          '${CampaignCatalog.worlds.length} worlds · '
                          '$totalCleared / ${CampaignCatalog.totalLevels} levels · '
                          '${app.save!.campaign.totalStars} stars',
                          style: PetalText.caption(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PetalButton(
                label: 'Play level ${app.save!.campaign.nextLevelId}',
                icon: Icons.play_arrow_rounded,
                onPressed: app.playNextLevel,
              ),
              const SizedBox(height: 14),
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
                      ratio: done / world.levelIds.length,
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

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.ratio,
    required this.accent,
    required this.unlocked,
    required this.emphasized,
    required this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final String progress;
  final double ratio;
  final Color accent;
  final bool unlocked;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    // World colours are deep; lift them for text on the dark panels.
    final readable = light ? accent : Color.lerp(accent, Colors.white, 0.45)!;
    final finished = ratio >= 1;

    final medal = Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: unlocked
          ? BlockMaterial.filled(
              color: Color.lerp(accent, surfaces.panel, light ? 0.05 : 0.2)!,
              surfaces: surfaces,
              isLight: light,
              radius: 17,
            )
          : BlockMaterial.empty(surfaces: surfaces, isLight: light, radius: 17),
      foregroundDecoration: unlocked ? BlockMaterial.gloss(17) : null,
      child: unlocked
          ? Text(
              '$index',
              style: PetalText.section(context)
                  .copyWith(color: Colors.white, fontSize: 20),
            )
          : Icon(Icons.lock_rounded, color: surfaces.muted, size: 20),
    );

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PetalRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              surfaces.panel,
              accent,
              unlocked ? (emphasized ? 0.24 : 0.14) : 0.04,
            )!,
            surfaces.panel.withValues(alpha: light ? 1 : 0.9),
          ],
        ),
        border: Border.all(
          color: emphasized
              ? readable.withValues(alpha: 0.8)
              : accent.withValues(alpha: unlocked ? 0.4 : 0.18),
          width: emphasized ? 1.8 : 1.1,
        ),
        boxShadow: emphasized ? PetalShadows.glow(accent, strength: 0.6) : null,
      ),
      padding: EdgeInsets.fromLTRB(
        14,
        emphasized ? 16 : 13,
        14,
        emphasized ? 16 : 13,
      ),
      child: Row(
        children: [
          medal,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PetalText.section(context).copyWith(fontSize: 16.5),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PetalText.caption(context)
                      .copyWith(color: readable, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 5,
                    color: readable,
                    backgroundColor: surfaces.emptyCell,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            !unlocked
                ? Icons.lock_rounded
                : finished
                ? Icons.check_circle_rounded
                : Icons.chevron_right_rounded,
            color: unlocked ? readable : surfaces.muted,
            size: finished ? 24 : 26,
          ),
        ],
      ),
    );

    return Opacity(
      opacity: unlocked ? 1 : 0.6,
      child: Semantics(
        button: true,
        enabled: unlocked,
        child: PressScale(onTap: onTap, scale: 0.98, child: card),
      ),
    );
  }
}
