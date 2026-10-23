import 'package:block_garden/game/bloom_charge.dart';
import 'package:block_garden/game/board.dart';
import 'package:block_garden/game/game_engine.dart';
import 'package:block_garden/game/piece.dart';
import 'package:block_garden/game/shapes.dart';
import 'package:block_garden/services/local_save_service.dart';
import 'package:block_garden/state/app_state.dart';
import 'package:block_garden/tutorial/tutorial_coach.dart';
import 'package:block_garden/ui/game/gameplay_screen.dart';
import 'package:block_garden/ui/screens/main_menu_screen.dart';
import 'package:block_garden/ui/theme/petal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameState _state(Board board, List<TrayPiece> tray) {
  return GameState(
    board: board,
    tray: tray,
    score: 0,
    bestScore: 0,
    combo: 0,
    linesClearedTotal: 0,
    bloom: const BloomState(),
    phase: GamePhase.playing,
    mode: GameMode.campaign,
    moveCount: 0,
    levelId: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bestMove finishes an open row with the live tray', () {
    var board = Board(size: 4);
    for (var c = 0; c < 3; c++) {
      board = board.tryPlace(ShapeCatalog.mono, 0, c, 1)!;
    }
    final tray = [
      TrayPiece(uid: 'seed', shape: ShapeCatalog.mono, colorIndex: 2),
      TrayPiece(uid: 'wide', shape: ShapeCatalog.square, colorIndex: 0),
    ];
    final move = TutorialCoach.bestMove(_state(board, tray), preferLineClear: true);
    expect(move, isNotNull);
    expect(move!.pieceUid, 'seed');
    expect(move.row, 0);
    expect(move.col, 3);
    expect(move.lineClears, 1);
    expect(board.canPlace(ShapeCatalog.mono, move.row, move.col), isTrue);
  });

  test('bestMove stays legal on an empty board', () {
    final board = Board(size: 5);
    final tray = [
      TrayPiece(uid: 'a', shape: ShapeCatalog.trioH, colorIndex: 0),
    ];
    final move = TutorialCoach.bestMove(_state(board, tray));
    expect(move, isNotNull);
    expect(board.canPlace(ShapeCatalog.trioH, move!.row, move.col), isTrue);
    expect(move.cells.length, 3);
  });

  test('lesson flags round-trip in player settings', () {
    const settings = PlayerSettings(
      tutorialLevel1Done: true,
      tutorialLevel2Done: false,
    );
    final again = PlayerSettings.fromJson(settings.toJson());
    expect(again.tutorialLevel1Done, isTrue);
    expect(again.tutorialLevel2Done, isFalse);
  });

  testWidgets('level 1 shows lesson cards and skip dismisses them', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    app.save = await app.localSave.loadOrCreate();
    app.startLevel(1);

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
    expect(find.text('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('Step 2 of 4'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pump();
    expect(find.text('Step 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(find.text('Step 1 of 4'), findsNothing);
    expect(app.save!.settings.tutorialLevel1Done, isTrue);
    expect(app.engine.state.phase, GamePhase.playing);
  });

  testWidgets('level 1 demo plants a real piece, then a finished lesson stays off', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    app.save = await app.localSave.loadOrCreate();
    app.startLevel(1);

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
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pump();
    }
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Watch the first move'), findsOneWidget);
    expect(app.engine.state.moveCount, 0);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(app.engine.state.moveCount, 1);
    expect(find.text('Why that worked'), findsOneWidget);

    app.completeTutorial(1);
    app.startLevel(1);
    await tester.pump();
    await tester.pump();
    expect(find.text('Step 1 of 4'), findsNothing);
    expect(app.save!.settings.tutorialLevel1Done, isTrue);
  });

  testWidgets('home asks a new player to open Classic Garden themselves', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    app.save = await app.localSave.loadOrCreate();
    app.screen = AppScreen.mainMenu;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          theme: PetalTheme.dark(),
          home: const MainMenuScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Step 1 · Classic Garden'), findsOneWidget);

    await tester.tap(find.text('Campaign'));
    await tester.pump();
    expect(app.screen, AppScreen.mainMenu);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(app.save!.settings.tutorialClassicDone, isTrue);
    expect(find.text('Step 2 · Daily Dew'), findsOneWidget);
  });
}
