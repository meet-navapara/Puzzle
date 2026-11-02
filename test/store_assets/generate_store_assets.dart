// Renders Play Store screenshots and the feature graphic from the real app.
// Not part of the suite (no _test suffix). Run with:
//   flutter test test/store_assets/generate_store_assets.dart
// Output: docs/store_assets/ (then run tool/flatten_store_assets.ps1, because
// Play requires PNGs without an alpha channel).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:block_garden/app.dart';
import 'package:block_garden/campaign/campaign_catalog.dart';
import 'package:block_garden/game/game_engine.dart';
import 'package:block_garden/state/app_state.dart';
import 'package:block_garden/ui/theme/petal_theme.dart';
import 'package:block_garden/ui/widgets/brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../campaign/level_bot.dart';

const _outDir = 'docs/store_assets';
const _font = 'StoreRoboto';

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
  ByteData read(String name) {
    final bytes = File('$fonts/$name').readAsBytesSync();
    return ByteData.sublistView(bytes);
  }

  final text = FontLoader(_font);
  for (final f in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    text.addFont(Future.value(read(f)));
  }
  await text.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(read('materialicons-regular.otf')));
  await icons.load();
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String name,
  double ratio,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<AppState> _player() async {
  SharedPreferences.setMockInitialValues({});
  final app = AppState();
  app.save = await app.localSave.loadOrCreate();
  app.save = app.save!.copyWith(
    settings: app.save!.settings.copyWith(
      welcomeSeen: true,
      tutorialSeen: true,
      tutorialLevel1Done: true,
      tutorialLevel2Done: true,
      tutorialClassicDone: true,
      tutorialDailyDone: true,
      reducedEffects: true,
    ),
    classicBest: 1840,
  );
  for (var id = 1; id <= 123; id++) {
    final par = CampaignCatalog.level(id).parMoves;
    app.save!.campaign.completeLevel(
      levelId: id,
      score: 200,
      sectionsDone: 1,
      moves: id % 7 == 0 ? par * 2 : (id % 3 == 0 ? par + 1 : par),
    );
  }
  app.selectedWorld = 2;
  return app;
}

void main() {
  testWidgets('store assets', (tester) async {
    await tester.runAsync(_loadFonts);
    // No audio plugin under flutter test; answer its channels with nothing.
    for (final channel in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
    PetalText.renderFontFamily = _font;
    addTearDown(() => PetalText.renderFontFamily = null);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    final app = await _player();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ChangeNotifierProvider.value(
          value: app,
          child: const PetalGridApp(),
        ),
      ),
    );

    Future<void> shot(String name, AppScreen screen) async {
      app.screen = screen;
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      app.notifyListeners();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await _capture(tester, key, name, 3);
    }

    await shot('screenshot_1_login', AppScreen.welcome);
    await shot('screenshot_4_menu', AppScreen.mainMenu);
    await shot('screenshot_5_worlds', AppScreen.worldMap);
    await shot('screenshot_3_levels', AppScreen.levelSelect);

    // A real game in progress: the solver plays through the app's own API.
    app.startLevel(124);
    app.dismissSectionIntro();
    final level = CampaignCatalog.level(124);
    for (var i = 0; i < 9 && app.engine.state.phase == GamePhase.playing; i++) {
      final move = LevelBot.bestMoveFor(app.engine.state);
      if (move == null) break;
      // Stop one move short of winning so the board stays in play.
      final before = app.engine.state;
      app.placePiece(move.uid, move.row, move.col);
      if (app.engine.state.phase != GamePhase.playing) {
        app.engine.restore(before);
        break;
      }
    }
    await shot('screenshot_2_gameplay', AppScreen.gameplay);

    // The moment of reward.
    app.startLevel(124);
    app.dismissSectionIntro();
    for (var s = 0; s < level.sections.length; s++) {
      for (
        var i = 0;
        i < 300 && app.engine.state.phase == GamePhase.playing;
        i++
      ) {
        final move = LevelBot.bestMoveFor(app.engine.state);
        if (move == null) break;
        app.placePiece(move.uid, move.row, move.col);
      }
      if (s + 1 < level.sections.length) app.continueNextSection();
    }
    await shot('screenshot_6_level_complete', AppScreen.gameplay);

    // Feature graphic, 1024 x 500.
    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1;
    final fg = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: fg,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: PetalTheme.dark(),
          home: const _FeatureGraphic(),
        ),
      ),
    );
    await tester.pump();
    await _capture(tester, fg, 'feature_graphic_1024x500', 1);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E2A22), Color(0xFF1A3D32), Color(0xFF2D6A4F)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandLogo(size: 210),
          const SizedBox(width: 44),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'PetalGrid',
                style: TextStyle(
                  fontFamily: _font,
                  color: Colors.white,
                  fontSize: 84,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Grow your garden one block at a time',
                style: TextStyle(
                  fontFamily: _font,
                  color: Color(0xFFD8F3DC),
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 18),
              Text(
                '500 levels · 10 worlds',
                style: TextStyle(
                  fontFamily: _font,
                  color: Color(0xFFF5C542),
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
