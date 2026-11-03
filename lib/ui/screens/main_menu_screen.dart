import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../campaign/campaign_catalog.dart';
import '../../core/app_config.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';
import '../widgets/ambient_petals.dart';
import '../widgets/brand_logo.dart';
import '../widgets/petal_button.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final surfaces = PetalSurfaces.of(context);
    final completed = app.save?.campaign.completedCount ?? 0;
    final petals = app.save?.campaign.petals ?? 0;
    final stars = app.save?.campaign.totalStars ?? 0;
    final best = app.save?.classicBest ?? 0;
    final nextId = app.save?.campaign.nextLevelId ?? 1;
    final nextLevel = CampaignCatalog.level(nextId);
    final world = CampaignCatalog.worlds[nextLevel.worldIndex];
    final reduced =
        (app.save?.settings.reducedEffects ?? false) ||
        MediaQuery.of(context).disableAnimations;
    final coaching = app.guideHomeClassic || app.guideHomeDaily;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GardenBackdrop(
        child: Stack(
          children: [
            Positioned.fill(child: AmbientPetals(animate: !reduced)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      petals: petals,
                      stars: stars,
                      onSettings: () => app.go(AppScreen.settings),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tall = constraints.maxHeight > 600;
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: tall ? 8 : 4),
                                  _BrandHero(compact: !tall, animate: !reduced),
                                  SizedBox(height: tall ? 28 : 18),
                                  if (app.hasResumableGame)
                                    PetalButton(
                                      label: 'Continue Garden',
                                      subtitle: 'Resume your saved board',
                                      icon: Icons.play_arrow_rounded,
                                      height: 68,
                                      onPressed: () {
                                        if (coaching) {
                                          _guardHome(context, app, () {});
                                          return;
                                        }
                                        if (!app.resumeActiveGame() &&
                                            context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Could not resume — start a new garden.',
                                                  ),
                                                ),
                                              );
                                        }
                                      },
                                    )
                                  else
                                    PetalButton(
                                      label: 'Play',
                                      subtitle: 'Level $nextId · ${world.name}',
                                      icon: Icons.play_arrow_rounded,
                                      height: 68,
                                      onPressed: () => _guardHome(
                                        context,
                                        app,
                                        app.playNextLevel,
                                      ),
                                    ),
                                  const SizedBox(height: 14),
                                  _CampaignCard(
                                    completed: completed,
                                    subtitle: completed == 0
                                        ? '${CampaignCatalog.worlds.length} worlds · ${CampaignCatalog.totalLevels} levels'
                                        : 'Next: level $nextId of ${CampaignCatalog.totalLevels}',
                                    accent: Color(world.accentColorValue),
                                    onTap: () => _guardHome(
                                      context,
                                      app,
                                      app.openWorldMap,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _ModeTile(
                                            title: 'Classic Garden',
                                            subtitle: best > 0
                                                ? 'Best $best'
                                                : 'Endless play',
                                            icon: Icons.spa_rounded,
                                            accent: surfaces.accent,
                                            coached: app.guideHomeClassic,
                                            onTap: app.startClassic,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _ModeTile(
                                            title: 'Daily Dew',
                                            subtitle:
                                                'Optional ad · +15 petals',
                                            icon: Icons.water_drop_rounded,
                                            accent: surfaces.blockPalette[2],
                                            coached: app.guideHomeDaily,
                                            onTap: () => _guardHome(
                                              context,
                                              app,
                                              () => app.go(AppScreen.daily),
                                              allowWhen: app.guideHomeDaily,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: tall ? 18 : 10),
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _showTutorial(context, app),
                                      icon: Icon(
                                        Icons.menu_book_rounded,
                                        size: 18,
                                        color: surfaces.accent,
                                      ),
                                      label: Text(
                                        'How to Play',
                                        style: PetalText.button(context)
                                            .copyWith(
                                              color: surfaces.accent,
                                              fontSize: 14,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (coaching)
                      _HomeCoach(
                        daily: app.guideHomeDaily,
                        onSkip: () {
                          if (app.guideHomeClassic) {
                            app.completeClassicTour();
                          } else {
                            app.completeDailyTour();
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _guardHome(
    BuildContext context,
    AppState app,
    VoidCallback action, {
    bool allowWhen = false,
  }) {
    if ((app.guideHomeClassic || app.guideHomeDaily) && !allowWhen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            app.guideHomeClassic
                ? 'Tap the glowing Classic Garden card to begin.'
                : 'Tap the glowing Daily Dew card next.',
          ),
        ),
      );
      return;
    }
    action();
  }

  void _showTutorial(BuildContext context, AppState app) {
    final surfaces = PetalSurfaces.of(context);
    const steps = <(IconData, String)>[
      (
        Icons.pan_tool_alt_rounded,
        'Drag a piece onto empty cells, or tap it, then tap the board.',
      ),
      (
        Icons.view_week_rounded,
        'Fill a whole row or column and it blooms away.',
      ),
      (Icons.bolt_rounded, 'Clear again on the next move for a combo.'),
      (
        Icons.local_florist_rounded,
        'Clears fill Bloom Charge. Prune removes one stuck cell.',
      ),
      (Icons.star_rounded, 'Finish in fewer moves for three stars.'),
      (Icons.grid_off_rounded, 'The garden ends when no tray piece fits.'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaces.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: surfaces.panelBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('How PetalGrid works', style: PetalText.screenTitle(ctx)),
                const SizedBox(height: 14),
                for (final (icon, text) in steps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: surfaces.accent.withValues(alpha: 0.16),
                          ),
                          child: Icon(icon, size: 18, color: surfaces.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: PetalText.body(ctx).copyWith(height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Replay the guided lessons any time from Settings.',
                  style: PetalText.caption(ctx),
                ),
                const SizedBox(height: 14),
                PetalButton(
                  label: 'Got it',
                  onPressed: () {
                    app.updateSettings(
                      app.save!.settings.copyWith(tutorialSeen: true),
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeCoach extends StatelessWidget {
  const _HomeCoach({required this.daily, required this.onSkip});

  final bool daily;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: PetalPanel(
        accent: surfaces.gold,
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surfaces.gold.withValues(alpha: 0.18),
              ),
              child: Icon(
                Icons.touch_app_rounded,
                size: 18,
                color: surfaces.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    daily ? 'Step 2 · Daily Dew' : 'Step 1 · Classic Garden',
                    style: PetalText.caption(context).copyWith(
                      color: surfaces.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    daily
                        ? 'Daily Dew is optional. Tap the glowing card. You claim the petals yourself.'
                        : 'Classic Garden never ends. Tap the glowing card, then plant the highlighted piece yourself.',
                    style: PetalText.body(context).copyWith(height: 1.35),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onSkip,
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.petals,
    required this.stars,
    required this.onSettings,
  });
  final int petals;
  final int stars;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Row(
      children: [
        PetalChip(
          icon: Icons.local_florist_rounded,
          value: '$petals',
          color: surfaces.accentSoft,
          label: 'petals',
        ),
        const SizedBox(width: 8),
        PetalChip(
          icon: Icons.star_rounded,
          value: '$stars',
          color: surfaces.gold,
          label: 'stars',
        ),
        const Spacer(),
        PetalIconButton(
          icon: Icons.settings_rounded,
          tooltip: 'Settings',
          onPressed: onSettings,
        ),
      ],
    );
  }
}

/// Logo in a glowing ring that breathes slowly, over the gradient wordmark.
class _BrandHero extends StatefulWidget {
  const _BrandHero({required this.compact, required this.animate});
  final bool compact;
  final bool animate;

  @override
  State<_BrandHero> createState() => _BrandHeroState();
}

class _BrandHeroState extends State<_BrandHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BrandHero old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final logo = widget.compact ? 76.0 : 96.0;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_c.value);
            return Transform.scale(scale: 1 + 0.035 * t, child: child);
          },
          child: Container(
            padding: EdgeInsets.all(widget.compact ? 16 : 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  surfaces.panel.withValues(alpha: 0.9),
                  surfaces.panel.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: surfaces.glowA.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: surfaces.glowA.withValues(alpha: 0.22),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: BrandLogo(size: logo),
          ),
        ),
        SizedBox(height: widget.compact ? 14 : 18),
        Semantics(
          header: true,
          label: AppConfig.appName,
          excludeSemantics: true,
          child: BrandWordmark(size: widget.compact ? 32 : 38),
        ),
        const SizedBox(height: 4),
        Text(
          AppConfig.appTagline,
          style: PetalText.supporting(context),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Wide card into the world map, with campaign progress.
class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.completed,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final int completed;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final tone = Color.lerp(accent, surfaces.onPanel, 0.25)!;
    final ratio = completed / CampaignCatalog.totalLevels;
    return Semantics(
      button: true,
      label: 'Campaign, $subtitle',
      child: PressScale(
        onTap: onTap,
        scale: 0.98,
        child: PetalPanel(
          accent: accent,
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              _IconBadge(icon: Icons.map_rounded, color: tone),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Campaign', style: PetalText.section(context)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: PetalText.supporting(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 5,
                        color: tone,
                        backgroundColor: surfaces.emptyCell,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: tone, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.coached = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool coached;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final tile = PetalPanel(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(icon: icon, color: accent),
          const SizedBox(height: 12),
          Text(
            title,
            style: PetalText.section(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: PetalText.caption(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: PressScale(
        onTap: onTap,
        child: coached
            ? DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PetalRadius.xl + 2),
                  border: Border.all(color: surfaces.gold, width: 2.4),
                  boxShadow: PetalShadows.glow(surfaces.gold),
                ),
                child: tile,
              )
            : tile,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.32),
            color.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
