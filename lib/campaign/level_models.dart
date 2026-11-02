import 'package:flutter/foundation.dart';

import '../game/piece.dart';
import '../game/shapes.dart';

enum LevelObjective {
  reachScore,
  clearLines,
  surviveMoves,
  clearBoard,
  comboStreak,
}

enum WorldTheme {
  verdantGrove,
  crystalHarbor,
  sunpetalDunes,
  emberWorkshop,
  mistwoodHollow,
  coralLagoon,
  frostglassPeaks,
  lunarObservatory,
  stormrootHighlands,
  celestialConservatory,
}

@immutable
class SectionDefinition {
  const SectionDefinition({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.objective,
    required this.boardSize,
    this.scoreTarget,
    this.lineTarget,
    this.moveLimit,
    this.comboTarget,
    this.parMoves,
    this.blockedCells = const [],
    this.prefilledCells = const [],
    this.shapePoolIds = const [],
    this.bloomEnabled = true,
    this.introText = '',
    this.seedOffset = 0,
  });

  final String id;
  final String name;
  final int iconCode;
  final LevelObjective objective;
  final int boardSize;
  final int? scoreTarget;
  final int? lineTarget;
  final int? moveLimit;
  final int? comboTarget;

  /// Moves a tidy run should need; drives the star rating. Survival sections
  /// have a fixed length, so they leave this unset or zero.
  final int? parMoves;
  final List<(int, int)> blockedCells;
  final List<(int, int, int)> prefilledCells;
  final List<String> shapePoolIds;
  final bool bloomEnabled;
  final String introText;

  /// Selects an alternate piece sequence; see LevelGenerator.seedOverrides.
  final int seedOffset;

  List<PieceShape> get shapePool {
    if (shapePoolIds.isEmpty) return ShapeCatalog.standardPool;
    return shapePoolIds
        .map((id) => ShapeCatalog.find(id))
        .whereType<PieceShape>()
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': iconCode,
    'objective': objective.name,
    'boardSize': boardSize,
    'scoreTarget': scoreTarget,
    'lineTarget': lineTarget,
    'moveLimit': moveLimit,
    'comboTarget': comboTarget,
    'par': parMoves,
    'blocked': blockedCells.map((e) => [e.$1, e.$2]).toList(),
    'prefilled': prefilledCells.map((e) => [e.$1, e.$2, e.$3]).toList(),
    'shapes': shapePoolIds,
    'bloom': bloomEnabled,
    'intro': introText,
  };
}

@immutable
class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.worldIndex,
    required this.name,
    required this.sections,
    this.firstClearReward = 10,
    this.challengeHint = '',
  });

  final int id;
  final int worldIndex;
  final String name;
  final List<SectionDefinition> sections;
  final int firstClearReward;
  final String challengeHint;

  int get sectionCount => sections.length;

  /// Target moves for three stars, counting only sections where moves can vary.
  int get parMoves => sections.fold(0, (sum, s) {
    if (s.objective == LevelObjective.surviveMoves) return sum;
    return sum + (s.parMoves ?? 0);
  });

  /// Stars for finishing in [moves]. Clearing always earns at least one.
  int starsForMoves(int moves) {
    final par = parMoves;
    if (moves <= par) return 3;
    if (moves * 2 <= par * 3) return 2;
    return 1;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'world': worldIndex,
    'name': name,
    'sections': sections.map((s) => s.toJson()).toList(),
    'reward': firstClearReward,
    'hint': challengeHint,
  };
}

@immutable
class WorldDefinition {
  const WorldDefinition({
    required this.index,
    required this.theme,
    required this.name,
    required this.subtitle,
    required this.accentColorValue,
    required this.levelIds,
    this.completionReward = 50,
  });

  final int index;
  final WorldTheme theme;
  final String name;
  final String subtitle;
  final int accentColorValue;
  final List<int> levelIds;
  final int completionReward;
}

@immutable
class LevelProgress {
  const LevelProgress({
    this.unlocked = false,
    this.completed = false,
    this.bestScore = 0,
    this.stars = 0,
    this.firstRewardClaimed = false,
    this.sectionsCompleted = 0,
  });

  final bool unlocked;
  final bool completed;
  final int bestScore;
  final int stars;
  final bool firstRewardClaimed;
  final int sectionsCompleted;

  LevelProgress copyWith({
    bool? unlocked,
    bool? completed,
    int? bestScore,
    int? stars,
    bool? firstRewardClaimed,
    int? sectionsCompleted,
  }) => LevelProgress(
    unlocked: unlocked ?? this.unlocked,
    completed: completed ?? this.completed,
    bestScore: bestScore ?? this.bestScore,
    stars: stars ?? this.stars,
    firstRewardClaimed: firstRewardClaimed ?? this.firstRewardClaimed,
    sectionsCompleted: sectionsCompleted ?? this.sectionsCompleted,
  );

  Map<String, dynamic> toJson() => {
    'u': unlocked,
    'c': completed,
    'bs': bestScore,
    's': stars,
    'fr': firstRewardClaimed,
    'sc': sectionsCompleted,
  };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
    unlocked: json['u'] as bool? ?? false,
    completed: json['c'] as bool? ?? false,
    bestScore: json['bs'] as int? ?? 0,
    stars: json['s'] as int? ?? 0,
    firstRewardClaimed: json['fr'] as bool? ?? false,
    sectionsCompleted: json['sc'] as int? ?? 0,
  );
}
