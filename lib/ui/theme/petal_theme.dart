import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'petal_tokens.dart';
import 'petal_typography.dart';

export '../../core/theme_preference.dart';
export 'petal_tokens.dart';
export 'petal_typography.dart';

/// Board / surface tokens that adapt to light and dark.
@immutable
class PetalSurfaces extends ThemeExtension<PetalSurfaces> {
  const PetalSurfaces({
    required this.backdropTop,
    required this.backdropBottom,
    required this.panel,
    required this.panelBorder,
    required this.boardFrame,
    required this.emptyCell,
    required this.blockedCell,
    required this.cellBorder,
    required this.hudChip,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.danger,
    required this.validGhost,
    required this.invalidGhost,
    required this.clearFlash,
    required this.placeFlash,
    required this.blockPalette,
    required this.onPanel,
    required this.muted,
    required this.success,
    required this.warning,
    required this.disabled,
    required this.scrim,
    required this.shadow,
    required this.glowA,
    required this.glowB,
    required this.gold,
    required this.ctaStart,
    required this.ctaEnd,
    required this.onCta,
  });

  final Color backdropTop;
  final Color backdropBottom;
  final Color panel;
  final Color panelBorder;
  final Color boardFrame;
  final Color emptyCell;
  final Color blockedCell;
  final Color cellBorder;
  final Color hudChip;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color danger;
  final Color validGhost;
  final Color invalidGhost;
  final Color clearFlash;
  final Color placeFlash;
  final List<Color> blockPalette;
  final Color onPanel;
  final Color muted;
  final Color success;
  final Color warning;
  final Color disabled;
  final Color scrim;
  final Color shadow;

  /// Soft light pools behind every screen (top-left and bottom-right).
  final Color glowA;
  final Color glowB;

  /// Stars, best scores and rewards.
  final Color gold;

  /// Primary call-to-action gradient (Play, Next level, Start).
  final Color ctaStart;
  final Color ctaEnd;
  final Color onCta;

  /// Twilight garden: plum night sky, glazed pastel petals.
  static const dark = PetalSurfaces(
    backdropTop: Color(0xFF1A1530),
    backdropBottom: Color(0xFF0E1A24),
    panel: Color(0xFF241F3B),
    panelBorder: Color(0xFF3B3459),
    boardFrame: Color(0xFF1B1731),
    emptyCell: Color(0xFF2B2546),
    blockedCell: Color(0xFF4F4668),
    cellBorder: Color(0x16FFFFFF),
    hudChip: Color(0xFF2A2446),
    accent: Color(0xFF62E0B6),
    accentSoft: Color(0xFFFF9E7D),
    onAccent: Color(0xFF0A1A14),
    danger: Color(0xFFFF7A86),
    validGhost: Color(0x9962E0B6),
    invalidGhost: Color(0x99FF7A86),
    clearFlash: Color(0xFFFFF1C9),
    placeFlash: Color(0x88FFFFFF),
    blockPalette: [
      Color(0xFF6EE0AE),
      Color(0xFFFFB07C),
      Color(0xFF74C8F7),
      Color(0xFFFFD86B),
      Color(0xFFB79CFF),
      Color(0xFFFF8BA7),
    ],
    onPanel: Color(0xFFF6F3FF),
    muted: Color(0xFFA8A1C4),
    success: Color(0xFF62E0B6),
    warning: Color(0xFFFFD86B),
    disabled: Color(0xFF5C5677),
    scrim: Color(0xB30A0816),
    shadow: Color(0x80060410),
    glowA: Color(0xFFFF7FA3),
    glowB: Color(0xFF46CFA8),
    gold: Color(0xFFFFC94D),
    ctaStart: Color(0xFFFF8AA6),
    ctaEnd: Color(0xFFFF9A62),
    onCta: Color(0xFFFFFFFF),
  );

