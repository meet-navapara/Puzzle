import '../game/game_engine.dart';
import 'level_models.dart';

/// The one place a campaign section becomes an engine run, shared by the app and
/// the solvability test so that test always plays exactly what players get.
extension SectionStarter on GameEngine {
  void startSection(
    LevelDefinition level,
    int sectionIndex, {
    int bestScore = 0,
    int levelRunScore = 0,
    int levelRunMoves = 0,
    int? seed,
  }) {
    final section = level.sections[sectionIndex];
    startCampaign(
      levelId: level.id,
      sectionIndex: sectionIndex,
      boardSize: section.boardSize,
      scoreTarget: section.scoreTarget,
      moveLimit: section.moveLimit,
      blocked: section.blockedCells,
      prefilled: section.prefilledCells,
      pool: section.shapePool,
      seed: seed ?? _dealSeed(level.id, sectionIndex, section.seedOffset),
      bestScore: bestScore,
      levelRunScore: levelRunScore,
      levelRunMoves: levelRunMoves,
      winOnScoreTarget: section.objective == LevelObjective.reachScore,
      surviveOnMovesExhausted: section.objective == LevelObjective.surviveMoves,
      lineTarget: section.objective == LevelObjective.clearLines
          ? section.lineTarget
          : null,
      comboTarget: section.objective == LevelObjective.comboStreak
          ? section.comboTarget
          : null,
      clearBoardGoal: section.objective == LevelObjective.clearBoard,
      bloomEnabled: section.bloomEnabled,
      sectionIntro: section.introText,
    );
  }

  /// Fixed per section, so a retry deals the same pieces and can be learned.
  static int _dealSeed(int levelId, int sectionIndex, int offset) =>
      levelId * 1000 + sectionIndex * 17 + offset * 100003;
}
