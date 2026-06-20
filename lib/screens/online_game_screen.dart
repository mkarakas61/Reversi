import 'dart:async';

import 'package:flutter/material.dart';

import '../game/app_settings.dart';
import '../game/profile_scope.dart';
import '../game/reversi_game.dart';
import '../l10n/app_strings.dart';
import '../models/online_game.dart';
import '../services/online_game_service.dart';
import '../services/sound_service.dart';
import '../theme/game_theme.dart';
import '../widgets/info_popup.dart';
import '../widgets/wood_board.dart';
import 'settings_screen.dart';

/// Live online match. Both clients render from the shared game document; the
/// player whose turn it is taps to move, which writes the new board to
/// Firestore. Reuses the [ReversiGame] engine and [WoodBoard] widget so the
/// rules and look match the local game. XP/level rewards are applied
/// server-side after the game ends (REV-50).
class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  int _lastMoveCount = -1;
  // The previous board, kept so each incoming snapshot can be diffed against it
  // to recover the placed + flipped cells and drive the flip animation (the doc
  // only carries the resulting board, not the move's captures).
  List<List<Disc?>>? _lastBoard;
  // The move to animate on the board, or null until the first real move lands.
  BoardMove? _move;
  // Transient "forced pass" popup message, or null when none is showing.
  String? _infoMessage;
  // Guards a one-time auto-exit when the opponent cancels an un-started match.
  bool _exited = false;
  // Presence heartbeat telling the opponent we're connected (REV-48); guards so
  // we start it once and only ever claim a disconnect win once.
  Timer? _heartbeat;
  bool _heartbeatStarted = false;
  bool _claiming = false;

  @override
  void dispose() {
    _heartbeat?.cancel();
    super.dispose();
  }

  /// Folds each new snapshot into local UI state: plays the move chime, derives
  /// the flip animation by diffing the board, and surfaces a forced-pass popup.
  /// Called during build (the snapshot already drives the rebuild), mirroring
  /// the local game's per-move bookkeeping.
  void _sync(OnlineGame g, String myUid, AppStrings strings) {
    final board = g.game.board;
    if (_lastMoveCount < 0) {
      // First snapshot: establish the baseline without animating or chiming.
      _lastMoveCount = g.moveCount;
      _lastBoard = board;
      return;
    }
    if (g.moveCount <= _lastMoveCount) return;

    SoundService.instance.playSfx(Sfx.place);
    Future<void>.delayed(const Duration(milliseconds: 260),
        () => SoundService.instance.playSfx(Sfx.flip));

    final placed = g.game.lastMove;
    final old = _lastBoard;
    String? info;
    if (placed != null && old != null) {
      final color = board[placed.row][placed.col];
      if (color != null) {
        // Captured discs are the cells that changed to the mover's colour.
        final flipped = <Position>{};
        for (var r = 0; r < ReversiGame.size; r++) {
          for (var c = 0; c < ReversiGame.size; c++) {
            if (board[r][c] == color &&
                old[r][c] != null &&
                old[r][c] != color) {
              flipped.add(Position(r, c));
            }
          }
        }
        _move = BoardMove(
            id: g.moveCount, placed: placed, flipped: flipped, color: color);

        // If it is the mover's turn again (and the game isn't over), the other
        // side had no legal move and was skipped.
        if (!g.isFinished && g.game.currentPlayer == color) {
          final skipped = color == Disc.black ? Disc.white : Disc.black;
          info = skipped == g.colorFor(myUid)
              ? strings.passSkippedYou
              : strings.passSkippedOpponent;
        }
      }
    }
    _infoMessage = info; // clears any stale popup on a non-pass move
    _lastMoveCount = g.moveCount;
    _lastBoard = board;
  }

  void _dismissInfo() {
    if (_infoMessage != null && mounted) {
      setState(() => _infoMessage = null);
    }
  }

  Future<void> _confirmLeave(OnlineGame? g, String myUid) async {
    // Finished, cancelled, or not yet loaded: just leave, no action.
    if (g == null || g.isFinished || g.isCancelled) {
      Navigator.of(context).pop();
      return;
    }
    // The game hasn't started (no moves yet): abort it for both — no penalty.
    if (g.moveCount == 0) {
      await OnlineGameService.instance.cancel(g.id);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final strings = AppStrings.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.leaveTitle),
        content: Text(strings.leaveOnlineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.leave),
          ),
        ],
      ),
    );
    if (leave == true) {
      await OnlineGameService.instance.resign(g, myUid);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = SettingsScope.of(context).settings;
    final myUid = ProfileScope.of(context).profile?.uid;

    if (myUid == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => Navigator.of(context).maybePop());
      return const SizedBox.shrink();
    }

    // Start the presence heartbeat once we know who we are (REV-48).
    if (!_heartbeatStarted) {
      _heartbeatStarted = true;
      OnlineGameService.instance.heartbeat(widget.gameId, myUid);
      _heartbeat = Timer.periodic(
        const Duration(seconds: 3),
        (_) => OnlineGameService.instance.heartbeat(widget.gameId, myUid),
      );
    }

    return StreamBuilder<OnlineGame>(
      stream: OnlineGameService.instance.watch(widget.gameId),
      builder: (context, snapshot) {
        final g = snapshot.data;
        if (g != null) {
          _sync(g, myUid, strings);
          if (g.isFinished || g.isCancelled) {
            _heartbeat?.cancel();
          }
          if (g.isCancelled && !_exited) {
            // The opponent aborted an un-started match — leave too, no penalty.
            _exited = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).maybePop();
            });
          } else if (!g.isFinished && !g.isCancelled && !_claiming) {
            // Opponent's heartbeat is stale (>10 s ago) — they disconnected.
            final opp = g.lastSeenFor(g.opponentUid(myUid));
            if (opp != null &&
                DateTime.now().difference(opp) > const Duration(seconds: 10)) {
              _claiming = true;
              OnlineGameService.instance.claimDisconnectWin(g, myUid);
            }
          }
        }
        return PopScope(
          // Finished / cancelled (or not-yet-loaded) games leave freely; an
          // active game intercepts back to cancel (pre-move) or resign.
          canPop: g == null || g.isFinished || g.isCancelled,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave(g, myUid);
          },
          child: Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(gradient: bannerGradient),
              child: SafeArea(
                child: g == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _GameBody(
                        game: g,
                        myUid: myUid,
                        settings: settings,
                        strings: strings,
                        move: _move,
                        infoMessage: _infoMessage,
                        onInfoDismissed: _dismissInfo,
                        onLeave: () => _confirmLeave(g, myUid),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.game,
    required this.myUid,
    required this.settings,
    required this.strings,
    required this.move,
    required this.infoMessage,
    required this.onInfoDismissed,
    required this.onLeave,
  });

  final OnlineGame game;
  final String myUid;
  final AppSettings settings;
  final AppStrings strings;
  final BoardMove? move;
  final String? infoMessage;
  final VoidCallback onInfoDismissed;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final myColor = game.colorFor(myUid);
    final oppColor = myColor == Disc.black ? Disc.white : Disc.black;
    final isMyTurn = !game.isFinished && game.game.currentPlayer == myColor;

    // My disc always wears my chosen coin; the opponent wears the other.
    final blackCoin =
        myColor == Disc.black ? settings.yourCoin : settings.opponentCoin;
    final whiteCoin =
        myColor == Disc.black ? settings.opponentCoin : settings.yourCoin;

    final opp = game.infoFor(game.opponentUid(myUid));
    final me = ProfileScope.of(context).profile;

    return Stack(
      children: [
        Column(
          children: [
            _TopBar(title: strings.onlinePlay, onLeave: onLeave),
            _PlayerStrip(
              name: opp['name'] as String? ?? '—',
              photoUrl: opp['photo'] as String?,
              score: game.game.scoreFor(oppColor),
              coin: settings.opponentCoin,
              active: !game.isFinished && !isMyTurn,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: WoodBoard(
                      board: game.game.board,
                      validMoves: isMyTurn ? game.game.validMoves : const {},
                      lastMove: game.game.lastMove,
                      theme: settings.board,
                      blackCoin: blackCoin,
                      whiteCoin: whiteCoin,
                      move: move,
                      onCellTap: (pos) {
                        if (!isMyTurn) return;
                        OnlineGameService.instance.submitMove(game, pos, myUid);
                      },
                    ),
                  ),
                ),
              ),
            ),
            _PlayerStrip(
              name: me?.displayName ?? strings.playerYou,
              photoUrl: me?.photoUrl,
              score: game.game.scoreFor(myColor),
              coin: settings.yourCoin,
              active: isMyTurn,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                game.isFinished
                    ? ''
                    : (isMyTurn ? strings.yourMove : strings.opponentTurn),
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (infoMessage != null)
          InfoPopup(
            key: ValueKey(game.moveCount),
            message: infoMessage!,
            onDismissed: onInfoDismissed,
          ),
        if (game.isFinished)
          _ResultOverlay(
            game: game,
            myColor: myColor,
            strings: strings,
            onMenu: () {
              SoundService.instance.playSfx(Sfx.button);
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onLeave});

  final String title;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.chevron_left,
            iconSize: 26,
            onTap: onLeave,
          ),
          Expanded(
            child: Center(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Mid-match access to board / coin / sound settings (changes apply
          // live since the board reads them from [SettingsScope]).
          _RoundIconButton(
            icon: Icons.settings,
            iconSize: 20,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          SoundService.instance.playSfx(Sfx.button);
          onTap();
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _PlayerStrip extends StatelessWidget {
  const _PlayerStrip({
    required this.name,
    required this.photoUrl,
    required this.score,
    required this.coin,
    required this.active,
  });

  final String name;
  final String? photoUrl;
  final int score;
  final CoinColor coin;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasUrl = url != null && url.isNotEmpty;
    final palette = coinPalettes[coin]!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.96 : 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? GameColors.accent : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: GameColors.onAccent.withValues(alpha: 0.12),
            backgroundImage: hasUrl ? NetworkImage(url) : null,
            child: hasUrl
                ? null
                : Icon(Icons.person_rounded,
                    size: 18, color: GameColors.onAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: GameColors.ink,
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.faceTop, palette.faceBottom],
              ),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: ThemeData.estimateBrightnessForColor(palette.faceMid) ==
                        Brightness.light
                    ? GameColors.ink
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.game,
    required this.myColor,
    required this.strings,
    required this.onMenu,
  });

  final OnlineGame game;
  final Disc myColor;
  final AppStrings strings;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final String title;
    if (game.isDraw) {
      title = strings.drawTitle;
    } else if (game.winner == myColor) {
      title = strings.youWon;
    } else {
      title = strings.youLost;
    }
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x99000000),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: GameColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${game.game.scoreFor(Disc.black)} - ${game.game.scoreFor(Disc.white)}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: GameColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: GameColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onMenu,
                    child: Text(
                      strings.mainMenu,
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
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