  /// Morning garden: blush cream sky, saturated glazed petals.
  static const light = PetalSurfaces(
    backdropTop: Color(0xFFFFF3EF),
    backdropBottom: Color(0xFFEDF5FF),
    panel: Color(0xFFFFFFFF),
    panelBorder: Color(0xFFE4DAEF),
    boardFrame: Color(0xFFEDE5F7),
    emptyCell: Color(0xFFDCD2EC),
    blockedCell: Color(0xFF7B6F95),
    cellBorder: Color(0x1A2B1E4A),
    hudChip: Color(0xFFF6F1FC),
    accent: Color(0xFF1F9C76),
    accentSoft: Color(0xFFEF6A4C),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFD62846),
    validGhost: Color(0xCC2FB98A),
    invalidGhost: Color(0xCCE5546A),
    clearFlash: Color(0xFFFFE7A0),
    placeFlash: Color(0x66FFFFFF),
    blockPalette: [
      Color(0xFF2DB889),
      Color(0xFFF28A47),
      Color(0xFF3A9FE2),
      Color(0xFFE5AE1C),
      Color(0xFF8A68E6),
      Color(0xFFEE5F7E),
    ],
    onPanel: Color(0xFF241D3B),
    muted: Color(0xFF6D6589),
    success: Color(0xFF1F9C76),
    warning: Color(0xFF9A6E00),
    disabled: Color(0xFFB2ABC2),
    scrim: Color(0x80180F2E),
    shadow: Color(0x33402A70),
    glowA: Color(0xFFFFB3C6),
    glowB: Color(0xFF9BE3CC),
    gold: Color(0xFFE09A00),
    ctaStart: Color(0xFFF7668A),
    ctaEnd: Color(0xFFF7894A),
    onCta: Color(0xFFFFFFFF),
  );

  static PetalSurfaces of(BuildContext context) {
    return Theme.of(context).extension<PetalSurfaces>() ?? dark;
  }

  @override
  PetalSurfaces copyWith({
    Color? backdropTop,
    Color? backdropBottom,
    Color? panel,
    Color? panelBorder,
    Color? boardFrame,
    Color? emptyCell,
    Color? blockedCell,
    Color? cellBorder,
    Color? hudChip,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? danger,
    Color? validGhost,
    Color? invalidGhost,
    Color? clearFlash,
    Color? placeFlash,
    List<Color>? blockPalette,
    Color? onPanel,
    Color? muted,
    Color? success,
    Color? warning,
    Color? disabled,
    Color? scrim,
    Color? shadow,
    Color? glowA,
    Color? glowB,
    Color? gold,
    Color? ctaStart,
    Color? ctaEnd,
    Color? onCta,
  }) {
    return PetalSurfaces(
      backdropTop: backdropTop ?? this.backdropTop,
      backdropBottom: backdropBottom ?? this.backdropBottom,
      panel: panel ?? this.panel,
      panelBorder: panelBorder ?? this.panelBorder,
      boardFrame: boardFrame ?? this.boardFrame,
      emptyCell: emptyCell ?? this.emptyCell,
      blockedCell: blockedCell ?? this.blockedCell,
      cellBorder: cellBorder ?? this.cellBorder,
      hudChip: hudChip ?? this.hudChip,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      validGhost: validGhost ?? this.validGhost,
      invalidGhost: invalidGhost ?? this.invalidGhost,
      clearFlash: clearFlash ?? this.clearFlash,
      placeFlash: placeFlash ?? this.placeFlash,
      blockPalette: blockPalette ?? this.blockPalette,
      onPanel: onPanel ?? this.onPanel,
      muted: muted ?? this.muted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      disabled: disabled ?? this.disabled,
      scrim: scrim ?? this.scrim,
      shadow: shadow ?? this.shadow,
      glowA: glowA ?? this.glowA,
      glowB: glowB ?? this.glowB,
      gold: gold ?? this.gold,
      ctaStart: ctaStart ?? this.ctaStart,
      ctaEnd: ctaEnd ?? this.ctaEnd,
      onCta: onCta ?? this.onCta,
    );
  }

  @override
  PetalSurfaces lerp(ThemeExtension<PetalSurfaces>? other, double t) {
    if (other is! PetalSurfaces) return this;
    return t < 0.5 ? this : other;
  }
}

/// Brand accents for logo / campaign world labels. Board blocks use [PetalSurfaces].
class PetalColors {
  PetalColors._();

  static const Color soil = Color(0xFF1A2F23);
  static const Color moss = Color(0xFF2D6A4F);
  static const Color leaf = Color(0xFF5ECF9A);
  static const Color petal = Color(0xFFE8A87C);
  static const Color bloom = Color(0xFFE8D48A);
  static const Color mist = Color(0xFFE9F5EE);
  static const Color ink = Color(0xFF0F1C14);
  static const Color foam = Color(0xFFF7FBF8);
  static const Color crystal = Color(0xFF64C5C5);
  static const Color ember = Color(0xFFE07A6E);
  static const Color lunar = Color(0xFF9B8EC4);
  static const Color danger = Color(0xFFC1121F);

  /// Prefer [PetalSurfaces.blockPalette] for gameplay; kept for non-theme callers.
  static List<Color> blockPaletteFor(Brightness brightness) =>
      brightness == Brightness.dark
      ? PetalSurfaces.dark.blockPalette
      : PetalSurfaces.light.blockPalette;
}

class PetalTheme {
  /// System fonts only — avoids missing-font yellow underlines.
  static ThemeData dark() => _build(Brightness.dark, PetalSurfaces.dark);

