import 'package:block_garden/campaign/campaign_catalog.dart';
import 'package:block_garden/game/game_engine.dart';
import 'package:block_garden/services/auth_service.dart';
import 'package:block_garden/state/app_state.dart';
import 'package:block_garden/ui/game/gameplay_screen.dart';
import 'package:block_garden/ui/screens/campaign_victory_screen.dart';
import 'package:block_garden/ui/screens/level_select_screen.dart';
import 'package:block_garden/ui/screens/main_menu_screen.dart';
import 'package:block_garden/ui/screens/privacy_screen.dart';
import 'package:block_garden/ui/screens/settings_screen.dart';
import 'package:block_garden/ui/screens/welcome_screen.dart';
import 'package:block_garden/ui/screens/world_map_screen.dart';
import 'package:block_garden/ui/theme/petal_theme.dart';
import 'package:block_garden/ui/widgets/google_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _app({bool tutorialsDone = true}) async {
  final app = AppState();
  app.save = await app.localSave.loadOrCreate();
  if (tutorialsDone) {
    app.save = app.save!.copyWith(
      settings: app.save!.settings.copyWith(
        tutorialSeen: true,
        tutorialLevel1Done: true,
        tutorialLevel2Done: true,
        tutorialClassicDone: true,
        tutorialDailyDone: true,
        // flutter_animate leaves a pending timer on the victory screen otherwise.
        reducedEffects: true,
      ),
    );
  }
  return app;
}

Future<void> _pump(
  WidgetTester tester,
  AppState app,
  Widget home, {
  Size size = const Size(390, 844),
  ThemeData? theme,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: app,
      child: MaterialApp(theme: theme ?? PetalTheme.dark(), home: home),
    ),
  );
  await tester.pump();
}

