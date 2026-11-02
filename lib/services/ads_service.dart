import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/app_config.dart';
import 'ad_policy.dart';

/// AdMob wrapper. Grants rewards only after SDK reward callback.
class AdsService extends ChangeNotifier {
  bool _initialized = false;
  bool _initializing = false;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;

  DateTime? _lastInterstitial;
  DateTime? _lastAppOpen;
  bool _rewardInFlight = false;
  bool _showingAd = false;

  Completer<RewardedAd?>? _rewardedLoad;
  Completer<InterstitialAd?>? _interstitialLoad;
  Completer<AppOpenAd?>? _appOpenLoad;

  int _rewardedFailStreak = 0;
  int _interstitialFailStreak = 0;
  int _appOpenFailStreak = 0;

  bool get isReady => _initialized;
  bool get isShowingAd => _showingAd;
  bool get rewardedReady => _rewarded != null;
  bool get interstitialReady => _interstitial != null;

  /// True when regulation requires a way to reopen the consent form (Settings).
  bool get privacyOptionsRequired => _privacyOptionsRequired;
  bool _privacyOptionsRequired = false;

  /// When the last full-screen ad closed; app-open ads wait a while after it.
  DateTime? _lastFullScreenClosed;

  String get _rewardedId => Platform.isIOS
      ? AppConfig.rewardedAdUnitIos
      : AppConfig.rewardedAdUnitAndroid;
  String get _interstitialId => Platform.isIOS
      ? AppConfig.interstitialAdUnitIos
      : AppConfig.interstitialAdUnitAndroid;
  String get _appOpenId => Platform.isIOS
      ? AppConfig.appOpenAdUnitIos
      : AppConfig.appOpenAdUnitAndroid;

  /// App-open ads are optional: with no ad unit configured they are skipped.
  bool get _appOpenEnabled => _appOpenId.isNotEmpty;

