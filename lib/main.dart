import 'dart:async';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'game/ai_player.dart';
import 'game/game_settings.dart';
import 'game/reversi_game.dart';
import 'l10n/app_strings.dart';
import 'screens/main_menu_screen.dart';
import 'services/analytics_service.dart';
import 'services/game_storage.dart';
import 'theme/game_theme.dart';
import 'widgets/wood_board.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FirebaseAnalytics? firebaseAnalytics;
  try {
    await Firebase.initializeApp();
    firebaseAnalytics = FirebaseAnalytics.instance;
  } catch (_) {
    firebaseAnalytics = null;
  }

  runApp(ReversiApp(analytics: AnalyticsService(analytics: firebaseAnalytics)));
}

class ReversiApp extends StatefulWidget {
  const ReversiApp({super.key, required this.analytics});

  final AnalyticsService analytics;

  @override
  State<ReversiApp> createState() => _ReversiAppState();
}

class _ReversiAppState extends State<ReversiApp> {
  Locale? _locale;

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
    widget.analytics.logLanguageChanged(locale: locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reversi',
      locale: _locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (_locale != null) {
          return _locale;
        }
        if (deviceLocale != null) {
          for (final locale in supportedLocales) {
            if (locale.languageCode == deviceLocale.languageCode) {
              return locale;
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
          onLocaleChanged: _setLocale,
          onStartGame: (mode, difficulty) {
            return Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReversiHomePage(
                  analytics: widget.analytics,
                  onLocaleChanged: _setLocale,
                  mode: mode,
                  difficulty: difficulty,
                ),
              ),
            );
          },
          onContinueGame: (saved) {
            return Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReversiHomePage(
                  analytics: widget.analytics,
                  onLocaleChanged: _setLocale,
                  mode: saved.mode,
                  difficulty: saved.difficulty,
                  initialGame: saved.game,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ReversiHomePage extends StatefulWidget {
  const ReversiHomePage({
    super.key,
    required this.analytics,
    required this.onLocaleChanged,
    required this.mode,
    required this.difficulty,
    this.initialGame,
  });

  final AnalyticsService analytics;
  final ValueChanged<Locale> onLocaleChanged;
  final GameMode mode;
  final Difficulty? difficulty;
  final ReversiGame? initialGame;

  @override
  State<ReversiHomePage> createState() => _ReversiHomePageState();
}

class _ReversiHomePageState extends State<ReversiHomePage> {
  static const Disc _humanDisc = Disc.black;
  static const Disc _aiDisc = Disc.white;

  late ReversiGame _game;
  bool _loggedInitialGame = false;
  bool _aiThinking = false;
  int _aiGeneration = 0;
  final GameStorage _storage = GameStorage();
  final Random _random = Random();

  bool get _isSinglePlayer => widget.mode == GameMode.singlePlayer;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame ?? ReversiGame.newGame();
    if (_isSinglePlayer) {
      // A restored game may have been saved while it was the AI's turn.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_runAiTurn());
      });
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
      widget.analytics.logGameEnded(
        blackScore: _game.scoreFor(Disc.black),
        whiteScore: _game.scoreFor(Disc.white),
        winner: _game.winner,
      );
      unawaited(_storage.clear());
    } else {
      unawaited(_storage.save(_game, widget.mode, widget.difficulty));
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
      await Future<void>.delayed(
        Duration(milliseconds: 400 + _random.nextInt(300)),
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
      } else {
        unawaited(_storage.save(_game, widget.mode, widget.difficulty));
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

    if (shouldRestart == true) {
      if (!mounted) {
        return;
      }
      _aiGeneration++;
      setState(() {
        _game = ReversiGame.newGame();
        _aiThinking = false;
      });
      unawaited(_storage.clear());
      widget.analytics.logGameStarted(
        locale: Localizations.localeOf(context).languageCode,
        mode: widget.mode.name,
        difficulty: widget.difficulty?.name,
      );
    }
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
    final validMoves = _game.validMoves;
    final blackScore = _game.scoreFor(Disc.black);
    final whiteScore = _game.scoreFor(Disc.white);
    final gameOver = _game.phase == GamePhase.gameOver;
    final blacksTurn = _game.currentPlayer == Disc.black;

    // Bottom card = black ("Sen"/Siyah, turquoise). Top card = white
    // ("Aria"/Beyaz, orange).
    final blackName = _isSinglePlayer ? strings.playerYou : strings.black;
    final whiteName = _isSinglePlayer ? strings.playerAi : strings.white;

    final whiteActive = !gameOver && !blacksTurn;
    final blackActive = !gameOver && blacksTurn;

    String statusFor(bool isBlack) {
      if (_aiThinking && !isBlack) return strings.aiThinking;
      if (_isSinglePlayer && isBlack) return strings.yourMove;
      return strings.toMove;
    }

    return PopScope(
      canPop: gameOver || _game.lastMove == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmLeave());
      },
      child: Scaffold(
        body: _CreamShell(
          child: Column(
            children: [
              _GameTopBar(
                onBack: () => Navigator.of(context).maybePop(),
                onNewGame: _confirmRestart,
                onLocaleChanged: widget.onLocaleChanged,
              ),
              _PlayerCard(
                side: Disc.white,
                name: whiteName,
                mono: whiteName.characters.first.toUpperCase(),
                score: whiteScore,
                active: whiteActive,
                statusText: statusFor(false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: WoodBoard(
                    board: _game.board,
                    validMoves: validMoves,
                    lastMove: _game.lastMove,
                    onCellTap: _play,
                  ),
                ),
              ),
              _PlayerCard(
                side: Disc.black,
                name: blackName,
                mono: blackName.characters.first.toUpperCase(),
                score: blackScore,
                active: blackActive,
                statusText: statusFor(true),
              ),
              const SizedBox(height: 8),
              if (gameOver)
                _GameOverBanner(game: _game, isSinglePlayer: _isSinglePlayer)
              else
                _TurnPill(
                  side: blacksTurn ? Disc.black : Disc.white,
                  text: _aiThinking
                      ? strings.aiThinking
                      : (_isSinglePlayer && blacksTurn
                          ? strings.yourMove
                          : '${blacksTurn ? blackName : whiteName} ${strings.toMove}'),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cream gradient background with the turquoise diagonal banner at the top.
class _CreamShell extends StatelessWidget {
  const _CreamShell({required this.child});

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
            height: 210,
            child: ClipPath(
              clipper: _BannerClipper(),
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: bannerGradient),
              ),
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
  @override
  Path getClip(Size size) {
    // polygon(0 0, 100% 0, 100% 60%, 0 80%)
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.60)
      ..lineTo(0, size.height * 0.80)
      ..close();
  }

  @override
  bool shouldReclip(_BannerClipper old) => false;
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
    required this.onLocaleChanged,
  });

  final VoidCallback onBack;
  final VoidCallback onNewGame;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final lang = Localizations.localeOf(context).languageCode;

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
                tooltip: strings.language,
                onTap: () => onLocaleChanged(
                  Locale(lang == 'tr' ? 'en' : 'tr'),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public, size: 18),
                    const SizedBox(width: 5),
                    Text(lang.toUpperCase()),
                  ],
                ),
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
  });

  final Disc side;
  final String name;
  final String mono;
  final int score;
  final bool active;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final isDark = side == Disc.black;
    final accent = isDark ? GameColors.accent : GameColors.accent2;

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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        GameColors.avatarDarkTop,
                        GameColors.avatarDarkBottom,
                      ]
                    : const [
                        GameColors.avatarLightTop,
                        GameColors.avatarLightBottom,
                      ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              mono,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
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
          _ScoreChip(isDark: isDark),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '$score',
              textAlign: TextAlign.right,
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
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: isDark
              ? const [GameColors.chipDarkTop, GameColors.chipDarkBottom]
              : const [GameColors.chipLightTop, GameColors.chipLightBottom],
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

class _GameOverBanner extends StatelessWidget {
  const _GameOverBanner({required this.game, required this.isSinglePlayer});

  final ReversiGame game;
  final bool isSinglePlayer;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final winner = game.winner;
    final String text;
    if (winner == null) {
      text = strings.draw;
    } else {
      final name = isSinglePlayer
          ? (winner == Disc.black ? strings.playerYou : strings.playerAi)
          : (winner == Disc.black ? strings.black : strings.white);
      text = strings.winnerNamed(name);
    }
    final accent =
        winner == Disc.white ? GameColors.accent2 : GameColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Baloo2',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}
