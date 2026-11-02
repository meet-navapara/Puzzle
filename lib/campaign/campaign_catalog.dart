import 'level_generator.dart';
import 'level_models.dart';

/// The complete 500-level PetalGrid campaign: ten worlds of fifty levels.
class CampaignCatalog {
  CampaignCatalog._();

  static const int levelsPerWorld = LevelGenerator.levelsPerWorld;
  static const int totalLevels = 500;

  /// Bump when level ids change meaning, so saves can migrate.
  static const int catalogVersion = 2;

  static final List<WorldDefinition> worlds = [
    _world(
      0,
      WorldTheme.verdantGrove,
      'Verdant Grove',
      'Learn to plant and clear',
      0xFF2D6A4F,
      100,
    ),
    _world(
      1,
      WorldTheme.crystalHarbor,
      'Crystal Harbor',
      'Precision among tide walls',
      0xFF0077B6,
      150,
    ),
    _world(
      2,
      WorldTheme.sunpetalDunes,
      'Sunpetal Dunes',
      'Overgrown beds under open sky',
      0xFFB7791F,
      200,
    ),
    _world(
      3,
      WorldTheme.emberWorkshop,
      'Ember Workshop',
      'Heat, pressure, tight fits',
      0xFFC1121F,
      250,
    ),
    _world(
      4,
      WorldTheme.mistwoodHollow,
      'Mistwood Hollow',
      'Winding paths through the fog',
      0xFF2F7F79,
      300,
    ),
    _world(
      5,
      WorldTheme.coralLagoon,
      'Coral Lagoon',
      'Two-part gardens below the tide',
      0xFFD1495B,
      350,
    ),
    _world(
      6,
      WorldTheme.frostglassPeaks,
      'Frostglass Peaks',
      'Thin air and heavier pieces',
      0xFF3D7EAA,
      400,
    ),
    _world(
      7,
      WorldTheme.lunarObservatory,
      'Lunar Observatory',
      'Scarce moves under starlight',
      0xFF5C4D7A,
      500,
    ),
    _world(
      8,
      WorldTheme.stormrootHighlands,
      'Stormroot Highlands',
      'Big boards and no easy pieces',
      0xFF4F6D7A,
      600,
    ),
    _world(
      9,
      WorldTheme.celestialConservatory,
      'Celestial Conservatory',
      'Master gardener trials',
      0xFF9B5DE5,
      1000,
    ),
  ];

  static WorldDefinition _world(
    int index,
    WorldTheme theme,
    String name,
    String subtitle,
    int accent,
    int reward,
  ) {
    return WorldDefinition(
      index: index,
      theme: theme,
      name: name,
      subtitle: subtitle,
      accentColorValue: accent,
      levelIds: List.unmodifiable(
        List.generate(levelsPerWorld, (i) => index * levelsPerWorld + i + 1),
      ),
      completionReward: reward,
    );
  }

  static final List<LevelDefinition> levels = _buildAllLevels();
  static final Map<int, LevelDefinition> byId = {
    for (final l in levels) l.id: l,
  };

  static LevelDefinition level(int id) {
    final l = byId[id];
    if (l == null) {
      throw ArgumentError(
        'Level $id does not exist (campaign ends at $totalLevels).',
      );
    }
    return l;
  }

  static WorldDefinition worldForLevel(int levelId) {
    return worlds[(levelId - 1) ~/ levelsPerWorld];
  }

  static List<LevelDefinition> _buildAllLevels() {
    final list = <LevelDefinition>[..._grove()];
    for (var id = list.length + 1; id <= totalLevels; id++) {
      final worldIndex = (id - 1) ~/ levelsPerWorld;
      final built = LevelGenerator.build(
        id,
        worldIndex: worldIndex,
        name: _levelName(id, worldIndex),
        iconCode: _worldIcons[worldIndex],
      );
      list.add(id == totalLevels ? _finale(built) : built);
    }
    assert(
      list.length == totalLevels,
      'Campaign must have $totalLevels levels',
    );
    assert(list.last.id == totalLevels);
    return List.unmodifiable(list);
  }

  static List<(int, int)> _corners(int size) => [
    (0, 0),
    (0, size - 1),
    (size - 1, 0),
    (size - 1, size - 1),
  ];

  static List<(int, int)> _centerBlock(int size, int w) {
    final start = (size - w) ~/ 2;
    return [
      for (var r = start; r < start + w; r++)
        for (var c = start; c < start + w; c++) (r, c),
    ];
  }

