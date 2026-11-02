import 'package:block_garden/campaign/campaign_catalog.dart';
import 'package:block_garden/campaign/level_models.dart';
import 'package:block_garden/campaign/progression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog has exactly 500 levels in ten worlds of fifty', () {
    expect(CampaignCatalog.levels.length, 500);
    expect(CampaignCatalog.levels.first.id, 1);
    expect(CampaignCatalog.levels.last.id, 500);
    expect(CampaignCatalog.worlds.length, 10);
    for (final w in CampaignCatalog.worlds) {
      expect(w.levelIds.length, 50);
    }
    final ids = CampaignCatalog.worlds.expand((w) => w.levelIds).toList();
    expect(ids, List.generate(500, (i) => i + 1));
  });

  test('worldForLevel agrees with each level and each world', () {
    for (final level in CampaignCatalog.levels) {
      final world = CampaignCatalog.worldForLevel(level.id);
      expect(world.index, level.worldIndex, reason: 'Level ${level.id}');
      expect(world.levelIds, contains(level.id));
    }
  });

  test('every level has at least one playable section', () {
    for (final level in CampaignCatalog.levels) {
      expect(
        level.sections.length,
        greaterThanOrEqualTo(1),
        reason: 'Level ${level.id}',
      );
    }
  });

  test('early levels use small boards for beginners', () {
    expect(CampaignCatalog.level(1).sections.length, 1);
    expect(CampaignCatalog.level(1).sections.first.boardSize, 5);
    expect(CampaignCatalog.level(2).sections.first.boardSize, 5);
    expect(CampaignCatalog.level(6).sections.length, greaterThanOrEqualTo(2));
  });

  test('level 500 is the finale, Eternal Bloom', () {
    final finale = CampaignCatalog.level(500);
    expect(finale.name, 'Eternal Bloom');
    expect(finale.sections.length, greaterThanOrEqualTo(3));
    expect(finale.sections.last.name, 'Eternal Bloom');
  });

  test('level 501 does not exist', () {
    expect(() => CampaignCatalog.level(501), throwsArgumentError);
    expect(() => CampaignCatalog.level(0), throwsArgumentError);
  });

  test('progression unlocks sequentially and no duplicate first reward', () {
    final p = CampaignProgression(null);
    expect(p.progressOf(1).unlocked, isTrue);
    expect(p.progressOf(2).unlocked, isFalse);

    final reward1 = p.completeLevel(levelId: 1, score: 100, sectionsDone: 1);
    expect(reward1, greaterThan(0));
    expect(p.progressOf(1).completed, isTrue);
    expect(p.progressOf(2).unlocked, isTrue);
    expect(p.nextLevelId, 2);

    final rewardReplay = p.completeLevel(
      levelId: 1,
      score: 200,
      sectionsDone: 1,
    );
    expect(rewardReplay, 0);
    expect(p.progressOf(1).bestScore, 200);
  });

  test('completing 500 marks campaign complete without creating 501', () {
    final p = CampaignProgression(null);
    for (var id = 1; id <= 500; id++) {
      expect(p.campaignComplete, isFalse);
      p.completeLevel(levelId: id, score: 500, sectionsDone: 3);
    }
    expect(p.campaignComplete, isTrue);
    expect(p.completedCount, 500);
    expect(p.levels.containsKey(501), isFalse);
    expect(p.nextLevelId, 500);
    expect(
      () => p.completeLevel(levelId: 501, score: 1, sectionsDone: 1),
      throwsArgumentError,
    );
  });

  test('each world pays its completion reward exactly once', () {
    final p = CampaignProgression(null);
    final world = CampaignCatalog.worlds.first;
    var total = 0;
    for (final id in world.levelIds) {
      total += p.completeLevel(levelId: id, score: 1, sectionsDone: 1);
    }
    final firstClears = world.levelIds
        .map((id) => CampaignCatalog.level(id).firstClearReward)
        .reduce((a, b) => a + b);
    expect(total, firstClears + world.completionReward);
    expect(p.petals, total);
    expect(p.completeLevel(levelId: 1, score: 2, sectionsDone: 1), 0);
  });

  group('stars', () {
    final level = CampaignCatalog.level(11);

    test('are rated on moves against par', () {
      final par = level.parMoves;
      expect(par, greaterThan(0));
      expect(level.starsForMoves(par), 3);
      expect(level.starsForMoves(par + 1), 2);
      expect(level.starsForMoves(par * 2), 1);
    });

    test('survival sections do not count toward par', () {
      for (final l in CampaignCatalog.levels) {
        final rated = l.sections
            .where((s) => s.objective != LevelObjective.surviveMoves)
            .fold<int>(0, (sum, s) => sum + (s.parMoves ?? 0));
        expect(l.parMoves, rated, reason: 'Level ${l.id}');
        expect(
          l.sections.first.objective,
          isNot(LevelObjective.surviveMoves),
          reason: 'Level ${l.id} must open on a rated section',
        );
      }
    });

    test('never go down on a worse replay', () {
      final p = CampaignProgression(null);
      p.completeLevel(levelId: 1, score: 10, sectionsDone: 1, moves: 1);
      expect(p.progressOf(1).stars, 3);
      p.completeLevel(levelId: 1, score: 10, sectionsDone: 1, moves: 500);
      expect(p.progressOf(1).stars, 3);
    });
  });

  test('merge keeps max progress and claimed flags', () {
    final a = CampaignProgression(null);
    a.completeLevel(levelId: 1, score: 50, sectionsDone: 1);
    a.petals = 10;
    final b = CampaignProgression(null);
    b.completeLevel(levelId: 1, score: 120, sectionsDone: 1);
    b.completeLevel(levelId: 2, score: 80, sectionsDone: 1);
    b.petals = 40;
    final m = CampaignProgression.merge(a, b);
    expect(m.progressOf(1).bestScore, 120);
    expect(m.progressOf(2).completed, isTrue);
    expect(m.progressOf(1).firstRewardClaimed, isTrue);
    expect(m.petals, 40);
  });

  test('merge reaches levels past the old 50 cap', () {
    final a = CampaignProgression(null);
    final b = CampaignProgression(null);
    for (var id = 1; id <= 300; id++) {
      b.completeLevel(levelId: id, score: 1, sectionsDone: 1);
    }
    final m = CampaignProgression.merge(a, b);
    expect(m.completedCount, 300);
    expect(m.progressOf(301).unlocked, isTrue);
  });
}
