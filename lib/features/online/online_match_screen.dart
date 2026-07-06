import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/game/reversi_game.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/game_colors.dart';
import '../board/board_move.dart';
import '../board/wood_board.dart';
import '../game/overlays/game_over_overlay.dart';
import '../game/widgets/cream_shell.dart';
import '../game/widgets/entry_slide.dart';
import '../game/widgets/game_top_bar.dart';
import '../game/widgets/player_card.dart';
import 'online_tokens.dart';
import 'widgets/online_board.dart';
import 'widgets/online_player_card.dart';
import 'widgets/online_result_overlay.dart';

/// "Online Oyna" match screen. The opponent ("Aylin", maple/white) is a local
/// AI; you ("Mert Karakaş", walnut/black) play from the bottom card.
///
/// In the wood theme it renders the dedicated handoff design; in the original
/// theme it mirrors the single-player game screen (same chrome, board, discs).
class OnlineMatchScreen extends StatefulWidget {
  const OnlineMatchScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen>
    with SingleTickerProviderStateMixin {
  static const Disc _you = Disc.black; // walnut
  static const Disc _opponent = Disc.white; // maple

  late ReversiGame _game = ReversiGame.newGame();
  bool _thinking = false;
  final int _aiGeneration = 0;
  Position? _lastMove;
  BoardMove? _lastBoardMove;
  int _moveSeq = 0;

  late final AnimationController _entry;
  late final ConfettiController _confettiLeft;
  late final ConfettiController _confettiRight;

  // Lets the game-over flower celebration find the board's on-screen rect.
  final GlobalKey _boardKey = GlobalKey();
  bool _celebrated = false;

  bool get _over => _game.phase == GamePhase.gameOver;

  @override
  void initState() {
    super.initState();
    _confettiLeft =
        ConfettiController(duration: const Duration(milliseconds: 2600));
    _confettiRight =
        ConfettiController(duration: const Duration(milliseconds: 2600));
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _entry.forward());
  }

  @override
  void dispose() {
    _entry.dispose();
    _confettiLeft.dispose();
    _confettiRight.dispose();
    super.dispose();
  }

  void _play(Position pos) {
    if (_over || _thinking || _game.currentPlayer != _you) return;
    final before = _game.currentPlayer;
    final move = _game.play(pos);
    if (!move.result.isValid) return;
    setState(() {
      _game = move.game;
      _lastMove = pos;
      _lastBoardMove = BoardMove(
        id: ++_moveSeq,
        placed: pos,
        flipped: move.result.flipped.toSet(),
        color: before,
      );
    });
    if (_over) {
      _handleGameEnded();
    } else if (_game.currentPlayer == _opponent) {
      unawaited(_runAi());
    }
  }

