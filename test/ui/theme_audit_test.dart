import 'package:block_garden/services/local_save_service.dart';
import 'package:block_garden/state/app_state.dart';
import 'package:block_garden/ui/game/board_view.dart';
import 'package:block_garden/ui/game/gameplay_screen.dart';
import 'package:block_garden/ui/screens/daily_screen.dart';
import 'package:block_garden/ui/screens/main_menu_screen.dart';
import 'package:block_garden/ui/screens/splash_screen.dart';
import 'package:block_garden/ui/screens/welcome_screen.dart';
import 'package:block_garden/ui/theme/petal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('theme surfaces', () {
    test('dark and light expose distinct board tokens', () {
      expect(
        PetalSurfaces.dark.emptyCell,
        isNot(PetalSurfaces.light.emptyCell),
      );
      expect(
        PetalSurfaces.dark.boardFrame,
        isNot(PetalSurfaces.light.boardFrame),
      );
      expect(PetalSurfaces.light.emptyCell.a, greaterThan(0.9));
      expect(PetalSurfaces.dark.onPanel, isNot(PetalSurfaces.light.onPanel));
    });

    testWidgets('ThemeData carries PetalSurfaces extension', (tester) async {
      for (final theme in [PetalTheme.dark(), PetalTheme.light()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                final s = PetalSurfaces.of(context);
                expect(s.accent, isNotNull);
                expect(s.cellBorder, isNotNull);
                expect(s.clearFlash, isNotNull);
                expect(s.onAccent, isNotNull);
                for (final style in [
                  Theme.of(context).textTheme.titleLarge,
                  Theme.of(context).textTheme.bodyMedium,
                ]) {
                  expect(
                    style?.decoration,
                    anyOf(isNull, equals(TextDecoration.none)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }
    });
  });

  group('theme preference persistence', () {
    test('PlayerSettings round-trips theme preference', () {
      for (final pref in AppThemePreference.values) {
        final s = PlayerSettings(themePreference: pref);
        final decoded = PlayerSettings.fromJson(s.toJson());
        expect(decoded.themePreference, pref);
      }
    });
  });

  group('screens render in light and dark', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      required ThemeData theme,
      required Widget home,
      AppState? app,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final state = app ?? AppState();
      state.save ??= await state.localSave.loadOrCreate();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(theme: theme, home: home),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    for (final entry in {
      'dark': PetalTheme.dark(),
      'light': PetalTheme.light(),
    }.entries) {
      testWidgets('splash ${entry.key}', (tester) async {
        await pumpScreen(
          tester,
          theme: entry.value,
          home: const SplashScreen(),
        );
        expect(find.text('PetalGrid'), findsOneWidget);
      });

      testWidgets('welcome ${entry.key}', (tester) async {
        await pumpScreen(
          tester,
          theme: entry.value,
          home: const WelcomeScreen(),
        );
        expect(find.text('Play as Guest'), findsOneWidget);
      });

      testWidgets('main menu ${entry.key}', (tester) async {
        await pumpScreen(
          tester,
          theme: entry.value,
          home: const MainMenuScreen(),
        );
        expect(find.text('Classic Garden'), findsOneWidget);
      });

      testWidgets('daily ${entry.key}', (tester) async {
        await pumpScreen(tester, theme: entry.value, home: const DailyScreen());
        expect(find.text('Daily Dew'), findsOneWidget);
      });
    }
  });

  testWidgets('theme switch does not reset classic board mid-game', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    app.save = await app.localSave.loadOrCreate();
    app.engine.startClassic(bestScore: 0);
    app.puzzleActive = true;
    app.screen = AppScreen.gameplay;
    final scoreBefore = app.engine.state.score;
    final boardBefore = app.engine.state.board;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          theme: PetalTheme.light(),
          darkTheme: PetalTheme.dark(),
          themeMode: ThemeMode.dark,
          home: const GameplayScreen(),
        ),
      ),
    );
    await tester.pump();

    app.updateSettings(
      app.save!.settings.copyWith(themePreference: AppThemePreference.light),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          theme: PetalTheme.light(),
          darkTheme: PetalTheme.dark(),
          themeMode: ThemeMode.light,
          home: const GameplayScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(app.engine.state.score, scoreBefore);
    expect(identical(app.engine.state.board, boardBefore), isTrue);
    expect(find.byType(BoardView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gameplay has no Great Move banner text in tree by default', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    app.save = await app.localSave.loadOrCreate();
    app.engine.startClassic(bestScore: 0);
    app.puzzleActive = true;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          theme: PetalTheme.dark(),
          home: const GameplayScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('GREAT MOVE'), findsNothing);
  });
}
