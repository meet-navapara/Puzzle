import 'dart:convert';

import 'package:block_garden/campaign/campaign_catalog.dart';
import 'package:block_garden/campaign/progression.dart';
import 'package:block_garden/core/app_config.dart';
import 'package:block_garden/game/game_engine.dart';
import 'package:block_garden/services/local_save_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A save as the 50-level build wrote it: every level entry present, no catalog
/// version, finale and world rewards claimed.
Map<String, dynamic> _oldCampaignJson({int cleared = 50}) => {
  'petals': 777,
  'campaignComplete': true,
  'victorySeen': true,
  'worldRewards': [0, 1, 2, 3, 4],
  'levels': {
    for (var id = 1; id <= 50; id++)
      '$id': {
        'u': id <= cleared,
        'c': id <= cleared,
        'bs': 100,
        's': 2,
        'fr': id <= cleared,
        'sc': 1,
      },
  },
};

void main() {
  group('migrating a 50-level save', () {
    test('keeps cleared levels and petals and opens level 51', () {
      final p = CampaignProgression.fromJson(_oldCampaignJson());
      expect(p.completedCount, 50);
      expect(p.petals, 777);
      expect(p.progressOf(30).stars, 2);
      expect(
        p.progressOf(51).unlocked,
        isTrue,
        reason: 'Player must not be stuck',
      );
      expect(p.progressOf(52).unlocked, isFalse);
      expect(p.nextLevelId, 51);
    });

    test('forgets the old finale so the new one still plays', () {
      final p = CampaignProgression.fromJson(_oldCampaignJson());
      expect(p.campaignComplete, isFalse);
      expect(p.campaignVictorySeen, isFalse);
    });

    test('old world rewards do not block the new, larger worlds', () {
      final p = CampaignProgression.fromJson(_oldCampaignJson());
      // Old world 0 was levels 1-10. New world 0 pays out on finishing level 50.
      final before = p.petals;
      final replay = p.completeLevel(levelId: 50, score: 1, sectionsDone: 1);
      expect(replay, CampaignCatalog.worlds.first.completionReward);
      expect(p.petals, before + replay);
    });

    test('ignores level ids outside the catalog', () {
      final json = _oldCampaignJson()
        ..['levels'] = {
          '501': {'u': true, 'c': true},
          'junk': {'u': true},
        };
      final p = CampaignProgression.fromJson(json);
      expect(p.levels.containsKey(501), isFalse);
      expect(p.progressOf(1).unlocked, isTrue);
    });

    test('drops a mid-run campaign board but keeps a classic one', () {
      final engine = GameEngine()..startClassic(seed: 5);
      final classic = engine.state.toJson();
      engine.startCampaign(
        levelId: 50,
        sectionIndex: 3,
        boardSize: 9,
        scoreTarget: 500,
        moveLimit: 28,
        blocked: const [],
        prefilled: const [],
        pool: CampaignCatalog.level(1).sections.first.shapePool,
      );
      final campaign = engine.state.toJson();

      Map<String, dynamic> save(Map<String, dynamic> active) => jsonDecode(
        jsonEncode({
          'schema': 1,
          'settings': <String, dynamic>{},
          'campaign': _oldCampaignJson(),
          'classicBest': 9,
          'activeGame': active,
        }),
      );

      expect(LocalSaveSnapshot.fromJson(save(campaign)).activeGame, isNull);
      expect(LocalSaveSnapshot.fromJson(save(classic)).activeGame, isNotNull);
    });

    test('shows the new login screen once to existing players', () {
      final s = PlayerSettings.fromJson({'welcomeSeen': true});
      expect(s.welcomeSeen, isFalse);
      expect(
        PlayerSettings.fromJson(s.copyWith(welcomeSeen: true).toJson())
            .welcomeSeen,
        isTrue,
      );
    });

    test('loads end to end and upgrades the schema', () async {
      SharedPreferences.setMockInitialValues({
        'petalgrid_save_v1': jsonEncode({
          'schema': 1,
          'settings': {'sound': false, 'welcomeSeen': true},
          'campaign': _oldCampaignJson(cleared: 12),
          'classicBest': 42,
          'guestId': 'guest_old',
        }),
      });
      final snap = await LocalSaveService().loadOrCreate();
      expect(snap.schemaVersion, AppConfig.saveSchemaVersion);
      expect(snap.classicBest, 42);
      expect(snap.guestId, 'guest_old');
      expect(snap.settings.soundEnabled, isFalse);
      expect(snap.campaign.completedCount, 12);
      expect(snap.campaign.progressOf(13).unlocked, isTrue);
    });
  });

  group('save format', () {
    test('round-trips progress beyond level 50', () {
      final p = CampaignProgression(null);
      for (var id = 1; id <= 120; id++) {
        p.completeLevel(levelId: id, score: id, sectionsDone: 1, moves: 1);
      }
      final again = CampaignProgression.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(again.completedCount, 120);
      expect(again.progressOf(120).bestScore, 120);
      expect(again.progressOf(121).unlocked, isTrue);
      expect(again.petals, p.petals);
      // World 1 and 2 rewards stay claimed across a reload.
      expect(again.completeLevel(levelId: 1, score: 1, sectionsDone: 1), 0);
    });

    test('a new save stays small: untouched levels are not stored', () {
      final encoded = jsonEncode(CampaignProgression(null).toJson());
      expect(encoded.length, lessThan(300));
      final levels =
          (jsonDecode(encoded) as Map<String, dynamic>)['levels'] as Map;
      expect(levels.keys, ['1']);
    });

    test('a fully finished save fits comfortably in a Firestore document', () {
      final p = CampaignProgression(null);
      for (var id = 1; id <= 500; id++) {
        p.completeLevel(levelId: id, score: 99999, sectionsDone: 4, moves: 1);
      }
      expect(jsonEncode(p.toJson()).length, lessThan(60000));
    });
  });
}
