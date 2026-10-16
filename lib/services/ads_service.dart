import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/app_config.dart';

/// AdMob wrapper. Grants rewards only after SDK reward callback.
class AdsService extends ChangeNotifier {
  bool _initialized = false;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;

  DateTime? _lastInterstitial;
  DateTime? _lastAppOpen;
  bool _rewardInFlight = false;
  bool _showingAd = false;

  bool get isReady => _initialized;
  bool get isShowingAd => _showingAd;
  bool get rewardedReady => _rewarded != null;

  String get _rewardedId => Platform.isIOS
      ? AppConfig.rewardedAdUnitIos
      : AppConfig.rewardedAdUnitAndroid;
  String get _interstitialId => Platform.isIOS
      ? AppConfig.interstitialAdUnitIos
      : AppConfig.interstitialAdUnitAndroid;
  String get _appOpenId => Platform.isIOS
      ? AppConfig.appOpenAdUnitIos
      : AppConfig.appOpenAdUnitAndroid;

  Future<void> initialize() async {
    if (!AppConfig.adsEnabled) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      loadRewarded();
      loadInterstitial();
      loadAppOpen();
      notifyListeners();
    } catch (e) {
      debugPrint('Ads init failed: $e');
      _initialized = false;
      notifyListeners();
    }
  }

  void loadRewarded() {
    if (!_initialized) return;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _rewarded = null;
          debugPrint('Rewarded load fail: $err');
          notifyListeners();
        },
      ),
    );
  }

  void loadInterstitial() {
    if (!_initialized) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void loadAppOpen() {
    if (!_initialized) return;
    AppOpenAd.load(
      adUnitId: _appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpen = ad,
        onAdFailedToLoad: (_) => _appOpen = null,
      ),
    );
  }

  void _clearRewardFlags({required bool reload}) {
    _showingAd = false;
    _rewardInFlight = false;
    if (reload) loadRewarded();
    notifyListeners();
  }

  /// Shows rewarded ad. Returns true only if reward callback fired.
  Future<bool> showRewarded({required String placement}) async {
    if (!_initialized || _rewarded == null || _rewardInFlight || _showingAd) {
      loadRewarded();
      return false;
    }
    final ad = _rewarded!;
    _rewarded = null;
    var rewarded = false;
    _rewardInFlight = true;
    _showingAd = true;
    notifyListeners();

    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _clearRewardFlags(reload: true);
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _clearRewardFlags(reload: true);
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          rewarded = true;
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          // Soft-lock guard: callbacks never fired.
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

  Future<bool> showInterstitialIfAllowed() async {
    if (!_initialized || _interstitial == null || _showingAd) return false;
    final now = DateTime.now();
    if (_lastInterstitial != null &&
        now.difference(_lastInterstitial!).inSeconds <
            AppConfig.interstitialMinIntervalSeconds) {
      return false;
    }
    final ad = _interstitial!;
    _interstitial = null;
    _showingAd = true;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingAd = false;
        _lastInterstitial = DateTime.now();
        loadInterstitial();
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _showingAd = false;
        loadInterstitial();
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
          loadInterstitial();
          notifyListeners();
        },
      );
      return true;
    } catch (_) {
      _showingAd = false;
      loadInterstitial();
      notifyListeners();
      return false;
    }
  }

  Future<bool> showAppOpenIfAllowed({required bool puzzleActive}) async {
    if (puzzleActive || !_initialized || _appOpen == null || _showingAd) {
      return false;
    }
    final now = DateTime.now();
    if (_lastAppOpen != null &&
        now.difference(_lastAppOpen!).inSeconds <
            AppConfig.appOpenMinIntervalSeconds) {
      return false;
    }
    final ad = _appOpen!;
    _appOpen = null;
    _showingAd = true;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _showingAd = false;
        _lastAppOpen = DateTime.now();
        loadAppOpen();
        notifyListeners();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _showingAd = false;
        loadAppOpen();
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
          loadAppOpen();
          notifyListeners();
        },
      );
      return true;
    } catch (_) {
      _showingAd = false;
      loadAppOpen();
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
