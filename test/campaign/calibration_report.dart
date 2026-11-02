// Prints how the difficulty curve plays per world, and the seed overrides needed
// so every section has a proven winning line. Tuning aid, not part of the suite
// (the file name has no _test suffix). Run with:
//   flutter test test/campaign/calibration_report.dart
// then paste the printed map into LevelGenerator.seedOverrides.
import 'package:block_garden/campaign/campaign_catalog.dart';
import 'package:block_garden/campaign/level_generator.dart';
import 'package:block_garden/campaign/level_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'level_bot.dart';

void main() {
  test('calibration report', () {
    final overrides = <String, int>{};
    for (final world in CampaignCatalog.worlds) {
      var clean = 0,
          three = 0,
          two = 0,
          one = 0,
          casualWins = 0,
          casualRuns = 0;
      for (final id in world.levelIds) {
        final level = CampaignCatalog.level(id);
        final strong = LevelBot().playLevel(level);
        if (strong.won) {
          clean++;
          switch (level.starsForMoves(strong.ratedMoves)) {
            case 3:
              three++;
            case 2:
              two++;
            default:
              one++;
          }
        }
        for (var s = 0; s < level.sections.length; s++) {
          if (LevelBot().playSection(level, s).won) continue;
          final section = level.sections[s];
          for (var offset = 1; offset <= 200; offset++) {
            final seed = id * 1000 + s * 17 + offset * 100003;
            if (LevelBot().playSection(level, s, seed: seed).won) {
              overrides[section.id] = offset;
              break;
            }
          }
        }
        for (var run = 0; run < 5; run++) {
          casualRuns++;
          final casual = LevelBot(
            mistakeRate: 0.3,
            rngSeed: id * 31 + run,
          ).playLevel(level, seed: id * 1000 + run * 7919 + 3);
          if (casual.won) casualWins++;
        }
      }
      // ignore: avoid_print
      print(
        '${world.name.padRight(23)} solver $clean/50 '
        'stars $three/$two/$one casual ${(100 * casualWins / casualRuns).round()}%',
      );
    }
    final sections = CampaignCatalog.levels.fold<int>(
      0,
      (sum, LevelDefinition l) => sum + l.sections.length,
    );
    // ignore: avoid_print
    print(
      'Sections $sections, existing overrides '
      '${LevelGenerator.seedOverrides.length}, new overrides ${overrides.length}',
    );
    // ignore: avoid_print
    print(
      'OVERRIDES ${overrides.entries.map((e) => "'${e.key}': ${e.value}").join(', ')}',
    );
  }, timeout: const Timeout(Duration(minutes: 20)));
}