  /// Level 500 keeps its generated trials but ends the campaign by name.
  static LevelDefinition _finale(LevelDefinition level) {
    final last = level.sections.last;
    return LevelDefinition(
      id: level.id,
      worldIndex: level.worldIndex,
      name: 'Eternal Bloom',
      firstClearReward: 500,
      challengeHint: 'Complete all sections to finish the campaign',
      sections: [
        ...level.sections.take(level.sections.length - 1),
        SectionDefinition(
          id: last.id,
          name: 'Eternal Bloom',
          iconCode: last.iconCode,
          objective: last.objective,
          boardSize: last.boardSize,
          scoreTarget: last.scoreTarget,
          moveLimit: last.moveLimit,
          parMoves: last.parMoves,
          blockedCells: last.blockedCells,
          prefilledCells: last.prefilledCells,
          shapePoolIds: last.shapePoolIds,
          introText: 'Final trial: keep the garden alive until the last move.',
        ),
      ],
    );
  }

  /// Every level gets its own name: one of ten words with one of five, per world.
  static String _levelName(int id, int worldIndex) {
    final position = (id - 1) % levelsPerWorld;
    final words = _worldWords[worldIndex];
    final first = words.$1[position ~/ words.$2.length];
    final second = words.$2[position % words.$2.length];
    return '$first $second';
  }

  static const List<int> _worldIcons = [
    0xe3ae,
    0xe0c6,
    0xe430,
    0xe3ed,
    0xe406,
    0xe546,
    0xeb3b,
    0xe3a8,
    0xe3a9,
    0xe3a9,
  ];

  static const List<(List<String>, List<String>)> _worldWords = [
    (
      [
        'Clover',
        'Fern',
        'Moss',
        'Willow',
        'Thyme',
        'Ivy',
        'Maple',
        'Sage',
        'Hazel',
        'Grove',
      ],
      ['Patch', 'Trail', 'Glade', 'Nook', 'Gate'],
    ),
    (
      [
        'Pier',
        'Glass',
        'Salt',
        'Tide',
        'Coral',
        'Beacon',
        'Marina',
        'Spray',
        'Anchor',
        'Crystal',
      ],
      ['Light', 'Shelf', 'Row', 'Arch', 'Quay'],
    ),
    (
      [
        'Amber',
        'Dune',
        'Saffron',
        'Mirage',
        'Golden',
        'Sirocco',
        'Oasis',
        'Copper',
        'Solar',
        'Sunpetal',
      ],
      ['Drift', 'Ridge', 'Terrace', 'Well', 'Crown'],
    ),
    (
      [
        'Coal',
        'Spark',
        'Kiln',
        'Brass',
        'Molten',
        'Cinder',
        'Forge',
        'Iron',
        'Bellows',
        'Ember',
      ],
      ['Pan', 'Rail', 'Lane', 'Gear', 'Heart'],
    ),
    (
      [
        'Fog',
        'Hollow',
        'Lichen',
        'Dusk',
        'Bracken',
        'Whisper',
        'Twilit',
        'Rowan',
        'Shade',
        'Mistwood',
      ],
      ['Path', 'Bend', 'Dell', 'Lantern', 'Keep'],
    ),
    (
      [
        'Reef',
        'Pearl',
        'Lagoon',
        'Anemone',
        'Shell',
        'Kelp',
        'Tidal',
        'Azure',
        'Nautilus',
        'Coral',
      ],
      ['Pool', 'Cove', 'Garden', 'Current', 'Atoll'],
    ),
    (
      [
        'Frost',
        'Glacier',
        'Rime',
        'Snow',
        'Icefall',
        'Winter',
        'Silver',
        'Crag',
        'Aurora',
        'Frostglass',
      ],
      ['Pass', 'Ledge', 'Spire', 'Hut', 'Summit'],
    ),
    (
      [
        'Moon',
        'Silver',
        'Star',
        'Night',
        'Orbit',
        'Lumen',
        'Crater',
        'Nebula',
        'Comet',
        'Lunar',
      ],
      ['Dial', 'Dome', 'Ledger', 'Orchid', 'Gate'],
    ),
    (
      [
        'Gale',
        'Thunder',
        'Heather',
        'Tempest',
        'Squall',
        'Slate',
        'Cairn',
        'Bluster',
        'Rain',
        'Stormroot',
      ],
      ['Moor', 'Tor', 'Fell', 'Watch', 'Throne'],
    ),
    (
      [
        'Prism',
        'Aurora',
        'Solar',
        'Comet',
        'Eden',
        'Halo',
        'Stellar',
        'Cosmos',
        'Apex',
        'Celestial',
      ],
      ['Hall', 'Court', 'Gallery', 'Spiral', 'Vault'],
    ),
  ];

