import 'dart:async';

import 'package:flutter/material.dart';

import '../game/app_settings.dart';
import '../game/profile_scope.dart';
import '../game/reversi_game.dart';
import '../l10n/app_strings.dart';
import '../models/online_game.dart';
import '../services/online_game_service.dart';
import '../services/sound_service.dart';
import '../theme/wood_theme.dart';
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
              decoration: const BoxDecoration(gradient: WoodDeco.darkBackground),
              child: SafeArea(
                child: g == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Wood.gold))
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
        Scaffold(
          appBar: _TopBar(title: strings.onlinePlay, onLeave: onLeave),
          body: Column(
            children: [
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
                  style: WoodText.heading(18, color: Wood.cream2, spacing: 1),
                ),
              ),
            ],
          ),
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

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar({required this.title, required this.onLeave});

  final String title;
  final VoidCallback onLeave;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return WoodAppBar(
      title: title.toUpperCase(),
      height: 60,
      spacing: 4,
      onBack: onLeave,
      actions: [
        WoodBarAction(
          icon: Icons.settings,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: WoodDeco.card(radius: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: hasUrl
                  ? DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: hasUrl ? null : const Color(0xFFF5EAD4),
            ),
            child: !hasUrl
                ? const Icon(Icons.person_rounded,
                    size: 22, color: Color(0xFF6B5235))
                : null,
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
                  style: WoodText.body(16, color: const Color(0xFF2E1F14), weight: FontWeight.w700),
                ),
                if (active)
                  Text(
                    'Sıranız',
                    style: WoodText.body(12, color: Wood.accent, weight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          Text(
            '$score',
            style: WoodText.heading(28, color: Wood.ink),
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
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF7ECD7), Color(0xFFEAD9BC)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Wood.goldSoft, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D3E2A1E),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: WoodText.heading(28, color: Wood.ink),
                ),
                const SizedBox(height: 12),
                Text(
                  '${game.game.scoreFor(Disc.black)} - ${game.game.scoreFor(Disc.white)}',
                  style: WoodText.heading(42, color: const Color(0xFF7A5224)),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: WoodButton(
                    label: strings.mainMenu,
                    onTap: onMenu,
                    variant: WoodButtonVariant.dark,
                    height: 50,
                    fontSize: 16,
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