/// Finishes the current section with legal moves through AppState, as a player.
void _winSection(AppState app) {
  for (var guard = 0; guard < 400; guard++) {
    final st = app.engine.state;
    if (st.phase != GamePhase.playing) return;
    var placed = false;
    outer:
    for (final piece in st.availableTray) {
      for (var r = 0; r < st.board.size; r++) {
        for (var c = 0; c < st.board.size; c++) {
          if (st.board.canPlace(piece.shape, r, c)) {
            placed = app.placePiece(piece.uid, r, c);
            break outer;
          }
        }
      }
    }
    if (!placed) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('login screen', () {
    testWidgets('offers Google and guest, with Google first', (tester) async {
      final app = await _app();
      await _pump(tester, app, const WelcomeScreen());
      final google = find.text('Continue with Google');
      final guest = find.text('Play as Guest');
      expect(google, findsOneWidget);
      expect(guest, findsOneWidget);
      expect(find.byType(GoogleMark), findsOneWidget);
      expect(
        tester.getTopLeft(google).dy,
        lessThan(tester.getTopLeft(guest).dy),
      );
      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('links to the Terms and Privacy Policy', (tester) async {
      final app = await _app();
      await _pump(tester, app, const WelcomeScreen());
      final rich = find.textContaining('By continuing', findRichText: true);
      expect(rich, findsOneWidget);
      final text = tester.widget<RichText>(rich).text.toPlainText();
      expect(text, contains('Terms'));
      expect(text, contains('Privacy Policy'));
    });

    testWidgets('Play as Guest opens the menu and is remembered', (
      tester,
    ) async {
      final app = await _app();
      app.screen = AppScreen.welcome;
      await _pump(tester, app, const WelcomeScreen());
      await tester.tap(find.text('Play as Guest'));
      await tester.pump();
      expect(app.screen, AppScreen.mainMenu);
      expect(app.save!.settings.welcomeSeen, isTrue);
    });

    testWidgets('shows a sign-in error without blocking guest play', (
      tester,
    ) async {
      final app = await _app();
      app.auth.errorMessage = 'Google Sign-In failed.';
      app.auth.status = AuthStatus.error;
      await _pump(tester, app, const WelcomeScreen());
      expect(find.text('Google Sign-In failed.'), findsOneWidget);
      await tester.tap(find.text('Play as Guest'));
      await tester.pump();
      expect(app.screen, AppScreen.mainMenu);
      expect(app.auth.errorMessage, isNull);
    });

    testWidgets('both buttons lock while signing in', (tester) async {
      final app = await _app();
      app.auth.status = AuthStatus.signingIn;
      await _pump(tester, app, const WelcomeScreen());
      expect(find.text('Signing in…'), findsOneWidget);
      await tester.tap(find.text('Play as Guest'));
      await tester.pump();
      expect(app.save!.settings.welcomeSeen, isFalse);
    });

    testWidgets('renders in the light theme too', (tester) async {
      final app = await _app();
      await _pump(
        tester,
        app,
        const WelcomeScreen(),
        theme: PetalTheme.light(),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('level flow', () {
    test('clearing a level rewards, rates and opens the next one', () async {
      final app = await _app();
      app.startLevel(1);
      _winSection(app);
      expect(app.engine.state.phase, GamePhase.levelComplete);
      final campaign = app.save!.campaign;
      expect(campaign.progressOf(1).completed, isTrue);
      expect(campaign.progressOf(1).stars, inInclusiveRange(1, 3));
      expect(app.lastRunStars, campaign.progressOf(1).stars);
      expect(campaign.progressOf(2).unlocked, isTrue);
      expect(campaign.petals, greaterThan(0));
      expect(app.statusMessage, contains('petals'));
    });

    test('Next level moves straight on to the following level', () async {
      final app = await _app();
      app.startLevel(1);
      _winSection(app);
      await app.leaveFinishedLevel(playNext: true);
      expect(app.engine.state.levelId, 2);
      expect(app.engine.state.phase, GamePhase.playing);
      expect(app.screen, AppScreen.gameplay);
      expect(app.advancingSection, isFalse);
    });

    test('Level list returns to the world the level belongs to', () async {
      final app = await _app();
      for (var id = 1; id <= 60; id++) {
        app.save!.campaign.completeLevel(
          levelId: id,
          score: 1,
          sectionsDone: 1,
        );
      }
      app.startLevel(61);
      _winSection(app);
      if (app.engine.state.phase != GamePhase.levelComplete) {
        app.engine.markLevelComplete();
      }
      await app.leaveFinishedLevel();
      expect(app.screen, AppScreen.levelSelect);
      expect(app.selectedWorld, 1);
    });

    test(
      'multi-section levels add up score and moves across sections',
      () async {
        final app = await _app();
        final level = CampaignCatalog.level(6);
        expect(level.sections.length, 2);
        for (var id = 1; id < 6; id++) {
          app.save!.campaign.completeLevel(
            levelId: id,
            score: 1,
            sectionsDone: 1,
          );
        }
        app.startLevel(6);
        _winSection(app);
        expect(app.engine.state.phase, GamePhase.levelComplete);
        final firstScore = app.engine.state.score;
        final firstMoves = app.engine.state.moveCount;
        expect(app.levelRunScore, firstScore);
        expect(app.levelRunMoves, firstMoves);
        expect(app.save!.campaign.progressOf(6).completed, isFalse);

        app.continueNextSection();
        expect(app.engine.state.sectionIndex, 1);
        expect(app.engine.state.levelRunScore, firstScore);
        expect(app.engine.state.levelRunMoves, firstMoves);
        await app.persist();
        expect(app.hasResumableGame, isTrue);
      },
    );

    test('finishing level 500 opens the victory screen', () async {
      final app = await _app();
      for (var id = 1; id < 500; id++) {
        app.save!.campaign.completeLevel(
          levelId: id,
          score: 1,
          sectionsDone: 1,
        );
      }
      final finale = CampaignCatalog.level(500);
      app.startLevel(500, sectionIndex: finale.sections.length - 1);
      _winSection(app);
      if (app.engine.state.phase != GamePhase.levelComplete) {
        app.engine.markLevelComplete();
        app.save!.campaign.completeLevel(
          levelId: 500,
          score: 1,
          sectionsDone: 4,
        );
      }
      await app.leaveFinishedLevel(playNext: true);
      expect(app.screen, AppScreen.campaignVictory);
      expect(app.save!.campaign.campaignComplete, isTrue);
    });

    test('a level reward message does not follow the player around', () async {
      final app = await _app();
      app.startLevel(1);
      _winSection(app);
      expect(app.statusMessage, contains('petals'));
      await app.leaveFinishedLevel();
      expect(app.statusMessage, isNull);
    });

    test('locked levels cannot be started', () async {
      final app = await _app();
      app.startLevel(2);
      expect(app.screen, isNot(AppScreen.gameplay));
      expect(app.engine.hasStarted, isFalse);
    });

    test('Menu from pause keeps the run; Menu after a loss does not', () async {
      final app = await _app();
      app.startClassic();
      app.pauseGame();
      app.exitToMenu();
      await app.persist();
      expect(app.hasResumableGame, isTrue);
      expect(app.resumeActiveGame(), isTrue);
      expect(app.screen, AppScreen.gameplay);

      app.engine.restore(app.engine.state.copyWith(phase: GamePhase.gameOver));
      app.exitToMenu();
      await app.persist();
      expect(app.hasResumableGame, isFalse);
    });
  });

  group('game over overlay', () {
    testWidgets('says why the run ended and offers the right rescue', (
      tester,
    ) async {
      final app = await _app();
      app.startLevel(1);
      app.engine.restore(
        app.engine.state.copyWith(phase: GamePhase.gameOver, movesRemaining: 0),
      );
      await _pump(tester, app, const GameplayScreen());
      expect(find.text('Out of Moves'), findsOneWidget);
      expect(find.text('Watch ad for 5 more moves'), findsOneWidget);
      expect(find.textContaining('Use Bloom Prune'), findsNothing);
    });

    testWidgets('a saved Bloom charge can reopen a stuck board', (
      tester,
    ) async {
      final app = await _app();
      app.startLevel(1);
      final st = app.engine.state;
      app.engine.restore(
        st.copyWith(
          phase: GamePhase.gameOver,
          bloom: st.bloom.addClearedCells(12),
        ),
      );
      await _pump(tester, app, const GameplayScreen());
      expect(find.text('Garden Full'), findsOneWidget);
      await tester.tap(find.text('Use Bloom Prune (1)'));
      await tester.pump();
      expect(app.engine.state.phase, GamePhase.playing);
      expect(app.bloomPruneMode, isTrue);
    });
  });

  group('level select', () {
    testWidgets('lays out a world of fifty and opens only unlocked levels', (
      tester,
    ) async {
      final app = await _app();
      for (var id = 1; id <= 3; id++) {
        app.save!.campaign.completeLevel(
          levelId: id,
          score: 1,
          sectionsDone: 1,
          moves: 1,
        );
      }
      await _pump(tester, app, const LevelSelectScreen());
      await tester.pump();
      expect(
        find.text('World 1 of 10 · 3 / 50 cleared · 9 stars'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Level 4, .*play now$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Level 2, .*3 of 3 stars$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Level 5, .*locked$')),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel(RegExp(r'^Level 5, ')));
      await tester.pump();
      expect(app.screen, isNot(AppScreen.gameplay));

      await tester.tap(find.bySemanticsLabel(RegExp(r'^Level 4, ')));
      await tester.pump();
      expect(app.screen, AppScreen.gameplay);
      expect(app.engine.state.levelId, 4);
    });

    testWidgets('opens scrolled to the current level', (tester) async {
      final app = await _app();
      for (var id = 1; id <= 44; id++) {
        app.save!.campaign.completeLevel(
          levelId: id,
          score: 1,
          sectionsDone: 1,
        );
      }
      await _pump(
        tester,
        app,
        const LevelSelectScreen(),
        size: const Size(360, 480),
      );
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp(r'^Level 45, .*play now$')),
        findsOneWidget,
      );
    });

    testWidgets('world map jumps to the next level', (tester) async {
      final app = await _app();
      app.save!.campaign.completeLevel(levelId: 1, score: 1, sectionsDone: 1);
      await _pump(tester, app, const WorldMapScreen());
      expect(find.text('Celestial Conservatory'), findsNothing); // lazily built
      await tester.tap(find.text('Play level 2'));
      await tester.pump();
      expect(app.engine.state.levelId, 2);
    });

    testWidgets('the last world can be reached and stays locked', (
      tester,
    ) async {
      final app = await _app();
      await _pump(tester, app, const WorldMapScreen());
      await tester.scrollUntilVisible(
        find.text('Celestial Conservatory'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Celestial Conservatory'));
      await tester.pump();
      expect(app.screen, isNot(AppScreen.levelSelect));
    });
  });

  group('copy no longer promises 50 levels', () {
    testWidgets('menu, map, settings and victory', (tester) async {
      final app = await _app();
      await _pump(tester, app, const MainMenuScreen());
      expect(find.text('10 worlds · 500 levels'), findsOneWidget);

      await _pump(tester, app, const WorldMapScreen());
      expect(find.textContaining('0 / 500 levels'), findsOneWidget);

      await _pump(tester, app, const SettingsScreen());
      expect(find.textContaining('0/500'), findsOneWidget);

      await _pump(tester, app, const CampaignVictoryScreen());
      expect(
        find.textContaining('500 gardens across 10 worlds'),
        findsOneWidget,
      );
    });

    testWidgets('privacy screen has no developer-facing wording', (
      tester,
    ) async {
      final app = await _app();
      await _pump(tester, app, const PrivacyScreen());
      expect(find.textContaining('test units'), findsNothing);
      expect(find.textContaining('I understand'), findsNothing);
      expect(find.text('Open privacy policy'), findsOneWidget);
    });
  });

  group('no screen overflows on any device class', () {
    const sizes = {
      'small phone': Size(320, 568),
      'phone': Size(390, 844),
      'tablet': Size(800, 1280),
      'tablet landscape': Size(1280, 800),
    };
    for (final entry in sizes.entries) {
      testWidgets(entry.key, (tester) async {
        final app = await _app();
        for (final screen in <Widget>[
          const WelcomeScreen(),
          const MainMenuScreen(),
          const WorldMapScreen(),
          const LevelSelectScreen(),
          const SettingsScreen(),
          const PrivacyScreen(),
          const CampaignVictoryScreen(),
        ]) {
          await _pump(tester, app, screen, size: entry.value);
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} at ${entry.key}',
          );
        }
        // Biggest board, and a level with the longest objective row.
        for (var id = 1; id < 500; id++) {
          app.save!.campaign.completeLevel(
            levelId: id,
            score: 1,
            sectionsDone: 1,
          );
        }
        app.startLevel(500);
        await _pump(tester, app, const GameplayScreen(), size: entry.value);
        app.dismissSectionIntro();
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'L500 at ${entry.key}');
        for (final phase in [GamePhase.gameOver, GamePhase.levelComplete]) {
          app.engine.restore(app.engine.state.copyWith(phase: phase));
          await _pump(tester, app, const GameplayScreen(), size: entry.value);
          expect(
            tester.takeException(),
            isNull,
            reason: '$phase at ${entry.key}',
          );
        }
      });
    }
  });
}