  static ThemeData light() => _build(Brightness.light, PetalSurfaces.light);

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required Color color,
    double height = 1.25,
  }) {
    return TextStyle(
      fontFamily: PetalText.renderFontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent,
      decorationThickness: 0,
      letterSpacing: 0,
    );
  }

  static SystemUiOverlayStyle overlayFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: dark
          ? PetalSurfaces.dark.backdropBottom
          : PetalSurfaces.light.backdropBottom,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  static ThemeData _build(Brightness brightness, PetalSurfaces surfaces) {
    final on = surfaces.onPanel;
    final muted = surfaces.muted;
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: surfaces.accent,
      onPrimary: surfaces.onAccent,
      secondary: surfaces.accentSoft,
      onSecondary: isDark ? const Color(0xFF1A1410) : Colors.white,
      tertiary: isDark ? const Color(0xFFE8D48A) : PetalColors.bloom,
      onTertiary: isDark ? const Color(0xFF1A1410) : Colors.white,
      error: surfaces.danger,
      onError: Colors.white,
      surface: surfaces.panel,
      onSurface: on,
      surfaceContainerHighest: surfaces.hudChip,
      outline: surfaces.panelBorder,
      shadow: surfaces.shadow,
      scrim: surfaces.scrim,
    );

    final textTheme = TextTheme(
      displayLarge: _style(size: 32, weight: FontWeight.w800, color: on),
      displayMedium: _style(size: 28, weight: FontWeight.w800, color: on),
      displaySmall: _style(size: 24, weight: FontWeight.w800, color: on),
      headlineLarge: _style(size: 22, weight: FontWeight.w800, color: on),
      headlineMedium: _style(size: 20, weight: FontWeight.w800, color: on),
      headlineSmall: _style(size: 18, weight: FontWeight.w800, color: on),
      titleLarge: _style(size: 18, weight: FontWeight.w800, color: on),
      titleMedium: _style(size: 16, weight: FontWeight.w700, color: on),
      titleSmall: _style(size: 14, weight: FontWeight.w700, color: on),
      bodyLarge: _style(size: 15, weight: FontWeight.w500, color: on),
      bodyMedium: _style(size: 14, weight: FontWeight.w500, color: muted),
      bodySmall: _style(size: 12, weight: FontWeight.w500, color: muted),
      labelLarge: _style(size: 15, weight: FontWeight.w800, color: on),
      labelMedium: _style(size: 12, weight: FontWeight.w700, color: muted),
      labelSmall: _style(size: 10, weight: FontWeight.w600, color: muted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [surfaces],
      scaffoldBackgroundColor: surfaces.backdropTop,
      textTheme: textTheme.apply(fontFamily: PetalText.renderFontFamily),
      primaryTextTheme: textTheme.apply(fontFamily: PetalText.renderFontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: on,
        systemOverlayStyle: overlayFor(brightness),
        titleTextStyle: _style(size: 20, weight: FontWeight.w800, color: on),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaces.accent,
          foregroundColor: surfaces.onAccent,
          disabledBackgroundColor: surfaces.disabled.withValues(alpha: 0.35),
          disabledForegroundColor: surfaces.muted,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(48, 48),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: _style(
            size: 15,
            weight: FontWeight.w800,
            color: surfaces.onAccent,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: surfaces.accent,
          side: BorderSide(color: surfaces.accent, width: 1.6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(48, 48),
          shape: const StadiumBorder(),
          textStyle: _style(
            size: 15,
            weight: FontWeight.w800,
            color: surfaces.accent,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: surfaces.accent,
          textStyle: _style(
            size: 14,
            weight: FontWeight.w700,
            color: surfaces.accent,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaces.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetalRadius.lg),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaces.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetalRadius.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaces.panel,
        contentTextStyle: _style(size: 14, weight: FontWeight.w600, color: on),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: surfaces.accent,
        linearTrackColor: surfaces.emptyCell,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return surfaces.accent;
          return surfaces.panelBorder;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return surfaces.accent.withValues(alpha: 0.35);
          }
          return surfaces.panelBorder.withValues(alpha: 0.4);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: surfaces.accent,
        inactiveTrackColor: surfaces.panelBorder,
        thumbColor: surfaces.accent,
      ),
      iconTheme: IconThemeData(color: on),
      dividerColor: surfaces.panelBorder,
    );
  }
}

class GardenBackdrop extends StatelessWidget {
  const GardenBackdrop({super.key, required this.child, this.accent});

  final Widget child;

  /// Tints the sky toward a world's colour.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    final brightness = Theme.of(context).brightness;
    final light = brightness == Brightness.light;
    final tint = accent == null
        ? s.backdropTop
        : Color.lerp(s.backdropTop, accent, light ? 0.06 : 0.1)!;
    final pool = accent ?? s.glowB;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: PetalTheme.overlayFor(brightness),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tint, s.backdropBottom],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.9, -0.85),
              radius: 1.1,
              colors: [
                s.glowA.withValues(alpha: light ? 0.28 : 0.16),
                s.glowA.withValues(alpha: 0),
              ],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.0, 0.95),
                radius: 1.2,
                colors: [
                  pool.withValues(alpha: light ? 0.26 : 0.14),
                  pool.withValues(alpha: 0),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
