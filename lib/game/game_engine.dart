import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'bloom_charge.dart';
import 'board.dart';
import 'piece.dart';
import 'rng.dart';
import 'scoring.dart';
import 'shapes.dart';

enum GameMode { classic, campaign }

enum GamePhase { playing, paused, connectionPaused, gameOver, levelComplete }

@immutable
class PlacementEvent {
  const PlacementEvent({
    required this.pieceUid,
    required this.row,
    required this.col,
    required this.clear,
    required this.score,
    required this.combo,
  });

  final String pieceUid;
  final int row;
  final int col;
  final ClearResult clear;
  final ScoreBreakdown score;
  final int combo;
}

@immutable
class GameState {
  const GameState({
    required this.board,
    required this.tray,
    required this.score,
    required this.bestScore,
    required this.combo,
    required this.linesClearedTotal,
    required this.bloom,
    required this.phase,
    required this.mode,
    required this.moveCount,
    this.levelId,
    this.sectionIndex = 0,
    this.movesRemaining,
    this.scoreTarget,
    this.lastEvent,
    this.rescueUsed = false,
    this.seed = 0,
    this.maxCombo = 0,
    this.levelRunScore = 0,
    this.winOnScoreTarget = false,
    this.surviveOnMovesExhausted = false,
    this.bloomEnabled = true,
    this.poolIds = const [],
    this.sectionIntro = '',
  });

  final Board board;
  final List<TrayPiece> tray;
  final int score;
  final int bestScore;
  final int combo;
  final int linesClearedTotal;
  final BloomState bloom;
  final GamePhase phase;
  final GameMode mode;
  final int moveCount;
  final int? levelId;
  final int sectionIndex;
  final int? movesRemaining;
  final int? scoreTarget;
  final PlacementEvent? lastEvent;
  final bool rescueUsed;
  final int seed;

  /// Highest combo reached in the current section.
  final int maxCombo;

  /// Cumulative score across sections of the current campaign level.
  final int levelRunScore;

  /// When true, reaching [scoreTarget] completes the section (reachScore only).
  final bool winOnScoreTarget;

  /// When true, exhausting moves completes the section (surviveMoves).
  final bool surviveOnMovesExhausted;

  final bool bloomEnabled;
  final List<String> poolIds;
  final String sectionIntro;

  List<TrayPiece> get availableTray => tray.where((p) => !p.used).toList();

  bool get isPlaying => phase == GamePhase.playing;

  GameState copyWith({
    Board? board,
    List<TrayPiece>? tray,
    int? score,
    int? bestScore,
    int? combo,
    int? linesClearedTotal,
    BloomState? bloom,
    GamePhase? phase,
    GameMode? mode,
    int? moveCount,
    int? levelId,
    int? sectionIndex,
    int? movesRemaining,
    int? scoreTarget,
    PlacementEvent? lastEvent,
    bool? rescueUsed,
    int? seed,
    int? maxCombo,
    int? levelRunScore,
    bool? winOnScoreTarget,
    bool? surviveOnMovesExhausted,
    bool? bloomEnabled,
    List<String>? poolIds,
    String? sectionIntro,
    bool clearLastEvent = false,
  }) {
    return GameState(
      board: board ?? this.board,
      tray: tray ?? this.tray,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      combo: combo ?? this.combo,
      linesClearedTotal: linesClearedTotal ?? this.linesClearedTotal,
      bloom: bloom ?? this.bloom,
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      moveCount: moveCount ?? this.moveCount,
      levelId: levelId ?? this.levelId,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      movesRemaining: movesRemaining ?? this.movesRemaining,
      scoreTarget: scoreTarget ?? this.scoreTarget,
      lastEvent: clearLastEvent ? null : (lastEvent ?? this.lastEvent),
      rescueUsed: rescueUsed ?? this.rescueUsed,
      seed: seed ?? this.seed,
      maxCombo: maxCombo ?? this.maxCombo,
      levelRunScore: levelRunScore ?? this.levelRunScore,
      winOnScoreTarget: winOnScoreTarget ?? this.winOnScoreTarget,
      surviveOnMovesExhausted:
          surviveOnMovesExhausted ?? this.surviveOnMovesExhausted,
      bloomEnabled: bloomEnabled ?? this.bloomEnabled,
      poolIds: poolIds ?? this.poolIds,
      sectionIntro: sectionIntro ?? this.sectionIntro,
    );
  }