  Future<void> _runAi() async {
    final generation = _aiGeneration;
    setState(() => _thinking = true);
    while (mounted &&
        generation == _aiGeneration &&
        _game.phase == GamePhase.playing &&
        _game.currentPlayer == _opponent) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || generation != _aiGeneration) return;
      final pos = _chooseAiMove();
      final move = _game.play(pos);
      if (!move.result.isValid) break;
      setState(() {
        _game = move.game;
        _lastMove = pos;
        _lastBoardMove = BoardMove(
          id: ++_moveSeq,
          placed: pos,
          flipped: move.result.flipped.toSet(),
          color: _opponent,
        );
      });
    }
    if (mounted && generation == _aiGeneration) {
      setState(() => _thinking = false);
    }
    if (_over) _handleGameEnded();
  }

  /// Greedy AI: most flips, +25 bonus for corner cells (per the handoff spec).
  Position _chooseAiMove() {
    final moves = _game.validMoves.toList();
    Position best = moves.first;
    int bestScore = -1 << 30;
    for (final m in moves) {
      final flips = _game.play(m).result.flipped.length;
      final corner = (m.row == 0 || m.row == 7) && (m.col == 0 || m.col == 7);
      final score = flips + (corner ? 25 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  void _handleGameEnded() {
    if (_celebrated) return;
    _celebrated = true;
    if (_game.winner == _you) {
      _confettiLeft.play();
      _confettiRight.play();
    }
  }

  void _restart() {
    _celebrated = false;
    _confettiLeft.stop();
    _confettiRight.stop();
    setState(() {
      _game = ReversiGame.newGame();
      _thinking = false;
      _lastMove = null;
      _lastBoardMove = null;
    });
  }

  String _resultTitle() {
    final winner = _game.winner;
    if (winner == null) return 'Berabere!';
    return winner == _you ? 'Kazandın!' : 'Kaybettin';
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context).settings;
    final wood = settings.appTheme == AppThemeId.wood;
    final blackScore = _game.scoreFor(Disc.black);
    final whiteScore = _game.scoreFor(Disc.white);
    final yourTurn = !_over && _game.currentPlayer == _you;
    final oppTurn = !_over && _game.currentPlayer == _opponent;

    return Scaffold(
      backgroundColor: wood ? OnlineTokens.phoneSurface : GameColors.creamTop,
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
              return wood
                  ? _woodView(camera, topIn, bottomIn, yourTurn, oppTurn,
                      blackScore, whiteScore, settings)
                  : _originalView(camera, topIn, bottomIn, yourTurn, oppTurn,
                      blackScore, whiteScore, settings);
            },
          ),
          if (_over)
            wood
                ? OnlineResultOverlay(
                    title: _resultTitle(),
                    blackScore: blackScore,
                    whiteScore: whiteScore,
                    onMenu: () => Navigator.of(context).maybePop(),
                    board: settings.board,
                    celebrate: _game.winner == _you,
                    flowerBoardKey: settings.board == BoardTheme.cicek
                        ? _boardKey
                        : null,
                  )
                : GameOverOverlay(
                    winner: _game.winner,
                    isSinglePlayer: true,
                    humanDisc: _you,
                    blackScore: blackScore,
                    whiteScore: whiteScore,
                    yourCoin: settings.yourCoin,
                    opponentCoin: settings.opponentCoin,
                    confettiLeft: _confettiLeft,
                    confettiRight: _confettiRight,
                    onPlayAgain: _restart,
                    onMenu: () => Navigator.of(context).maybePop(),
                    strings: (
                      title: _resultTitle(),
                      message: null,
                      titleCoin: _game.winner == null
                          ? null
                          : (_game.winner == _you
                              ? settings.yourCoin
                              : settings.opponentCoin),
                    ),
                  ),
        ],
      ),
    );
  }

  // ---- Original theme: mirrors the single-player game screen ----
  Widget _originalView(
    double camera,
    double topIn,
    double bottomIn,
    bool yourTurn,
    bool oppTurn,
    int blackScore,
    int whiteScore,
    AppSettings settings,
  ) {
    return CreamShell(
      t: camera,
      child: Column(
        children: [
          EntrySlide(
            progress: topIn,
            beginOffset: const Offset(0, -1.4),
            child: GameTopBar(
              onBack: () => Navigator.of(context).maybePop(),
              onNewGame: _restart,
              onSettings: widget.onOpenSettings,
            ),
          ),
          EntrySlide(
            progress: topIn,
            beginOffset: const Offset(0, -1.4),
            child: PlayerCard(
              side: Disc.white,
              name: 'Aylin',
              mono: 'A',
              score: whiteScore,
              active: oppTurn,
              statusText: _thinking ? 'düşünüyor' : 'sırada',
              coin: settings.opponentCoin,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: EntrySlide(
                progress: camera,
                beginOffset: const Offset(0, 0.35),
                child: WoodBoard(
                  board: _game.board,
                  validMoves: _game.validMoves,
                  lastMove: _game.lastMove,
                  onCellTap: _play,
                  theme: settings.board,
                  blackCoin: settings.yourCoin,
                  whiteCoin: settings.opponentCoin,
                  move: _lastBoardMove,
                ),
              ),
            ),
          ),
          EntrySlide(
            progress: bottomIn,
            beginOffset: const Offset(0, 1.4),
            child: PlayerCard(
              side: Disc.black,
              name: 'Mert Karakaş',
              mono: 'M',
              score: blackScore,
              active: yourTurn,
              statusText: 'senin sıran',
              coin: settings.yourCoin,
            ),
          ),
          const SizedBox(height: 8),
          EntrySlide(
            progress: bottomIn,
            beginOffset: const Offset(0, 1.4),
            child: _over
                ? const SizedBox(height: 36)
                : TurnPill(
                    side: yourTurn ? Disc.black : Disc.white,
                    text: yourTurn ? 'Senin sıran' : 'Rakibin sırası',
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ---- Wood theme: the dedicated handoff design ----
  Widget _woodView(
    double camera,
    double topIn,
    double bottomIn,
    bool yourTurn,
    bool oppTurn,
    int blackScore,
    int whiteScore,
    AppSettings settings,
  ) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.1),
          radius: 1.1,
          colors: [Color(0xFFFBF6EC), OnlineTokens.phoneSurface],
          stops: [0.0, 0.6],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            EntrySlide(
              progress: topIn,
              beginOffset: const Offset(0, -1.4),
              child: _AppBar(
                onBack: () => Navigator.of(context).maybePop(),
                onSettings: widget.onOpenSettings,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
                child: Column(
                  children: [
                    EntrySlide(
                      progress: topIn,
                      beginOffset: const Offset(0, -1.4),
                      child: OnlinePlayerCard(
                        discAsset:
                            OnlineTokens.discFor(settings.board, isDark: false),
                        name: 'Aylin',
                        score: whiteScore,
                        active: oppTurn,
                        statusText: oppTurn ? 'sırada' : '',
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: EntrySlide(
                          progress: camera,
                          beginOffset: const Offset(0, 0.35),
                          child: OnlineBoard(
                            key: _boardKey,
                            board: _game.board,
                            validMoves: _game.validMoves,
                            lastMove: _lastMove,
                            showHints: yourTurn,
                            onCellTap: _play,
                            theme: settings.board,
                            move: _lastBoardMove,
                          ),
                        ),
                      ),
                    ),
                    EntrySlide(
                      progress: bottomIn,
                      beginOffset: const Offset(0, 1.4),
                      child: OnlinePlayerCard(
                        discAsset:
                            OnlineTokens.discFor(settings.board, isDark: true),
                        name: 'Mert Karakaş',
                        score: blackScore,
                        active: yourTurn,
                        statusText: yourTurn ? 'senin sıran' : '',
                      ),
                    ),
                    EntrySlide(
                      progress: bottomIn,
                      beginOffset: const Offset(0, 1.4),
                      child: _TurnPill(
                        over: _over,
                        yourTurn: yourTurn,
                        board: settings.board,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x267A5634), width: 1),
        ),
      ),
      child: Row(
        children: [
          _IconButton(icon: Icons.chevron_left, onTap: onBack),
          const Expanded(
            child: Text(
              'ONLINE OYNA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Marcellus',
                fontSize: 18,
                letterSpacing: 4,
                color: OnlineTokens.inkScore,
              ),
            ),
          ),
          _IconButton(icon: Icons.settings, onTap: onSettings),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x14785230), // rgba(120,82,48,.08)
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 22, color: OnlineTokens.inkScore),
        ),
      ),
    );
  }
}

class _TurnPill extends StatelessWidget {
  const _TurnPill({
    required this.over,
    required this.yourTurn,
    required this.board,
  });

  final bool over;
  final bool yourTurn;
  final BoardTheme board;

  @override
  Widget build(BuildContext context) {
    final label =
        over ? 'Oyun bitti' : (yourTurn ? 'Senin sıran' : 'Rakibin sırası');
    final disc = OnlineTokens.discFor(board, isDark: yourTurn);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OnlineTokens.cardTop, OnlineTokens.cardBottom],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: OnlineTokens.pillBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!over) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: Image.asset(disc, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: OnlineTokens.pillText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
