import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../campaign/campaign_catalog.dart';
import '../../campaign/level_generator.dart';
import '../../campaign/level_models.dart';
import '../../state/app_state.dart';
import '../game/block_material.dart';
import '../theme/petal_theme.dart';
import '../widgets/petal_button.dart';

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
    final reduced =
        (app.save?.settings.reducedEffects ?? false) ||
        MediaQuery.of(context).disableAnimations;
    final tone = Color.lerp(accent, surfaces.onPanel, 0.2)!;

    return GardenBackdrop(
      accent: accent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PetalIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => app.go(AppScreen.worldMap),
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
              const SizedBox(height: 12),
              PetalPanel(
                accent: accent,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.subtitle,
                      style: PetalText.supporting(context)
                          .copyWith(color: surfaces.onPanel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: done / world.levelIds.length,
                        minHeight: 6,
                        color: tone,
                        backgroundColor: surfaces.emptyCell,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                      // Room for the current tile's pulse without drawing over the header.
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 24),
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
                          animate: !reduced,
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
    required this.animate,
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
  final bool animate;
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
    final light = Theme.of(context).brightness == Brightness.light;
    final locked = !unlocked;
    final radius = BorderRadius.circular(PetalRadius.lg);

    final BoxDecoration decoration;
    final Color numberColor;
    if (current) {
      decoration = BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surfaces.ctaStart, surfaces.ctaEnd],
        ),
        boxShadow: PetalShadows.glow(surfaces.ctaStart),
      );
      numberColor = surfaces.onCta;
    } else if (completed) {
      decoration = BlockMaterial.filled(
        color: Color.lerp(accent, surfaces.panel, light ? 0.1 : 0.25)!,
        surfaces: surfaces,
        isLight: light,
        radius: PetalRadius.lg,
      );
      numberColor = Colors.white;
    } else if (unlocked) {
      decoration = BoxDecoration(
        borderRadius: radius,
        color: surfaces.panel.withValues(alpha: 0.9),
        border: Border.all(
          color: accent.withValues(alpha: milestone ? 0.95 : 0.6),
          width: milestone ? 2 : 1.4,
        ),
      );
      numberColor = Color.lerp(accent, surfaces.onPanel, 0.2)!;
    } else {
      decoration = BlockMaterial.empty(
        surfaces: surfaces,
        isLight: light,
        radius: PetalRadius.lg,
      );
      numberColor = surfaces.muted;
    }

    Widget tile = Container(
      decoration: decoration,
      foregroundDecoration: completed || current
          ? BlockMaterial.gloss(PetalRadius.lg)
          : null,
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
                    color: surfaces.muted.withValues(alpha: 0.7),
                  )
                : Text(
                    '$id',
                    style: PetalText.section(context)
                        .copyWith(fontSize: 17, color: numberColor),
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
                      size: 13,
                      color: s < stars
                          ? surfaces.gold
                          : Colors.black.withValues(alpha: 0.22),
                    ),
                ],
              ),
            ),
          ] else if (current) ...[
            Icon(Icons.play_arrow_rounded, size: 16, color: surfaces.onCta),
          ] else if (milestone && !locked) ...[
            const SizedBox(height: 2),
            Icon(Icons.flag_rounded, size: 12, color: accent),
          ],
        ],
      ),
    );
    if (current && animate) tile = _Pulse(child: tile);

    return Semantics(
      button: true,
      enabled: unlocked,
      label: _semanticLabel,
      excludeSemantics: true,
      child: PressScale(onTap: onTap, scale: 0.92, child: tile),
    );
  }
}

/// Gentle breathing scale for the level the player should play next.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 1.0,
        end: 1.06,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
