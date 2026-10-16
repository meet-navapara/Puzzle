import 'level_models.dart';
import 'campaign_catalog.dart';

/// Campaign unlock / reward logic. Pure — no I/O.
class CampaignProgression {
  CampaignProgression(Map<int, LevelProgress>? initial)
    : _levels = {
        for (final l in CampaignCatalog.levels)
          l.id: initial?[l.id] ?? LevelProgress(unlocked: l.id == 1),
      };

  final Map<int, LevelProgress> _levels;
  final Set<int> _worldRewardsClaimed = {};
  int petals = 0;
  bool campaignComplete = false;
  bool campaignVictorySeen = false;

  Map<int, LevelProgress> get levels => Map.unmodifiable(_levels);

  LevelProgress progressOf(int id) => _levels[id] ?? const LevelProgress();

  int get completedCount => _levels.values.where((p) => p.completed).length;

  int get totalLevels => 50;

  /// Apply a finished level run. Returns petals newly awarded (0 if replay).
  int completeLevel({
    required int levelId,
    required int score,
    required int sectionsDone,
  }) {
    if (levelId < 1 || levelId > 50) {
      throw ArgumentError('Invalid level $levelId');
    }
    final def = CampaignCatalog.level(levelId);
    final prev = progressOf(levelId);
    var stars = 0;
    for (var i = 0; i < def.starsThresholds.length; i++) {
      if (score >= def.starsThresholds[i]) stars = i + 1;
    }
    if (stars < prev.stars) stars = prev.stars;

    final best = score > prev.bestScore ? score : prev.bestScore;
    var reward = 0;
    var firstClaimed = prev.firstRewardClaimed;
    if (!prev.firstRewardClaimed) {
      reward = def.firstClearReward;
      petals += reward;
      firstClaimed = true;
    }

    _levels[levelId] = prev.copyWith(
      unlocked: true,
      completed: true,
      bestScore: best,
      stars: stars,
      firstRewardClaimed: firstClaimed,
      sectionsCompleted: sectionsDone > prev.sectionsCompleted
          ? sectionsDone
          : prev.sectionsCompleted,
    );

    // Unlock next level (never 51).
    if (levelId < 50) {
      final next = progressOf(levelId + 1);
      _levels[levelId + 1] = next.copyWith(unlocked: true);
    } else {
      campaignComplete = true;
    }

    reward += _tryClaimWorldReward(def.worldIndex);
    return reward;
  }

  int _tryClaimWorldReward(int worldIndex) {
    final world = CampaignCatalog.worlds[worldIndex];
    if (_worldRewardsClaimed.contains(worldIndex)) return 0;
    final allDone = world.levelIds.every((id) => progressOf(id).completed);
    if (!allDone) return 0;
    _worldRewardsClaimed.add(worldIndex);
    petals += world.completionReward;
    return world.completionReward;
  }

  void markVictorySeen() => campaignVictorySeen = true;

  Map<String, dynamic> toJson() => {
    'petals': petals,
    'campaignComplete': campaignComplete,
    'victorySeen': campaignVictorySeen,
    'worldRewards': _worldRewardsClaimed.toList(),
    'levels': {for (final e in _levels.entries) '${e.key}': e.value.toJson()},
  };

  factory CampaignProgression.fromJson(Map<String, dynamic> json) {
    final map = <int, LevelProgress>{};
    final raw = json['levels'] as Map<String, dynamic>? ?? {};
    for (final e in raw.entries) {
      map[int.parse(e.key)] = LevelProgress.fromJson(
        Map<String, dynamic>.from(e.value as Map),
      );
    }
    final p = CampaignProgression(map);
    p.petals = json['petals'] as int? ?? 0;
    p.campaignComplete = json['campaignComplete'] as bool? ?? false;
    p.campaignVictorySeen = json['victorySeen'] as bool? ?? false;
    final wr = (json['worldRewards'] as List?)?.cast<int>() ?? [];
    p._worldRewardsClaimed.addAll(wr);
    // Ensure level 1 unlocked.
    if (!(p._levels[1]?.unlocked ?? false)) {
      p._levels[1] = (p._levels[1] ?? const LevelProgress()).copyWith(
        unlocked: true,
      );
    }
    return p;
  }

  /// Merge guest + cloud: take max progress, never double-claim rewards.
  static CampaignProgression merge(
    CampaignProgression a,
    CampaignProgression b,
  ) {
    final merged = <int, LevelProgress>{};
    for (var id = 1; id <= 50; id++) {
      final pa = a.progressOf(id);
      final pb = b.progressOf(id);
      merged[id] = LevelProgress(
        unlocked: pa.unlocked || pb.unlocked,
        completed: pa.completed || pb.completed,
        bestScore: pa.bestScore > pb.bestScore ? pa.bestScore : pb.bestScore,
        stars: pa.stars > pb.stars ? pa.stars : pb.stars,
        firstRewardClaimed: pa.firstRewardClaimed || pb.firstRewardClaimed,
        sectionsCompleted: pa.sectionsCompleted > pb.sectionsCompleted
            ? pa.sectionsCompleted
            : pb.sectionsCompleted,
      );
    }
    final result = CampaignProgression(merged);
    // Petals: use max of the two to avoid loss; document that true
    // economy integrity needs server-side ledgers.
    result.petals = a.petals > b.petals ? a.petals : b.petals;
    result.campaignComplete = a.campaignComplete || b.campaignComplete;
    result.campaignVictorySeen = a.campaignVictorySeen || b.campaignVictorySeen;
    result._worldRewardsClaimed
      ..addAll(a._worldRewardsClaimed)
      ..addAll(b._worldRewardsClaimed);
    return result;
  }
}
