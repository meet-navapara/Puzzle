import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';
import '../widgets/brand_logo.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final surfaces = PetalSurfaces.of(context);
    final completed = app.save?.campaign.completedCount ?? 0;
    final petals = app.save?.campaign.petals ?? 0;
    final best = app.save?.classicBest ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GardenBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                onSettings: () => app.go(AppScreen.settings),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tall = constraints.maxHeight > 560;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BrandHero(compact: !tall),
                            SizedBox(height: tall ? 18 : 12),
                            _ProgressRibbon(
                              completed: completed,
                              petals: petals,
                              best: best,
                            ),
                            SizedBox(height: tall ? 20 : 14),
                            if (app.hasResumableGame) ...[
                              _FeatureCard(
                                title: 'Continue Garden',
                                subtitle: 'Resume your saved mid-run board',
                                icon: Icons.play_circle_filled_rounded,
                                onTap: () {
                                  if (app.guideHomeClassic || app.guideHomeDaily) {
                                    _guardHome(context, app, () {});
                                    return;
                                  }
                                  if (!app.resumeActiveGame() &&
                                      context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not resume — start a new garden.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                height: tall ? 96 : 84,
                                emphasized: true,
                                accent: surfaces.accentSoft,
                              ),
                              const SizedBox(height: 10),
                            ],
                            _FeatureCard(
                              title: 'Classic Garden',
                              subtitle:
                                  'Endless bloom · chase your best score',
                              icon: Icons.spa_rounded,
                              onTap: app.startClassic,
                              height: tall ? 108 : 90,
                              emphasized: !app.hasResumableGame || app.guideHomeClassic,
                              coached: app.guideHomeClassic,
                              accent: surfaces.accent,
                            ),
                            const SizedBox(height: 10),
                            _FeatureCard(
                              title: 'Campaign',
                              subtitle: 'Five worlds · 50 unique gardens',
                              icon: Icons.map_rounded,
                              onTap: () => _guardHome(context, app, app.openWorldMap),
                              height: tall ? 88 : 78,
                              accent: surfaces.accentSoft,
                            ),
                            const SizedBox(height: 10),
                            _FeatureCard(
                              title: 'Daily Dew',
                              subtitle:
                                  'Optional rewarded bonus · +15 petals',
                              icon: Icons.water_drop_rounded,
                              onTap: () => _guardHome(
                                context,
                                app,
                                () => app.go(AppScreen.daily),
                                allowWhen: app.guideHomeDaily,
                              ),
                              height: tall ? 88 : 78,
                              coached: app.guideHomeDaily,
                              accent: surfaces.blockPalette[2],
                            ),
                            SizedBox(height: tall ? 20 : 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => _showTutorial(context, app),
                                icon: Icon(
                                  Icons.menu_book_rounded,
                                  size: 18,
                                  color: surfaces.accent,
                                ),
                                label: Text(
                                  'How to Play',
                                  style: PetalText.button(context).copyWith(
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
              if (app.guideHomeClassic || app.guideHomeDaily)
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaces.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How PetalGrid works', style: PetalText.screenTitle(ctx)),
              const SizedBox(height: 12),
              Text(
                '1. Drag (or tap-select then tap a cell) to plant a piece.\n'
                '2. Complete a full row or column — it blooms clear.\n'
                '3. Chain clears for Bloom Streaks and bigger scores.\n'
                '4. Fill Bloom Charge, then Prune one stuck cell.\n'
                '5. Spend petals for an extra bloom charge if needed.\n'
                '6. The garden ends when no tray piece can fit.',
                style: PetalText.body(ctx).copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    app.updateSettings(
                      app.save!.settings.copyWith(tutorialSeen: true),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Got it'),
                ),
              ),
            ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaces.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surfaces.accentSoft),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                daily ? 'Step 2 · Daily Dew' : 'Step 1 · Classic Garden',
                style: PetalText.caption(context).copyWith(
                  color: surfaces.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                daily
                    ? 'Daily Dew is optional. Tap the glowing card. You claim the petals yourself.'
                    : 'Classic Garden never ends. Tap the glowing card, then plant the highlighted piece yourself.',
                style: PetalText.body(context).copyWith(height: 1.35),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onSkip, child: const Text('Skip')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Row(
      children: [
        const Spacer(),
        _GhostIconButton(
          tooltip: 'Settings',
          icon: Icons.settings_outlined,
          onPressed: onSettings,
          color: surfaces.onPanel,
        ),
      ],
    );
  }
}

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: surfaces.panel.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: surfaces.panel.withValues(alpha: 0.7),
            border: Border.all(color: surfaces.accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: surfaces.accent.withValues(alpha: 0.12),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: BrandLogo(size: compact ? 56 : 72),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          AppConfig.appName,
          style: PetalText.display(context)
              .copyWith(fontSize: compact ? 26 : 30, letterSpacing: 0.4),
          textAlign: TextAlign.center,
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

class _ProgressRibbon extends StatelessWidget {
  const _ProgressRibbon({
    required this.completed,
    required this.petals,
    required this.best,
  });

  final int completed;
  final int petals;
  final int best;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaces.panel.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(PetalRadius.lg),
        border: Border.all(color: surfaces.panelBorder.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          _RibbonStat(value: '$completed', label: 'cleared'),
          _RibbonDivider(color: surfaces.panelBorder),
          _RibbonStat(value: '$petals', label: 'petals'),
          _RibbonDivider(color: surfaces.panelBorder),
          _RibbonStat(value: '$best', label: 'best'),
        ],
      ),
    );
  }
}

class _RibbonStat extends StatelessWidget {
  const _RibbonStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: PetalText.score(context)),
          const SizedBox(height: 2),
          Text(label, style: PetalText.caption(context)),
        ],
      ),
    );
  }
}

class _RibbonDivider extends StatelessWidget {
  const _RibbonDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: color.withValues(alpha: 0.8),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.height,
    required this.accent,
    this.emphasized = false,
    this.coached = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  final Color accent;
  final bool emphasized;
  final bool coached;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final radius = emphasized ? PetalRadius.xl : PetalRadius.lg;
    final iconBox = emphasized ? 52.0 : 46.0;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: emphasized ? 0.24 : 0.14),
                  surfaces.panel,
                  surfaces.panel,
                ],
              ),
              border: Border.all(
                color: coached
                    ? surfaces.accentSoft
                    : accent.withValues(alpha: emphasized ? 0.5 : 0.32),
                width: coached ? 2.4 : (emphasized ? 1.3 : 1.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: emphasized ? 0.12 : 0.06),
                  blurRadius: emphasized ? 18 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(emphasized ? 16 : 14),
                    ),
                    child: Icon(
                      icon,
                      color: accent,
                      size: emphasized ? 28 : 24,
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
                              .copyWith(fontSize: emphasized ? 17 : 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: PetalText.supporting(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: accent,
                    size: emphasized ? 22 : 20,
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