  /// Wait until the first Flutter frame so WebView/JS engine can attach.
  Future<void> initialize() async {
    if (!AppConfig.adsEnabled || _initialized || _initializing) return;
    _initializing = true;
    try {
      final binding = WidgetsBinding.instance;
      if (binding.lifecycleState != AppLifecycleState.resumed) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      // WebView/JS engine often isn't ready until after first paint.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Consent comes first: no ad SDK traffic until the user has had a choice.
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) {
        debugPrint('Ads held back: consent not available yet');
        return;
      }

      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.t,
          testDeviceIds: [
            if (AppConfig.adsUseTestIds) 'EMULATOR',
            ...AppConfig.ownerTestDeviceIds,
          ],
        ),
      );
      await MobileAds.instance.initialize();

      _initialized = true;
      debugPrint(
        'Ads SDK ready (testIds=${AppConfig.adsUseTestIds}, '
        'rewarded=$_rewardedId)',
      );
      unawaited(preloadAll());
      notifyListeners();
    } catch (e) {
      debugPrint('Ads init failed: $e');
      _initialized = false;
      notifyListeners();
      // Retry once after a short delay — common after JavascriptEngine races.
      unawaited(
        Future<void>.delayed(const Duration(seconds: 2), () {
          _initializing = false;
          initialize();
        }),
      );
      return;
    } finally {
      _initializing = false;
    }
  }

  /// Google UMP: shows the consent form only where it is required (EEA, UK...).
  /// Failures fall through; [ConsentInformation.canRequestAds] gates ads after.
  Future<void> _gatherConsent() async {
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null) debugPrint('Consent form: ${error.message}');
            finish();
          });
        } catch (e) {
          debugPrint('Consent form failed: $e');
          finish();
        }
      },
      (error) {
        debugPrint('Consent info: ${error.message}');
        finish();
      },
    );
    await done.future;
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    _privacyOptionsRequired =
        status == PrivacyOptionsRequirementStatus.required;
    notifyListeners();
  }

  /// Reopens the consent form so a player can change their ad choices.
  Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('Privacy options: ${error.message}');
      if (!done.isCompleted) done.complete();
    });
    await done.future;
  }

  Future<void> preloadAll() async {
    if (!_initialized) return;
    await Future.wait([
      loadRewarded(force: false),
      loadInterstitial(force: false),
      loadAppOpen(force: false),
    ]);
  }

  /// Background retries stop here; a player asking for an ad still tries again.
  /// Without a cap, an ad unit AdMob rejects would be retried all session.
  static const int _maxAutoRetries = 5;

  Duration _backoff(int streak) {
    final seconds = (1 << streak.clamp(0, 4)).clamp(1, 16);
    return Duration(seconds: seconds);
  }

  Future<RewardedAd?> loadRewarded({bool force = true}) async {
    if (!_initialized) return _rewarded;
    if (!force && _rewarded != null) return _rewarded;
    if (_rewardedLoad != null) return _rewardedLoad!.future;

    _rewardedLoad = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedFailStreak = 0;
          debugPrint('Rewarded loaded');
          _rewardedLoad?.complete(ad);
          _rewardedLoad = null;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          _rewardedFailStreak++;
          debugPrint('Rewarded failed: $err');
          _rewardedLoad?.complete(null);
          _rewardedLoad = null;
          notifyListeners();
          unawaited(
            Future<void>.delayed(_backoff(_rewardedFailStreak), () {
              if (_rewarded == null &&
                  !_showingAd &&
                  _rewardedFailStreak < _maxAutoRetries) {
                unawaited(loadRewarded());
              }
            }),
          );
        },
      ),
    );
    return _rewardedLoad!.future;
  }

  Future<InterstitialAd?> loadInterstitial({bool force = true}) async {
    if (!_initialized) return _interstitial;
    if (!force && _interstitial != null) return _interstitial;
    if (_interstitialLoad != null) return _interstitialLoad!.future;

    _interstitialLoad = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialFailStreak = 0;
          debugPrint('Interstitial loaded');
          _interstitialLoad?.complete(ad);
          _interstitialLoad = null;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _interstitial = null;
          _interstitialFailStreak++;
          debugPrint('Interstitial failed: $err');
          _interstitialLoad?.complete(null);
          _interstitialLoad = null;
          notifyListeners();
          unawaited(
            Future<void>.delayed(_backoff(_interstitialFailStreak), () {
              if (_interstitial == null &&
                  !_showingAd &&
                  _interstitialFailStreak < _maxAutoRetries) {
                unawaited(loadInterstitial());
              }
            }),
          );
        },
      ),
    );
    return _interstitialLoad!.future;
  }

  Future<AppOpenAd?> loadAppOpen({bool force = true}) async {
    if (!_initialized || !_appOpenEnabled) return _appOpen;
    if (!force && _appOpen != null) return _appOpen;
    if (_appOpenLoad != null) return _appOpenLoad!.future;

    _appOpenLoad = Completer<AppOpenAd?>();
    AppOpenAd.load(
      adUnitId: _appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _appOpenFailStreak = 0;
          debugPrint('AppOpen loaded');
          _appOpenLoad?.complete(ad);
          _appOpenLoad = null;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _appOpen = null;
          _appOpenFailStreak++;
          debugPrint('AppOpen failed: $err');
          _appOpenLoad?.complete(null);
          _appOpenLoad = null;
          notifyListeners();
          unawaited(
            Future<void>.delayed(_backoff(_appOpenFailStreak), () {
              if (_appOpen == null &&
                  !_showingAd &&
                  _appOpenFailStreak < _maxAutoRetries) {
                unawaited(loadAppOpen());
              }
            }),
          );
        },
      ),
    );
    return _appOpenLoad!.future;
  }

  void _clearRewardFlags({required bool reload}) {
    _lastFullScreenClosed = DateTime.now();
    _showingAd = false;
    _rewardInFlight = false;
    if (reload) unawaited(loadRewarded());
    notifyListeners();
  }

  /// Shows rewarded ad. Returns true only if reward callback fired.
  Future<bool> showRewarded({required String placement}) async {
    if (!_initialized || _rewardInFlight || _showingAd) return false;

    RewardedAd? pending = _rewarded;
    pending ??= await loadRewarded().timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
    if (pending == null) {
      debugPrint('Rewarded unavailable for $placement');
      return false;
    }
    final RewardedAd ad = pending;

    _rewarded = null;
    var rewarded = false;
    _rewardInFlight = true;
    _showingAd = true;
    notifyListeners();

    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        _clearRewardFlags(reload: true);
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (shown, err) {
        debugPrint('Rewarded show fail ($placement): $err');
        shown.dispose();
        _clearRewardFlags(reload: true);
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          rewarded = true;
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          try {
            ad.dispose();
          } catch (_) {}
          _clearRewardFlags(reload: true);
          return rewarded;
        },
      );
    } catch (e) {
      debugPrint('Rewarded show failed ($placement): $e');
      try {
        ad.dispose();
      } catch (_) {}
      _clearRewardFlags(reload: true);
      if (!completer.isCompleted) completer.complete(false);
      return false;
    }
  }

  /// Between-levels interstitial. The caller awaits this before moving on, so it
  /// can only appear at that break. It never waits for a load: an ad arriving
  /// seconds later would land on top of the next puzzle.
  Future<bool> showLevelClearInterstitial({required int levelsCleared}) async {
    if (!_initialized || _showingAd) return false;
    if (!AdPolicy.canShowInterstitial(
      now: DateTime.now(),
      lastShown: _lastInterstitial,
      levelsCleared: levelsCleared,
    )) {
      return false;
    }
    final ad = _interstitial;
    if (ad == null) {
      unawaited(loadInterstitial());
      return false;
    }

    _interstitial = null;
    _showingAd = true;
    notifyListeners();
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingAd = false;
        _lastInterstitial = DateTime.now();
        _lastFullScreenClosed = _lastInterstitial;
        unawaited(loadInterstitial());
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('Interstitial show fail: $err');
        ad.dispose();
        _showingAd = false;
        unawaited(loadInterstitial());
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
    );
    try {
      await ad.show();
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _showingAd = false;
          unawaited(loadInterstitial());
          notifyListeners();
        },
      );
      return true;
    } catch (e) {
      debugPrint('Interstitial show exception: $e');
      _showingAd = false;
      unawaited(loadInterstitial());
      notifyListeners();
      return false;
    }
  }

  /// Shows an app-open ad on a genuine return to the app. Same rule as above: an
  /// ad that is not already loaded is skipped, never shown late.
  Future<bool> showAppOpenIfAllowed({
    required Duration timeInBackground,
  }) async {
    if (!_initialized || _showingAd || !_appOpenEnabled) return false;
    if (!AdPolicy.canShowAppOpen(
      now: DateTime.now(),
      lastShown: _lastAppOpen,
      lastFullScreenClosed: _lastFullScreenClosed,
      timeInBackground: timeInBackground,
    )) {
      return false;
    }
    final ad = _appOpen;
    if (ad == null) {
      unawaited(loadAppOpen());
      return false;
    }

    _appOpen = null;
    _showingAd = true;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingAd = false;
        _lastAppOpen = DateTime.now();
        _lastFullScreenClosed = _lastAppOpen;
        unawaited(loadAppOpen());
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _showingAd = false;
        unawaited(loadAppOpen());
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
    );
    try {
      await ad.show();
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _showingAd = false;
          unawaited(loadAppOpen());
          notifyListeners();
        },
      );
      return true;
    } catch (_) {
      _showingAd = false;
      unawaited(loadAppOpen());
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
    _appOpen?.dispose();
    super.dispose();
  }
}
