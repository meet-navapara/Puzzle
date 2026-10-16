import 'package:block_garden/ui/theme/petal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('theme text styles never use underlines', (tester) async {
    late TextTheme textTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: PetalTheme.dark(),
        home: Builder(
          builder: (context) {
            textTheme = Theme.of(context).textTheme;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    for (final style in [
      textTheme.displayLarge,
      textTheme.displayMedium,
      textTheme.displaySmall,
      textTheme.headlineLarge,
      textTheme.headlineMedium,
      textTheme.headlineSmall,
      textTheme.titleLarge,
      textTheme.titleMedium,
      textTheme.titleSmall,
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
      textTheme.labelMedium,
      textTheme.labelSmall,
    ]) {
      expect(style, isNotNull);
      expect(
        style!.decoration,
        anyOf(isNull, equals(TextDecoration.none)),
        reason: 'Unexpected decoration on ${style.fontSize}pt style',
      );
      expect(style.fontSize, isNotNull);
      expect(style.fontSize!, lessThanOrEqualTo(36));
    }
  });

  testWidgets('PetalText semantic styles are undecorated and capped', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PetalTheme.dark(),
        home: Builder(
          builder: (context) {
            final styles = [
              PetalText.display(context),
              PetalText.screenTitle(context),
              PetalText.section(context),
              PetalText.body(context),
              PetalText.supporting(context),
              PetalText.score(context),
              PetalText.scoreLabel(context),
              PetalText.button(context),
              PetalText.caption(context),
              PetalText.accent(context),
            ];
            for (final s in styles) {
              expect(s.decoration, TextDecoration.none);
              expect(s.fontSize!, lessThanOrEqualTo(32));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('PetalSurfaces extension is present on dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PetalTheme.dark(),
        home: Builder(
          builder: (context) {
            final surfaces = PetalSurfaces.of(context);
            expect(surfaces.onPanel, isNot(equals(Colors.transparent)));
            expect(surfaces.panel, isNot(equals(surfaces.backdropTop)));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
