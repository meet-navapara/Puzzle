import 'package:flutter/material.dart';

import '../../tutorial/tutorial_copy.dart';
import '../theme/petal_theme.dart';

enum TutorialPhase { inactive, cards, demo, explain, guided, practice, success }

/// Full-screen lesson cards before play, and the success card after.
class TutorialCardOverlay extends StatelessWidget {
  const TutorialCardOverlay({
    super.key,
    required this.phase,
    required this.cardIndex,
    required this.levelId,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onContinueSuccess,
  });

  final TutorialPhase phase;
  final int cardIndex;
  final int levelId;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onContinueSuccess;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final cards = TutorialCopy.cards;
    final showingCards = phase == TutorialPhase.cards;
    final index = cardIndex.clamp(0, cards.length - 1);
    final card = cards[index];
    final last = index == cards.length - 1;

    return Material(
      color: surfaces.scrim.withValues(alpha: 0.72),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaces.panel,
                  borderRadius: BorderRadius.circular(PetalRadius.lg),
                  border: Border.all(color: surfaces.accentSoft, width: 1.4),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        showingCards
                            ? 'Step ${index + 1} of ${cards.length}'
                            : 'Lesson complete',
                        style: PetalText.caption(context).copyWith(
                          color: surfaces.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        showingCards ? card.title : 'You did it',
                        style: PetalText.screenTitle(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        showingCards
                            ? card.body
                            : TutorialCopy.levelSuccess(levelId),
                        style: PetalText.body(context).copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      if (showingCards)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            TextButton(
                              onPressed: index == 0 ? null : onBack,
                              child: const Text('Back'),
                            ),
                            TextButton(
                              onPressed: onSkip,
                              child: const Text('Skip'),
                            ),
                            ElevatedButton(
                              onPressed: onNext,
                              child: Text(last ? 'Start' : 'Next'),
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: onContinueSuccess,
                          child: const Text('Continue'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact coach that stays off the tray while the player acts.
class TutorialCoachBanner extends StatelessWidget {
  const TutorialCoachBanner({
    super.key,
    required this.phase,
    required this.message,
    required this.feedback,
    required this.showHint,
    required this.hintOn,
    required this.onSkip,
    required this.onContinue,
    required this.onToggleHint,
  });

  final TutorialPhase phase;
  final String message;
  final String feedback;
  final bool showHint;
  final bool hintOn;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final VoidCallback onToggleHint;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final title = switch (phase) {
      TutorialPhase.demo => 'Watch the first move',
      TutorialPhase.explain => 'Why that worked',
      TutorialPhase.guided => 'Your turn',
      TutorialPhase.practice => 'Practice',
      _ => 'Lesson',
    };

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaces.panel.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surfaces.accentSoft),
          boxShadow: PetalShadows.panel(surfaces.shadow),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: PetalText.section(context)),
              const SizedBox(height: 4),
              Text(message, style: PetalText.body(context).copyWith(height: 1.35)),
              if (feedback.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  feedback,
                  style: PetalText.caption(context).copyWith(
                    color: surfaces.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  if (showHint)
                    TextButton(
                      onPressed: onToggleHint,
                      child: Text(hintOn ? 'Hide hint' : 'Hint'),
                    ),
                  TextButton(onPressed: onSkip, child: const Text('Skip tutorial')),
                  if (phase == TutorialPhase.explain)
                    ElevatedButton(
                      onPressed: onContinue,
                      child: const Text('Continue'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
