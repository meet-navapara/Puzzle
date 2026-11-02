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
    this.lineTarget,
    this.comboTarget,
    this.clearBoardGoal = false,
    this.levelRunMoves = 0,
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

  /// Lines to clear to complete a clearLines section.
  final int? lineTarget;

  /// Consecutive clears needed to complete a comboStreak section.
  final int? comboTarget;

  /// When true, emptying the board completes the section.
  final bool clearBoardGoal;

  /// Moves spent on earlier sections of this level (star rating).
  final int levelRunMoves;

  bool get outOfMoves => movesRemaining != null && movesRemaining! <= 0;

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
    int? lineTarget,
    int? comboTarget,
    bool? clearBoardGoal,
    int? levelRunMoves,
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
      lineTarget: lineTarget ?? this.lineTarget,
      comboTarget: comboTarget ?? this.comboTarget,
      clearBoardGoal: clearBoardGoal ?? this.clearBoardGoal,
      levelRunMoves: levelRunMoves ?? this.levelRunMoves,
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
    'lineTarget': lineTarget,
    'comboTarget': comboTarget,
    'clearBoardGoal': clearBoardGoal,
    'levelRunMoves': levelRunMoves,
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
      lineTarget: json['lineTarget'] as int?,
      comboTarget: json['comboTarget'] as int?,
      clearBoardGoal: json['clearBoardGoal'] as bool? ?? false,
      levelRunMoves: json['levelRunMoves'] as int? ?? 0,
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

  static const int rescueExtraMoves = 5;

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
    final board = Board(size: boardSize);
    _state = GameState(
      board: board,
      tray: _dealTray(board),
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
    int? lineTarget,
    int? comboTarget,
    bool clearBoardGoal = false,
    int levelRunMoves = 0,
  }) {
    final s = seed ?? (levelId * 1000 + sectionIndex * 17);
    _rng = SeededRng(s);
    _pool = pool;
    final board = Board(size: boardSize)
        .applyPattern(blocked: blocked, prefilled: prefilled);
    _state = GameState(
      board: board,
      tray: _dealTray(board),
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
      lineTarget: lineTarget,
      comboTarget: comboTarget,
      clearBoardGoal: clearBoardGoal,
      levelRunMoves: levelRunMoves,
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

  List<TrayPiece> _rollTray() {
    return List.generate(3, (_) {
      final shape = _rng.pick(_pool);
      final color = _rng.nextInt(6);
      return TrayPiece(uid: _uuid.v4(), shape: shape, colorIndex: color);
    });
  }

  /// Rolls a tray with at least one piece that fits [board], so a fresh deal is
  /// never an instant loss. Falls back to a single-cell piece on tight boards.
  List<TrayPiece> _dealTray(Board board) {
    var tray = _rollTray();
    for (var i = 0; i < 12; i++) {
      if (board.anyPieceFits(tray)) return tray;
      tray = _rollTray();
    }
    return [
      TrayPiece(
        uid: _uuid.v4(),
        shape: ShapeCatalog.mono,
        colorIndex: tray.first.colorIndex,
      ),
      ...tray.skip(1),
    ];
  }

  /// True once the section's goal is satisfied by these running totals.
  bool _objectiveMet({
    required int score,
    required int lines,
    required int maxCombo,
    required int? movesLeft,
    required Board board,
  }) {
    final st = _state;
    if (st.mode != GameMode.campaign) return false;
    if (st.winOnScoreTarget &&
        st.scoreTarget != null &&
        score >= st.scoreTarget!) {
      return true;
    }
    if (st.lineTarget != null && lines >= st.lineTarget!) return true;
    if (st.comboTarget != null && maxCombo >= st.comboTarget!) return true;
    if (st.clearBoardGoal && board.filledCount == 0) return true;
    return st.surviveOnMovesExhausted && movesLeft != null && movesLeft <= 0;
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
    final maxCombo = nextCombo > _state.maxCombo ? nextCombo : _state.maxCombo;
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
      tray = _dealTray(afterClear);
    }

    var movesLeft = _state.movesRemaining;
    if (movesLeft != null) {
      movesLeft = movesLeft - 1;
    }

    final newScore = _state.score + breakdown.totalDelta;
    final best = newScore > _state.bestScore ? newScore : _state.bestScore;

    final lines = _state.linesClearedTotal + clear.lineCount;
    var phase = GamePhase.playing;

    // The goal wins first: a move that reaches it can't also lose the section.
    if (_objectiveMet(
      score: newScore,
      lines: lines,
      maxCombo: maxCombo,
      movesLeft: movesLeft,
      board: afterClear,
    )) {
      phase = GamePhase.levelComplete;
    } else if (movesLeft != null && movesLeft <= 0) {
      phase = GamePhase.gameOver;
    } else if (!afterClear.anyPieceFits(tray)) {
      phase = GamePhase.gameOver;
    }

    _state = _state.copyWith(
      board: afterClear,
      tray: tray,
      score: newScore,
      bestScore: best,
      combo: nextCombo,
      maxCombo: maxCombo,
      linesClearedTotal: lines,
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

    if (_objectiveMet(
      score: newScore,
      lines: _state.linesClearedTotal + clear.lineCount,
      maxCombo: _state.maxCombo,
      movesLeft: _state.movesRemaining,
      board: after,
    )) {
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

  /// True when a game-over board could be saved by spending a Bloom charge.
  bool get canReviveWithBloom {
    final st = _state;
    return st.phase == GamePhase.gameOver &&
        st.bloomEnabled &&
        st.bloom.canPrune &&
        !st.outOfMoves;
  }

  /// Reopens a stuck board so the player can Bloom Prune a cell.
  GameState? reviveForPrune() {
    if (!canReviveWithBloom) return null;
    _state = _state.copyWith(phase: GamePhase.playing);
    return _state;
  }

  /// Rewarded-ad rescue: fresh tray once per run, confirmed by the ad service.
  /// A section lost by running out of moves also gets [rescueExtraMoves] more,
  /// otherwise the reward would end the run on the very next placement.
  GameState? applyRescueTray() {
    if (_state.phase != GamePhase.gameOver) return null;
    if (_state.rescueUsed) return null;
    final rescueTray = _dealTray(_state.board);
    if (!_state.board.anyPieceFits(rescueTray)) return null;

    _state = _state.copyWith(
      tray: rescueTray,
      phase: GamePhase.playing,
      rescueUsed: true,
      combo: 0,
      movesRemaining: _state.outOfMoves ? rescueExtraMoves : null,
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
