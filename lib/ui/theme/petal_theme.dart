import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'petal_tokens.dart';

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

  static const dark = PetalSurfaces(
    backdropTop: Color(0xFF12161E),
    backdropBottom: Color(0xFF1A2330),
    panel: Color(0xFF252C38),
    panelBorder: Color(0xFF3D4658),
    boardFrame: Color(0xFF171C26),
    emptyCell: Color(0xFF2C3444),
    blockedCell: Color(0xFF3F4758),
    cellBorder: Color(0x22FFFFFF),
    hudChip: Color(0xFF2A3140),
    accent: Color(0xFF5ECF9A),
    accentSoft: Color(0xFFE8A87C),
    onAccent: Color(0xFF0E1410),
    danger: Color(0xFFE57373),
    validGhost: Color(0x995ECF9A),
    invalidGhost: Color(0x99E57373),
    clearFlash: Color(0xFFFFF3C4),
    placeFlash: Color(0x88FFFFFF),
    blockPalette: [
      Color(0xFF5ECF9A),
      Color(0xFFE8A87C),
      Color(0xFF64C5C5),
      Color(0xFFE8D48A),
      Color(0xFF9B8EC4),
      Color(0xFFE07A6E),
    ],
    onPanel: Color(0xFFF2F5F8),
    muted: Color(0xFF9AA3B5),
    success: Color(0xFF5ECF9A),
    warning: Color(0xFFE8D48A),
    disabled: Color(0xFF5A6270),
    scrim: Color(0x99000000),
    shadow: Color(0x66000000),
  );

  /// Light garden palette — solid, high-contrast blocks (no soft glow haze).
  static const light = PetalSurfaces(
    backdropTop: Color(0xFFE4F0E8),
    backdropBottom: Color(0xFFF4F9F5),
    panel: Color(0xFFFFFFFF),
    panelBorder: Color(0xFFBFD2C6),
    boardFrame: Color(0xFF1A3328),
    emptyCell: Color(0xFFC9DCD0),
    blockedCell: Color(0xFF3E4F46),
    cellBorder: Color(0x42000000),
    hudChip: Color(0xFFEEF5F0),
    accent: Color(0xFF2D6A4F),
    accentSoft: Color(0xFFD97757),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC1121F),
    validGhost: Color(0xCC3FA87A),
    invalidGhost: Color(0xCCE07A5F),
    clearFlash: Color(0xFFFFE8A3),
    placeFlash: Color(0x55FFF8E7),
    blockPalette: [
      Color(0xFF2F9E6A),
      Color(0xFFD96545),
      Color(0xFF1FA8A0),
      Color(0xFFD4A52E),
      Color(0xFF6B5A96),
      Color(0xFFC94A3A),
    ],
    onPanel: Color(0xFF122018),
    muted: Color(0xFF5A6B60),
    success: Color(0xFF2D6A4F),
    warning: Color(0xFF9A7B00),
    disabled: Color(0xFFA0A8A3),
    scrim: Color(0x73000000),
    shadow: Color(0x28000000),
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
      textTheme: textTheme,
      primaryTextTheme: textTheme,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PetalRadius.md),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PetalRadius.md),
          ),
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
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    final a = accent ?? s.accent;
    final brightness = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: PetalTheme.overlayFor(brightness),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              s.backdropTop,
              Color.lerp(s.backdropTop, a, 0.1) ?? s.backdropBottom,
              s.backdropBottom,
            ],
          ),
        ),
        child: Material(color: Colors.transparent, elevation: 0, child: child),
      ),
    );
  }
}
