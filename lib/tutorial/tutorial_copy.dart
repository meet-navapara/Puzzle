/// Beginner cards shown before the first guided levels.
class TutorialCard {
  const TutorialCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class TutorialCopy {
  TutorialCopy._();

  static const cards = <TutorialCard>[
    TutorialCard(
      title: 'Welcome to PetalGrid',
      body:
          'PetalGrid is a garden puzzle. You plant colorful pieces on a board and grow a score by filling space.',
    ),
    TutorialCard(
      title: 'How to play',
      body:
          'Drag a piece from the tray onto empty cells. You can also tap a piece, then tap the board. Pieces cannot overlap or sit on blocked soil.',
    ),
    TutorialCard(
      title: 'How to finish',
      body:
          'Fill every open cell in a row or a column and that line blooms — the pieces clear and you score. Level 1 ends when you reach the score goal. Level 2 ends after you bloom two lines.',
    ),
    TutorialCard(
      title: 'A good move',
      body:
          'Straight pieces are easiest for a first bloom. Combos happen when you clear again on the next plant. We will show the first move, then you try the next one.',
    ),
  ];

  static String levelSuccess(int levelId) {
    if (levelId == 1) {
      return 'You learned the basic move: plant a piece, finish a line, and watch it bloom. Level 2 will let you practice with a little less help.';
    }
    return 'You practiced finding your own blooms. From the next garden onward you can play without the lesson — use Hint only when you want it.';
  }
}