  // ——— Verdant Grove opening (1–10): the hand-built lesson levels ———
  // Early levels use 5×5 / 6×6 boards and short goals so beginners finish quickly.
  static List<LevelDefinition> _grove() {
    return [
      LevelDefinition(
        id: 1,
        worldIndex: 0,
        name: 'First Seed',
        firstClearReward: 5,
        sections: [
          SectionDefinition(
            id: '1a',
            name: 'Plant',
            iconCode: 0xe0bb,
            objective: LevelObjective.reachScore,
            boardSize: 5,
            scoreTarget: 18,
            parMoves: 6,
            shapePoolIds: LevelGenerator.starter,
            introText: 'Drag a piece onto the small garden. Fill a row or column to clear it.',
          ),
        ],
      ),
      LevelDefinition(
        id: 2,
        worldIndex: 0,
        name: 'Sunny Row',
        sections: [
          SectionDefinition(
            id: '2a',
            name: 'Rows',
            iconCode: 0xe8e5,
            objective: LevelObjective.clearLines,
            boardSize: 5,
            lineTarget: 2,
            scoreTarget: 20,
            parMoves: 7,
            shapePoolIds: LevelGenerator.starter,
          ),
        ],
      ),
      LevelDefinition(
        id: 3,
        worldIndex: 0,
        name: 'Corner Pots',
        sections: [
          SectionDefinition(
            id: '3a',
            name: 'Edges',
            iconCode: 0xf1b8,
            objective: LevelObjective.reachScore,
            boardSize: 5,
            scoreTarget: 28,
            parMoves: 9,
            blockedCells: _corners(5),
            shapePoolIds: LevelGenerator.easy,
            introText: 'Stone cells cannot be planted. A line clears once its open cells are full.',
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
            parMoves: 11,
            blockedCells: _corners(6),
            shapePoolIds: LevelGenerator.easy,
            introText: 'A slightly larger bed — still quick to clear.',
          ),
          SectionDefinition(
            id: '4b',
            name: 'Inner Path',
            iconCode: 0xe3ae,
            objective: LevelObjective.reachScore,
            boardSize: 6,
            scoreTarget: 50,
            parMoves: 14,
            shapePoolIds: LevelGenerator.easy,
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
            parMoves: 15,
            shapePoolIds: LevelGenerator.easy,
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
            parMoves: 16,
            blockedCells: [(2, 0), (2, 1), (3, 4), (3, 5)],
            shapePoolIds: LevelGenerator.easy,
          ),
          SectionDefinition(
            id: '6b',
            name: 'Path B',
            iconCode: 0xe566,
            objective: LevelObjective.clearLines,
            boardSize: 6,
            lineTarget: 3,
            scoreTarget: 45,
            parMoves: 12,
            shapePoolIds: LevelGenerator.standard,
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
            introText: 'Clear lines on back-to-back moves to build a combo.',
            boardSize: 6,
            comboTarget: 2,
            scoreTarget: 40,
            parMoves: 11,
            shapePoolIds: LevelGenerator.standard,
          ),
          SectionDefinition(
            id: '7b',
            name: 'Flourish',
            iconCode: 0xe8e5,
            objective: LevelObjective.reachScore,
            boardSize: 6,
            scoreTarget: 70,
            parMoves: 18,
            shapePoolIds: LevelGenerator.standard,
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
            parMoves: 20,
            blockedCells: _centerBlock(7, 1),
            shapePoolIds: LevelGenerator.standard,
          ),
          SectionDefinition(
            id: '8b',
            name: 'Archipelago',
            iconCode: 0xe548,
            objective: LevelObjective.reachScore,
            boardSize: 7,
            scoreTarget: 95,
            parMoves: 24,
            blockedCells: [
              ..._centerBlock(7, 1),
              (1, 1),
              (1, 5),
              (5, 1),
              (5, 5),
            ],
            shapePoolIds: LevelGenerator.standard,
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
            objective: LevelObjective.clearLines,
            boardSize: 7,
            moveLimit: 18,
            lineTarget: 3,
            scoreTarget: 70,
            parMoves: 18,
            shapePoolIds: LevelGenerator.standard,
          ),
          SectionDefinition(
            id: '9b',
            name: 'Steady',
            introText: 'Keep planting until the moves run out.',
            iconCode: 0xe425,
            objective: LevelObjective.surviveMoves,
            boardSize: 7,
            moveLimit: 16,
            scoreTarget: 90,
            shapePoolIds: LevelGenerator.standard,
          ),
        ],
      ),
      LevelDefinition(
        id: 10,
        worldIndex: 0,
        name: 'Little Gate',
        firstClearReward: 25,
        sections: [
          SectionDefinition(
            id: '10a',
            name: 'Gate A',
            iconCode: 0xe8d4,
            objective: LevelObjective.reachScore,
            boardSize: 7,
            scoreTarget: 100,
            parMoves: 25,
            blockedCells: _corners(7),
            shapePoolIds: LevelGenerator.standard,
          ),
          SectionDefinition(
            id: '10b',
            name: 'Gate B',
            iconCode: 0xe8d4,
            objective: LevelObjective.reachScore,
            boardSize: 7,
            scoreTarget: 90,
            parMoves: 16,
            moveLimit: 24,
            blockedCells: [..._corners(7), ..._centerBlock(7, 1)],
            shapePoolIds: LevelGenerator.standard,
            introText: 'Clear the Little Gate to open the wider Grove.',
          ),
        ],
      ),
    ];
  }
}