  Map<String, dynamic> toJson() => {
    'board': board.toJson(),
    'tray': tray
        .map(
          (p) => {
            'uid': p.uid,
            'shapeId': p.shape.id,
            'color': p.colorIndex,
            'used': p.used,
          },
        )
        .toList(),
    'score': score,
    'bestScore': bestScore,
    'combo': combo,
    'lines': linesClearedTotal,
    'bloom': bloom.toJson(),
    'phase': phase.name,
    'mode': mode.name,
    'moves': moveCount,
    'levelId': levelId,
    'section': sectionIndex,
    'movesLeft': movesRemaining,
    'scoreTarget': scoreTarget,
    'rescueUsed': rescueUsed,
    'seed': seed,
    'maxCombo': maxCombo,
    'levelRunScore': levelRunScore,
    'winOnScore': winOnScoreTarget,
    'surviveMoves': surviveOnMovesExhausted,
    'bloomEnabled': bloomEnabled,
    'poolIds': poolIds,
    'intro': sectionIntro,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final tray = (json['tray'] as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final shape =
          ShapeCatalog.find(m['shapeId'] as String) ?? ShapeCatalog.mono;
      return TrayPiece(
        uid: m['uid'] as String,
        shape: shape,
        colorIndex: m['color'] as int,
        used: m['used'] as bool? ?? false,
      );
    }).toList();

    final poolRaw = (json['poolIds'] as List?)?.cast<String>() ?? const [];

    return GameState(
      board: Board.fromJson(Map<String, dynamic>.from(json['board'] as Map)),
      tray: tray,
      score: json['score'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      combo: json['combo'] as int? ?? 0,
      linesClearedTotal: json['lines'] as int? ?? 0,
      bloom: BloomState.fromJson(
        Map<String, dynamic>.from(json['bloom'] as Map? ?? {}),
      ),
      phase: GamePhase.values.firstWhere(
        (p) => p.name == json['phase'],
        orElse: () => GamePhase.playing,
      ),
      mode: GameMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => GameMode.classic,
      ),
      moveCount: json['moves'] as int? ?? 0,
      levelId: json['levelId'] as int?,
      sectionIndex: json['section'] as int? ?? 0,
      movesRemaining: json['movesLeft'] as int?,
      scoreTarget: json['scoreTarget'] as int?,
      rescueUsed: json['rescueUsed'] as bool? ?? false,
      seed: json['seed'] as int? ?? 0,
      maxCombo: json['maxCombo'] as int? ?? 0,
      levelRunScore: json['levelRunScore'] as int? ?? 0,
      winOnScoreTarget: json['winOnScore'] as bool? ?? false,
      surviveOnMovesExhausted: json['surviveMoves'] as bool? ?? false,
      bloomEnabled: json['bloomEnabled'] as bool? ?? true,
      poolIds: poolRaw,
      sectionIntro: json['intro'] as String? ?? '',
    );
  }
}

