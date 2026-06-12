import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:confetti/confetti.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'game/ai_player.dart';
import 'game/app_settings.dart';
import 'game/game_settings.dart';
import 'game/reversi_game.dart';
import 'l10n/app_strings.dart';
import 'screens/main_menu_screen.dart';
import 'screens/settings_screen.dart';
import 'services/analytics_service.dart';
import 'services/game_storage.dart';
import 'services/settings_storage.dart';
import 'theme/game_theme.dart';
import 'widgets/wood_board.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settingsStorage = SettingsStorage();
  final settings = await settingsStorage.load();
  final settingsController = SettingsController(settings, settingsStorage);

  FirebaseAnalytics? firebaseAnalytics;
  try {
    await Firebase.initializeApp();
    firebaseAnalytics = FirebaseAnalytics.instance;
  } catch (_) {
    firebaseAnalytics = null;
  }

  runApp(ReversiApp(
    analytics: AnalyticsService(analytics: firebaseAnalytics),
    settings: settingsController,
  ));
}

class ReversiApp extends StatelessWidget {
  const ReversiApp({
    super.key,
    required this.analytics,
    required this.settings,
  });

  final AnalyticsService analytics;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: settings,
      child: Builder(
        builder: (context) {
          final locale = SettingsScope.of(context).settings.locale;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Reversi',
            locale: locale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (locale != null) {
                return locale;
              }
              if (deviceLocale != null) {
                for (final supported in supportedLocales) {
                  if (supported.languageCode == deviceLocale.languageCode) {
                    return supported;
                  }
                }
              }
              return const Locale('en');
            },
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF7B4A24),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF3A2419),
              fontFamily: 'Roboto',
            ),
            home: Builder(
              builder: (context) => MainMenuScreen(
                onStartGame: (mode, difficulty, timeLimit) {
                  return Navigator.of(context).push(
                    _gameRoute(
                      ReversiHomePage(
                        analytics: analytics,
                        mode: mode,
                        difficulty: difficulty,
                        timeLimit: timeLimit,
                      ),
                    ),
                  );
                },
                onContinueGame: (saved) {
                  return Navigator.of(context).push(
                    _gameRoute(
                      ReversiHomePage(
                        analytics: analytics,
                        mode: saved.mode,
                        difficulty: saved.difficulty,
                        timeLimit: saved.timeLimit,
                        initialGame: saved.game,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pushes the shared settings sheet. Used from both the menu and the game.
Future<void> openSettings(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
  );
}

/// Neutral route into the game. The "camera descends to the table" entrance is
/// choreographed inside [ReversiHomePage] itself, so the route only needs a
/// soft crossfade — the game's first frame is full-screen turquoise, matching
/// the menu background underneath, so there is no visible seam.
PageRoute<void> _gameRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class ReversiHomePage extends StatefulWidget {
  const ReversiHomePage({
    super.key,
    required this.analytics,
    required this.mode,
    required this.difficulty,
    this.timeLimit = TimeLimit.none,
    this.initialGame,
  });

  final AnalyticsService analytics;
  final GameMode mode;
  final Difficulty? difficulty;
  final TimeLimit timeLimit;
  final ReversiGame? initialGame;

  @override
  State<ReversiHomePage> createState() => _ReversiHomePageState();
}

class _ReversiHomePageState extends State<ReversiHomePage>
    with SingleTickerProviderStateMixin {
  static const Disc _humanDisc = Disc.black;
  static const Disc _aiDisc = Disc.white;

  late ReversiGame _game;
  bool _loggedInitialGame = false;
  bool _aiThinking = false;
  int _aiGeneration = 0;
  final GameStorage _storage = GameStorage();
  final Random _random = Random();

  // "Camera descends to the table" entrance. 0 = full-screen turquoise with
  // everything off-stage; 1 = settled game layout. See [_CreamShell] and the
  // staggered [_EntrySlide] panels in build().
  late final AnimationController _entry;

  // Game-over celebration cannons, fired from the two bottom corners.
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;
  bool _celebrated = false;

  // Describes the most recent placement so the board can play its flip
  // animation. `id` increments per move; the board animates when it changes.
  int _moveSeq = 0;
  BoardMove? _lastMove;

  // Per-move chess clock for timed two-player games. Ticks every half second
  // so the last-10-seconds warning can blink at 2 Hz.
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
    // Let the entrance settle before play begins: the AI starts thinking (a
    // restored game may have been saved mid-AI-turn) and the move clock starts
    // counting only once the table is in place.
    _entry.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isSinglePlayer) {
          unawaited(_runAiTurn());
        }
        _restartClock();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _entry.forward());
  }

  @override
  void dispose() {
    _entry.dispose();
    _clock?.cancel();
    _confettiLeft.dispose();
    _confettiRight.dispose();
    super.dispose();
  }

  /// (Re)starts the move clock for the player to move. No-op in untimed or
  /// single-player games; cancels any previous countdown.
  void _restartClock() {
    _clock?.cancel();
    _clock = null;
    if (!_isTimed || !mounted || _game.phase != GamePhase.playing) {
      return;
    }
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
      if (_ticksLeft <= 0) {
        _clock?.cancel();
        _clock = null;
        unawaited(_onTimeExpired());
      }
    });
  }

  /// The mover's clock hit zero: show the "time's up" notice for three
  /// seconds, then hand the turn to the opponent and restart the clock.
  Future<void> _onTimeExpired() async {
    setState(() => _timeUpVisible = true);
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
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

  /// Fires once when the game ends. Confetti only for a celebratory result:
  /// any winner in two-player, or the human winning in single player.
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loggedInitialGame) {
      _loggedInitialGame = true;
      widget.analytics.logGameStarted(
        locale: Localizations.localeOf(context).languageCode,
        mode: widget.mode.name,
        difficulty: widget.difficulty?.name,
      );
    }
  }

  void _play(Position position) {
    if (_timeUpVisible) {
      return; // turn is being forfeited; ignore board taps
    }
    if (_isSinglePlayer && (_aiThinking || _game.currentPlayer != _humanDisc)) {
      return;
    }

    final strings = AppStrings.of(context);
    final beforePlayer = _game.currentPlayer;
    final move = _game.play(position);

    if (!move.result.isValid) {
      _showMessage(strings.invalidMove);
      return;
    }

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
      if (_isSinglePlayer) {
        unawaited(_runAiTurn());
      }
    }
  }

  Future<void> _runAiTurn() async {
    if (!_isSinglePlayer) {
      return;
    }
    final generation = _aiGeneration;
    while (mounted &&
        generation == _aiGeneration &&
        _game.phase == GamePhase.playing &&
        _game.currentPlayer == _aiDisc) {
      if (!_aiThinking) {
        setState(() => _aiThinking = true);
      }
      // Deliberate pause so the AI feels like it is genuinely thinking — at
      // least three seconds before every move.
      await Future<void>.delayed(
        Duration(milliseconds: 3000 + _random.nextInt(800)),
      );
      if (!mounted || generation != _aiGeneration) {
        return;
      }
      final position = await compute(
        _aiMoveTask,
        _AiMoveRequest(_game, widget.difficulty!),
      );
      if (!mounted || generation != _aiGeneration) {
        return;
      }
      final move = _game.play(position);
      if (!move.result.isValid) {
        break;
      }
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
    final shouldRestart = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.restartTitle),
          content: Text(strings.restartBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.restart),
            ),
          ],
        );
      },
    );

    if (shouldRestart == true && mounted) {
      _startNewGame();
    }
  }

  /// Resets to a fresh board and clears the celebration. Shared by the top-bar
  /// "new game" action and the game-over "Play Again" button.
  void _startNewGame() {
    _aiGeneration++;
    _celebrated = false;
    _lastMove = null;
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
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.leaveTitle),
          content: Text(strings.leaveBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.leave),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

    // Bottom card = black side ("Sen" / coin name). Top card = white side
    // (AI / coin name). In two-player the names follow the chosen coin colour;
    // in single player the AI shows its difficulty in parentheses.
    final blackName = _isSinglePlayer
        ? strings.playerYou
        : strings.coinColorLabel(settings.yourCoin);
    final whiteName = _isSinglePlayer
        ? (widget.difficulty != null
            ? '${strings.playerAi} (${strings.difficultyLabel(widget.difficulty!)})'
            : strings.playerAi)
        : strings.coinColorLabel(settings.opponentCoin);

    final whiteActive = !gameOver && !blacksTurn;
    final blackActive = !gameOver && blacksTurn;

    String statusFor(bool isBlack) {
      if (_aiThinking && !isBlack) return strings.aiThinking;
      if (_isSinglePlayer && isBlack) return strings.yourMove;
      return strings.toMove;
    }

    // Move clock shown in the centre of the active player's card.
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
            // Camera descent: turquoise band shrinks and the board rises, in
            // lockstep. Panels then settle in from top and bottom.
            final camera =
                const Interval(0.0, 0.55, curve: Curves.easeOutCubic)
                    .transform(t);
            final topIn = const Interval(0.45, 0.82, curve: Curves.easeOutBack)
                .transform(t);
            final bottomIn =
                const Interval(0.55, 0.95, curve: Curves.easeOutBack)
                    .transform(t);

            return _CreamShell(
              t: camera,
              child: Column(
                children: [
                  _EntrySlide(
                    progress: topIn,
                    beginOffset: const Offset(0, -1.4),
                    child: _GameTopBar(
                      onBack: () => Navigator.of(context).maybePop(),
                      onNewGame: _confirmRestart,
                      onSettings: () => openSettings(context),
                    ),
                  ),
                  _EntrySlide(
                    progress: topIn,
                    beginOffset: const Offset(0, -1.4),
                    child: _PlayerCard(
                      side: Disc.white,
                      name: whiteName,
                      mono: whiteName.characters.first.toUpperCase(),
                      score: whiteScore,
                      active: whiteActive,
                      statusText: statusFor(false),
                      coin: settings.opponentCoin,
                      countdown: whiteActive ? clockText : null,
                      countdownUrgent: clockUrgent,
                      countdownVisible: clockVisible,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _EntrySlide(
                        progress: camera,
                        beginOffset: const Offset(0, 0.35),
                        child: WoodBoard(
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
                  _EntrySlide(
                    progress: bottomIn,
                    beginOffset: const Offset(0, 1.4),
                    child: _PlayerCard(
                      side: Disc.black,
                      name: blackName,
                      mono: blackName.characters.first.toUpperCase(),
                      score: blackScore,
                      active: blackActive,
                      statusText: statusFor(true),
                      coin: settings.yourCoin,
                      countdown: blackActive ? clockText : null,
                      countdownUrgent: clockUrgent,
                      countdownVisible: clockVisible,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // When the game ends, the full-screen overlay takes over, so
                  // the pill slot just holds its height to avoid a layout jump.
                  _EntrySlide(
                    progress: bottomIn,
                    beginOffset: const Offset(0, 1.4),
                    child: gameOver
                        ? const SizedBox(height: 36)
                        : _TurnPill(
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
            if (_timeUpVisible) _TimeUpOverlay(message: strings.timeUp),
            if (gameOver)
              _GameOverOverlay(
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
              ),
          ],
        ),
      ),
    );
  }
}

/// Slides [child] in from [beginOffset] (a fraction of the child's own size)
/// to its resting place as [progress] runs 0→1, fading in alongside. Used for
/// the staggered panel entrance. [progress] may briefly overshoot 1 (easeOut
/// Back) for a gentle settle; opacity is clamped.
class _EntrySlide extends StatelessWidget {
  const _EntrySlide({
    required this.progress,
    required this.beginOffset,
    required this.child,
  });

  final double progress;
  final Offset beginOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offset = Offset.lerp(beginOffset, Offset.zero, progress)!;
    return FractionalTranslation(
      translation: offset,
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: child,
      ),
    );
  }
}

/// Cream gradient background with the turquoise diagonal banner at the top.
///
/// [t] drives the "camera descent": at 0 the turquoise band fills the whole
/// screen as a plain rectangle (seamlessly matching the menu background); at 1
/// it has shrunk to the 210px diagonal strip, revealing the cream table
/// surface beneath.
class _CreamShell extends StatelessWidget {
  const _CreamShell({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: creamShellGradient),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fullH = MediaQuery.sizeOf(context).height;
                final bandH = lerpDouble(fullH, 210, t)!;
                return ClipPath(
                  clipper: _BannerClipper(t),
                  child: SizedBox(
                    height: bandH,
                    width: double.infinity,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(gradient: bannerGradient),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerClipper extends CustomClipper<Path> {
  const _BannerClipper(this.t);

  final double t;

  @override
  Path getClip(Size size) {
    // At t=1: polygon(0 0, 100% 0, 100% 60%, 0 80%). At t=0 the bottom corners
    // drop to the full height, so the band clips to a plain rectangle.
    final brY = lerpDouble(size.height, size.height * 0.60, t)!;
    final blY = lerpDouble(size.height, size.height * 0.80, t)!;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, brY)
      ..lineTo(0, blY)
      ..close();
  }

  @override
  bool shouldReclip(_BannerClipper old) => old.t != t;
}

/// White skeuomorphic pill button used in the game top bar.
class _BarButton extends StatelessWidget {
  const _BarButton({required this.child, required this.onTap, this.tooltip});

  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), offset: Offset(0, 3)),
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Container(
            height: 38,
            constraints: const BoxConstraints(minWidth: 38),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: GameColors.onAccent,
              ),
              child: IconTheme(
                data: const IconThemeData(color: GameColors.onAccent, size: 20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _GameTopBar extends StatelessWidget {
  const _GameTopBar({
    required this.onBack,
    required this.onNewGame,
    required this.onSettings,
  });

  final VoidCallback onBack;
  final VoidCallback onNewGame;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SizedBox(
      height: 46,
      child: Row(
        children: [
          _BarButton(
            tooltip: strings.back,
            onTap: onBack,
            child: const Icon(Icons.chevron_left, size: 22),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  strings.appTitle.toUpperCase(),
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 23,
                    letterSpacing: 3.4,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Color(0x1F000000), offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BarButton(
                tooltip: strings.settings,
                onTap: onSettings,
                child: const Icon(Icons.settings, size: 19),
              ),
              const SizedBox(width: 9),
              _BarButton(
                tooltip: strings.newGame,
                onTap: onNewGame,
                child: const Icon(Icons.refresh, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.side,
    required this.name,
    required this.mono,
    required this.score,
    required this.active,
    required this.statusText,
    required this.coin,
    this.countdown,
    this.countdownUrgent = false,
    this.countdownVisible = true,
  });

  final Disc side;
  final String name;
  final String mono;
  final int score;
  final bool active;
  final String statusText;

  /// This side's chosen coin colour — drives the avatar and the score disc.
  final CoinColor coin;

  /// Move-clock text ("0:27") shown in the centre of the card while it is this
  /// side's turn in a timed game; `null` hides the clock.
  final String? countdown;

  /// Last ten seconds: the clock turns red and blinks via [countdownVisible].
  final bool countdownUrgent;
  final bool countdownVisible;

  @override
  Widget build(BuildContext context) {
    final isDark = side == Disc.black;
    final accent = isDark ? GameColors.accent : GameColors.accent2;
    final palette = coinPalettes[coin]!;
    // Light coins (white) need dark text on the avatar to stay legible.
    final monoColor =
        ThemeData.estimateBrightnessForColor(palette.faceMid) == Brightness.light
            ? GameColors.ink
            : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        // Always reserve the border so toggling active doesn't resize the
        // card (which would otherwise nudge the board between turns).
        border: Border.all(
          color: active ? accent : Colors.transparent,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, 6)),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (countdown != null)
            AnimatedOpacity(
              opacity: countdownVisible ? 1.0 : 0.15,
              duration: const Duration(milliseconds: 220),
              child: Text(
                countdown!,
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1,
                  color: countdownUrgent
                      ? const Color(0xFFE0312B)
                      : (side == Disc.black
                          ? GameColors.accent
                          : GameColors.accent2),
                ),
              ),
            ),
          Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.faceTop, palette.faceBottom],
              ),
              border: Border.all(color: const Color(0x14000000), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              mono,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: monoColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: GameColors.ink,
                  ),
                ),
                SizedBox(
                  height: 15,
                  child: Text(
                    active ? statusText.toLowerCase() : '',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ScoreChip(coin: coin),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: Text(
              '$score',
              textAlign: TextAlign.right,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 28,
                height: 1,
                color: GameColors.ink,
              ),
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.coin});

  final CoinColor coin;

  @override
  Widget build(BuildContext context) {
    final palette = coinPalettes[coin]!;
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [palette.faceTop, palette.faceBottom],
          stops: const [0.0, 0.72],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 2, spreadRadius: -1),
        ],
      ),
    );
  }
}

class _TurnPill extends StatelessWidget {
  const _TurnPill({required this.side, required this.text});

  final Disc side;
  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = side == Disc.black ? GameColors.accent : GameColors.accent2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), offset: Offset(0, 4)),
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 4, spreadRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: GameColors.onAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiMoveRequest {
  const _AiMoveRequest(this.game, this.difficulty);

  final ReversiGame game;
  final Difficulty difficulty;
}

// Runs in a background isolate via compute() so the deeper hard-mode
// searches never block the UI thread.
Position _aiMoveTask(_AiMoveRequest request) {
  return ReversiAi(difficulty: request.difficulty).chooseMove(request.game);
}

/// Brief "time's up" notice for timed games: a light scrim that blocks input
/// and a centred card. Shown for three seconds before the turn is forfeited.
class _TimeUpOverlay extends StatelessWidget {
  const _TimeUpOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const ColoredBox(color: Color(0x42000000)),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(
                scale: 0.85 + 0.15 * v.clamp(0.0, 1.0),
                child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      offset: Offset(0, 14),
                      blurRadius: 34,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_off_outlined,
                      size: 38,
                      color: Color(0xFFE0312B),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        height: 1.25,
                        color: GameColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen end-of-game celebration: a dimmed scrim, two confetti cannons
/// firing from the bottom corners (for celebratory results), and a centred card
/// with the result and the Play Again / Main Menu choices.
class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.winner,
    required this.isSinglePlayer,
    required this.humanDisc,
    required this.blackScore,
    required this.whiteScore,
    required this.yourCoin,
    required this.opponentCoin,
    required this.confettiLeft,
    required this.confettiRight,
    required this.onPlayAgain,
    required this.onMenu,
  });

  final Disc? winner;
  final bool isSinglePlayer;
  final Disc humanDisc;
  final int blackScore;
  final int whiteScore;
  final CoinColor yourCoin;
  final CoinColor opponentCoin;
  final ConfettiController confettiLeft;
  final ConfettiController confettiRight;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    // Resolve the scenario.
    String? title;
    String? message;
    CoinColor? titleCoin;
    if (winner == null) {
      title = strings.drawTitle;
    } else if (isSinglePlayer) {
      if (winner == humanDisc) {
        title = strings.youWon;
        titleCoin = yourCoin;
      } else {
        // AI win — apologetic message, no celebration.
        message = strings.aiLuckyMessage;
      }
    } else {
      final coin = winner == Disc.black ? yourCoin : opponentCoin;
      title = strings.winnerTitle(strings.coinColorLabel(coin));
      titleCoin = coin;
    }

    Color titleColor = GameColors.ink;
    if (titleCoin != null) {
      final mid = coinPalettes[titleCoin]!.faceMid;
      titleColor =
          ThemeData.estimateBrightnessForColor(mid) == Brightness.light
              ? GameColors.ink
              : mid;
    }

    final confettiColors = <Color>[
      GameColors.accent,
      GameColors.accent2,
      const Color(0xFFFFC83D),
      Colors.white,
      coinPalettes[yourCoin]!.faceMid,
      coinPalettes[opponentCoin]!.faceMid,
    ];

    return Positioned.fill(
      child: Stack(
        children: [
          // Scrim — also absorbs taps so the board can't be touched.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const ColoredBox(color: Color(0x6B000000)),
            ),
          ),
          // Two explosive bursts from the upper corners spray particles in
          // every direction, then gravity rains them down across the whole
          // screen for a full-coverage celebration.
          Align(
            alignment: const Alignment(-0.9, -0.75),
            child: ConfettiWidget(
              confettiController: confettiLeft,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 34,
              minBlastForce: 16,
              maxBlastForce: 48,
              gravity: 0.22,
              particleDrag: 0.04,
              minimumSize: const Size(9, 7),
              maximumSize: const Size(16, 11),
              colors: confettiColors,
            ),
          ),
          Align(
            alignment: const Alignment(0.9, -0.75),
            child: ConfettiWidget(
              confettiController: confettiRight,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 34,
              minBlastForce: 16,
              maxBlastForce: 48,
              gravity: 0.22,
              particleDrag: 0.04,
              minimumSize: const Size(9, 7),
              maximumSize: const Size(16, 11),
              colors: confettiColors,
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.scale(
                scale: 0.85 + 0.15 * v.clamp(0.0, 1.0),
                child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
              ),
              child: _GameOverCard(
                title: title,
                titleColor: titleColor,
                message: message,
                yourCoin: yourCoin,
                opponentCoin: opponentCoin,
                blackScore: blackScore,
                whiteScore: whiteScore,
                onPlayAgain: onPlayAgain,
                onMenu: onMenu,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverCard extends StatelessWidget {
  const _GameOverCard({
    required this.title,
    required this.titleColor,
    required this.message,
    required this.yourCoin,
    required this.opponentCoin,
    required this.blackScore,
    required this.whiteScore,
    required this.onPlayAgain,
    required this.onMenu,
  });

  final String? title;
  final Color titleColor;
  final String? message;
  final CoinColor yourCoin;
  final CoinColor opponentCoin;
  final int blackScore;
  final int whiteScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 16),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 26,
                height: 1.1,
                color: titleColor,
              ),
            ),
          if (message != null)
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.35,
                color: GameColors.inkSoft,
              ),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScoreBadge(coin: yourCoin, score: blackScore),
              const SizedBox(width: 10),
              const Text(
                '–',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: GameColors.inkSoft,
                ),
              ),
              const SizedBox(width: 10),
              _ScoreBadge(coin: opponentCoin, score: whiteScore),
            ],
          ),
          const SizedBox(height: 22),
          _GameOverButton(
            label: strings.playAgain,
            icon: Icons.replay_rounded,
            primary: true,
            onTap: onPlayAgain,
          ),
          const SizedBox(height: 12),
          _GameOverButton(
            label: strings.mainMenu,
            icon: Icons.home_rounded,
            primary: false,
            onTap: onMenu,
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.coin, required this.score});

  final CoinColor coin;
  final int score;

  @override
  Widget build(BuildContext context) {
    final palette = coinPalettes[coin]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [palette.faceTop, palette.faceBottom],
              stops: const [0.0, 0.72],
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x33000000), blurRadius: 2, spreadRadius: -1),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$score',
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 26,
            height: 1,
            color: GameColors.ink,
          ),
        ),
      ],
    );
  }
}

class _GameOverButton extends StatelessWidget {
  const _GameOverButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : GameColors.onAccent;
    final bg = primary ? GameColors.accent2 : const Color(0xFFF0ECE3);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: primary
              ? const [
                  BoxShadow(color: Color(0x1F000000), offset: Offset(0, 4)),
                  BoxShadow(
                      color: Color(0x24000000),
                      offset: Offset(0, 8),
                      blurRadius: 16),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 21),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
