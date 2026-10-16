import 'package:block_garden/campaign/campaign_catalog.dart';
import 'package:block_garden/campaign/progression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog has exactly 50 levels ending at 50', () {
    expect(CampaignCatalog.levels.length, 50);
    expect(CampaignCatalog.levels.first.id, 1);
    expect(CampaignCatalog.levels.last.id, 50);
    expect(CampaignCatalog.worlds.length, 5);
    for (final w in CampaignCatalog.worlds) {
      expect(w.levelIds.length, 10);
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

  test('level 50 has finale section Eternal Bloom', () {
    final l50 = CampaignCatalog.level(50);
    expect(l50.name, 'Eternal Bloom');
    expect(l50.sections.length, greaterThanOrEqualTo(3));
    expect(l50.sections.last.name, 'Eternal Bloom');
  });

  test('level 51 does not exist', () {
    expect(() => CampaignCatalog.level(51), throwsArgumentError);
  });

  test('progression unlocks sequentially and no duplicate first reward', () {
    final p = CampaignProgression(null);
    expect(p.progressOf(1).unlocked, isTrue);
    expect(p.progressOf(2).unlocked, isFalse);

    final reward1 = p.completeLevel(levelId: 1, score: 100, sectionsDone: 1);
    expect(reward1, greaterThan(0));
    expect(p.progressOf(1).completed, isTrue);
    expect(p.progressOf(2).unlocked, isTrue);

    final rewardReplay = p.completeLevel(
      levelId: 1,
      score: 200,
      sectionsDone: 1,
    );
    expect(rewardReplay, 0);
    expect(p.progressOf(1).bestScore, 200);
  });

  test('completing 50 marks campaign complete without creating 51', () {
    final p = CampaignProgression(null);
    for (var id = 1; id <= 50; id++) {
      p.completeLevel(levelId: id, score: 500, sectionsDone: 3);
    }
    expect(p.campaignComplete, isTrue);
    expect(p.completedCount, 50);
    expect(p.levels.containsKey(51), isFalse);
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
}
