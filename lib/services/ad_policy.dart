import '../core/app_config.dart';

/// When full-screen ads may appear. Pure rules, kept apart from the SDK wrapper
/// so they are testable: AdMob treats ads after every action, or ads that
/// surprise the player, as disruptive.
class AdPolicy {
  AdPolicy._();

  static bool canShowInterstitial({
    required DateTime now,
    required DateTime? lastShown,
    required int levelsCleared,
  }) {
    if (levelsCleared < AppConfig.interstitialFirstAfterLevels) return false;
    if (lastShown == null) return true;
    return now.difference(lastShown).inSeconds >=
        AppConfig.interstitialMinIntervalSeconds;
  }

  static bool canShowAppOpen({
    required DateTime now,
    required DateTime? lastShown,
    required DateTime? lastFullScreenClosed,
    required Duration timeInBackground,
  }) {
    if (timeInBackground.inSeconds < AppConfig.appOpenMinBackgroundSeconds) {
      return false;
    }
    if (lastFullScreenClosed != null &&
        now.difference(lastFullScreenClosed).inSeconds <
            AppConfig.appOpenAfterAdCooldownSeconds) {
      return false;
    }
    if (lastShown == null) return true;
    return now.difference(lastShown).inSeconds >=
        AppConfig.appOpenMinIntervalSeconds;
  }
}