/// Pure gameplay engine. Deterministic given seed + actions.
class GameEngine {
  GameEngine({Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      _rng = SeededRng(1),
      _state = GameState(
        board: Board(size: 8),
        tray: const [],
        score: 0,
        bestScore: 0,
        combo: 0,
        linesClearedTotal: 0,
        bloom: const BloomState(),
        phase: GamePhase.paused,
        mode: GameMode.classic,
        moveCount: 0,
        seed: 1,
      );

  final Uuid _uuid;
  SeededRng _rng;
  GameState _state;
  List<PieceShape> _pool = ShapeCatalog.standardPool;
  bool _started = false;

  GameState get state => _state;
  bool get hasStarted => _started;

  void startClassic({
    int boardSize = 8,
    int? seed,
    int bestScore = 0,
    List<PieceShape>? pool,
  }) {
    final s = seed ?? DateTime.now().millisecondsSinceEpoch;
    _rng = SeededRng(s);
    _pool = pool ?? ShapeCatalog.standardPool;
    _state = GameState(
      board: Board(size: boardSize),
      tray: _generateTray(),
      score: 0,
      bestScore: bestScore,
      combo: 0,
      linesClearedTotal: 0,
      bloom: const BloomState(),
      phase: GamePhase.playing,
      mode: GameMode.classic,
      moveCount: 0,
      seed: s,
      poolIds: _pool.map((p) => p.id).toList(),
      bloomEnabled: true,
    );
    _started = true;
  }

  void startCampaign({
    required int levelId,
    required int sectionIndex,
    required int boardSize,
    required int? scoreTarget,
    required int? moveLimit,
    required List<(int, int)> blocked,
    required List<(int, int, int)> prefilled,
    required List<PieceShape> pool,
    int? seed,
    int bestScore = 0,
    int levelRunScore = 0,
    bool winOnScoreTarget = false,
    bool surviveOnMovesExhausted = false,
    bool bloomEnabled = true,
    String sectionIntro = '',
  }) {
    final s = seed ?? (levelId * 1000 + sectionIndex * 17);
    _rng = SeededRng(s);
    _pool = pool;
    final board = Board(size: boardSize)
        .applyPattern(blocked: blocked, prefilled: prefilled);
    _state = GameState(
      board: board,
      tray: _generateTray(),
      score: 0,
      bestScore: bestScore,
      combo: 0,
      linesClearedTotal: 0,
      bloom: const BloomState(),
      phase: GamePhase.playing,
      mode: GameMode.campaign,
      moveCount: 0,
      levelId: levelId,
      sectionIndex: sectionIndex,
      movesRemaining: moveLimit,
      scoreTarget: scoreTarget,
      seed: s,
      maxCombo: 0,
      levelRunScore: levelRunScore,
      winOnScoreTarget: winOnScoreTarget,
      surviveOnMovesExhausted: surviveOnMovesExhausted,
      bloomEnabled: bloomEnabled,
      poolIds: pool.map((p) => p.id).toList(),
      sectionIntro: sectionIntro,
    );
    _started = true;
  }

  void restore(GameState state) {
    _state = state;
    if (state.poolIds.isNotEmpty) {
      final restored = state.poolIds
          .map(ShapeCatalog.find)
          .whereType<PieceShape>()
          .toList();
      if (restored.isNotEmpty) _pool = restored;
    } else {
      _pool = ShapeCatalog.standardPool;
    }
    _rng = SeededRng(state.seed + state.moveCount + 1);
    _started = true;
  }

  List<TrayPiece> _generateTray() {
    return List.generate(3, (_) {
      final shape = _rng.pick(_pool);
      final color = _rng.nextInt(6);
      return TrayPiece(uid: _uuid.v4(), shape: shape, colorIndex: color);
    });
  }

  bool canPlace(String pieceUid, int row, int col) {
    if (!_state.isPlaying) return false;
    final piece = _findAvailable(pieceUid);
    if (piece == null) return false;
    return _state.board.canPlace(piece.shape, row, col);
  }

  /// Place a piece. Returns updated state or null if illegal.
  GameState? place(String pieceUid, int row, int col) {
    if (!_state.isPlaying) return null;
    final piece = _findAvailable(pieceUid);
    if (piece == null) return null;

    final placed = _state.board.tryPlace(
      piece.shape,
      row,
      col,
      piece.colorIndex,
    );
    if (placed == null) return null;

    final clear = placed.findClears();
    final afterClear = placed.applyClears(clear);

    final nextCombo = clear.hasClears ? _state.combo + 1 : 0;
    final maxCombo =
        nextCombo > _state.maxCombo ? nextCombo : _state.maxCombo;
    final breakdown = ScoreBreakdown.forPlacement(
      placedCells: piece.shape.cellCount,
      lineCount: clear.lineCount,
      combo: nextCombo,
    );

    var bloom = _state.bloom;
    if (_state.bloomEnabled && clear.cellsCleared > 0) {
      bloom = bloom.addClearedCells(clear.cellsCleared);
    }

    var tray = _state.tray
        .map((p) => p.uid == pieceUid ? p.copyWith(used: true) : p)
        .toList();

    if (tray.every((p) => p.used)) {
      tray = _generateTray();
    }

    var movesLeft = _state.movesRemaining;
    if (movesLeft != null) {
      movesLeft = movesLeft - 1;
    }

    final newScore = _state.score + breakdown.totalDelta;
    final best = newScore > _state.bestScore ? newScore : _state.bestScore;

    var phase = GamePhase.playing;

    // Score-target win only for reachScore sections.
    if (_state.mode == GameMode.campaign &&
        _state.winOnScoreTarget &&
        _state.scoreTarget != null &&
        newScore >= _state.scoreTarget!) {
      phase = GamePhase.levelComplete;
    }

    // Survive objective: exhausting moves wins (checked before dead-board).
    if (phase == GamePhase.playing &&
        _state.surviveOnMovesExhausted &&
        movesLeft != null &&
        movesLeft <= 0) {
      phase = GamePhase.levelComplete;
    }

    // Failed timed reachScore: out of moves without hitting target.
    if (phase == GamePhase.playing &&
        movesLeft != null &&
        movesLeft <= 0 &&
        _state.winOnScoreTarget &&
        _state.scoreTarget != null &&
        newScore < _state.scoreTarget!) {
      phase = GamePhase.gameOver;
    }

    // Dead board → game over, unless we already completed (e.g. survived).
    if (phase == GamePhase.playing && !afterClear.anyPieceFits(tray)) {
      phase = GamePhase.gameOver;
    }

    _state = _state.copyWith(
      board: afterClear,
      tray: tray,
      score: newScore,
      bestScore: best,
      combo: nextCombo,
      maxCombo: maxCombo,
      linesClearedTotal: _state.linesClearedTotal + clear.lineCount,
      bloom: bloom,
      phase: phase,
      moveCount: _state.moveCount + 1,
      movesRemaining: movesLeft,
      lastEvent: PlacementEvent(
        pieceUid: pieceUid,
        row: row,
        col: col,
        clear: clear,
        score: breakdown,
        combo: nextCombo,
      ),
    );
    return _state;
  }

  /// Bloom Prune: spend one charge to remove a single filled cell.
  GameState? bloomPrune(int row, int col) {
    if (!_state.isPlaying || !_state.bloomEnabled) return null;
    final spent = _state.bloom.spendCharge();
    if (spent == null) return null;
    final pruned = _state.board.pruneCell(row, col);
    if (pruned == null) return null;

    final clear = pruned.findClears();
    final after = pruned.applyClears(clear);
    final bonus = ScoreBreakdown.forPlacement(
      placedCells: 0,
      lineCount: 0,
      combo: _state.combo,
      bloomBonus: 2,
    );

    final newScore = _state.score + bonus.totalDelta;
    var phase = GamePhase.playing;

    if (_state.mode == GameMode.campaign &&
        _state.winOnScoreTarget &&
        _state.scoreTarget != null &&
        newScore >= _state.scoreTarget!) {
      phase = GamePhase.levelComplete;
    } else if (!after.anyPieceFits(_state.tray)) {
      phase = GamePhase.gameOver;
    }

    _state = _state.copyWith(
      board: after,
      bloom: spent,
      score: newScore,
      phase: phase,
      moveCount: _state.moveCount + 1,
      linesClearedTotal: _state.linesClearedTotal + clear.lineCount,
    );
    return _state;
  }

  /// Mark section/level complete from AppState objective checks.
  GameState markLevelComplete() {
    if (_state.phase == GamePhase.playing) {
      _state = _state.copyWith(phase: GamePhase.levelComplete);
    }
    return _state;
  }

  /// Mark game over from AppState when objectives fail.
  GameState markGameOver() {
    if (_state.phase == GamePhase.playing) {
      _state = _state.copyWith(phase: GamePhase.gameOver);
    }
    return _state;
  }

  GameState pause() {
    if (_state.phase == GamePhase.playing) {
      _state = _state.copyWith(phase: GamePhase.paused);
    }
    return _state;
  }

  GameState resume() {
    if (_state.phase == GamePhase.paused ||
        _state.phase == GamePhase.connectionPaused) {
      _state = _state.copyWith(phase: GamePhase.playing);
      if (!_state.board.anyPieceFits(_state.tray)) {
        _state = _state.copyWith(phase: GamePhase.gameOver);
      }
    }
    return _state;
  }

  GameState connectionPause() {
    if (_state.phase == GamePhase.playing || _state.phase == GamePhase.paused) {
      _state = _state.copyWith(phase: GamePhase.connectionPaused);
    }
    return _state;
  }

  /// Rewarded-ad rescue: refill tray once per run if confirmed by ad service.
  GameState? applyRescueTray() {
    if (_state.phase != GamePhase.gameOver) return null;
    if (_state.rescueUsed) return null;
    final tray = _generateTray();
    List<TrayPiece> rescueTray = tray;
    for (var i = 0; i < 8; i++) {
      if (_state.board.anyPieceFits(rescueTray)) break;
      rescueTray = _generateTray();
    }
    if (!_state.board.anyPieceFits(rescueTray)) {
      rescueTray = [
        TrayPiece(uid: _uuid.v4(), shape: ShapeCatalog.mono, colorIndex: 0),
        ...rescueTray.take(2),
      ];
    }
    if (!_state.board.anyPieceFits(rescueTray)) return null;

    _state = _state.copyWith(
      tray: rescueTray,
      phase: GamePhase.playing,
      rescueUsed: true,
      combo: 0,
    );
    return _state;
  }

  TrayPiece? _findAvailable(String uid) {
    try {
      return _state.tray.firstWhere((p) => p.uid == uid && !p.used);
    } catch (_) {
      return null;
    }
  }
}
