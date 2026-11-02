import 'package:block_garden/campaign/campaign_catalog.dart';
import 'package:block_garden/campaign/level_generator.dart';
import 'package:block_garden/campaign/level_models.dart';
import 'package:block_garden/game/board.dart';
import 'package:flutter_test/flutter_test.dart';

import 'level_bot.dart';

Board _openingBoard(SectionDefinition s) =>
    Board(size: s.boardSize)
        .applyPattern(blocked: s.blockedCells, prefilled: s.prefilledCells);

void main() {
  test('every section can be won on the piece sequence the game deals', () {
    final lost = <String>[];
    for (final level in CampaignCatalog.levels) {
      for (var i = 0; i < level.sections.length; i++) {
        if (!LevelBot().playSection(level, i).won) {
          lost.add(level.sections[i].id);
        }
      }
    }
    expect(
      lost,
      isEmpty,
      reason:
          'Unwinnable deals. Re-run test/campaign/calibration_report.dart '
          'and update LevelGenerator.seedOverrides.',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('every shape in a section pool fits its opening board', () {
    for (final level in CampaignCatalog.levels) {
      for (final s in level.sections) {
        final board = _openingBoard(s);
        for (final shape in s.shapePool) {
          expect(
            board.canFitAnywhere(shape),
            isTrue,
            reason: 'Section ${s.id}: ${shape.id} cannot be placed',
          );
        }
      }
    }
  });

  test('no opening board starts with a finished line', () {
    for (final level in CampaignCatalog.levels) {
      for (final s in level.sections) {
        expect(
          _openingBoard(s).findClears().hasClears,
          isFalse,
          reason: 'Section ${s.id}',
        );
      }
    }
  });

  test('section goals are complete and in range', () {
    for (final level in CampaignCatalog.levels) {
      for (final s in level.sections) {
        final why = 'Section ${s.id}';
        expect(s.boardSize, inInclusiveRange(5, 10), reason: why);
        expect(s.shapePool.length, s.shapePoolIds.length, reason: why);
        switch (s.objective) {
          case LevelObjective.reachScore:
            expect(s.scoreTarget, greaterThan(0), reason: why);
          case LevelObjective.clearLines:
            expect(s.lineTarget, greaterThan(0), reason: why);
          case LevelObjective.comboStreak:
            expect(s.comboTarget, greaterThan(1), reason: why);
          case LevelObjective.surviveMoves:
            expect(s.moveLimit, greaterThan(0), reason: why);
          case LevelObjective.clearBoard:
            fail('$why uses an objective with no levels designed for it');
        }
      }
    }
  });

  test('levels and section ids are all distinct', () {
    final names = CampaignCatalog.levels.map((l) => l.name).toSet();
    expect(names.length, 500);

    final sectionIds = CampaignCatalog.levels
        .expand((l) => l.sections)
        .map((s) => s.id)
        .toList();
    expect(sectionIds.toSet().length, sectionIds.length);

    // Same goals on the same board would be a repeat, whatever the name says.
    final signatures = CampaignCatalog.levels
        .map(
          (l) => l.sections
              .map(
                (s) =>
                    '${s.objective.name}|${s.boardSize}|${s.scoreTarget}|'
                    '${s.lineTarget}|${s.comboTarget}|${s.moveLimit}|'
                    '${(s.blockedCells.toList()..sort((a, b) => a.$1 * 100 + a.$2 - b.$1 * 100 - b.$2))}|'
                    '${s.prefilledCells}|${s.seedOffset}|${s.id}',
              )
              .join('/'),
        )
        .toSet();
    expect(signatures.length, 500);
  });

  test('level generation is deterministic', () {
    final a = LevelGenerator.build(
      250,
      worldIndex: 4,
      name: 'x',
      iconCode: 1,
    ).toJson();
    final b = LevelGenerator.build(
      250,
      worldIndex: 4,
      name: 'x',
      iconCode: 1,
    ).toJson();
    expect(a.toString(), b.toString());
  });

  test('difficulty rises across the campaign and eases after milestones', () {
    expect(LevelGenerator.difficulty(11), lessThan(0.1));
    expect(LevelGenerator.difficulty(490), greaterThan(0.85));
    expect(
      LevelGenerator.difficulty(251),
      lessThan(LevelGenerator.difficulty(250)),
      reason: 'The level after a milestone should be a breather',
    );
    for (var id = 1; id <= 491; id += 10) {
      expect(
        LevelGenerator.difficulty(id + 9),
        greaterThan(LevelGenerator.difficulty(id)),
      );
    }
  });

  test('a careless player finds early worlds easy and late worlds hard', () {
    double winRate(int worldIndex) {
      var wins = 0, runs = 0;
      for (final id in CampaignCatalog.worlds[worldIndex].levelIds) {
        final level = CampaignCatalog.level(id);
        for (var run = 0; run < 3; run++) {
          runs++;
          final bot = LevelBot(mistakeRate: 0.3, rngSeed: id * 31 + run);
          if (bot.playLevel(level, seed: id * 1000 + run * 7919 + 3).won) {
            wins++;
          }
        }
      }
      return wins / runs;
    }

    final early = (winRate(0) + winRate(1)) / 2;
    final late = (winRate(8) + winRate(9)) / 2;
    expect(early, greaterThan(0.6), reason: 'First worlds are too hard');
    expect(late, lessThan(0.5), reason: 'Last worlds are too easy');
    expect(late, greaterThan(0.1), reason: 'Last worlds are a brick wall');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('stars feel earned: solver gets 3 stars often, but not always', () {
    var three = 0, won = 0;
    for (final level in CampaignCatalog.levels) {
      final run = LevelBot().playLevel(level);
      if (!run.won) continue;
      won++;
      if (level.starsForMoves(run.ratedMoves) == 3) three++;
    }
    expect(won, greaterThan(400));
    expect(three / won, lessThan(0.95));
    expect(three / won, greaterThan(0.3));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
