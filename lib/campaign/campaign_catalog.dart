import 'level_models.dart';

/// Builds the complete 50-level PetalGrid campaign with five worlds.
class CampaignCatalog {
  CampaignCatalog._();

  static final List<WorldDefinition> worlds = [
    const WorldDefinition(
      index: 0,
      theme: WorldTheme.verdantGrove,
      name: 'Verdant Grove',
      subtitle: 'Learn to plant and clear',
      accentColorValue: 0xFF2D6A4F,
      levelIds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      completionReward: 40,
    ),
    const WorldDefinition(
      index: 1,
      theme: WorldTheme.crystalHarbor,
      name: 'Crystal Harbor',
      subtitle: 'Precision among tide walls',
      accentColorValue: 0xFF0077B6,
      levelIds: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
      completionReward: 60,
    ),
    const WorldDefinition(
      index: 2,
      theme: WorldTheme.emberWorkshop,
      name: 'Ember Workshop',
      subtitle: 'Heat, pressure, tight fits',
      accentColorValue: 0xFFC1121F,
      levelIds: [21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
      completionReward: 80,
    ),
    const WorldDefinition(
      index: 3,
      theme: WorldTheme.lunarObservatory,
      name: 'Lunar Observatory',
      subtitle: 'Scarce moves under starlight',
      accentColorValue: 0xFF5C4D7A,
      levelIds: [31, 32, 33, 34, 35, 36, 37, 38, 39, 40],
      completionReward: 100,
    ),
    const WorldDefinition(
      index: 4,
      theme: WorldTheme.celestialConservatory,
      name: 'Celestial Conservatory',
      subtitle: 'Master gardener trials',
      accentColorValue: 0xFF9B5DE5,
      levelIds: [41, 42, 43, 44, 45, 46, 47, 48, 49, 50],
      completionReward: 150,
    ),
  ];

  static final List<LevelDefinition> levels = _buildAllLevels();
  static final Map<int, LevelDefinition> byId = {
    for (final l in levels) l.id: l,
  };

  static LevelDefinition level(int id) {
    final l = byId[id];
    if (l == null) {
      throw ArgumentError('Level $id does not exist (campaign ends at 50).');
    }
    return l;
  }

  static WorldDefinition worldForLevel(int levelId) {
    return worlds.firstWhere((w) => w.levelIds.contains(levelId));
  }

  static List<LevelDefinition> _buildAllLevels() {
    final list = <LevelDefinition>[];
    list.addAll(_grove());
    list.addAll(_harbor());
    list.addAll(_ember());
    list.addAll(_lunar());
    list.addAll(_celestial());
    assert(list.length == 50, 'Campaign must have exactly 50 levels');
    assert(list.last.id == 50);
    return List.unmodifiable(list);
  }

  static List<(int, int)> _ring(int size, {int inset = 0}) {
    final cells = <(int, int)>[];
    final lo = inset;
    final hi = size - 1 - inset;
    for (var i = lo; i <= hi; i++) {
      cells.add((lo, i));
      cells.add((hi, i));
      cells.add((i, lo));
      cells.add((i, hi));
    }
    return cells.toSet().toList();
  }

  static List<(int, int)> _corners(int size) => [
    (0, 0),
    (0, size - 1),
    (size - 1, 0),
    (size - 1, size - 1),
  ];

  static List<(int, int)> _checker(int size, {int step = 2}) {
    final cells = <(int, int)>[];
    for (var r = 0; r < size; r += step) {
      for (var c = (r % (step * 2) == 0) ? step : 0; c < size; c += step * 2) {
        cells.add((r, c));
      }
    }
    return cells;
  }

  static List<(int, int)> _centerBlock(int size, int w) {
    final start = (size - w) ~/ 2;
    final cells = <(int, int)>[];
    for (var r = start; r < start + w; r++) {
      for (var c = start; c < start + w; c++) {
        cells.add((r, c));
      }
    }
    return cells;
  }

  /// Tiny starter shapes — fast clears on small boards.
  static const _starter = ['mono', 'duo_h', 'duo_v', 'trio_h', 'corner'];
  static const _easy = [
    'mono',
    'duo_h',
    'duo_v',
    'trio_h',
    'trio_v',
    'corner',
    'square',
  ];
  static const _std = [
    'mono',
    'duo_h',
    'duo_v',
    'trio_h',
    'trio_v',
    'corner',
    'square',
    'tee',
    'long_h',
    'long_v',
    'l',
    'j',
    's',
    'z',
  ];
  static const _adv = [
    'mono',
    'duo_h',
    'duo_v',
    'trio_h',
    'corner',
    'square',
    'tee',
    'plus',
    'long_h',
    'long_v',
    'l',
    'j',
    's',
    'z',
    'big_l',
    'u',
  ];

  // ——— World 1: Verdant Grove (1–10) ———
  // Early levels use 5×5 / 6×6 boards and short goals so beginners finish quickly.
  static List<LevelDefinition> _grove() {
    return [
      LevelDefinition(
        id: 1,
        worldIndex: 0,
        name: 'First Seed',
        firstClearReward: 5,
        starsThresholds: const [15, 25, 40],
        sections: [
          SectionDefinition(
            id: '1a',
            name: 'Plant',
            iconCode: 0xe0bb,
            objective: LevelObjective.reachScore,
            boardSize: 5,
            scoreTarget: 18,
            shapePoolIds: _starter,
            introText: 'Drag a piece onto the small garden. Fill a row or column to clear it.',
          ),
        ],
      ),
      LevelDefinition(
        id: 2,
        worldIndex: 0,
        name: 'Sunny Row',
        starsThresholds: const [20, 35, 50],
        sections: [
          SectionDefinition(
            id: '2a',
            name: 'Rows',
            iconCode: 0xe8e5,
            objective: LevelObjective.clearLines,
            boardSize: 5,
            lineTarget: 2,
            scoreTarget: 20,
            shapePoolIds: _starter,
          ),
        ],
      ),
      LevelDefinition(
        id: 3,
        worldIndex: 0,
        name: 'Corner Pots',
        starsThresholds: const [25, 40, 55],
        sections: [
          SectionDefinition(
            id: '3a',
            name: 'Edges',
            iconCode: 0xf1b8,
            objective: LevelObjective.reachScore,
            boardSize: 5,
            scoreTarget: 28,
            blockedCells: _corners(5),
            shapePoolIds: _easy,
          ),
        ],
      ),
      LevelDefinition(
        id: 4,
        worldIndex: 0,
        name: 'Trellis Practice',
        sections: [
          SectionDefinition(
            id: '4a',
            name: 'Frame',
            iconCode: 0xe3ae,
            objective: LevelObjective.reachScore,
            boardSize: 6,
            scoreTarget: 40,
            blockedCells: _corners(6),
            shapePoolIds: _easy,
            introText: 'A slightly larger bed — still quick to clear.',
          ),
          SectionDefinition(
            id: '4b',
            name: 'Inner Path',
            iconCode: 0xe3ae,
            objective: LevelObjective.reachScore,
            boardSize: 6,
            scoreTarget: 50,
            shapePoolIds: _easy,
          ),
        ],
      ),
      LevelDefinition(
        id: 5,
        worldIndex: 0,
        name: 'Bloom Meter',
        challengeHint: 'Use Bloom Prune once',
        sections: [
          SectionDefinition(
            id: '5a',
            name: 'Charge',
            iconCode: 0xe3a9,
            objective: LevelObjective.reachScore,
            boardSize: 6,
            scoreTarget: 55,
            shapePoolIds: _easy,
            introText:
                'Clear lines to fill Bloom Charge, then Prune one stuck cell.',
          ),
        ],
      ),
      LevelDefinition(
        id: 6,
        worldIndex: 0,
        name: 'Pathway Beds',
        sections: [
          SectionDefinition(
            id: '6a',
            name: 'Path A',
            iconCode: 0xe566,
            objective: LevelObjective.reachScore,
            boardSize: 6,
            scoreTarget: 60,
            blockedCells: [(2, 0), (2, 1), (3, 4), (3, 5)],
            shapePoolIds: _easy,
          ),
          SectionDefinition(
            id: '6b',
            name: 'Path B',
            iconCode: 0xe566,
            objective: LevelObjective.clearLines,
            boardSize: 6,
            lineTarget: 3,
            scoreTarget: 45,
            shapePoolIds: _std,
          ),
        ],
      ),
      LevelDefinition(
        id: 7,
        worldIndex: 0,
        name: 'Combo Meadow',
        sections: [
          SectionDefinition(
            id: '7a',
            name: 'Chain',
            iconCode: 0xe8e5,
            objective: LevelObjective.comboStreak,
            boardSize: 6,
            comboTarget: 2,
            scoreTarget: 40,
            shapePoolIds: _std,
          ),
          SectionDefinition(
            id: '7b',
            name: 'Flourish',
            iconCode: 0xe8e5,
            objective: LevelObjective.reachScore,
            boardSize: 6,
            scoreTarget: 70,
            shapePoolIds: _std,
          ),
        ],
      ),
      LevelDefinition(
        id: 8,
        worldIndex: 0,
        name: 'Stone Islands',
        sections: [
          SectionDefinition(
            id: '8a',
            name: 'Isles',
            iconCode: 0xe548,
            objective: LevelObjective.reachScore,
            boardSize: 7,
            scoreTarget: 80,
            blockedCells: _centerBlock(7, 1),
            shapePoolIds: _std,
          ),
          SectionDefinition(
            id: '8b',
            name: 'Archipelago',
            iconCode: 0xe548,
            objective: LevelObjective.reachScore,
            boardSize: 7,
            scoreTarget: 95,
            blockedCells: [
              ..._centerBlock(7, 1),
              (1, 1),
              (1, 5),
              (5, 1),
              (5, 5),
            ],
            shapePoolIds: _std,
          ),
        ],
      ),
      LevelDefinition(
        id: 9,
        worldIndex: 0,
        name: 'Timed Sprouts',
        sections: [
          SectionDefinition(
            id: '9a',
            name: 'Quick',
            iconCode: 0xe425,
            objective: LevelObjective.surviveMoves,
            boardSize: 7,
            moveLimit: 14,
            scoreTarget: 70,
            shapePoolIds: _std,
          ),
          SectionDefinition(
            id: '9b',
            name: 'Steady',
            iconCode: 0xe425,
            objective: LevelObjective.surviveMoves,
            boardSize: 7,
            moveLimit: 16,
            scoreTarget: 90,
            shapePoolIds: _std,
          ),
        ],
      ),
      LevelDefinition(
        id: 10,
        worldIndex: 0,
        name: 'Grove Gate',
        firstClearReward: 25,
        sections: [
          SectionDefinition(
            id: '10a',
            name: 'Gate A',
            iconCode: 0xe8d4,
            objective: LevelObjective.reachScore,
            boardSize: 7,
            scoreTarget: 100,
            blockedCells: _corners(7),
            shapePoolIds: _std,
          ),
          SectionDefinition(
            id: '10b',
            name: 'Gate B',
            iconCode: 0xe8d4,
            objective: LevelObjective.reachScore,
            boardSize: 7,
            scoreTarget: 120,
            moveLimit: 20,
            blockedCells: [..._corners(7), ..._centerBlock(7, 1)],
            shapePoolIds: _std,
            introText: 'Clear the Grove Gate to unlock Crystal Harbor.',
          ),
        ],
      ),
    ];
  }

  // ——— World 2: Crystal Harbor (11–20) ———
  static List<LevelDefinition> _harbor() {
    return List.generate(10, (i) {
      final id = 11 + i;
      final difficulty = i;
      return LevelDefinition(
        id: id,
        worldIndex: 1,
        name: _harborNames[i],
        firstClearReward: 12 + i,
        starsThresholds: [
          80 + difficulty * 10,
          150 + difficulty * 15,
          220 + difficulty * 20,
        ],
        sections: [
          SectionDefinition(
            id: '${id}a',
            name: '${_harborNames[i]} Tide',
            iconCode: 0xe0c6,
            objective: LevelObjective.reachScore,
            boardSize: 8,
            scoreTarget: 160 + difficulty * 20,
            moveLimit: difficulty >= 6 ? 26 - (difficulty - 6) : null,
            blockedCells: difficulty < 3
                ? _ring(8, inset: 0).take(8).toList()
                : difficulty < 6
                ? [
                    ..._corners(8),
                    ...(difficulty.isEven
                        ? _centerBlock(8, 2)
                        : <(int, int)>[]),
                  ]
                : _checker(8),
            shapePoolIds: difficulty < 4 ? _std : _adv,
          ),
          SectionDefinition(
            id: '${id}b',
            name: '${_harborNames[i]} Deep',
            iconCode: 0xe0c6,
            objective: difficulty >= 7
                ? LevelObjective.clearLines
                : LevelObjective.reachScore,
            boardSize: difficulty >= 8 ? 9 : 8,
            scoreTarget: 180 + difficulty * 25,
            lineTarget: difficulty >= 7 ? 6 + (difficulty - 7) : null,
            moveLimit: difficulty >= 5 ? 24 : null,
            blockedCells: _harborBlocked(difficulty),
            shapePoolIds: _adv,
          ),
          if (difficulty >= 4)
            SectionDefinition(
              id: '${id}c',
              name: '${_harborNames[i]} Crest',
              iconCode: 0xe0c6,
              objective: LevelObjective.reachScore,
              boardSize: 8,
              scoreTarget: 200 + difficulty * 20,
              moveLimit: 20 + (10 - difficulty),
              blockedCells: [..._ring(8), ..._corners(8)],
              shapePoolIds: _adv,
            ),
        ],
      );
    });
  }

  static List<(int, int)> _harborBlocked(int d) {
    if (d < 2) return [(3, 3), (3, 4), (4, 3), (4, 4)];
    if (d < 5) return _ring(8, inset: 1);
    if (d < 8) return [..._checker(8), ..._corners(8)];
    return [..._ring(8), ..._centerBlock(8, 2)];
  }

  static const _harborNames = [
    'Pier Light',
    'Glass Buoy',
    'Salt Lattice',
    'Tide Shelf',
    'Coral Notch',
    'Beacon Row',
    'Marina Gate',
    'Spray Arch',
    'Harbor Crown',
    'Crystal Quay',
  ];

  // ——— World 3: Ember Workshop (21–30) ———
  static List<LevelDefinition> _ember() {
    return List.generate(10, (i) {
      final id = 21 + i;
      final d = i;
      return LevelDefinition(
        id: id,
        worldIndex: 2,
        name: _emberNames[i],
        firstClearReward: 15 + i,
        starsThresholds: [100 + d * 12, 180 + d * 18, 280 + d * 22],
        sections: [
          SectionDefinition(
            id: '${id}a',
            name: '${_emberNames[i]} Forge',
            iconCode: 0xe3ed,
            objective: LevelObjective.reachScore,
            boardSize: 8,
            scoreTarget: 200 + d * 25,
            moveLimit: 22 - (d ~/ 3),
            blockedCells: _emberBlocked(d, section: 0),
            shapePoolIds: _adv,
            bloomEnabled: true,
          ),
          SectionDefinition(
            id: '${id}b',
            name: '${_emberNames[i]} Anvil',
            iconCode: 0xe3ed,
            objective: d >= 5
                ? LevelObjective.comboStreak
                : LevelObjective.clearLines,
            boardSize: 9,
            scoreTarget: 220 + d * 28,
            lineTarget: d < 5 ? 7 + d : null,
            comboTarget: d >= 5 ? 3 : null,
            moveLimit: 20,
            blockedCells: _emberBlocked(d, section: 1),
            shapePoolIds: _adv,
          ),
          SectionDefinition(
            id: '${id}c',
            name: '${_emberNames[i]} Temper',
            iconCode: 0xe3ed,
            objective: LevelObjective.surviveMoves,
            boardSize: 8,
            moveLimit: 16 + (d % 3),
            scoreTarget: 180 + d * 20,
            blockedCells: _emberBlocked(d, section: 2),
            shapePoolIds: _adv,
          ),
        ],
      );
    });
  }

  static List<(int, int)> _emberBlocked(int d, {required int section}) {
    final base = <(int, int)>[
      ...(d.isEven ? _ring(8) : _corners(8)),
      ..._centerBlock(8, d < 4 ? 1 : 2),
    ];
    if (section > 0) {
      base.addAll([(2, 5), (5, 2), (2, 2), (5, 5)]);
    }
    if (section > 1) {
      base.addAll(_checker(8).take(6));
    }
    return base.toSet().toList();
  }

  static const _emberNames = [
    'Coal Pan',
    'Spark Rail',
    'Kiln Lane',
    'Brass Gear',
    'Molten Slot',
    'Cinder Maze',
    'Forge Heart',
    'Iron Lattice',
    'Crucible',
    'Ember Crown',
  ];

  // ——— World 4: Lunar Observatory (31–40) ———
  static List<LevelDefinition> _lunar() {
    return List.generate(10, (i) {
      final id = 31 + i;
      final d = i;
      return LevelDefinition(
        id: id,
        worldIndex: 3,
        name: _lunarNames[i],
        firstClearReward: 18 + i,
        starsThresholds: [120 + d * 15, 220 + d * 20, 340 + d * 25],
        sections: [
          SectionDefinition(
            id: '${id}a',
            name: '${_lunarNames[i]} Rise',
            iconCode: 0xe3a8,
            objective: LevelObjective.reachScore,
            boardSize: 9,
            scoreTarget: 260 + d * 30,
            moveLimit: 18 - (d ~/ 4),
            blockedCells: _lunarBlocked(d, 0),
            shapePoolIds: _adv,
          ),
          SectionDefinition(
            id: '${id}b',
            name: '${_lunarNames[i]} Zenith',
            iconCode: 0xe3a8,
            objective: LevelObjective.clearLines,
            boardSize: 9,
            lineTarget: 8 + (d ~/ 2),
            scoreTarget: 240 + d * 25,
            moveLimit: 20,
            blockedCells: _lunarBlocked(d, 1),
            shapePoolIds: _adv,
          ),
          SectionDefinition(
            id: '${id}c',
            name: '${_lunarNames[i]} Eclipse',
            iconCode: 0xe3a8,
            objective: LevelObjective.surviveMoves,
            boardSize: 8,
            moveLimit: 14 + (d % 4),
            scoreTarget: 200 + d * 22,
            blockedCells: _lunarBlocked(d, 2),
            shapePoolIds: _adv,
            introText: d == 9
                ? 'Final lunar trial before the Conservatory.'
                : '',
          ),
        ],
      );
    });
  }

  static List<(int, int)> _lunarBlocked(int d, int section) {
    final size = section < 2 ? 9 : 8;
    final cells = <(int, int)>[..._ring(size), ..._checker(size).take(4 + d)];
    if (section >= 1) cells.addAll(_centerBlock(size, 2));
    if (section >= 2) {
      for (var i = 1; i < size - 1; i++) {
        if (i % 3 == 0) cells.add((i, size ~/ 2));
      }
    }
    return cells.toSet().where((e) => e.$1 < size && e.$2 < size).toList();
  }

  static const _lunarNames = [
    'Moon Dial',
    'Silver Dome',
    'Star Ledger',
    'Night Orchid',
    'Orbit Shelf',
    'Lumen Arch',
    'Crater Ring',
    'Nebula Slot',
    'Astrolabe',
    'Lunar Gate',
  ];

  // ——— World 5: Celestial Conservatory (41–50) ———
  static List<LevelDefinition> _celestial() {
    return List.generate(10, (i) {
      final id = 41 + i;
      final d = i;
      final isFinale = id == 50;
      return LevelDefinition(
        id: id,
        worldIndex: 4,
        name: isFinale ? 'Eternal Bloom' : _celestialNames[i],
        firstClearReward: isFinale ? 100 : 22 + i,
        starsThresholds: isFinale
            ? const [300, 500, 750]
            : [150 + d * 18, 280 + d * 22, 420 + d * 28],
        challengeHint: isFinale
            ? 'Complete all sections to finish the campaign'
            : '',
        sections: [
          SectionDefinition(
            id: '${id}a',
            name: isFinale ? 'Dawn Trial' : '${_celestialNames[i]} Wing',
            iconCode: 0xe3a9,
            objective: LevelObjective.reachScore,
            boardSize: 9,
            scoreTarget: isFinale ? 400 : 300 + d * 35,
            moveLimit: isFinale ? 24 : 16 - (d ~/ 5),
            blockedCells: _celestialBlocked(d, 0, finale: isFinale),
            shapePoolIds: _adv,
            introText: isFinale
                ? 'The Conservatory opens. Three trials remain.'
                : '',
          ),
          SectionDefinition(
            id: '${id}b',
            name: isFinale ? 'Noon Trial' : '${_celestialNames[i]} Spire',
            iconCode: 0xe3a9,
            objective: LevelObjective.comboStreak,
            boardSize: 9,
            comboTarget: isFinale ? 4 : 3,
            scoreTarget: isFinale ? 350 : 280 + d * 30,
            moveLimit: isFinale ? 22 : 18,
            blockedCells: _celestialBlocked(d, 1, finale: isFinale),
            shapePoolIds: _adv,
          ),
          SectionDefinition(
            id: '${id}c',
            name: isFinale ? 'Dusk Trial' : '${_celestialNames[i]} Vault',
            iconCode: 0xe3a9,
            objective: LevelObjective.surviveMoves,
            boardSize: isFinale ? 9 : 8,
            moveLimit: isFinale ? 20 : 12 + (d % 3),
            scoreTarget: isFinale ? 320 : 250 + d * 28,
            blockedCells: _celestialBlocked(d, 2, finale: isFinale),
            shapePoolIds: _adv,
          ),
          if (isFinale)
            SectionDefinition(
              id: '50d',
              name: 'Eternal Bloom',
              iconCode: 0xe3a9,
              objective: LevelObjective.reachScore,
              boardSize: 9,
              scoreTarget: 500,
              moveLimit: 28,
              blockedCells: [
                ..._ring(9),
                ..._centerBlock(9, 3),
                ..._checker(9).take(8),
              ],
              shapePoolIds: _adv,
              introText:
                  'Final challenge: reach 500 points before the garden seals.',
            ),
        ],
      );
    });
  }

  static List<(int, int)> _celestialBlocked(
    int d,
    int section, {
    bool finale = false,
  }) {
    final size = 9;
    if (finale) {
      final cells = <(int, int)>{
        ..._ring(size),
        ..._corners(size),
        if (section >= 1) ..._centerBlock(size, 2),
        if (section >= 2) ..._checker(size).take(10),
      };
      return cells.toList();
    }
    final cells = <(int, int)>{
      ..._ring(size, inset: section == 0 ? 0 : 1),
      ..._checker(size).take(5 + d + section * 2),
      if (section >= 1) ..._centerBlock(size, 2),
    };
    return cells.toList();
  }

  static const _celestialNames = [
    'Prism Hall',
    'Aurora Court',
    'Solarium',
    'Comet Gallery',
    'Eden Spiral',
    'Halo Conservatory',
    'Stellar Nursery',
    'Cosmos Orchard',
    'Apex Greenhouse',
    'Eternal Bloom',
  ];
}
