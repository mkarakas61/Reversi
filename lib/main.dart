import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'game/game_settings.dart';
import 'game/reversi_game.dart';
import 'l10n/app_strings.dart';
import 'screens/main_menu_screen.dart';
import 'services/analytics_service.dart';

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
            Navigator.of(context).push(
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
  });

  final AnalyticsService analytics;
  final ValueChanged<Locale> onLocaleChanged;
  final GameMode mode;
  final Difficulty? difficulty;

  @override
  State<ReversiHomePage> createState() => _ReversiHomePageState();
}

class _ReversiHomePageState extends State<ReversiHomePage> {
  late ReversiGame _game;
  bool _loggedInitialGame = false;

  @override
  void initState() {
    super.initState();
    _game = ReversiGame.newGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loggedInitialGame) {
      _loggedInitialGame = true;
      widget.analytics.logGameStarted(
        locale: Localizations.localeOf(context).languageCode,
      );
    }
  }

  void _play(Position position) {
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
      setState(() => _game = ReversiGame.newGame());
      widget.analytics.logGameStarted(
        locale: Localizations.localeOf(context).languageCode,
      );
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

    return Scaffold(
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A2D1D), Color(0xFF251711)],
            ),
          ),
          child: Column(
            children: [
              _TopBar(
                mode: widget.mode,
                difficulty: widget.difficulty,
                onNewGame: _confirmRestart,
                onLocaleChanged: widget.onLocaleChanged,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _StatusPanel(
                  game: _game,
                  blackScore: blackScore,
                  whiteScore: whiteScore,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ReversiBoard(
                      board: _game.board,
                      validMoves: validMoves,
                      lastMove: _game.lastMove,
                      onCellTap: _play,
                    ),
                  ),
                ),
              ),
              if (_game.phase == GamePhase.gameOver)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: _GameOverBanner(game: _game),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Text(
                    '${strings.validMoveHint}: ${validMoves.length}',
                    style: const TextStyle(
                      color: Color(0xFFE9D8B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.difficulty,
    required this.onNewGame,
    required this.onLocaleChanged,
  });

  final GameMode mode;
  final Difficulty? difficulty;
  final VoidCallback onNewGame;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final modeLabel = mode == GameMode.twoPlayer
        ? strings.modeTwoPlayer
        : strings.modeSinglePlayer(strings.difficultyLabel(difficulty!));

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: strings.back,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFF1D0)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.appTitle,
                  style: const TextStyle(
                    color: Color(0xFFFFF1D0),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  modeLabel,
                  style: const TextStyle(
                    color: Color(0xFFE9D8B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<Locale>(
            tooltip: strings.language,
            icon: const Icon(Icons.language, color: Color(0xFFFFF1D0)),
            onSelected: onLocaleChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('tr'), child: Text('Türkçe')),
              PopupMenuItem(value: Locale('en'), child: Text('English')),
            ],
          ),
          IconButton(
            tooltip: strings.newGame,
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh, color: Color(0xFFFFF1D0)),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.game,
    required this.blackScore,
    required this.whiteScore,
  });

  final ReversiGame game;
  final int blackScore;
  final int whiteScore;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final currentPlayerName = game.currentPlayer.name;
    final title = game.phase == GamePhase.gameOver
        ? strings.gameOver
        : strings.turn(currentPlayerName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5C58F),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2A1710),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _ScorePill(
            label: strings.black,
            score: blackScore,
            disc: Disc.black,
          ),
          const SizedBox(width: 8),
          _ScorePill(
            label: strings.white,
            score: whiteScore,
            disc: Disc.white,
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.score,
    required this.disc,
  });

  final String label;
  final int score;
  final Disc disc;

  @override
  Widget build(BuildContext context) {
    final isBlack = disc == Disc.black;
    return Container(
      constraints: const BoxConstraints(minWidth: 68),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isBlack ? const Color(0xFF161616) : const Color(0xFFF8F0DD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isBlack ? Colors.white : const Color(0xFF2A1710),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: isBlack ? Colors.white : const Color(0xFF2A1710),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ReversiBoard extends StatelessWidget {
  const ReversiBoard({
    super.key,
    required this.board,
    required this.validMoves,
    required this.lastMove,
    required this.onCellTap,
  });

  final List<List<Disc?>> board;
  final Set<Position> validMoves;
  final Position? lastMove;
  final ValueChanged<Position> onCellTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF6B3F21),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF26150D), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              offset: Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ReversiGame.size,
          ),
          itemCount: ReversiGame.size * ReversiGame.size,
          itemBuilder: (context, index) {
            final row = index ~/ ReversiGame.size;
            final col = index % ReversiGame.size;
            final position = Position(row, col);
            return _BoardCell(
              disc: board[row][col],
              isValidMove: validMoves.contains(position),
              isLastMove: lastMove == position,
              onTap: () => onCellTap(position),
            );
          },
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.disc,
    required this.isValidMove,
    required this.isLastMove,
    required this.onTap,
  });

  final Disc? disc;
  final bool isValidMove;
  final bool isLastMove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Semantics(
      label: isValidMove
          ? strings.validMoveHint
          : isLastMove
              ? strings.lastMoveHint
              : null,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            color: const Color(0xFF1F7A45),
            border: Border.all(color: const Color(0xFF0E3E25), width: 0.8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLastMove)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166).withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              if (isValidMove && disc == null)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D0).withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: disc == null
                    ? const SizedBox.shrink()
                    : _DiscView(key: ValueKey(disc), disc: disc!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscView extends StatelessWidget {
  const _DiscView({super.key, required this.disc});

  final Disc disc;

  @override
  Widget build(BuildContext context) {
    final isBlack = disc == Disc.black;
    return FractionallySizedBox(
      widthFactor: 0.78,
      heightFactor: 0.78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.28, -0.36),
            radius: 0.88,
            colors: isBlack
                ? const [Color(0xFF555555), Color(0xFF080808)]
                : const [Colors.white, Color(0xFFD8D0BF)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x77000000),
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverBanner extends StatelessWidget {
  const _GameOverBanner({required this.game});

  final ReversiGame game;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final winner = game.winner;
    final text = winner == null ? strings.draw : strings.winner(winner.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF2A1710),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
