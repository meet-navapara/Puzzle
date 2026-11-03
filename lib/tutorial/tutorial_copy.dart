/// Which animated mini-garden a lesson card plays.
enum TutorialDemo { drag, rowBloom, reachGoal, lineGoal, columnBloom }

/// One short lesson card: a title, one or two lines, and a demo.
class TutorialCard {
  const TutorialCard({
    required this.title,
    required this.body,
    required this.demo,
  });

  final String title;
  final String body;
  final TutorialDemo demo;
}

class TutorialCopy {
  TutorialCopy._();

  /// Level 1 teaches the core move and its goal (reach a score).
  static const level1 = <TutorialCard>[
    TutorialCard(
      title: 'Drag a piece',
      body: 'Drag a piece from the tray onto empty cells. You can also tap it, then tap the board.',
      demo: TutorialDemo.drag,
    ),
    TutorialCard(
      title: 'Fill a line to bloom',
      body: 'Fill every open cell in a row and it blooms away. That is where big points come from.',
      demo: TutorialDemo.rowBloom,
    ),
    TutorialCard(
      title: 'Reach the goal',
      body: 'Level 1 ends when your score reaches the goal. Watch the first move, then you try.',
      demo: TutorialDemo.reachGoal,
    ),
  ];

  /// Level 2 introduces line goals and columns.
  static const level2 = <TutorialCard>[
    TutorialCard(
      title: 'New goal: bloom 2 lines',
      body: 'This garden counts lines, not points. Bloom two lines to finish.',
      demo: TutorialDemo.lineGoal,
    ),
    TutorialCard(
      title: 'Columns count too',
      body: 'A full column blooms just like a row. Look both ways before you plant.',
      demo: TutorialDemo.columnBloom,
    ),
  ];

  static List<TutorialCard> cardsFor(int levelId) =>
      levelId == 2 ? level2 : level1;

  static String levelSuccess(int levelId) {
    if (levelId == 1) {
      return 'You planted, bloomed a line and reached the goal. Level 2 adds a new kind of goal.';
    }
    return 'Two lines bloomed. From here on you play on your own. You can replay these lessons from Settings.';
  }
}
