import 'package:block_garden/core/app_config.dart';
import 'package:block_garden/services/ad_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 12);
  Duration secs(int n) => Duration(seconds: n);

  group('interstitial', () {
    test('new players see none during their first levels', () {
      for (
        var cleared = 0;
        cleared < AppConfig.interstitialFirstAfterLevels;
        cleared++
      ) {
        expect(
          AdPolicy.canShowInterstitial(
            now: now,
            lastShown: null,
            levelsCleared: cleared,
          ),
          isFalse,
        );
      }
    });

    test('never appear back to back', () {
      expect(
        AdPolicy.canShowInterstitial(
          now: now,
          lastShown: now.subtract(
            secs(AppConfig.interstitialMinIntervalSeconds - 1),
          ),
          levelsCleared: 100,
        ),
        isFalse,
      );
      expect(
        AdPolicy.canShowInterstitial(
          now: now,
          lastShown: now.subtract(
            secs(AppConfig.interstitialMinIntervalSeconds),
          ),
          levelsCleared: 100,
        ),
        isTrue,
      );
    });
  });

  group('app open', () {
    final longAway = secs(AppConfig.appOpenMinBackgroundSeconds);

    test('needs a real return to the app, not a quick switch', () {
      expect(
        AdPolicy.canShowAppOpen(
          now: now,
          lastShown: null,
          lastFullScreenClosed: null,
          timeInBackground: longAway - secs(1),
        ),
        isFalse,
      );
      expect(
        AdPolicy.canShowAppOpen(
          now: now,
          lastShown: null,
          lastFullScreenClosed: null,
          timeInBackground: longAway,
        ),
        isTrue,
      );
    });

    test('does not stack on another ad that just closed', () {
      expect(
        AdPolicy.canShowAppOpen(
          now: now,
          lastShown: null,
          lastFullScreenClosed: now.subtract(secs(5)),
          timeInBackground: longAway,
        ),
        isFalse,
      );
    });

    test('respects its own interval', () {
      expect(
        AdPolicy.canShowAppOpen(
          now: now,
          lastShown: now.subtract(
            secs(AppConfig.appOpenMinIntervalSeconds - 1),
          ),
          lastFullScreenClosed: null,
          timeInBackground: longAway,
        ),
        isFalse,
      );
    });
  });
}
