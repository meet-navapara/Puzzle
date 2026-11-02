import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../campaign/campaign_catalog.dart';
import '../campaign/level_models.dart';
import '../campaign/section_starter.dart';
import '../core/app_config.dart';
import '../game/game_engine.dart';
import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_save_service.dart';
import '../services/connectivity_service.dart';
import '../services/haptics_service.dart';
import '../services/local_save_service.dart';

enum AppScreen {
  splash,
  welcome,
  connectionRequired,
  mainMenu,
  classic,
  worldMap,
  levelSelect,
  gameplay,
  settings,
  profile,
  daily,
  privacy,
  campaignVictory,
}

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  AppState({
    LocalSaveService? localSave,
    AuthService? auth,
    CloudSaveService? cloud,
    ConnectivityService? connectivity,
    AdsService? ads,
    AudioService? audio,
    HapticsService? haptics,
  }) : localSave = localSave ?? LocalSaveService(),
       auth = auth ?? AuthService(),
       cloud = cloud ?? CloudSaveService(),
       connectivity = connectivity ?? ConnectivityService(),
       ads = ads ?? AdsService(),
       audio = audio ?? AudioService(),
       haptics = haptics ?? HapticsService();

  final LocalSaveService localSave;
  final AuthService auth;
  final CloudSaveService cloud;
  final ConnectivityService connectivity;
  final AdsService ads;
  final AudioService audio;
  final HapticsService haptics;

  final GameEngine engine = GameEngine();

  AppScreen screen = AppScreen.splash;
  AppScreen? previousScreen;
  AppScreen? _screenBeforeConnection;
  LocalSaveSnapshot? save;
  bool ready = false;
  String? statusMessage;
  int selectedWorld = 0;
  int? selectedLevelId;
  int campaignSectionIndex = 0;
  bool bloomPruneMode = false;
  bool puzzleActive = false;
  bool dailyClaimedToday = false;
  bool advancingSection = false;
  bool showingSectionIntro = false;

  /// When set, the next start of this campaign level replays its lesson.
  int? replayTutorialLevelId;

  /// Bumps whenever a level boots so the lesson can restart on the same seed.
  int tutorialSession = 0;

  bool replayClassicTour = false;
  bool replayDailyTour = false;

  // Campaign runtime objective tracking beyond score.
  int sectionLinesCleared = 0;
  int sectionMaxCombo = 0;
  int levelRunScore = 0;

  /// Rated moves across finished sections of this level (for stars).
  int levelRunMoves = 0;

  /// Stars earned by the run that just finished; null until a level ends.
  int? lastRunStars;

  /// A rewarded rescue is loading or on screen.
  bool rescueInProgress = false;

  Future<void>? _persistChain;
  VoidCallback? _authListener;
  Timer? _cloudPushTimer;
  DateTime? _backgroundedAt;

  /// Coalesces cloud writes; a move-by-move push would spend Firestore quota.
  static const Duration _cloudPushDelay = Duration(seconds: 20);

  bool get hasResumableGame {
    final g = save?.activeGame;
    if (g == null) return false;
    if (g.phase == GamePhase.levelComplete) {
      // Between sections of a level there is still something to come back to.
      final level = CampaignCatalog.byId[g.levelId];
      return level != null && g.sectionIndex + 1 < level.sections.length;
    }
    return g.phase == GamePhase.playing ||
        g.phase == GamePhase.paused ||
        g.phase == GamePhase.connectionPaused;
  }

  DateTime? get lastDailyClaim => save?.lastDailyClaimUtc;

  Future<void> bootstrap() async {
    WidgetsBinding.instance.addObserver(this);
    save = await localSave.loadOrCreate();
    _refreshDailyClaimFlag();
    _applySettings();
    try {
      await auth.initialize();
    } catch (e) {
      debugPrint('auth.initialize failed: $e');
    }
    _authListener = () => notifyListeners();
    auth.addListener(_authListener!);
    try {
      await connectivity.start().timeout(
        AppConfig.connectivityTimeout + const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('connectivity.start failed/timed out: $e');
    }
    connectivity.addListener(_onConnectivity);
    unawaited(audio.warmUp());
    ready = true;

    // Login is always the first screen for a new player, even when offline:
    // its buttons explain the connection requirement if it applies.
    if (!_shouldSkipWelcome()) {
      screen = AppScreen.welcome;
    } else if (AppConfig.requireInternetForPlay && !connectivity.isOnline) {
      _screenBeforeConnection = AppScreen.mainMenu;
      screen = AppScreen.connectionRequired;
    } else {
      screen = AppScreen.mainMenu;
    }
    notifyListeners();
    unawaited(_syncFromCloud());

    // Init ads after first UI frame so WebView/JavascriptEngine can attach.
    if (AppConfig.adsEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(ads.initialize());
      });
    }
  }

  bool _shouldSkipWelcome() {
    if (auth.isAuthenticated) return true;
    return save?.settings.welcomeSeen ?? false;
  }

  /// A signed-in player may have progressed on another device since last time.
  Future<void> _syncFromCloud() async {
    final uid = auth.uid;
    if (uid == null || save == null || !connectivity.isOnline) return;
    final remote = await cloud.fetch(uid);
    if (remote == null || save == null || auth.uid != uid) return;
    save = cloud.resolveConflict(
      local: save!,
      cloud: remote,
      policy: CloudMergePolicy.mergeProgress,
    );
    _refreshDailyClaimFlag();
    await persist();
    notifyListeners();
  }

  void _refreshDailyClaimFlag() {
    final claim = save?.lastDailyClaimUtc;
    if (claim == null) {
      dailyClaimedToday = false;
      return;
    }
    final now = DateTime.now().toUtc();
    dailyClaimedToday =
        claim.year == now.year &&
        claim.month == now.month &&
        claim.day == now.day;
  }

  void _applySettings() {
    final s = save!.settings;
    audio.applySettings(
      sound: s.soundEnabled,
      music: s.musicEnabled,
      sVol: s.soundVolume,
      mVol: s.musicVolume,
    );
    haptics.enabled = s.hapticsEnabled;
  }

  void _onConnectivity() {
    if (!AppConfig.requireInternetForPlay) return;
    if (!connectivity.isOnline) {
      if (puzzleActive &&
          engine.hasStarted &&
          engine.state.phase == GamePhase.playing) {
        engine.connectionPause();
        statusMessage = 'Connection lost — garden paused';
        notifyListeners();
      } else if (screen != AppScreen.connectionRequired &&
          screen != AppScreen.splash &&
          screen != AppScreen.welcome &&
          screen != AppScreen.privacy) {
        _screenBeforeConnection = screen;
        screen = AppScreen.connectionRequired;
        notifyListeners();
      }
    } else {
      if (engine.hasStarted &&
          engine.state.phase == GamePhase.connectionPaused) {
        engine.resume();
        statusMessage = 'Connection restored';
      }
      if (screen == AppScreen.connectionRequired) {
        screen = _screenBeforeConnection ?? AppScreen.mainMenu;
        _screenBeforeConnection = null;
      }
      notifyListeners();
    }
  }

  Future<void> persist({
    GameState? activeGame,
    bool clearActive = false,
    DateTime? lastDailyClaimUtc,
  }) {
    Future<void> job() async {
      if (save == null) return;
      save = save!.copyWith(
        activeGame: clearActive ? null : (activeGame ?? save!.activeGame),
        clearActiveGame: clearActive,
        lastDailyClaimUtc: lastDailyClaimUtc,
        linkedUid: auth.uid ?? save!.linkedUid,
        updatedAt: DateTime.now().toUtc(),
      );
      await localSave.save(save!);
      _scheduleCloudPush();
    }

    _persistChain = (_persistChain ?? Future.value()).then((_) => job());
    return _persistChain!;
  }

  void _scheduleCloudPush() {
    if (auth.uid == null) return;
    _cloudPushTimer?.cancel();
    _cloudPushTimer = Timer(_cloudPushDelay, _pushToCloudNow);
  }

  void _pushToCloudNow() {
    _cloudPushTimer?.cancel();
    _cloudPushTimer = null;
    final uid = auth.uid;
    if (uid != null && save != null && connectivity.isOnline) {
      unawaited(cloud.push(uid, save!));
    }
  }

  void go(AppScreen next) {
    if (next == screen) return;
    previousScreen = screen;
    screen = next;
    // A message belongs to the screen that raised it.
    statusMessage = null;
    notifyListeners();
  }

  /// Android/system back handling. Returns true if the app may exit.
  bool handleSystemBack() {
    switch (screen) {
      case AppScreen.splash:
        return true;
      case AppScreen.welcome:
      case AppScreen.mainMenu:
        return true;
      case AppScreen.gameplay:
      case AppScreen.classic:
        final phase = engine.state.phase;
        if (phase == GamePhase.playing) {
          pauseGame();
          return false;
        }
        if (phase == GamePhase.paused) {
          resumeGame();
          return false;
        }
        if (phase == GamePhase.gameOver || phase == GamePhase.levelComplete) {
          exitToMenu();
          return false;
        }
        return false;
      case AppScreen.privacy:
        go(
          previousScreen == AppScreen.welcome
              ? AppScreen.welcome
              : (previousScreen == AppScreen.settings
                    ? AppScreen.settings
                    : AppScreen.mainMenu),
        );
        return false;
      case AppScreen.settings:
      case AppScreen.profile:
      case AppScreen.daily:
      case AppScreen.worldMap:
      case AppScreen.campaignVictory:
        go(AppScreen.mainMenu);
        return false;
      case AppScreen.levelSelect:
        go(AppScreen.worldMap);
        return false;
      case AppScreen.connectionRequired:
        return false;
    }
  }

  Future<void> continueAsGuest() async {
    if (AppConfig.requireInternetForPlay && !connectivity.isOnline) {
      _screenBeforeConnection = AppScreen.welcome;
      screen = AppScreen.connectionRequired;
      notifyListeners();
      return;
    }
    auth.clearError();
    if (save != null && !save!.settings.welcomeSeen) {
      save = save!.copyWith(
        settings: save!.settings.copyWith(welcomeSeen: true),
      );
      unawaited(persist());
    }
    screen = AppScreen.mainMenu;
    notifyListeners();
  }

  Future<void> signInGoogle() async {
    notifyListeners(); // pick up AuthStatus.signingIn immediately
    final ok = await auth.signInWithGoogle();
    if (!ok) {
      notifyListeners();
      return;
    }
    final uid = auth.uid!;
    final remote = await cloud.fetch(uid);
    if (remote != null && save != null) {
      save = cloud.resolveConflict(
        local: save!,
        cloud: remote,
        policy: CloudMergePolicy.mergeProgress,
      );
      save = save!.copyWith(linkedUid: uid, updatedAt: DateTime.now().toUtc());
    } else if (save != null) {
      save = save!.copyWith(linkedUid: uid, updatedAt: DateTime.now().toUtc());
    }
    _refreshDailyClaimFlag();
    if (save != null && !save!.settings.welcomeSeen) {
      save = save!.copyWith(
        settings: save!.settings.copyWith(welcomeSeen: true),
      );
    }
    await persist();
    _pushToCloudNow();
    screen = AppScreen.mainMenu;
    notifyListeners();
  }

  Future<void> signOutLocal() async {
    _pushToCloudNow();
    await auth.signOut();
    if (save != null) {
      save = save!.copyWith(clearLinkedUid: true);
      await persist();
    }
    screen = AppScreen.welcome;
    notifyListeners();
  }

  void startClassic() {
    if (!_gateOnline()) return;
    final best = save?.classicBest ?? 0;
    engine.startClassic(bestScore: best);
    puzzleActive = true;
    bloomPruneMode = false;
    showingSectionIntro = false;
    advancingSection = false;
    levelRunScore = 0;
    levelRunMoves = 0;
    sectionLinesCleared = 0;
    sectionMaxCombo = 0;
    statusMessage = null;
    tutorialSession++;
    screen = AppScreen.gameplay;
    unawaited(persist(activeGame: engine.state));
    notifyListeners();
  }

  /// Resume a mid-run save from the main menu.
  bool resumeActiveGame() {
    final g = save?.activeGame;
    if (g == null) return false;
    if (!_gateOnline()) return false;
    engine.restore(
      g.copyWith(
        phase: g.phase == GamePhase.connectionPaused
            ? GamePhase.paused
            : (g.phase == GamePhase.playing ? GamePhase.paused : g.phase),
      ),
    );
    sectionLinesCleared = g.linesClearedTotal;
    sectionMaxCombo = g.maxCombo;
    levelRunScore = g.levelRunScore;
    levelRunMoves = g.levelRunMoves;
    selectedLevelId = g.levelId;
    campaignSectionIndex = g.sectionIndex;
    puzzleActive = true;
    bloomPruneMode = false;
    showingSectionIntro = false;
    advancingSection = false;
    statusMessage = 'Garden resumed — tap Resume to continue';
    screen = AppScreen.gameplay;
    notifyListeners();
    return true;
  }

  void openWorldMap() {
    if (!_gateOnline()) return;
    screen = AppScreen.worldMap;
    notifyListeners();
  }

  /// Jumps straight into the next uncleared level.
  void playNextLevel() {
    final s = save;
    if (s == null) return;
    startLevel(s.campaign.nextLevelId);
  }

  void selectWorld(int index) {
    selectedWorld = index;
    screen = AppScreen.levelSelect;
    notifyListeners();
  }

  /// True when campaign level 1 or 2 should open the interactive lesson.
  bool shouldGuideLevel(int? levelId) {
    if (levelId != 1 && levelId != 2) return false;
    if (!engine.hasStarted || engine.state.mode != GameMode.campaign) {
      return false;
    }
    if (engine.state.levelId != levelId) return false;
    if (replayTutorialLevelId == levelId) return true;
    final settings = save?.settings;
    if (settings == null || save == null) return false;
    if (levelId == 1 && settings.tutorialLevel1Done) return false;
    if (levelId == 2 && settings.tutorialLevel2Done) return false;
    if (save!.campaign.progressOf(levelId!).completed) return false;
    return true;
  }

  void completeTutorial(int levelId) {
    replayTutorialLevelId = null;
    final settings = save?.settings;
    if (settings == null) return;
    if (levelId == 1 && !settings.tutorialLevel1Done) {
      updateSettings(settings.copyWith(tutorialLevel1Done: true));
    } else if (levelId == 2 && !settings.tutorialLevel2Done) {
      updateSettings(settings.copyWith(tutorialLevel2Done: true));
    } else {
      notifyListeners();
    }
  }

  bool get guideHomeClassic {
    if (replayClassicTour) return false;
    final settings = save?.settings;
    if (settings == null) return false;
    if (settings.tutorialClassicDone) return false;
    if ((save?.classicBest ?? 0) > 0) return false;
    return true;
  }

  bool get guideHomeDaily {
    if (replayDailyTour) return false;
    final settings = save?.settings;
    if (settings == null || save == null) return false;
    if (settings.tutorialDailyDone) return false;
    if (save!.lastDailyClaimUtc != null) return false;
    if (!settings.tutorialClassicDone && (save!.classicBest == 0)) {
      return false;
    }
    return true;
  }

  bool get shouldGuideClassic {
    if (!engine.hasStarted || engine.state.mode != GameMode.classic) {
      return false;
    }
    if (replayClassicTour) return true;
    final settings = save?.settings;
    if (settings == null) return false;
    if (settings.tutorialClassicDone) return false;
    if ((save?.classicBest ?? 0) > 0 && !replayClassicTour) return false;
    return true;
  }

  bool get shouldGuideDaily {
    if (replayDailyTour) return true;
    final settings = save?.settings;
    if (settings == null) return false;
    return !settings.tutorialDailyDone;
  }

  void completeClassicTour() {
    replayClassicTour = false;
    final settings = save?.settings;
    if (settings == null || settings.tutorialClassicDone) {
      notifyListeners();
      return;
    }
    updateSettings(settings.copyWith(tutorialClassicDone: true));
  }

  void completeDailyTour() {
    replayDailyTour = false;
    final settings = save?.settings;
    if (settings == null || settings.tutorialDailyDone) {
      notifyListeners();
      return;
    }
    updateSettings(settings.copyWith(tutorialDailyDone: true));
  }

  void replayClassicLesson() {
    replayClassicTour = true;
    startClassic();
  }

  void replayDailyLesson() {
    replayDailyTour = true;
    screen = AppScreen.daily;
    notifyListeners();
  }

  void replayTutorial(int levelId) {
    if (levelId != 1 && levelId != 2) return;
    final progress = save?.campaign.progressOf(levelId);
    if (progress == null || !progress.unlocked) return;
    replayTutorialLevelId = levelId;
    startLevel(levelId);
  }

  void startLevel(int levelId, {int sectionIndex = 0}) {
    if (replayTutorialLevelId != levelId) replayTutorialLevelId = null;
    if (!_gateOnline()) return;
    final progress = save!.campaign.progressOf(levelId);
    if (!progress.unlocked) return;
    final level = CampaignCatalog.level(levelId);
    if (sectionIndex < 0 || sectionIndex >= level.sections.length) return;
    selectedLevelId = levelId;
    selectedWorld = level.worldIndex;
    campaignSectionIndex = sectionIndex;
    if (sectionIndex == 0) {
      levelRunScore = 0;
      levelRunMoves = 0;
    }
    lastRunStars = null;
    tutorialSession++;
    _bootSection(level, sectionIndex);
  }

  void _bootSection(LevelDefinition level, int sectionIndex) {
    final section = level.sections[sectionIndex];
    engine.startSection(
      level,
      sectionIndex,
      bestScore: save!.campaign.progressOf(level.id).bestScore,
      levelRunScore: levelRunScore,
      levelRunMoves: levelRunMoves,
    );
    sectionLinesCleared = 0;
    sectionMaxCombo = 0;
    puzzleActive = true;
    bloomPruneMode = false;
    advancingSection = false;
    showingSectionIntro = section.introText.trim().isNotEmpty;
    statusMessage = null;
    screen = AppScreen.gameplay;
    unawaited(persist(activeGame: engine.state));
    notifyListeners();
  }

  void dismissSectionIntro() {
    showingSectionIntro = false;
    notifyListeners();
  }

  bool placePiece(String uid, int row, int col) {
    final before = engine.state;
    final result = engine.place(uid, row, col);
    if (result == null) return false;
    unawaited(audio.playPlace());
    unawaited(haptics.light());
    final event = result.lastEvent;
    if (event != null && event.clear.hasClears) {
      sectionLinesCleared += event.clear.lineCount;
      if (result.maxCombo > sectionMaxCombo) {
        sectionMaxCombo = result.maxCombo;
      }
      unawaited(audio.playClear());
      unawaited(haptics.success());
    } else if (result.maxCombo > sectionMaxCombo) {
      sectionMaxCombo = result.maxCombo;
    }
    if (result.mode == GameMode.classic &&
        result.score > (save?.classicBest ?? 0)) {
      save = save!.copyWith(classicBest: result.score, activeGame: result);
    }
    unawaited(persist(activeGame: engine.state));
    notifyListeners();

    if (before.phase != engine.state.phase) {
      if (engine.state.phase == GamePhase.levelComplete) {
        _onSectionComplete();
      } else if (engine.state.phase == GamePhase.gameOver) {
        unawaited(audio.playGameOver());
      }
    }
    return true;
  }

  void _onSectionComplete() {
    final st = engine.state;
    if (st.levelId == null) return;
    final level = CampaignCatalog.level(st.levelId!);
    levelRunScore += st.score;
    if (level.sections[st.sectionIndex].objective !=
        LevelObjective.surviveMoves) {
      levelRunMoves += st.moveCount;
    }
    // Keep cumulative on engine state for save/resume.
    engine.restore(
      st.copyWith(levelRunScore: levelRunScore, levelRunMoves: levelRunMoves),
    );

    final nextSection = st.sectionIndex + 1;
    if (nextSection < level.sections.length) {
      statusMessage = 'Section clear';
      unawaited(persist(activeGame: engine.state));
      notifyListeners();
      return;
    }
    final reward = save!.campaign.completeLevel(
      levelId: st.levelId!,
      score: levelRunScore,
      sectionsDone: level.sections.length,
      moves: levelRunMoves,
    );
    lastRunStars = level.starsForMoves(levelRunMoves);
    statusMessage = reward > 0 ? '+$reward petals' : 'Level complete';
    unawaited(persist(clearActive: true));
    _pushToCloudNow();
    notifyListeners();
  }

  /// The level offered after [levelId], or null after the finale.
  int? levelAfter(int levelId) =>
      levelId < CampaignCatalog.totalLevels ? levelId + 1 : null;

  void continueNextSection() {
    final st = engine.state;
    if (advancingSection || st.levelId == null) return;
    final level = CampaignCatalog.level(st.levelId!);
    final next = st.sectionIndex + 1;
    if (next >= level.sections.length) return;
    advancingSection = true;
    campaignSectionIndex = next;
    statusMessage = null;
    _bootSection(level, next);
  }

  /// Leaves a finished level. Any interstitial plays here, in the natural break
  /// after the player tapped, and is awaited so it can't cover the next puzzle.
  Future<void> leaveFinishedLevel({bool playNext = false}) async {
    final st = engine.state;
    if (advancingSection || st.levelId == null) return;
    advancingSection = true;
    puzzleActive = false;
    notifyListeners();
    final finishedId = st.levelId!;
    await ads.showLevelClearInterstitial(
      levelsCleared: save!.campaign.completedCount,
    );
    advancingSection = false;
    statusMessage = null;
    final nextId = levelAfter(finishedId);
    if (nextId == null) {
      save!.campaign.markVictorySeen();
      screen = AppScreen.campaignVictory;
      unawaited(persist(clearActive: true));
      notifyListeners();
      return;
    }
    if (playNext) {
      startLevel(nextId);
      return;
    }
    selectedWorld = CampaignCatalog.worldForLevel(finishedId).index;
    screen = AppScreen.levelSelect;
    unawaited(persist(clearActive: true));
    notifyListeners();
  }

  bool toggleBloomMode() {
    if (!engine.state.bloomEnabled) return false;
    if (!engine.state.bloom.canPrune) return false;
    bloomPruneMode = !bloomPruneMode;
    // Backing out of a revive with nothing playable ends the run again.
    if (!bloomPruneMode &&
        !engine.state.board.anyPieceFits(engine.state.tray)) {
      engine.markGameOver();
    }
    notifyListeners();
    return bloomPruneMode;
  }

  /// Reopens a stuck board so a saved Bloom charge can free a cell.
  void reviveWithBloom() {
    if (engine.reviveForPrune() == null) return;
    bloomPruneMode = true;
    statusMessage = null;
    notifyListeners();
  }

  /// Spend petals for one bloom charge (economy sink).
  bool buyBloomCharge() {
    if (save == null) return false;
    if (!engine.state.bloomEnabled) return false;
    if (engine.state.phase != GamePhase.playing) return false;
    const cost = AppConfig.bloomChargePetalCost;
    if (save!.campaign.petals < cost) {
      statusMessage = 'Need $cost petals for a bloom charge';
      notifyListeners();
      return false;
    }
    if (engine.state.bloom.charges >= engine.state.bloom.maxCharges) {
      statusMessage = 'Bloom charges are full';
      notifyListeners();
      return false;
    }
    save!.campaign.petals -= cost;
    final bloom = engine.state.bloom.addClearedCells(
      engine.state.bloom.progressNeeded,
    );
    engine.restore(engine.state.copyWith(bloom: bloom));
    statusMessage = '-$cost petals · +1 bloom';
    unawaited(persist(activeGame: engine.state));
    notifyListeners();
    return true;
  }

  bool pruneAt(int row, int col) {
    if (!bloomPruneMode) return false;
    final result = engine.bloomPrune(row, col);
    if (result == null) return false;
    bloomPruneMode = false;
    unawaited(audio.playBloom());
    unawaited(haptics.medium());
    if (engine.state.phase == GamePhase.levelComplete) {
      _onSectionComplete();
    }
    unawaited(persist(activeGame: engine.state));
    notifyListeners();
    return true;
  }

  void pauseGame() {
    engine.pause();
    unawaited(persist(activeGame: engine.state));
    notifyListeners();
  }

  void resumeGame() {
    engine.resume();
    statusMessage = null;
    notifyListeners();
  }

  void restartGame() {
    final st = engine.state;
    if (st.mode == GameMode.classic) {
      startClassic();
    } else if (st.levelId != null) {
      levelRunScore = 0;
      startLevel(st.levelId!, sectionIndex: 0);
    }
  }

  Future<bool> tryRescue() async {
    if (rescueInProgress) return false;
    rescueInProgress = true;
    statusMessage = null;
    notifyListeners();
    final earned = await ads.showRewarded(placement: 'game_over_rescue');
    rescueInProgress = false;
    if (!earned) {
      statusMessage = 'No ad available or not finished. Try again in a moment.';
      notifyListeners();
      return false;
    }
    final ok = engine.applyRescueTray();
    if (ok == null) {
      statusMessage = 'Rescue unavailable';
      notifyListeners();
      return false;
    }
    statusMessage = 'Rescue tray granted';
    unawaited(persist(activeGame: engine.state));
    notifyListeners();
    return true;
  }

  Future<bool> claimDailyBonus() async {
    _refreshDailyClaimFlag();
    if (dailyClaimedToday) {
      statusMessage = 'Daily bonus already claimed';
      notifyListeners();
      return false;
    }
    final earned = await ads.showRewarded(placement: 'daily_bonus');
    if (!earned) {
      statusMessage = 'Watch the full ad to claim petals';
      notifyListeners();
      return false;
    }
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    save!.campaign.petals += 15;
    dailyClaimedToday = true;
    statusMessage = '+15 petals';
    await persist(lastDailyClaimUtc: today);
    notifyListeners();
    return true;
  }

  void updateSettings(PlayerSettings settings) {
    save = save!.copyWith(settings: settings);
    _applySettings();
    unawaited(persist());
    notifyListeners();
  }

  void exitToMenu() {
    puzzleActive = false;
    bloomPruneMode = false;
    showingSectionIntro = false;
    advancingSection = false;
    statusMessage = null;
    // A paused run stays resumable from Continue Garden; a finished one doesn't.
    final phase = engine.state.phase;
    final finished =
        phase == GamePhase.gameOver ||
        (phase == GamePhase.levelComplete &&
            !(engine.state.levelId != null &&
                engine.state.sectionIndex + 1 <
                    CampaignCatalog.level(engine.state.levelId!)
                        .sections
                        .length));
    if (finished) {
      unawaited(persist(clearActive: true));
    } else {
      unawaited(persist(activeGame: engine.state));
    }
    screen = AppScreen.mainMenu;
    notifyListeners();
  }

  Future<void> retryConnection() async {
    final ok = await connectivity.checkNow();
    if (!ok) {
      notifyListeners();
      return;
    }
    screen = _screenBeforeConnection ?? AppScreen.mainMenu;
    _screenBeforeConnection = null;
    notifyListeners();
  }

  bool _gateOnline() {
    if (AppConfig.requireInternetForPlay && !connectivity.isOnline) {
      _screenBeforeConnection = screen;
      screen = AppScreen.connectionRequired;
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Signed-in: re-auth → wipe Firestore (while authed) → delete Auth → clear local.
  /// Guest: clears local device data only.
  Future<bool> deleteAccountAndData() async {
    final uid = auth.uid;
    // A delayed push firing after deletion would recreate the player's data.
    _cloudPushTimer?.cancel();
    _cloudPushTimer = null;
    if (uid != null) {
      final reauthed = await auth.reauthenticateWithGoogle();
      if (!reauthed) {
        statusMessage =
            auth.errorMessage ??
            'Could not verify Google Sign-In. Account was not deleted.';
        notifyListeners();
        return false;
      }
      final cloudOk = await cloud.deleteCloudData(uid);
      final authOk = await auth.deleteAccount(reauthenticateFirst: false);
      if (!authOk) {
        statusMessage = auth.errorMessage ?? 'Cloud data may be gone, but Auth deletion failed. Retry or email support.';
        notifyListeners();
        return false;
      }
      statusMessage = cloudOk
          ? 'Account and cloud data deleted.'
          : 'Account deleted. If cloud data remains, email support.';
    } else {
      statusMessage = 'Local data on this device cleared.';
    }
    await localSave.clear();
    save = await localSave.loadOrCreate();
    dailyClaimedToday = false;
    puzzleActive = false;
    bloomPruneMode = false;
    screen = AppScreen.welcome;
    notifyListeners();
    return true;
  }

  /// Guest / local wipe without touching Firebase Auth.
  Future<void> clearLocalDataOnly() async {
    puzzleActive = false;
    bloomPruneMode = false;
    dailyClaimedToday = false;
    await localSave.clear();
    save = await localSave.loadOrCreate();
    statusMessage = 'Local data on this device cleared.';
    screen = AppScreen.welcome;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only hard-pause on backgrounded — not notification shade (inactive).
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      _pushToCloudNow();
      unawaited(audio.pauseMusic());
      if (puzzleActive && engine.state.phase == GamePhase.playing) {
        engine.pause();
        unawaited(persist(activeGame: engine.state));
        notifyListeners();
      }
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(audio.resumeMusic());
      unawaited(connectivity.checkNow());
      _onReturnedToApp();
    }
  }

  void _onReturnedToApp() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    // Consent may have been unreachable at launch. Retry only here, away from
    // play, so its form can never interrupt a puzzle.
    if (AppConfig.adsEnabled && !ads.isReady && !puzzleActive) {
      unawaited(ads.initialize());
    }
    if (backgroundedAt == null || puzzleActive) return;
    // Only quiet menu screens: not login, sign-in overlays, or a live board.
    final quietScreen =
        screen == AppScreen.mainMenu ||
        screen == AppScreen.worldMap ||
        screen == AppScreen.levelSelect;
    if (!quietScreen || auth.status == AuthStatus.signingIn) return;
    unawaited(
      ads.showAppOpenIfAllowed(
        timeInBackground: DateTime.now().difference(backgroundedAt),
      ),
    );
  }

  @override
  void dispose() {
    _cloudPushTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    connectivity.removeListener(_onConnectivity);
    if (_authListener != null) {
      auth.removeListener(_authListener!);
    }
    connectivity.dispose();
    ads.dispose();
    auth.dispose();
    audio.dispose();
    super.dispose();
  }
}

const uuid = Uuid();

/// Exit the process when system back is allowed on root screens.
Future<void> maybeExitApp() => SystemNavigator.pop();
