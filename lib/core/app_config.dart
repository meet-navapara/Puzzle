/// Environment-specific configuration for PetalGrid.
///
/// ## Release checklist (store submission)
/// 1. Set [firebaseEnabled] true after adding google-services / Firebase options.
/// 2. Set [adsUseTestIds] false and paste real AdMob app + unit IDs.
/// 3. Host real [privacyPolicyUrl], [termsUrl], [supportUrl].
/// 4. Publish a GDPR message in AdMob → Privacy & messaging (the app shows it).
/// 5. Confirm Families / Kids category policy if targeting children.
///
/// `dart run tool/release_check.dart` verifies these before you build.
class AppConfig {
  AppConfig._();

  static const String appName = 'PetalGrid';
  static const String appTagline = 'Grow your garden one block at a time';
  static const String packageIdAndroid = 'com.petalgrid.game';
  static const String packageIdIos = 'com.petalgrid.game';
  static const int saveSchemaVersion = 2;

  /// Set true only after Firebase options files are installed.
  static const bool firebaseEnabled = true;

  /// Web OAuth client ID from `google-services.json` (`client_type` 3).
  /// Required by google_sign_in so Firebase Auth receives an ID token.
  static const String googleWebClientId =
      '712821429659-c14u3hsv62grq200i9vdofn087uau7jj.apps.googleusercontent.com';

  /// Set true to initialize the Mobile Ads SDK.
  static const bool adsEnabled = true;

  /// When true, uses Google's official test ad unit IDs (safe for development).
  /// Flip to false and fill production IDs below before store release.
  static const bool adsUseTestIds = false;

  /// Product policy: require internet reachability to enter play modes.
  static const bool requireInternetForPlay = true;

  static const Duration connectivityTimeout = Duration(seconds: 8);
  static const Duration connectivityCheckInterval = Duration(seconds: 12);
  static const String reachabilityUrl = 'https://www.gstatic.com/generate_204';

  // --- Test AdMob IDs (Google official) ---
  static const String _testAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String _testIosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testAppOpenAndroid =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIos =
      'ca-app-pub-3940256099942544/5574069941';

  // --- Production placeholders (owner must replace) ---
  static const String _prodAndroidAppId =
      'ca-app-pub-1959480289882936~8672528981';
  static const String _prodIosAppId = 'ca-app-pub-1959480289882936~8672528981';
  static const String _prodRewardedAndroid =
      'ca-app-pub-1959480289882936/1679745226';
  static const String _prodRewardedIos =
      'ca-app-pub-1959480289882936/1679745226';
  static const String _prodInterstitialAndroid =
      'ca-app-pub-1959480289882936/9407026158';
  static const String _prodInterstitialIos =
      'ca-app-pub-1959480289882936/9407026158';
  static const String _prodAppOpenAndroid = '';
  static const String _prodAppOpenIos = '';

  static String get androidAppId =>
      adsUseTestIds ? _testAndroidAppId : _prodAndroidAppId;
  static String get iosAppId => adsUseTestIds ? _testIosAppId : _prodIosAppId;

  static String get rewardedAdUnitAndroid =>
      adsUseTestIds ? _testRewardedAndroid : _prodRewardedAndroid;
  static String get rewardedAdUnitIos =>
      adsUseTestIds ? _testRewardedIos : _prodRewardedIos;

  static String get interstitialAdUnitAndroid =>
      adsUseTestIds ? _testInterstitialAndroid : _prodInterstitialAndroid;
  static String get interstitialAdUnitIos =>
      adsUseTestIds ? _testInterstitialIos : _prodInterstitialIos;

  static String get appOpenAdUnitAndroid =>
      adsUseTestIds ? _testAppOpenAndroid : _prodAppOpenAndroid;
  static String get appOpenAdUnitIos =>
      adsUseTestIds ? _testAppOpenIos : _prodAppOpenIos;

  /// Minimum gap between interstitials, so ads never follow every level.
  static const int interstitialMinIntervalSeconds = 120;

  /// New players clear this many levels before seeing any interstitial.
  static const int interstitialFirstAfterLevels = 5;
  static const int appOpenMinIntervalSeconds = 240;

  /// App-open ads need a real return to the app, not a quick app switch.
  static const int appOpenMinBackgroundSeconds = 30;

  /// No app-open ad this soon after another full-screen ad closes.
  static const int appOpenAfterAdCooldownSeconds = 60;

  /// Your own phones: they get test ads even in the real app, so testing never
  /// counts as invalid clicks on your account. Run the real-ads build once, then
  /// `adb logcat | grep setTestDeviceIds` prints the ID to paste here.
  static const List<String> ownerTestDeviceIds = <String>[
    '876F1F64D4A835BDCF0CBEA8FDC6C8F8', // Pixel 8a
  ];

  /// Hosted on Firebase Hosting (petalgrid-e7287).
  static const String privacyPolicyUrl =
      'https://petalgrid-e7287.web.app/privacy.html';
  static const String supportUrl =
      'https://petalgrid-e7287.web.app/support.html';
  static const String termsUrl = 'https://petalgrid-e7287.web.app/terms.html';

  /// Play Console → App content → Account deletion URL.
  static const String accountDeletionUrl =
      'https://petalgrid-e7287.web.app/delete-account.html';
  static const String supportEmail = 'navaparameetdev@gmail.com';

  /// Bloom Charge: cells cleared needed for one charge; max stored charges.
  static const int bloomChargePerClearCells = 12;
  static const int bloomMaxCharges = 3;
  static const int bloomRescueCost = 1;

  /// Petal cost to buy one bloom charge in-run.
  static const int bloomChargePetalCost = 10;
}
