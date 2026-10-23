import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../campaign/campaign_catalog.dart';
import '../../campaign/level_models.dart';
import '../../core/app_config.dart';
import '../../game/bloom_charge.dart';
import '../../game/game_engine.dart';
import '../../game/piece.dart';
import '../../state/app_state.dart';
import '../theme/petal_theme.dart';
import '../widgets/app_dialog.dart';
import 'board_view.dart';
import 'game_fx.dart';
import 'piece_visual.dart';
import 'placement_mapper.dart';
import 'tray_view.dart';
import 'tutorial_layer.dart';
import '../../tutorial/tutorial_coach.dart';
import '../../tutorial/tutorial_copy.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with TickerProviderStateMixin {
  final GlobalKey _boardKey = GlobalKey();

  String? _selectedUid;
  String? _draggingUid;
  TrayPiece? _dragPiece;
  Offset? _lastPointerGlobal;
  bool _dragSessionClosed = false;

  /// Ghost updates without setState — avoids freezing mid-drag tray rebuilds.
  final ValueNotifier<_GhostPaint?> _ghostPaint = ValueNotifier(null);

  OverlayEntry? _dragOverlay;
  final ValueNotifier<Offset?> _fingerGlobal = ValueNotifier(null);

  Set<(int, int)> _placePulse = {};
  double _placeScale = 1.0;
  List<int> _clearRows = const [];
  List<int> _clearCols = const [];
  bool _clearActive = false;
  int _clearToken = 0;
  String? _bannerText;
  int _bannerToken = 0;
  int? _scoreFloat;
  int _scoreToken = 0;
  int _fxGeneration = 0;
  bool _rejectShake = false;

  TutorialPhase _tutorPhase = TutorialPhase.inactive;
  int _tutorCard = 0;
  int? _tutorLevelId;
  TutorialMove? _tutorMove;
  int _guidedPlayerMoves = 0;
  bool _hintOn = false;
  String _tutorFeedback = '';
  String _tutorMessage = '';
  int _tutorRun = 0;

  @override
  void dispose() {
    _removeDragOverlay();
    _ghostPaint.dispose();
    _fingerGlobal.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppState>();
    final started = app.engine.hasStarted;
    final id = started ? app.engine.state.levelId : null;
    final seed = started ? app.engine.state.seed : null;
    final classic = started && app.engine.state.mode == GameMode.classic;
    final key = classic
        ? Object.hash('classic', seed, app.tutorialSession)
        : id == null
        ? null
        : Object.hash(id, seed, app.tutorialSession);
    if (key == _tutorLevelId) return;
    _tutorLevelId = key;
    _tutorPhase = TutorialPhase.inactive;
    _tutorCard = 0;
    _tutorMove = null;
    _guidedPlayerMoves = 0;
    _hintOn = false;
    _tutorFeedback = '';
    final run = ++_tutorRun;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || run != _tutorRun) return;
      _maybeStartTutorial();
    });
  }

  bool get _tutorLock =>
      _tutorPhase == TutorialPhase.cards ||
      _tutorPhase == TutorialPhase.demo ||
      _tutorPhase == TutorialPhase.explain ||
      _tutorPhase == TutorialPhase.success;

  bool get _showGuideCells =>
      _tutorMove != null &&
      (_tutorPhase == TutorialPhase.demo ||
          _tutorPhase == TutorialPhase.guided ||
          (_tutorPhase == TutorialPhase.practice && _hintOn));

  void _maybeStartTutorial() {
    final app = context.read<AppState>();
    if (!app.engine.hasStarted) return;
    final id = app.engine.state.levelId;
    if (app.shouldGuideClassic) {
      setState(() {
        _tutorFeedback = '';
        _tutorMessage =
            'Drag the glowing piece onto the glowing cells. You make this move.';
        _refreshTutorMove();
        _tutorPhase = TutorialPhase.guided;
      });
      return;
    }
    if (!app.shouldGuideLevel(id)) return;
    app.dismissSectionIntro();
    final resume = app.engine.state.moveCount > 0;
    setState(() {
      _tutorFeedback = '';
      if (!resume) {
        _tutorPhase = TutorialPhase.cards;
        _tutorCard = 0;
        return;
      }
      _tutorMove = TutorialCoach.bestMove(
        app.engine.state,
        preferLineClear: id == 2,
      );
      _tutorPhase = id == 2 && app.engine.state.moveCount >= 3
          ? TutorialPhase.practice
          : TutorialPhase.guided;
    });
  }

  void _refreshTutorMove() {
    final state = context.read<AppState>().engine.state;
    _tutorMove = TutorialCoach.bestMove(
      state,
      preferLineClear: state.levelId == 2,
    );
  }

  Future<void> _playTutorDemo() async {
    final app = context.read<AppState>();
    final run = _tutorRun;
    final move = TutorialCoach.bestMove(
      app.engine.state,
      preferLineClear: app.engine.state.levelId == 2,
    );
    if (!mounted || run != _tutorRun) return;
    if (move == null) {
      setState(() => _tutorPhase = TutorialPhase.guided);
      return;
    }
    setState(() {
      _tutorPhase = TutorialPhase.demo;
      _tutorMove = move;
      _tutorMessage = move.reason;
      _tutorFeedback = '';
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || run != _tutorRun || _tutorPhase != TutorialPhase.demo) {
      return;
    }
    final placed = app.placePiece(move.pieceUid, move.row, move.col);
    if (!placed) {
      setState(() => _tutorPhase = TutorialPhase.guided);
      _refreshTutorMove();
      return;
    }
    _noteTutorAfterPlace(fromDemo: true);
  }

  void _noteTutorAfterPlace({bool fromDemo = false}) {
    final app = context.read<AppState>();
    final state = app.engine.state;
    if (state.phase == GamePhase.levelComplete) {
      setState(() {
        _tutorPhase = TutorialPhase.success;
        _tutorMove = null;
        _tutorFeedback = '';
      });
      return;
    }
    setState(() {
      _refreshTutorMove();
      _tutorFeedback = '';
      if (fromDemo) {
        _tutorPhase = TutorialPhase.explain;
        return;
      }
      if (_tutorPhase == TutorialPhase.guided) {
        if (state.mode == GameMode.classic) {
          _tutorPhase = TutorialPhase.explain;
          _tutorMessage =
              'You planted it yourself. Fill a whole row or column and it blooms. Classic has no level end — the crown is your best score.';
          _tutorMove = null;
          return;
        }
        _guidedPlayerMoves++;
        if (state.levelId == 2 && _guidedPlayerMoves >= 2) {
          _tutorPhase = TutorialPhase.practice;
          _hintOn = false;
          _tutorMove = null;
        }
      } else if (_tutorPhase == TutorialPhase.practice && _hintOn) {
        _refreshTutorMove();
      }
    });
  }

  void _skipTutorial() {
    final app = context.read<AppState>();
    if (app.engine.hasStarted && app.engine.state.mode == GameMode.classic) {
      app.completeClassicTour();
    } else {
      final id = app.engine.state.levelId;
      if (id != null) app.completeTutorial(id);
    }
    setState(() {
      _tutorPhase = TutorialPhase.inactive;
      _tutorMove = null;
      _tutorFeedback = '';
    });
  }

  bool get _reducedMotion {
    final settings = context.read<AppState>().save?.settings;
    final media = MediaQuery.of(context).disableAnimations;
    return (settings?.reducedEffects ?? false) || media;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild only when play-relevant fields change — not on statusMessage alone.
    final snapshot = context.select<AppState, _PlaySnapshot>(
      (a) => _PlaySnapshot.from(a),
    );
    final app = context.read<AppState>();
    final st = snapshot.state;
    final surfaces = PetalSurfaces.of(context);
    final selected = _resolveSelected(st);
    // Keep tip slot reserved during drag so the board does not jump.
    final tutorialPending =
        !(app.save?.settings.tutorialSeen ?? true) &&
        st.phase == GamePhase.playing;
    final showTip = tutorialPending && _draggingUid == null;

    Color? worldAccent;
    if (st.mode == GameMode.campaign && st.levelId != null) {
      final world =
          CampaignCatalog.worlds[CampaignCatalog.level(st.levelId!).worldIndex];
      worldAccent = Color(world.accentColorValue);
    }

    return GardenBackdrop(
      accent: worldAccent,
      child: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final short = constraints.maxHeight < 640;
                final trayH = short ? 96.0 : 108.0;
                final bloomH = 52.0;
                // Crown row + hero score + optional objective chips.
                final headerH = short ? 118.0 : 132.0;
                // Fixed tip reservation — never depends on drag state.
                final tipH = tutorialPending ? 36.0 : 0.0;
                final availableBoard = math.max(
                  180.0,
                  constraints.maxHeight - headerH - trayH - bloomH - tipH - 28,
                );
                final boardSide = math.min(
                  constraints.maxWidth - 28,
                  availableBoard,
                );

                return Column(
                  children: [
                    _ScoreBoard(
                      state: st,
                      linesCleared: snapshot.sectionLinesCleared,
                      maxCombo: snapshot.sectionMaxCombo,
                      compact: short,
                      onPause: app.pauseGame,
                    ),
                    const SizedBox(height: PetalSpace.sm),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: boardSide,
                          height: boardSide,
                          child: ValueListenableBuilder<_GhostPaint?>(
                            valueListenable: _ghostPaint,
                            builder: (context, ghost, _) {
                              final paintPiece = _dragPiece ?? selected;
                              final showGhost = ghost != null &&
                                  ghost.target.overBoard &&
                                  paintPiece != null;
                              final ghostValid =
                                  showGhost && ghost.target.valid;
                              List<int> previewRows = const [];
                              List<int> previewCols = const [];
                              if (ghostValid) {
                                final preview = st.board.previewClears(
                                  paintPiece.shape,
                                  ghost.target.row,
                                  ghost.target.col,
                                  paintPiece.colorIndex,
                                );
                                previewRows = preview.clearedRows;
                                previewCols = preview.clearedCols;
                              }
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  BoardView(
                                    boardKey: _boardKey,
                                    board: st.board,
                                    ghostShape:
                                        showGhost ? paintPiece.shape : null,
                                    ghostRow:
                                        showGhost ? ghost.target.row : null,
                                    ghostCol:
                                        showGhost ? ghost.target.col : null,
                                    ghostValid: ghostValid,
                                    ghostColorIndex:
                                        paintPiece?.colorIndex ?? 0,
                                    pruneMode: snapshot.bloomPruneMode,
                                    placePulseCells: _placePulse,
                                    placeScale: _placeScale,
                                    clearRows: _clearRows,
                                    clearCols: _clearCols,
                                    clearToken: _clearToken,
                                    clearActive: _clearActive,
                                    previewClearRows: previewRows,
                                    previewClearCols: previewCols,
                                    guideCells: _showGuideCells
                                        ? _tutorMove!.cells
                                        : const {},
                                    reducedMotion: _reducedMotion,
                                    onClearFxFinished: () {
                                      if (!mounted) return;
                                      setState(() {
                                        _clearActive = false;
                                        _clearRows = const [];
                                        _clearCols = const [];
                                      });
                                    },
                                    onCellTap: (r, c) =>
                                        _onCellTap(app, st, r, c),
                                  ),
                                  // Overlay hint — never changes Column height.
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    bottom: -2,
                                    child: IgnorePointer(
                                      child: AnimatedOpacity(
                                        duration: PetalMotion.tap,
                                        opacity:
                                            (_draggingUid != null &&
                                                ghost != null &&
                                                ghost.target.overBoard &&
                                                !ghost.target.valid)
                                            ? 1
                                            : 0,
                                        child: _InvalidHint(
                                          color: surfaces.danger,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (tutorialPending)
                      SizedBox(
                        height: tipH,
                        child: Opacity(
                          opacity: showTip ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !showTip,
                            child: _CompactTutorialTip(
                              onDismiss: () {
                                final s = app.save!.settings;
                                app.updateSettings(
                                  s.copyWith(tutorialSeen: true),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedSlide(
                        duration: PetalMotion.reject,
                        curve: PetalMotion.snappy,
                        offset: _rejectShake
                            ? const Offset(0.028, 0)
                            : Offset.zero,
                        child: TrayView(
                          pieces: st.tray,
                          selectedUid: _selectedUid,
                          draggingUid: _draggingUid,
                          highlightUid: _showGuideCells
                              ? _tutorMove!.pieceUid
                              : null,
                          trayHeight: trayH,
                          onSelect: (p) {
                            _ghostPaint.value = null;
                            setState(() {
                              _selectedUid = p.uid;
                              _lastPointerGlobal = null;
                            });
                            if (snapshot.bloomPruneMode) {
                              app.toggleBloomMode();
                            }
                          },
                          onDragStarted: (p, global) {
                            _beginDrag(p, global);
                            if (snapshot.bloomPruneMode) {
                              app.toggleBloomMode();
                            }
                          },
                          onDragUpdate: (p, global) {
                            _moveDrag(p, global);
                          },
                          onDragEnd: (p) => _finishDrag(p),
                        ),
                      ),
                    ),
                    const SizedBox(height: PetalSpace.sm),
                    if (st.bloomEnabled)
                      _BloomBar(
                        bloom: st.bloom,
                        active: snapshot.bloomPruneMode,
                        petals: snapshot.petals,
                        onToggle: () {
                          final on = app.toggleBloomMode();
                          if (on) {
                            _ghostPaint.value = null;
                            setState(() {
                              _selectedUid = null;
                            });
                          }
                        },
                        onBuyCharge: () => app.buyBloomCharge(),
                      )
                    else
                      const SizedBox(height: 8),
                    const SizedBox(height: PetalSpace.sm),
                  ],
                );
              },
            ),
            if (_bannerText != null)
              Positioned(
                top: 72,
                left: 0,
                right: 0,
                child: Center(
                  child: FxBanner(
                    key: ValueKey(_bannerToken),
                    text: _bannerText!,
                    token: _bannerToken,
                    reducedMotion: _reducedMotion,
                    onFinished: () {
                      if (mounted) setState(() => _bannerText = null);
                    },
                  ),
                ),
              ),
            if (_scoreFloat != null)
              Positioned(
                top: 120,
                right: 24,
                child: ScoreFloat(
                  key: ValueKey(_scoreToken),
                  points: _scoreFloat!,
                  token: _scoreToken,
                  reducedMotion: _reducedMotion,
                ),
              ),
            if (_tutorPhase == TutorialPhase.demo ||
                _tutorPhase == TutorialPhase.explain ||
                _tutorPhase == TutorialPhase.guided ||
                _tutorPhase == TutorialPhase.practice)
              Positioned(
                left: 12,
                right: 12,
                bottom: MediaQuery.sizeOf(context).height < 700 ? 148 : 176,
                child: TutorialCoachBanner(
                  phase: _tutorPhase,
                  message: _tutorPhase == TutorialPhase.demo
                      ? 'Watch the glowing cells. This plant uses the real garden rules.'
                      : _tutorPhase == TutorialPhase.explain
                      ? _tutorMessage
                      : _tutorPhase == TutorialPhase.practice
                      ? 'Try the next plants yourself. Hint shows one strong move.'
                      : (_tutorMove?.reason ??
                          'Drag the glowing piece onto the glowing cells.'),
                  feedback: _tutorFeedback,
                  showHint: _tutorPhase == TutorialPhase.practice,
                  hintOn: _hintOn,
                  onSkip: _skipTutorial,
                  onContinue: () {
                    final live = context.read<AppState>();
                    if (live.engine.state.mode == GameMode.classic) {
                      live.completeClassicTour();
                      setState(() {
                        _tutorPhase = TutorialPhase.inactive;
                        _tutorMove = null;
                        _tutorFeedback = '';
                      });
                      return;
                    }
                    setState(() {
                      _tutorPhase = TutorialPhase.guided;
                      _tutorFeedback = '';
                      _refreshTutorMove();
                    });
                  },
                  onToggleHint: () {
                    setState(() {
                      _hintOn = !_hintOn;
                      if (_hintOn) {
                        _refreshTutorMove();
                      } else {
                        _tutorMove = null;
                      }
                    });
                  },
                ),
              ),
            if (_tutorPhase == TutorialPhase.cards ||
                _tutorPhase == TutorialPhase.success)
              Positioned.fill(
                child: TutorialCardOverlay(
                  phase: _tutorPhase,
                  cardIndex: _tutorCard,
                  levelId: st.levelId ?? 1,
                  onBack: () => setState(() {
                    if (_tutorCard > 0) _tutorCard--;
                  }),
                  onNext: () {
                    if (_tutorCard < TutorialCopy.cards.length - 1) {
                      setState(() => _tutorCard++);
                    } else {
                      _playTutorDemo();
                    }
                  },
                  onSkip: _skipTutorial,
                  onContinueSuccess: _skipTutorial,
                ),
              ),
            if (snapshot.showingSectionIntro &&
                _tutorPhase == TutorialPhase.inactive &&
                st.phase == GamePhase.playing)
              _SectionIntroOverlay(
                text: st.sectionIntro,
                onDismiss: app.dismissSectionIntro,
              ),
            if (st.phase == GamePhase.paused) _PauseOverlay(app: app),
            if (st.phase == GamePhase.connectionPaused)
              const _ConnectionOverlay(),
            if (st.phase == GamePhase.gameOver) _GameOverOverlay(app: app),
            if (st.phase == GamePhase.levelComplete &&
                _tutorPhase != TutorialPhase.success)
              _LevelCompleteOverlay(app: app),
          ],
        ),
      ),
    );
  }

  TrayPiece? _resolveSelected(GameState st) {
    final uid = _selectedUid;
    if (uid == null) return null;
    for (final p in st.tray) {
      if (p.uid == uid && !p.used) return p;
    }
    return null;
  }

  /// Always maps against the live engine board — never a stale build closure.
  PlacementTarget? _mapPointer(TrayPiece piece, Offset global) {
    final board = context.read<AppState>().engine.state.board;
    return BoardPlacementMapper.fromGlobalPointer(
      boardKey: _boardKey,
      globalPointer: global,
      board: board,
      shape: piece.shape,
    );
  }

  void _beginDrag(TrayPiece piece, Offset global) {
    if (_tutorLock) return;
    if (_tutorPhase == TutorialPhase.guided &&
        _tutorMove != null &&
        piece.uid != _tutorMove!.pieceUid) {
      setState(() {
        _tutorFeedback = 'Use the glowing piece in the tray.';
      });
      _playReject();
      return;
    }
    _dragSessionClosed = false;
    _lastPointerGlobal = global;
    _dragPiece = piece;
    _ghostPaint.value = null;
    setState(() {
      _draggingUid = piece.uid;
      _selectedUid = piece.uid;
    });
    _showDragOverlay(piece);
    _moveDrag(piece, global);
  }

  void _moveDrag(TrayPiece piece, Offset global) {
    if (_dragSessionClosed || _draggingUid != piece.uid) return;
    _lastPointerGlobal = global;
    _fingerGlobal.value = global;
    final target = _mapPointer(piece, global);
    if (target == null) return;
    final prev = _ghostPaint.value?.target;
    if (prev?.row == target.row &&
        prev?.col == target.col &&
        prev?.valid == target.valid &&
        prev?.overBoard == target.overBoard) {
      return;
    }
    // No setState — only the board ghost rebuilds.
    _ghostPaint.value = _GhostPaint(piece: piece, target: target);
  }

  void _finishDrag(TrayPiece piece) {
    if (_dragSessionClosed) return;
    _dragSessionClosed = true;

    final app = context.read<AppState>();
    final pointer = _lastPointerGlobal;
    final target = pointer != null ? _mapPointer(piece, pointer) : null;

    _removeDragOverlay();
    _ghostPaint.value = null;
    _fingerGlobal.value = null;

    setState(() {
      _draggingUid = null;
      _dragPiece = null;
      _lastPointerGlobal = null;
      _selectedUid = piece.uid;
    });

    if (target != null && target.valid && target.overBoard) {
      _tryPlace(app, piece.uid, target.row, target.col);
      return;
    }

    // Invalid / off-board: board unchanged, piece stays in tray.
    if (target != null && target.overBoard && !target.valid) {
      _playReject();
    }
  }

  void _showDragOverlay(TrayPiece piece) {
    _removeDragOverlay();
    _dragOverlay = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder<Offset?>(
          valueListenable: _fingerGlobal,
          builder: (context, finger, _) {
            if (finger == null) return const SizedBox.shrink();
            const extent = 96.0;
            final rows = piece.shape.height;
            final cols = piece.shape.width;
            final cell = extent / (rows > cols ? rows : cols);
            final w = cols * cell;
            final h = rows * cell;
            final lift = cell * BoardPlacementMapper.defaultFingerLiftCells;
            return IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    left: finger.dx - w / 2,
                    top: finger.dy - h / 2 - lift,
                    child: Opacity(
                      opacity:
                          Theme.of(context).brightness == Brightness.light
                              ? 0.96
                              : 0.78,
                      child: PieceVisual(
                        piece: piece,
                        maxExtent: extent,
                        bare: true,
                        lifted: true,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    Overlay.of(context, rootOverlay: true).insert(_dragOverlay!);
  }

  void _removeDragOverlay() {
    _dragOverlay?.remove();
    _dragOverlay = null;
  }

  void _onCellTap(AppState app, GameState st, int r, int c) {
    if (_tutorLock || _draggingUid != null) return;
    if (app.bloomPruneMode) {
      app.pruneAt(r, c);
      return;
    }
    final selected = _resolveSelected(st);
    if (selected == null) return;
    final target = BoardPlacementMapper.fromCellTap(
      board: st.board,
      shape: selected.shape,
      tappedRow: r,
      tappedCol: c,
    );
    if (target.valid) {
      _tryPlace(app, selected.uid, target.row, target.col);
    } else {
      _ghostPaint.value = _GhostPaint(piece: selected, target: target);
      _playReject();
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || _draggingUid != null) return;
        _ghostPaint.value = null;
      });
    }
  }

  void _tryPlace(AppState app, String uid, int row, int col) {
    if (_tutorLock) return;
    if (_tutorPhase == TutorialPhase.guided &&
        _tutorMove != null &&
        !_tutorMove!.matches(uid, row, col)) {
      setState(() {
        _tutorFeedback = 'Not quite — plant on the glowing cells.';
      });
      _playReject();
      return;
    }
    final before = app.engine.state;
    final ok = app.placePiece(uid, row, col);
    if (!ok) {
      _ghostPaint.value = null;
      if (_tutorPhase == TutorialPhase.guided ||
          _tutorPhase == TutorialPhase.practice) {
        setState(() {
          _tutorFeedback = 'That spot does not fit. Try an open group of cells.';
        });
      }
      _playReject();
      return;
    }
    if (_tutorPhase == TutorialPhase.guided ||
        _tutorPhase == TutorialPhase.practice) {
      _noteTutorAfterPlace();
    }
    final after = app.engine.state;
    final event = after.lastEvent;
    final gen = ++_fxGeneration;

    TrayPiece? piece;
    for (final p in before.tray) {
      if (p.uid == uid) {
        piece = p;
        break;
      }
    }
    if (piece != null) {
      final cells = {
        for (final (dr, dc) in piece.shape.cells) (row + dr, col + dc),
      };
      _ghostPaint.value = null;
      setState(() {
        _placePulse = cells;
        _placeScale = 1.08;
        _selectedUid = null;
      });
      Future<void>.delayed(PetalMotion.place, () {
        if (!mounted || gen != _fxGeneration) return;
        setState(() {
          _placePulse = {};
          _placeScale = 1.0;
        });
      });
    } else {
      _ghostPaint.value = null;
      setState(() {
        _selectedUid = null;
      });
    }

    if (event != null && event.score.totalDelta > 0) {
      setState(() {
        _scoreFloat = event.score.totalDelta;
        _scoreToken++;
      });
    }

    if (event != null && event.clear.hasClears) {
      setState(() {
        _clearRows = List<int>.from(event.clear.clearedRows);
        _clearCols = List<int>.from(event.clear.clearedCols);
        _clearActive = true;
        _clearToken++;
      });

      final banner = PetalFxCopy.forClear(
        lines: event.clear.lineCount,
        combo: event.combo,
      );
      if (banner != null) {
        setState(() {
          _bannerText = banner;
          _bannerToken++;
        });
      }
    }
  }

  void _playReject() {
    unawaited(context.read<AppState>().audio.playReject());
    setState(() => _rejectShake = true);
    Future<void>.delayed(PetalMotion.reject, () {
      if (mounted) setState(() => _rejectShake = false);
    });
  }
}

class _GhostPaint {
  const _GhostPaint({required this.piece, required this.target});
  final TrayPiece piece;
  final PlacementTarget target;
}

/// Slim equality so Provider `select` skips unrelated AppState notifies.
class _PlaySnapshot {
  const _PlaySnapshot({
    required this.state,
    required this.bloomPruneMode,
    required this.tutorialSeen,
    required this.statusMessage,
    required this.sectionLinesCleared,
    required this.sectionMaxCombo,
    required this.showingSectionIntro,
    required this.petals,
    required this.advancingSection,
  });

  factory _PlaySnapshot.from(AppState a) => _PlaySnapshot(
    state: a.engine.state,
    bloomPruneMode: a.bloomPruneMode,
    tutorialSeen: a.save?.settings.tutorialSeen ?? true,
    statusMessage: a.statusMessage,
    sectionLinesCleared: a.sectionLinesCleared,
    sectionMaxCombo: a.sectionMaxCombo,
    showingSectionIntro: a.showingSectionIntro,
    petals: a.save?.campaign.petals ?? 0,
    advancingSection: a.advancingSection,
  );

  final GameState state;
  final bool bloomPruneMode;
  final bool tutorialSeen;
  final String? statusMessage;
  final int sectionLinesCleared;
  final int sectionMaxCombo;
  final bool showingSectionIntro;
  final int petals;
  final bool advancingSection;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PlaySnapshot &&
        identical(other.state, state) &&
        other.bloomPruneMode == bloomPruneMode &&
        other.tutorialSeen == tutorialSeen &&
        other.statusMessage == statusMessage &&
        other.sectionLinesCleared == sectionLinesCleared &&
        other.sectionMaxCombo == sectionMaxCombo &&
        other.showingSectionIntro == showingSectionIntro &&
        other.petals == petals &&
        other.advancingSection == advancingSection;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(state),
    bloomPruneMode,
    tutorialSeen,
    sectionLinesCleared,
    sectionMaxCombo,
    showingSectionIntro,
    petals,
    advancingSection,
    statusMessage,
  );
}

class _CompactTutorialTip extends StatelessWidget {
  const _CompactTutorialTip({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Material(
        color: surfaces.panel,
        borderRadius: BorderRadius.circular(PetalRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 18, color: surfaces.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag a piece onto open cells',
                  style: PetalText.caption(context)
                      .copyWith(color: surfaces.onPanel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text('Got it', style: PetalText.caption(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvalidHint extends StatelessWidget {
  const _InvalidHint({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'No fit here',
          style: PetalText.caption(context)
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Clean scoreboard: crown + best (left), pause (right), giant centered score.
class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({
    required this.state,
    required this.linesCleared,
    required this.maxCombo,
    required this.onPause,
    this.compact = false,
  });

  final GameState state;
  final int linesCleared;
  final int maxCombo;
  final VoidCallback onPause;
  final bool compact;

  static const Color _bestGold = Color(0xFFF5C542);

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    String? subtitle;
    if (state.mode == GameMode.campaign && state.levelId != null) {
      final level = CampaignCatalog.level(state.levelId!);
      subtitle = 'Lv ${level.id} · ${level.sections[state.sectionIndex].name}';
    }

    final objectiveChips = <Widget>[];
    if (state.mode == GameMode.campaign && state.levelId != null) {
      final section =
          CampaignCatalog.level(state.levelId!).sections[state.sectionIndex];
      switch (section.objective) {
        case LevelObjective.reachScore:
          objectiveChips.add(
            _StatChip(
              label: 'Goal',
              value: '${state.score}/${section.scoreTarget ?? '?'}',
            ),
          );
        case LevelObjective.clearLines:
          objectiveChips.add(
            _StatChip(
              label: 'Lines',
              value: '$linesCleared/${section.lineTarget ?? '?'}',
            ),
          );
        case LevelObjective.surviveMoves:
          objectiveChips.add(
            _StatChip(
              label: 'Survive',
              value: '${state.movesRemaining ?? 0}',
            ),
          );
        case LevelObjective.clearBoard:
          objectiveChips.add(
            _StatChip(
              label: 'Clear',
              value: '${state.board.filledCount} left',
            ),
          );
        case LevelObjective.comboStreak:
          objectiveChips.add(
            _StatChip(
              label: 'Combo',
              value: '$maxCombo/${section.comboTarget ?? '?'}',
              accent: true,
            ),
          );
      }
    } else if (state.scoreTarget != null) {
      objectiveChips.add(
        _StatChip(label: 'Goal', value: '${state.scoreTarget}'),
      );
    }

    final extras = <Widget>[
      if (state.combo > 1)
        _StatChip(label: 'Combo', value: 'x${state.combo}', accent: true),
      if (state.movesRemaining != null &&
          !(state.mode == GameMode.campaign &&
              state.surviveOnMovesExhausted))
        _StatChip(label: 'Moves', value: '${state.movesRemaining}'),
      ...objectiveChips,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 2 : 4, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: _bestGold, size: 20),
              const SizedBox(width: 5),
              Text(
                '${state.bestScore}',
                style: PetalText.highScore(context),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Pause',
                onPressed: onPause,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.settings_rounded,
                  color: surfaces.onPanel.withValues(alpha: 0.85),
                  size: 26,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            '${state.score}',
            textAlign: TextAlign.center,
            style: PetalText.heroScore(context).copyWith(
              fontSize: compact ? 38 : 44,
              color: surfaces.onPanel,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PetalText.caption(context),
            ),
          ],
          if (extras.isNotEmpty) ...[
            SizedBox(height: compact ? 6 : 8),
            Row(
              children: [
                for (var i = 0; i < extras.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: extras[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? surfaces.accentSoft.withValues(alpha: 0.22)
            : surfaces.hudChip,
        borderRadius: BorderRadius.circular(PetalRadius.md),
        border: Border.all(
          color: accent ? surfaces.accentSoft : surfaces.panelBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: PetalText.scoreLabel(context)),
          Text(
            value,
            style: PetalText.score(
              context,
            ).copyWith(color: accent ? surfaces.accentSoft : surfaces.onPanel),
          ),
        ],
      ),
    );
  }
}

class _BloomBar extends StatelessWidget {
  const _BloomBar({
    required this.bloom,
    required this.active,
    required this.petals,
    required this.onToggle,
    required this.onBuyCharge,
  });
  final BloomState bloom;
  final bool active;
  final int petals;
  final VoidCallback onToggle;
  final VoidCallback onBuyCharge;

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    final progress = bloom.progress / bloom.progressNeeded;
    final can = bloom.canPrune;
    final canBuy =
        petals >= AppConfig.bloomChargePetalCost &&
        bloom.charges < bloom.maxCharges;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: surfaces.panel,
          borderRadius: BorderRadius.circular(PetalRadius.md),
          border: Border.all(color: surfaces.panelBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bloom ${bloom.charges}/${bloom.maxCharges}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PetalText.accent(context),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: surfaces.emptyCell,
                      color: surfaces.accentSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!can)
              TextButton(
                onPressed: canBuy ? onBuyCharge : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  '+1 · ${AppConfig.bloomChargePetalCost}p',
                  style: PetalText.caption(context).copyWith(
                    color: canBuy ? surfaces.accent : surfaces.muted,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: can ? onToggle : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: active ? surfaces.accentSoft : surfaces.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 36),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                active ? 'Pick' : 'Prune',
                style: PetalText.button(context).copyWith(
                  fontSize: 13,
                  color: can ? surfaces.onAccent : surfaces.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppDialogTitle('Paused'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppIconAction(
                  icon: Icons.play_arrow_rounded,
                  label: 'Resume',
                  primary: true,
                  onPressed: app.resumeGame,
                ),
              ),
              Expanded(
                child: AppIconAction(
                  icon: Icons.refresh_rounded,
                  label: 'Restart',
                  onPressed: () => _confirmRestart(context, app),
                ),
              ),
              Expanded(
                child: AppIconAction(
                  icon: Icons.home_rounded,
                  label: 'Menu',
                  onPressed: app.exitToMenu,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestart(BuildContext context, AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restart garden?', style: PetalText.section(ctx)),
        content: Text(
          'Current progress on this board will be lost.',
          style: PetalText.body(ctx),
        ),
        actions: [
          IconButton(
            tooltip: 'Cancel',
            onPressed: () => Navigator.pop(ctx, false),
            icon: const Icon(Icons.close_rounded),
          ),
          IconButton(
            tooltip: 'Restart',
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
    if (ok == true) app.restartGame();
  }
}

class _ConnectionOverlay extends StatelessWidget {
  const _ConnectionOverlay();

  @override
  Widget build(BuildContext context) {
    final surfaces = PetalSurfaces.of(context);
    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: surfaces.accentSoft),
          const SizedBox(height: 10),
          Text('Connection lost', style: PetalText.screenTitle(context)),
          const SizedBox(height: 8),
          Text(
            'Your garden is paused. Progress is kept. Resume when internet returns.',
            textAlign: TextAlign.center,
            style: PetalText.supporting(context),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final st = app.engine.state;
    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppDialogTitle('Garden Full'),
          const SizedBox(height: 12),
          AppStatRow(label: 'Score', value: '${st.score}'),
          AppStatRow(label: 'Best', value: '${st.bestScore}'),
          AppStatRow(label: 'Lines cleared', value: '${st.linesClearedTotal}'),
          const SizedBox(height: 14),
          if (!st.rescueUsed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await app.tryRescue();
                },
                icon: const Icon(Icons.ondemand_video_rounded),
                label: const Text('Watch ad for rescue'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: AppIconAction(
                  icon: Icons.refresh_rounded,
                  label: 'Retry',
                  primary: true,
                  onPressed: app.restartGame,
                ),
              ),
              Expanded(
                child: AppIconAction(
                  icon: Icons.home_rounded,
                  label: 'Menu',
                  onPressed: app.exitToMenu,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelCompleteOverlay extends StatelessWidget {
  const _LevelCompleteOverlay({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final st = app.engine.state;
    final level = CampaignCatalog.level(st.levelId!);
    final hasMore = st.sectionIndex + 1 < level.sections.length;
    final surfaces = PetalSurfaces.of(context);
    final busy = app.advancingSection;
    final message = hasMore
        ? (app.statusMessage == 'Section clear'
            ? app.statusMessage
            : 'Section clear')
        : app.statusMessage;
    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 36,
            color: surfaces.accentSoft,
          ),
          const SizedBox(height: 8),
          AppDialogTitle(hasMore ? 'Section Clear!' : 'Level Complete!'),
          const SizedBox(height: 8),
          AppStatRow(label: 'Section score', value: '${st.score}'),
          if (!hasMore)
            AppStatRow(label: 'Level total', value: '${st.levelRunScore}'),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: PetalText.supporting(context),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy
                  ? null
                  : () {
                      if (hasMore) {
                        app.continueNextSection();
                      } else {
                        app.finishLevelFromUi();
                      }
                    },
              child: Text(hasMore ? 'Next section' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionIntroOverlay extends StatelessWidget {
  const _SectionIntroOverlay({required this.text, required this.onDismiss});
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppDialogTitle('Garden tip'),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: PetalText.body(context),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDismiss,
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
