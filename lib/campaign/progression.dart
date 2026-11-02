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

  int get totalLevels => CampaignCatalog.totalLevels;

  int get totalStars => _levels.values.fold(0, (sum, p) => sum + p.stars);

  /// The level to offer next: the first unlocked level not yet cleared, or the
  /// finale once everything is done.
  int get nextLevelId {
    for (var id = 1; id <= totalLevels; id++) {
      final p = progressOf(id);
      if (p.unlocked && !p.completed) return id;
    }
    return totalLevels;
  }

  /// Apply a finished level run. Returns petals newly awarded (0 if replay).
  /// [moves] counts rated moves for stars; omit it to record a plain clear.
  int completeLevel({
    required int levelId,
    required int score,
    required int sectionsDone,
    int? moves,
  }) {
    if (levelId < 1 || levelId > totalLevels) {
      throw ArgumentError('Invalid level $levelId');
    }
    final def = CampaignCatalog.level(levelId);
    final prev = progressOf(levelId);
    var stars = moves == null ? 1 : def.starsForMoves(moves);
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

    if (levelId < totalLevels) {
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

  /// Only levels the player has touched are stored, which keeps the save small
  /// (a fresh save would otherwise carry 500 identical entries).
  Map<String, dynamic> toJson() => {
    'catalog': CampaignCatalog.catalogVersion,
    'petals': petals,
    'campaignComplete': campaignComplete,
    'victorySeen': campaignVictorySeen,
    'worldRewards': _worldRewardsClaimed.toList(),
    'levels': {
      for (final e in _levels.entries)
        if (e.value.unlocked || e.value.completed) '${e.key}': e.value.toJson(),
    },
  };

  factory CampaignProgression.fromJson(Map<String, dynamic> json) {
    final map = <int, LevelProgress>{};
    final raw = json['levels'] as Map<String, dynamic>? ?? {};
    for (final e in raw.entries) {
      final id = int.tryParse(e.key);
      if (id == null || id < 1 || id > CampaignCatalog.totalLevels) continue;
      map[id] = LevelProgress.fromJson(
        Map<String, dynamic>.from(e.value as Map),
      );
    }
    final p = CampaignProgression(map);
    p.petals = json['petals'] as int? ?? 0;

    // Saves from the 50-level catalog keep cleared levels and petals, but their
    // finale and world-reward flags described worlds that no longer exist.
    final current =
        (json['catalog'] as int? ?? 1) == CampaignCatalog.catalogVersion;
    if (current) {
      p.campaignComplete = json['campaignComplete'] as bool? ?? false;
      p.campaignVictorySeen = json['victorySeen'] as bool? ?? false;
      final wr = (json['worldRewards'] as List?)?.cast<int>() ?? const <int>[];
      p._worldRewardsClaimed.addAll(wr);
    }
    p._repairUnlocks();
    return p;
  }

  /// Level 1 is always open, and clearing a level always opens the next one.
  /// Without this a player who finished the old level 50 would be stuck at 51.
  void _repairUnlocks() {
    _levels[1] = progressOf(1).copyWith(unlocked: true);
    for (var id = 1; id < totalLevels; id++) {
      if (progressOf(id).completed && !progressOf(id + 1).unlocked) {
        _levels[id + 1] = progressOf(id + 1).copyWith(unlocked: true);
      }
    }
  }

  /// Merge guest + cloud: take max progress, never double-claim rewards.
  static CampaignProgression merge(
    CampaignProgression a,
    CampaignProgression b,
  ) {
    final merged = <int, LevelProgress>{};
    for (var id = 1; id <= CampaignCatalog.totalLevels; id++) {
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
