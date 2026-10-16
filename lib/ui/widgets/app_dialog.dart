import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';

/// Shared modal shell for pause / game-over / completion.
class AppDialogShell extends StatelessWidget {
  const AppDialogShell({super.key, required this.child, this.maxWidth = 340});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final reduced = MediaQuery.of(context).disableAnimations;
    return Material(
      color: surfaces.scrim,
      child: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: reduced ? PetalMotion.tap : PetalMotion.dialog,
            curve: PetalMotion.settle,
            builder: (context, t, child) {
              final opacity = reduced ? 1.0 : t;
              final scale = reduced ? 1.0 : (0.92 + 0.08 * t);
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: surfaces.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: surfaces.panelBorder),
                  boxShadow: PetalShadows.panel(
                    surfaces.shadow,
                    light: Theme.of(context).brightness == Brightness.light,
                  ),
                ),
                child: SingleChildScrollView(child: child),
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
      style: PetalText.screenTitle(context),
      textAlign: TextAlign.center,
    );
  }
}

class AppStatRow extends StatelessWidget {
  const AppStatRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: PetalText.supporting(context))),
          Text(value, style: PetalText.score(context)),
        ],
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
    final bg = primary ? surfaces.accent : surfaces.hudChip;
    final fg = primary ? surfaces.onAccent : surfaces.onPanel;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: 1,
                duration: PetalMotion.tap,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                    border: primary
                        ? null
                        : Border.all(color: surfaces.panelBorder),
                    boxShadow: primary
                        ? [
                            BoxShadow(
                              color: surfaces.accent.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icon, color: fg, size: 24),
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
