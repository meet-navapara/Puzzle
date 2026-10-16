import 'package:block_garden/game/game_engine.dart';
import 'package:block_garden/state/app_state.dart';
import 'package:block_garden/ui/game/gameplay_screen.dart';
import 'package:block_garden/ui/theme/petal_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> pumpGameplay(
    WidgetTester tester, {
    required Size size,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState();
    await app.localSave.loadOrCreate().then((s) => app.save = s);
    // Bypass connectivity gate for layout regression tests.
    app.engine.startClassic(bestScore: 0);
    app.puzzleActive = true;
    app.screen = AppScreen.gameplay;

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            theme: PetalTheme.dark(),
            home: const GameplayScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(app.engine.state.phase, GamePhase.playing);
    return app;
  }

  testWidgets('gameplay fits short phone without Find an open fit', (
    tester,
  ) async {
    await pumpGameplay(tester, size: const Size(360, 640));
    expect(find.textContaining('Find an open fit'), findsNothing);
    expect(find.textContaining('Bloom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gameplay fits tall phone', (tester) async {
    await pumpGameplay(tester, size: const Size(390, 844));
    expect(find.text('Classic Garden'), findsOneWidget);
    expect(find.textContaining('Score'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pause overlay uses compact dialog title', (tester) async {
    final app = await pumpGameplay(tester, size: const Size(360, 700));
    app.pauseGame();
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });
}
