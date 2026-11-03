import 'package:flutter/material.dart';

import '../../tutorial/tutorial_copy.dart';
import '../theme/petal_theme.dart';
import '../widgets/petal_button.dart';
import 'tutorial_demo.dart';

enum TutorialPhase { inactive, cards, demo, explain, guided, practice, success }

/// Lesson cards before play (each with an animated demo), and the success
/// card after the lesson level is cleared.
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
    this.reducedMotion = false,
  });

  final TutorialPhase phase;
  final int cardIndex;
  final int levelId;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onContinueSuccess;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final cards = TutorialCopy.cardsFor(levelId);
    final showingCards = phase == TutorialPhase.cards;
    final index = cardIndex.clamp(0, cards.length - 1);
    final card = cards[index];
    final last = index == cards.length - 1;

    final Widget body = showingCards
        ? Column(
            key: ValueKey('card$index'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _LessonPill(text: 'Level $levelId lesson'),
                  const Spacer(),
                  Text(
                    'Step ${index + 1} of ${cards.length}',
                    style: PetalText.caption(context).copyWith(
                      color: surfaces.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PetalRadius.xl),
                  color: surfaces.hudChip.withValues(alpha: 0.6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  // Short phones get a smaller demo so the whole card fits.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (MediaQuery.sizeOf(context).height * 0.3)
                          .clamp(120.0, 250.0),
                    ),
                    child: Center(
                      child: TutorialDemoView(
                        demo: card.demo,
                        animate: !reducedMotion,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                card.title,
                style: PetalText.screenTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                card.body,
                style: PetalText.body(context)
                    .copyWith(height: 1.45, color: surfaces.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              _Dots(count: cards.length, index: index),
              const SizedBox(height: 14),
              PetalButton(
                label: last ? 'Start' : 'Next',
                icon: last
                    ? Icons.play_arrow_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: onNext,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: index == 0 ? null : onBack,
                    child: const Text('Back'),
                  ),
                  TextButton(onPressed: onSkip, child: const Text('Skip')),
                ],
              ),
            ],
          )
        : Column(
            key: const ValueKey('success'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(surfaces.gold, Colors.white, 0.3)!,
                        surfaces.gold,
                      ],
                    ),
                    boxShadow: PetalShadows.glow(surfaces.gold),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Lesson complete',
                style: PetalText.caption(
                  context,
                ).copyWith(color: surfaces.gold, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'You did it',
                style: PetalText.screenTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                TutorialCopy.levelSuccess(levelId),
                style: PetalText.body(context)
                    .copyWith(height: 1.45, color: surfaces.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              PetalButton(label: 'Continue', onPressed: onContinueSuccess),
            ],
          );

    return Material(
      color: surfaces.scrim,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PetalRadius.xxl),
                  color: surfaces.panel,
                  border: Border.all(color: surfaces.panelBorder),
                  boxShadow: PetalShadows.panel(surfaces.shadow),
                ),
                // Each new card slides in; the old one is gone at once, so
                // there is only ever one set of buttons.
                child: TweenAnimationBuilder<double>(
                  key: body.key,
                  tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
                  duration: PetalMotion.screen,
                  curve: PetalMotion.snappy,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(18 * (1 - t), 0),
                      child: child,
                    ),
                  ),
                  child: body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonPill extends StatelessWidget {
  const _LessonPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: s.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded, size: 14, color: s.gold),
          const SizedBox(width: 5),
          Text(
            text,
            style: PetalText.caption(context)
                .copyWith(color: s.gold, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = PetalSurfaces.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: PetalMotion.tap,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == index ? s.accent : s.muted.withValues(alpha: 0.35),
            ),
          ),
      ],
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
    final (title, icon) = switch (phase) {
      TutorialPhase.demo => ('Watch the first move', Icons.visibility_rounded),
      TutorialPhase.explain => ('Why that worked', Icons.lightbulb_rounded),
      TutorialPhase.guided => ('Your turn', Icons.touch_app_rounded),
      TutorialPhase.practice => ('Practice', Icons.spa_rounded),
      _ => ('Lesson', Icons.school_rounded),
    };

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: surfaces.panel.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(PetalRadius.xl),
          border: Border.all(color: surfaces.gold.withValues(alpha: 0.7)),
          boxShadow: PetalShadows.panel(surfaces.shadow),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surfaces.gold.withValues(alpha: 0.18),
                  ),
                  child: Icon(icon, size: 18, color: surfaces.gold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: PetalText.section(context)),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: PetalText.body(context).copyWith(height: 1.35),
                      ),
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
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                if (showHint)
                  TextButton(
                    onPressed: onToggleHint,
                    child: Text(hintOn ? 'Hide hint' : 'Hint'),
                  ),
                TextButton(
                  onPressed: onSkip,
                  child: const Text('Skip tutorial'),
                ),
                if (phase == TutorialPhase.explain)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 2),
                    child: PetalButton(
                      label: 'Continue',
                      expand: false,
                      height: 40,
                      onPressed: onContinue,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
