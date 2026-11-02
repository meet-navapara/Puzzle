import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../campaign/campaign_catalog.dart';
import '../../campaign/level_generator.dart';
import '../../campaign/level_models.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';

/// Fifty levels per world, so this is a compact grid that opens at the player's
/// current level rather than a long list they would have to scroll every visit.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const int _columns = 5;
  static const double _gap = 10;

  final ScrollController _scroll = ScrollController();
  bool _didScroll = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToCurrent(WorldDefinition world, int currentId, double tileSize) {
    if (_didScroll) return;
    _didScroll = true;
    final index = world.levelIds.indexOf(currentId);
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final row = index ~/ _columns;
      final position = _scroll.position;
      final target = row * (tileSize + _gap) - position.viewportDimension / 3;
      _scroll.jumpTo(target.clamp(0.0, position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final world = CampaignCatalog.worlds[app.selectedWorld];
    final accent = Color(world.accentColorValue);
    final surfaces = PetalSurfaces.of(context);
    final campaign = app.save!.campaign;
    final done = world.levelIds
        .where((id) => campaign.progressOf(id).completed)
        .length;
    final stars = world.levelIds.fold<int>(
      0,
      (sum, id) => sum + campaign.progressOf(id).stars,
    );
    final currentId = campaign.nextLevelId;

    return GardenBackdrop(
      accent: accent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                          'World ${world.index + 1} of ${CampaignCatalog.worlds.length} · '
                          '$done / ${world.levelIds.length} cleared · $stars stars',
                          style: PetalText.caption(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                world.subtitle,
                style: PetalText.supporting(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 600
                        ? _columns * 2
                        : _columns;
                    final tile =
                        (constraints.maxWidth - _gap * (columns - 1)) / columns;
                    _scrollToCurrent(world, currentId, tile);
                    return GridView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: _gap,
                        crossAxisSpacing: _gap,
                      ),
                      itemCount: world.levelIds.length,
                      itemBuilder: (context, i) {
                        final id = world.levelIds[i];
                        final p = campaign.progressOf(id);
                        return _LevelTile(
                          id: id,
                          name: CampaignCatalog.level(id).name,
                          unlocked: p.unlocked,
                          completed: p.completed,
                          stars: p.stars,
                          accent: accent,
                          current: id == currentId && !p.completed,
                          milestone: LevelGenerator.isMilestone(id),
                          onTap: p.unlocked ? () => app.startLevel(id) : null,
                        );
                      },
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

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.id,
    required this.name,
    required this.unlocked,
    required this.completed,
    required this.stars,
    required this.accent,
    required this.current,
    required this.milestone,
    required this.onTap,
  });

  final int id;
  final String name;
  final bool unlocked;
  final bool completed;
  final int stars;
  final Color accent;
  final bool current;
  final bool milestone;
  final VoidCallback? onTap;

  String get _semanticLabel {
    final status = !unlocked
        ? 'locked'
        : completed
        ? '$stars of 3 stars'
        : current
        ? 'play now'
        : 'ready';
    return 'Level $id, $name, $status';
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final locked = !unlocked;
    final radius = BorderRadius.circular(PetalRadius.lg);

    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Semantics(
        button: true,
        enabled: unlocked,
        label: _semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: current
                    ? accent.withValues(alpha: 0.34)
                    : completed
                    ? accent.withValues(alpha: 0.16)
                    : surfaces.panel,
                border: Border.all(
                  color: current
                      ? accent
                      : milestone && unlocked
                      ? accent.withValues(alpha: 0.75)
                      : surfaces.panelBorder,
                  width: current || milestone ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: locked
                          ? Icon(
                              Icons.lock_rounded,
                              size: 18,
                              color: surfaces.muted,
                            )
                          : Text(
                              '$id',
                              style: PetalText.section(context).copyWith(
                                fontSize: 16,
                                color: current || completed
                                    ? surfaces.onPanel
                                    : accent,
                              ),
                            ),
                    ),
                    if (completed) ...[
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var s = 0; s < 3; s++)
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: s < stars
                                    ? surfaces.accentSoft
                                    : surfaces.muted.withValues(alpha: 0.3),
                              ),
                          ],
                        ),
                      ),
                    ] else if (milestone && !locked) ...[
                      const SizedBox(height: 2),
                      Icon(Icons.flag_rounded, size: 12, color: accent),
                    ],
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
