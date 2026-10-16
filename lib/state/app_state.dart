import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import '../campaign/campaign_catalog.dart';
import '../campaign/level_models.dart';
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

  // Campaign runtime objective tracking beyond score.
  int sectionLinesCleared = 0;
  int sectionMaxCombo = 0;
  int levelRunScore = 0;

  Future<void>? _persistChain;
  VoidCallback? _authListener;

  bool get hasResumableGame {
    final g = save?.activeGame;
    if (g == null) return false;
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
    await auth.initialize();
    _authListener = () => notifyListeners();
    auth.addListener(_authListener!);
    await connectivity.start();
    connectivity.addListener(_onConnectivity);
    if (AppConfig.adsEnabled) {
      unawaited(ads.initialize());
    }
    unawaited(audio.warmUp());
    ready = true;

    if (AppConfig.requireInternetForPlay && !connectivity.isOnline) {
      _screenBeforeConnection = AppScreen.welcome;
      screen = AppScreen.connectionRequired;
    } else if (_shouldSkipWelcome()) {
      screen = AppScreen.mainMenu;
    } else {
      screen = AppScreen.welcome;
    }
    notifyListeners();
  }

  bool _shouldSkipWelcome() {
    final s = save;
    if (s == null) return false;
    if (s.settings.welcomeSeen) return true;
    if (s.settings.tutorialSeen) return true;
    if (s.classicBest > 0) return true;
    if (s.campaign.completedCount > 0) return true;
    return false;
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
      final uid = auth.uid;
      if (uid != null && connectivity.isOnline) {
        unawaited(cloud.push(uid, save!));
      }
    }

    _persistChain = (_persistChain ?? Future.value()).then((_) => job());
    return _persistChain!;
  }

  void go(AppScreen next) {
    if (next == screen) return;
    previousScreen = screen;
    screen = next;
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
        go(previousScreen == AppScreen.welcome
            ? AppScreen.welcome
            : (previousScreen == AppScreen.settings
                ? AppScreen.settings
                : AppScreen.mainMenu));
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
    if (save != null && !save!.settings.welcomeSeen) {
      save = save!.copyWith(
        settings: save!.settings.copyWith(welcomeSeen: true),
      );
      unawaited(persist());
    }
    screen = AppScreen.mainMenu;
    notifyListeners();
    unawaited(ads.showAppOpenIfAllowed(puzzleActive: false));
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
    screen = AppScreen.mainMenu;
    notifyListeners();
  }

  Future<void> signOutLocal() async {
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
    sectionLinesCleared = 0;
    sectionMaxCombo = 0;
    statusMessage = null;
    screen = AppScreen.gameplay;
    unawaited(persist(activeGame: engine.state));
    notifyListeners();
  }

  /// Resume a mid-run save from the main menu.
  bool resumeActiveGame() {
    final g = save?.activeGame;
    if (g == null) return false;
    if (!_gateOnline()) return false;
    engine.restore(g.copyWith(
      phase: g.phase == GamePhase.connectionPaused
          ? GamePhase.paused
          : (g.phase == GamePhase.playing ? GamePhase.paused : g.phase),
    ));
    sectionLinesCleared = g.linesClearedTotal;
    sectionMaxCombo = g.maxCombo;
    levelRunScore = g.levelRunScore;
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

  void selectWorld(int index) {
    selectedWorld = index;
    screen = AppScreen.levelSelect;
    notifyListeners();
  }

  void startLevel(int levelId, {int sectionIndex = 0}) {
    if (!_gateOnline()) return;
    final progress = save!.campaign.progressOf(levelId);
    if (!progress.unlocked) return;
    final level = CampaignCatalog.level(levelId);
    if (sectionIndex < 0 || sectionIndex >= level.sections.length) return;
    selectedLevelId = levelId;
    campaignSectionIndex = sectionIndex;
    levelRunScore = sectionIndex == 0 ? 0 : levelRunScore;
    if (sectionIndex == 0) levelRunScore = 0;
    _bootSection(level, sectionIndex);
  }

  void _bootSection(LevelDefinition level, int sectionIndex) {
    final section = level.sections[sectionIndex];
    final best = save!.campaign.progressOf(level.id).bestScore;
    engine.startCampaign(
      levelId: level.id,
      sectionIndex: sectionIndex,
      boardSize: section.boardSize,
      scoreTarget: section.scoreTarget,
      moveLimit: section.moveLimit,
      blocked: section.blockedCells,
      prefilled: section.prefilledCells,
      pool: section.shapePool,
      bestScore: best,
      levelRunScore: levelRunScore,
      winOnScoreTarget: section.objective == LevelObjective.reachScore,
      surviveOnMovesExhausted: section.objective == LevelObjective.surviveMoves,
      bloomEnabled: section.bloomEnabled,
      sectionIntro: section.introText,
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
    _checkCampaignObjectives();
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

  void _checkCampaignObjectives() {
    final st = engine.state;
    if (st.mode != GameMode.campaign || st.levelId == null) return;
    if (st.phase != GamePhase.playing) return;
    final level = CampaignCatalog.level(st.levelId!);
    final section = level.sections[st.sectionIndex];
    var done = false;
    switch (section.objective) {
      case LevelObjective.reachScore:
        done = section.scoreTarget != null && st.score >= section.scoreTarget!;
      case LevelObjective.clearLines:
        done =
            section.lineTarget != null &&
            sectionLinesCleared >= section.lineTarget!;
      case LevelObjective.surviveMoves:
        done = st.movesRemaining != null && st.movesRemaining! <= 0;
      case LevelObjective.clearBoard:
        done = st.board.filledCount == 0 && st.moveCount > 0;
      case LevelObjective.comboStreak:
        done =
            section.comboTarget != null &&
            sectionMaxCombo >= section.comboTarget!;
    }
    if (done) {
      engine.markLevelComplete();
      return;
    }

    // Timed non-survive sections: out of moves without completing → fail.
    if (st.movesRemaining != null &&
        st.movesRemaining! <= 0 &&
        section.objective != LevelObjective.surviveMoves) {
      engine.markGameOver();
    }
  }

  void _onSectionComplete() {
    final st = engine.state;
    if (st.levelId == null) return;
    final level = CampaignCatalog.level(st.levelId!);
    levelRunScore += st.score;
    // Keep cumulative on engine state for save/resume.
    engine.restore(st.copyWith(levelRunScore: levelRunScore));

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
    );
    statusMessage = reward > 0 ? '+$reward petals' : 'Level complete';
    unawaited(persist(clearActive: true));
    notifyListeners();
  }

  void continueNextSection() {
    if (advancingSection) return;
    advancingSection = true;
    final st = engine.state;
    if (st.levelId == null) {
      advancingSection = false;
      return;
    }
    final level = CampaignCatalog.level(st.levelId!);
    final next = st.sectionIndex + 1;
    if (next >= level.sections.length) {
      puzzleActive = false;
      if (st.levelId == 50) {
        save!.campaign.markVictorySeen();
        screen = AppScreen.campaignVictory;
      } else {
        screen = AppScreen.levelSelect;
        unawaited(ads.showInterstitialIfAllowed());
      }
      unawaited(persist(clearActive: true));
      advancingSection = false;
      notifyListeners();
      return;
    }
    campaignSectionIndex = next;
    statusMessage = null;
    _bootSection(level, next);
  }

  void finishLevelFromUi() {
    continueNextSection();
  }

  bool toggleBloomMode() {
    if (!engine.state.bloomEnabled) return false;
    if (!engine.state.bloom.canPrune) return false;
    bloomPruneMode = !bloomPruneMode;
    notifyListeners();
    return bloomPruneMode;
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
    _checkCampaignObjectives();
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
    final earned = await ads.showRewarded(placement: 'game_over_rescue');
    if (!earned) {
      statusMessage = 'Reward not earned — no rescue granted';
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
    unawaited(persist(clearActive: true));
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
    if (uid != null) {
      final reauthed = await auth.reauthenticateWithGoogle();
      if (!reauthed) {
        statusMessage = auth.errorMessage ??
            'Could not verify Google Sign-In. Account was not deleted.';
        notifyListeners();
        return false;
      }
      final cloudOk = await cloud.deleteCloudData(uid);
      final authOk = await auth.deleteAccount(reauthenticateFirst: false);
      if (!authOk) {
        statusMessage = auth.errorMessage ??
            'Cloud data may be gone, but Auth deletion failed. Retry or email support.';
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
      if (!puzzleActive) {
        unawaited(ads.showAppOpenIfAllowed(puzzleActive: puzzleActive));
      }
    }
  }

  @override
  void dispose() {
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
