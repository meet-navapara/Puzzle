import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';
import 'petal_button.dart';

/// Shared modal shell for pause / game-over / completion.
class AppDialogShell extends StatelessWidget {
  const AppDialogShell({
    super.key,
    required this.child,
    this.maxWidth = 360,
    this.badge,
    this.badgeColor,
  });

  final Widget child;
  final double maxWidth;

  /// Optional icon shown in a glowing medallion above the card.
  final IconData? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    final reduced = MediaQuery.of(context).disableAnimations;
    final tone = badgeColor ?? surfaces.accent;
    const medal = 64.0;

    final card = Container(
      padding: EdgeInsets.fromLTRB(
        22,
        badge == null ? 24 : medal / 2 + 14,
        22,
        18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PetalRadius.xxl),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(surfaces.panel, tone, light ? 0.06 : 0.1)!,
            surfaces.panel,
          ],
        ),
        border: Border.all(color: surfaces.panelBorder),
        boxShadow: PetalShadows.panel(surfaces.shadow, light: light),
      ),
      child: SingleChildScrollView(child: child),
    );

    return Material(
      color: surfaces.scrim,
      child: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: reduced ? PetalMotion.tap : PetalMotion.dialog,
            curve: PetalMotion.settle,
            builder: (context, t, child) {
              // settle (easeOutBack) overshoots past 1 — Opacity must stay in [0, 1].
              final opacity = reduced ? 1.0 : t.clamp(0.0, 1.0);
              final scale = reduced ? 1.0 : (0.9 + 0.1 * t);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: MediaQuery.sizeOf(context).height * 0.86,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: badge == null
                    ? card
                    : Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: medal / 2),
                            child: card,
                          ),
                          Container(
                            width: medal,
                            height: medal,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.lerp(tone, Colors.white, 0.25)!,
                                  tone,
                                ],
                              ),
                              border: Border.all(
                                color: surfaces.panel,
                                width: 4,
                              ),
                              boxShadow: PetalShadows.glow(tone),
                            ),
                            child: Icon(
                              badge,
                              size: 30,
                              color: light ? Colors.white : surfaces.onAccent,
                            ),
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

class AppDialogTitle extends StatelessWidget {
  const AppDialogTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: PetalText.screenTitle(context).copyWith(fontSize: 23),
      textAlign: TextAlign.center,
    );
  }
}

class AppStatRow extends StatelessWidget {
  const AppStatRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;

  /// Gold value, for the number the player cares about most.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: s.hudChip.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(PetalRadius.md),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: PetalText.supporting(context))),
            Text(
              value,
              style: PetalText.score(context)
                  .copyWith(color: highlight ? s.gold : null),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular icon action used in pause / dialog toolbars.
class AppIconAction extends StatelessWidget {
  const AppIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final fg = primary ? surfaces.onCta : surfaces.onPanel;
    final size = primary ? 60.0 : 52.0;

    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        onTap: onPressed,
        scale: 0.9,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60,
                child: Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary ? null : surfaces.hudChip,
                      gradient: primary
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [surfaces.ctaStart, surfaces.ctaEnd],
                            )
                          : null,
                      border: primary
                          ? null
                          : Border.all(color: surfaces.panelBorder),
                      boxShadow: primary
                          ? PetalShadows.glow(surfaces.ctaStart)
                          : null,
                    ),
                    child: Icon(icon, color: fg, size: primary ? 30 : 24),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PetalText.caption(context).copyWith(
                  color: surfaces.onPanel,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three stars that pop in one after another.
class StarBurst extends StatelessWidget {
  const StarBurst({
    super.key,
    required this.stars,
    this.size = 44,
    this.reduced = false,
  });

  final int stars;
  final double size;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    return Semantics(
      label: '$stars of 3 stars',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              // The middle star sits higher, like a crown.
              padding: EdgeInsets.only(bottom: i == 1 ? 10 : 0),
              child: _PopStar(
                lit: i < stars,
                size: i == 1 ? size * 1.2 : size,
                delay: Duration(milliseconds: 140 + i * 160),
                reduced: reduced,
                color: s.gold,
                unlit: s.muted.withValues(alpha: 0.25),
              ),
            ),
        ],
      ),
    );
  }
}

class _PopStar extends StatefulWidget {
  const _PopStar({
    required this.lit,
    required this.size,
    required this.delay,
    required this.reduced,
    required this.color,
    required this.unlit,
  });

  final bool lit;
  final double size;
  final Duration delay;
  final bool reduced;
  final Color color;
  final Color unlit;

  @override
  State<_PopStar> createState() => _PopStarState();
}

class _PopStarState extends State<_PopStar>
    with SingleTickerProviderStateMixin {
  static const _pop = Duration(milliseconds: 420);

  // The stagger lives inside the animation (an Interval), not a timer.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + _pop,
    value: widget.reduced || !widget.lit ? 1 : 0,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _pop).inMilliseconds,
      1,
      curve: Curves.elasticOut,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (_c.value < 1) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.star_rounded,
      size: widget.size,
      color: widget.lit ? widget.color : widget.unlit,
      shadows: widget.lit
          ? [Shadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 16)]
          : null,
    );
    return ScaleTransition(scale: _scale, child: icon);
  }
}
