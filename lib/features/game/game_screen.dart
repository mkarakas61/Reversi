import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/reversi_app.dart' show routeObserver;
import '../../core/game/ai_player.dart';
import '../../core/game/game_settings.dart';
import '../../core/game/reversi_game.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/game_stats.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/game_storage.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/stats_storage.dart';
import '../../core/settings/app_settings.dart';
import '../board/board_move.dart';
import '../../core/theme/board_palette.dart';
import '../board/wood_board.dart';
import '../online/widgets/online_board.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/time_up_overlay.dart';
import 'widgets/cream_shell.dart';
import 'widgets/entry_slide.dart';
import 'widgets/game_top_bar.dart';
import 'widgets/player_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.analytics,
    required this.mode,
    required this.difficulty,
    this.timeLimit = TimeLimit.none,
    this.initialGame,
    required this.onOpenSettings,
  });

  final AnalyticsService analytics;
  final GameMode mode;
  final Difficulty? difficulty;
  final TimeLimit timeLimit;
  final ReversiGame? initialGame;
  final VoidCallback onOpenSettings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  static const Disc _humanDisc = Disc.black;
  static const Disc _aiDisc = Disc.white;

  late ReversiGame _game;
  bool _loggedInitialGame = false;
  bool _aiThinking = false;
  int _aiGeneration = 0;
  final GameStorage _storage = GameStorage();
  final StatsStorage _statsStorage = StatsStorage();
  final Random _random = Random();

  // Lifetime-stats bookkeeping for the current game.
  DateTime _gameStartTime = DateTime.now();
  int _flippedThisGame = 0;

  // Lets the game-over flower celebration find the board's on-screen rect.
  final GlobalKey _boardKey = GlobalKey();

  // Undo history: the game state *before* each applied move/forfeit, newest
  // last. Single-player undo rewinds past the AI's reply to the player's turn.
  final List<ReversiGame> _history = [];

  late final AnimationController _entry;
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;
  bool _celebrated = false;

  int _moveSeq = 0;
  BoardMove? _lastMove;

  Timer? _clock;
  int _ticksLeft = 0;
  bool _blinkOn = true;
  bool _timeUpVisible = false;

  bool get _isSinglePlayer => widget.mode == GameMode.singlePlayer;
  bool get _isTimed => !_isSinglePlayer && widget.timeLimit.seconds != null;
  int get _secondsLeft => (_ticksLeft + 1) ~/ 2;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame ?? ReversiGame.newGame();
    _confettiLeft =
        ConfettiController(duration: const Duration(milliseconds: 2600));
    _confettiRight =
        ConfettiController(duration: const Duration(milliseconds: 2600));
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _entry.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isSinglePlayer) unawaited(_runAiTurn());
        _restartClock();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _entry.forward());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _entry.dispose();
    _clock?.cancel();
    _confettiLeft.dispose();
    _confettiRight.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SoundService.instance.refreshRingerMode();
      SoundService.instance.resumeMusic();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      SoundService.instance.pauseMusic();
      SoundService.instance.stopAllSfx();
    }
  }

  // Switch to the calm in-game track when this screen is shown or returned to.
  @override
  void didPush() => SoundService.instance.playMusic(Music.game);

  @override
  void didPopNext() => SoundService.instance.playMusic(Music.game);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
    if (!_loggedInitialGame) {
      _loggedInitialGame = true;
      widget.analytics.logGameStarted(
        locale: Localizations.localeOf(context).languageCode,
        mode: widget.mode.name,
        difficulty: widget.difficulty?.name,
      );
    }
  }

  void _restartClock() {
    _clock?.cancel();
    _clock = null;
    if (!_isTimed || !mounted || _game.phase != GamePhase.playing) return;
    setState(() {
      _ticksLeft = widget.timeLimit.seconds! * 2;
      _blinkOn = true;
    });
    _clock = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _ticksLeft--;
        _blinkOn = !_blinkOn;
      });
      // Tick once per second through the final ten seconds.
      if (_ticksLeft > 0 && _ticksLeft <= 20 && _ticksLeft.isEven) {
        SoundService.instance.playSfx(Sfx.tick);
      }
      if (_ticksLeft <= 0) {
        _clock?.cancel();
        _clock = null;
        unawaited(_onTimeExpired());
      }
    });
  }

  /// Plays the placement thock, then a flip swoosh if any discs were captured.
  void _playMoveSfx(int flippedCount) {
    SoundService.instance.playSfx(Sfx.place);
    if (flippedCount > 0) {
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        SoundService.instance.playSfx(Sfx.flip);
      });
    }
  }

  /// Undo is available once there is history, the AI is not mid-think, and no
  /// "time's up" overlay is showing.
  bool get _canUndo => _history.isNotEmpty && !_aiThinking && !_timeUpVisible;

  /// Steps the board back. Two-player undoes one ply; single-player rewinds
  /// past the AI's reply to the player's own previous turn.
  void _undo() {
    if (!_canUndo) return;
    _aiGeneration++; // cancel any pending AI turn
    ReversiGame? target;
    if (_isSinglePlayer) {
      while (_history.isNotEmpty) {
        target = _history.removeLast();
        if (target.currentPlayer == _humanDisc) break;
      }
    } else {
      target = _history.removeLast();
    }
    if (target == null) return;
    _confettiLeft.stop();
    _confettiRight.stop();
    setState(() {
      _game = target!;
      _aiThinking = false;
      _celebrated = false;
      _timeUpVisible = false;
      _lastMove = null; // no flip animation on undo
    });
    unawaited(_storage.save(_game, widget.mode, widget.difficulty,
        timeLimit: widget.timeLimit));
    _restartClock();
  }

  Future<void> _onTimeExpired() async {
    SoundService.instance.playSfx(Sfx.timeup);
    setState(() => _timeUpVisible = true);
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _history.add(_game);
    setState(() {
      _timeUpVisible = false;
      _game = _game.forfeitTurn();
    });
    if (_game.phase == GamePhase.gameOver) {
      unawaited(_storage.clear());
      _handleGameEnded();
    } else {
      unawaited(_storage.save(_game, widget.mode, widget.difficulty,
          timeLimit: widget.timeLimit));
      _restartClock();
    }
  }

  void _handleGameEnded() {
    if (_celebrated) return;
    _celebrated = true;
    final winner = _game.winner;
    final celebrate =
        winner != null && (!_isSinglePlayer || winner == _humanDisc);
    if (celebrate) {
      _confettiLeft.play();
      _confettiRight.play();
    }
    final Sfx endSfx;
    if (winner == null) {
      endSfx = Sfx.draw;
    } else if (celebrate) {
      endSfx = Sfx.win;
    } else {
      endSfx = Sfx.lose; // single player, AI won
    }
    SoundService.instance.playSfx(endSfx);
    unawaited(_recordStats());
  }

  /// Updates the lifetime statistics with this game's result. Two-player
  /// games are not recorded — with no AI opponent, win/loss/draw has no
  /// consistent meaning (the human may have played either side).
  Future<void> _recordStats() async {
    if (!_isSinglePlayer) return;
    final blackScore = _game.scoreFor(Disc.black);
    final whiteScore = _game.scoreFor(Disc.white);
    final stats = await _statsStorage.load();
    final updated = stats.recordGame(
      mode: StatsMode.fromDifficulty(widget.difficulty),
      outcome: outcomeFor(_game.winner),
      scoreDiff: (blackScore - whiteScore).abs(),
      flippedDiscs: _flippedThisGame,
      durationSeconds: DateTime.now().difference(_gameStartTime).inSeconds,
    );
    await _statsStorage.save(updated);
  }

  void _play(Position position) {
    if (_timeUpVisible) return;
    if (_isSinglePlayer && (_aiThinking || _game.currentPlayer != _humanDisc)) {
      return;
    }

    final strings = AppStrings.of(context);
    final beforePlayer = _game.currentPlayer;
    final move = _game.play(position);

    if (!move.result.isValid) {
      SoundService.instance.playSfx(Sfx.invalid);
      _showMessage(strings.invalidMove);
      return;
    }

    _playMoveSfx(move.result.flipped.length);
    _flippedThisGame += move.result.flipped.length;
    _history.add(_game);
    _lastMove = BoardMove(
      id: ++_moveSeq,
      placed: position,
      flipped: move.result.flipped.toSet(),
      color: beforePlayer,
    );
    setState(() => _game = move.game);
    widget.analytics.logMove(
      player: beforePlayer,
      position: position,
      flippedCount: move.result.flipped.length,
    );

    if (move.result.passOccurred) {
      final passed = beforePlayer == Disc.black ? Disc.white : Disc.black;
      _showMessage(strings.forcedPass(passed.name));
      widget.analytics.logPass(player: passed);
    }

    if (move.result.gameOver) {
      _clock?.cancel();
      widget.analytics.logGameEnded(
        blackScore: _game.scoreFor(Disc.black),
        whiteScore: _game.scoreFor(Disc.white),
        winner: _game.winner,
      );
      unawaited(_storage.clear());
      _handleGameEnded();
    } else {
      unawaited(_storage.save(_game, widget.mode, widget.difficulty,
          timeLimit: widget.timeLimit));
      _restartClock();
      if (_isSinglePlayer) unawaited(_runAiTurn());
    }
  }

  Future<void> _runAiTurn() async {
    if (!_isSinglePlayer) return;
    final generation = _aiGeneration;
    while (mounted &&
        generation == _aiGeneration &&
        _game.phase == GamePhase.playing &&
        _game.currentPlayer == _aiDisc) {
      if (!_aiThinking) setState(() => _aiThinking = true);
      // Deliberate pause so the AI feels like it is genuinely thinking. The base
      // wait follows the player's chosen game speed (read fresh each move so a
      // mid-game change takes effect immediately), with a small random jitter so
      // moves don't feel mechanical.
      final baseDelay =
          SettingsScope.of(context).settings.gameSpeed.aiDelayMs;
      await Future<void>.delayed(
          Duration(milliseconds: baseDelay + _random.nextInt(500)));
      if (!mounted || generation != _aiGeneration) return;
      final position = await compute(
        _aiMoveTask,
        _AiMoveRequest(_game, widget.difficulty!),
      );
      if (!mounted || generation != _aiGeneration) return;
      final move = _game.play(position);
      if (!move.result.isValid) break;
      _playMoveSfx(move.result.flipped.length);
      _flippedThisGame += move.result.flipped.length;
      _history.add(_game);
      _lastMove = BoardMove(
        id: ++_moveSeq,
        placed: position,
        flipped: move.result.flipped.toSet(),
        color: _aiDisc,
      );
      setState(() => _game = move.game);
      widget.analytics.logMove(
        player: _aiDisc,
        position: position,
        flippedCount: move.result.flipped.length,
      );
      if (move.result.passOccurred) {
        _showMessage(AppStrings.of(context).forcedPass(_humanDisc.name));
        widget.analytics.logPass(player: _humanDisc);
      }
      if (move.result.gameOver) {
        widget.analytics.logGameEnded(
          blackScore: _game.scoreFor(Disc.black),
          whiteScore: _game.scoreFor(Disc.white),
          winner: _game.winner,
        );
        unawaited(_storage.clear());
        _handleGameEnded();
      } else {
        unawaited(_storage.save(_game, widget.mode, widget.difficulty,
            timeLimit: widget.timeLimit));
      }
    }
    if (mounted && generation == _aiGeneration && _aiThinking) {
      setState(() => _aiThinking = false);
    }
  }

  Future<void> _confirmRestart() async {
    final strings = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.restartTitle),
        content: Text(strings.restartBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.restart)),
        ],
      ),
    );
    if (ok == true && mounted) _startNewGame();
  }

  void _startNewGame() {
    _aiGeneration++;
    _celebrated = false;
    _lastMove = null;
    _gameStartTime = DateTime.now();
    _flippedThisGame = 0;
    _history.clear();
    _confettiLeft.stop();
    _confettiRight.stop();
    setState(() {
      _game = ReversiGame.newGame();
      _aiThinking = false;
      _timeUpVisible = false;
    });
    _restartClock();
    unawaited(_storage.clear());
    widget.analytics.logGameStarted(
      locale: Localizations.localeOf(context).languageCode,
      mode: widget.mode.name,
      difficulty: widget.difficulty?.name,
    );
  }

  Future<void> _confirmLeave() async {
    final strings = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.leaveTitle),
        content: Text(strings.leaveBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.leave)),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  ({String? title, String? message, CoinColor? titleCoin}) _resolveGameOver(
      AppStrings strings, AppSettings settings) {
    if (_game.winner == null) {
      return (title: strings.drawTitle, message: null, titleCoin: null);
    }
    if (_isSinglePlayer) {
      if (_game.winner == _humanDisc) {
        return (title: strings.youWon, message: null, titleCoin: settings.yourCoin);
      }
      return (title: null, message: strings.aiLuckyMessage, titleCoin: null);
    }
    final coin = _game.winner == Disc.black
        ? settings.yourCoin
        : settings.opponentCoin;
    return (
      title: strings.winnerTitle(strings.coinColorLabel(coin)),
      message: null,
      titleCoin: coin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = SettingsScope.of(context).settings;
    final validMoves = _game.validMoves;
    final blackScore = _game.scoreFor(Disc.black);
    final whiteScore = _game.scoreFor(Disc.white);
    final gameOver = _game.phase == GamePhase.gameOver;
    final blacksTurn = _game.currentPlayer == Disc.black;

    final blackName = _isSinglePlayer
        ? strings.playerYou
        : strings.coinColorLabel(settings.yourCoin);
    final whiteName = _isSinglePlayer
        ? (widget.difficulty != null
            ? '${strings.playerAi} (${strings.difficultyLabel(widget.difficulty!)})'
            : strings.playerAi)
        : strings.coinColorLabel(settings.opponentCoin);

    final secondsLeft = _secondsLeft.clamp(0, 5999);
    final clockText = _isTimed && !gameOver && _clock != null
        ? '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}'
        : null;
    final clockUrgent = secondsLeft <= 10;
    final clockVisible = !clockUrgent || _blinkOn;

    return PopScope(
      canPop: gameOver || _game.lastMove == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmLeave());
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _entry,
              builder: (context, _) {
                final t = _entry.value;
                final camera =
                    const Interval(0.0, 0.55, curve: Curves.easeOutCubic)
                        .transform(t);
                final topIn =
                    const Interval(0.45, 0.82, curve: Curves.easeOutBack)
                        .transform(t);
                final bottomIn =
                    const Interval(0.55, 0.95, curve: Curves.easeOutBack)
                        .transform(t);

                return CreamShell(
                  t: camera,
                  child: Column(
                    children: [
                      EntrySlide(
                        progress: topIn,
                        beginOffset: const Offset(0, -1.4),
                        child: GameTopBar(
                          onBack: () => Navigator.of(context).maybePop(),
                          onNewGame: _confirmRestart,
                          onSettings: widget.onOpenSettings,
                          onUndo: _undo,
                          canUndo: _canUndo,
                          showSpeed: _isSinglePlayer,
                          gameSpeed: settings.gameSpeed,
                          onSpeedChanged:
                              SettingsScope.of(context).setGameSpeed,
                        ),
                      ),
                      EntrySlide(
                        progress: topIn,
                        beginOffset: const Offset(0, -1.4),
                        child: PlayerCard(
                          side: Disc.white,
                          name: whiteName,
                          mono: whiteName.characters.first.toUpperCase(),
                          score: whiteScore,
                          active: !gameOver && !blacksTurn,
                          statusText: _aiThinking
                              ? strings.aiThinking
                              : strings.toMove,
                          coin: settings.opponentCoin,
                          countdown: (!gameOver && !blacksTurn) ? clockText : null,
                          countdownUrgent: clockUrgent,
                          countdownVisible: clockVisible,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: EntrySlide(
                            progress: camera,
                            beginOffset: const Offset(0, 0.35),
                            child: rendersWithOnlineBoard(settings.board)
                                ? Center(
                                    child: OnlineBoard(
                                      key: _boardKey,
                                      board: _game.board,
                                      validMoves: validMoves,
                                      lastMove: _game.lastMove,
                                      showHints: !gameOver,
                                      onCellTap: _play,
                                      theme: settings.board,
                                      move: _lastMove,
                                    ),
                                  )
                                : WoodBoard(
                                    board: _game.board,
                                    validMoves: validMoves,
                                    lastMove: _game.lastMove,
                                    onCellTap: _play,
                                    theme: settings.board,
                                    blackCoin: settings.yourCoin,
                                    whiteCoin: settings.opponentCoin,
                                    move: _lastMove,
                                  ),
                          ),
                        ),
                      ),
                      EntrySlide(
                        progress: bottomIn,
                        beginOffset: const Offset(0, 1.4),
                        child: PlayerCard(
                          side: Disc.black,
                          name: blackName,
                          mono: blackName.characters.first.toUpperCase(),
                          score: blackScore,
                          active: !gameOver && blacksTurn,
                          statusText: _isSinglePlayer
                              ? strings.yourMove
                              : strings.toMove,
                          coin: settings.yourCoin,
                          countdown: (!gameOver && blacksTurn) ? clockText : null,
                          countdownUrgent: clockUrgent,
                          countdownVisible: clockVisible,
                        ),
                      ),
                      const SizedBox(height: 8),
                      EntrySlide(
                        progress: bottomIn,
                        beginOffset: const Offset(0, 1.4),
                        child: gameOver
                            ? const SizedBox(height: 36)
                            : TurnPill(
                                side: blacksTurn ? Disc.black : Disc.white,
                                text: _aiThinking
                                    ? strings.aiThinking
                                    : (_isSinglePlayer && blacksTurn
                                        ? strings.yourMove
                                        : '${blacksTurn ? blackName : whiteName} ${strings.toMove}'),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
            if (_timeUpVisible) TimeUpOverlay(message: strings.timeUp),
            if (gameOver)
              GameOverOverlay(
                winner: _game.winner,
                isSinglePlayer: _isSinglePlayer,
                humanDisc: _humanDisc,
                blackScore: blackScore,
                whiteScore: whiteScore,
                yourCoin: settings.yourCoin,
                opponentCoin: settings.opponentCoin,
                confettiLeft: _confettiLeft,
                confettiRight: _confettiRight,
                onPlayAgain: _startNewGame,
                onMenu: () => Navigator.of(context).maybePop(),
                strings: _resolveGameOver(strings, settings),
                flowerBoardKey:
                    settings.board == BoardTheme.cicek ? _boardKey : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _AiMoveRequest {
  const _AiMoveRequest(this.game, this.difficulty);
  final ReversiGame game;
  final Difficulty difficulty;
}

Position _aiMoveTask(_AiMoveRequest request) =>
    ReversiAi(difficulty: request.difficulty).chooseMove(request.game);
