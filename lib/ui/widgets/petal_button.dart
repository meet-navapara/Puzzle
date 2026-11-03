import 'package:flutter/material.dart';

import '../theme/petal_theme.dart';

/// Shrinks slightly while pressed, so every tappable surface feels physical.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: PetalMotion.instant,
        curve: PetalMotion.snappy,
        child: widget.child,
      ),
    );
  }
}

/// The one primary action on a screen: Play, Next level, Start, Resume.
class PetalButton extends StatelessWidget {
  const PetalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.subtitle,
    this.height = 56,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Small second line, e.g. "Level 124".
  final String? subtitle;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    final enabled = onPressed != null;
    final text = PetalText.button(context)
        .copyWith(color: s.onCta, fontSize: height >= 64 ? 19 : 16.5);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: s.onCta, size: height >= 64 ? 28 : 22),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: icon == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: PetalText.caption(context).copyWith(
                    color: s.onCta.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: PetalMotion.tap,
          opacity: enabled ? 1 : 0.5,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [s.ctaStart, s.ctaEnd],
              ),
              boxShadow: enabled ? PetalShadows.glow(s.ctaStart) : null,
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.white.withValues(alpha: 0.26),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Round frosted icon button for top bars (settings, back, pause).
class PetalIconButton extends StatelessWidget {
  const PetalIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: PressScale(
          onTap: onPressed,
          scale: 0.9,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.panel.withValues(alpha: 0.72),
              border: Border.all(color: s.panelBorder.withValues(alpha: 0.8)),
              boxShadow: PetalShadows.lift(
                s.shadow,
                light: Theme.of(context).brightness == Brightness.light,
              ),
            ),
            child: Icon(icon, size: size * 0.48, color: s.onPanel),
          ),
        ),
      ),
    );
  }
}

/// Compact pill showing a resource: petals, stars, best score.
class PetalChip extends StatelessWidget {
  const PetalChip({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.label,
  });

  final IconData icon;
  final String value;
  final Color color;

  /// Read by screen readers, e.g. "petals".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    return Semantics(
      label: label == null ? value : '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
        decoration: BoxDecoration(
          color: s.panel.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: s.panelBorder.withValues(alpha: 0.8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 7),
            Text(value, style: PetalText.score(context).copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

/// Rounded frosted panel used for cards, HUD blocks and dialogs.
class PetalPanel extends StatelessWidget {
  const PetalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = PetalRadius.xl,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Optional colour wash from the top-left corner.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    final light = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent == null
                ? Color.lerp(s.panel, Colors.white, light ? 0 : 0.04)!
                : Color.lerp(s.panel, accent, light ? 0.1 : 0.16)!,
            s.panel.withValues(alpha: light ? 1 : 0.92),
          ],
        ),
        border: Border.all(color: s.panelBorder.withValues(alpha: 0.85)),
        boxShadow: PetalShadows.panel(s.shadow, light: light),
      ),
      child: child,
    );
  }
}
