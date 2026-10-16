import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../campaign/campaign_catalog.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final world = CampaignCatalog.worlds[app.selectedWorld];
    final accent = Color(world.accentColorValue);
    final surfaces = PetalSurfaces.of(context);
    final done = world.levelIds
        .where((id) => app.save!.campaign.progressOf(id).completed)
        .length;

    return GardenBackdrop(
      accent: accent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Material(
                    color: surfaces.panel.withValues(alpha: 0.7),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => app.go(AppScreen.worldMap),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: surfaces.onPanel,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          world.name,
                          style: PetalText.screenTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'World ${world.index + 1} of 5 · $done / ${world.levelIds.length} cleared',
                          style: PetalText.caption(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PetalRadius.xl),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withValues(alpha: 0.24), surfaces.panel],
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.map_rounded, color: accent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        world.subtitle,
                        style: PetalText.section(context)
                            .copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Levels', style: PetalText.section(context)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: world.levelIds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final id = world.levelIds[i];
                    final p = app.save!.campaign.progressOf(id);
                    final level = CampaignCatalog.level(id);
                    final isNext =
                        p.unlocked &&
                        !p.completed &&
                        world.levelIds
                            .take(i)
                            .every(
                              (prev) =>
                                  app.save!.campaign.progressOf(prev).completed,
                            );

                    return _LevelCard(
                      id: id,
                      name: level.name,
                      unlocked: p.unlocked,
                      completed: p.completed,
                      stars: p.stars,
                      accent: accent,
                      emphasized:
                          isNext || (p.unlocked && !p.completed && i == 0),
                      onTap: p.unlocked ? () => app.startLevel(id) : null,
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.id,
    required this.name,
    required this.unlocked,
    required this.completed,
    required this.stars,
    required this.accent,
    required this.emphasized,
    required this.onTap,
  });

  final int id;
  final String name;
  final bool unlocked;
  final bool completed;
  final int stars;
  final Color accent;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final locked = !unlocked;

    String statusLabel;
    if (locked) {
      statusLabel = 'Locked';
    } else if (completed) {
      statusLabel = stars > 0
          ? '$stars star${stars == 1 ? '' : 's'}'
          : 'Cleared';
    } else if (emphasized) {
      statusLabel = 'Play now';
    } else {
      statusLabel = 'Ready';
    }

    return Opacity(
      opacity: locked ? 0.58 : 1,
      child: Semantics(
        button: true,
        enabled: unlocked,
        label: 'Level $id $name',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(PetalRadius.xl),
            onTap: onTap,
            child: Ink(
              height: emphasized ? 88 : 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(PetalRadius.xl),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(
                      alpha: emphasized
                          ? 0.26
                          : completed
                          ? 0.18
                          : 0.12,
                    ),
                    surfaces.panel,
                    surfaces.panel,
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(
                    alpha: emphasized
                        ? 0.5
                        : unlocked
                        ? 0.32
                        : 0.18,
                  ),
                  width: emphasized ? 1.3 : 1.1,
                ),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                          color: accent.withValues(
                            alpha: Theme.of(context).brightness ==
                                    Brightness.light
                                ? (emphasized ? 0.1 : 0.05)
                                : (emphasized ? 0.14 : 0.06),
                          ),
                          blurRadius: emphasized ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$id',
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
                            name,
                            style: PetalText.section(context)
                                .copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            statusLabel,
                            style: PetalText.supporting(context).copyWith(
                              color: locked
                                  ? surfaces.muted
                                  : emphasized
                                  ? accent
                                  : surfaces.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (unlocked && stars > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(
                                3,
                                (s) => Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: s < stars
                                        ? surfaces.accentSoft
                                        : surfaces.muted.withValues(
                                            alpha: 0.28,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      locked
                          ? Icons.lock_rounded
                          : completed
                          ? Icons.check_circle_rounded
                          : Icons.play_arrow_rounded,
                      color: locked
                          ? surfaces.muted
                          : completed
                          ? accent
                          : accent,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
