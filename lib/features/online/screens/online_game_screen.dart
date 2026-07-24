import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/profile/profile_scope.dart';
import '../../../core/game/reversi_game.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/online_game.dart';
import '../../../core/models/online_stats.dart';
import '../../../core/models/progress_history.dart';
import '../../../core/models/rank.dart';
import '../../../core/services/online_game_service.dart';
import '../../../core/services/player_profile_service.dart';
import '../../../core/services/progress_history_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/coin_palette.dart';
import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';
import '../../../shared/widgets/info_popup.dart';
import '../../../shared/widgets/rank_badge.dart';
import '../../board/board_move.dart';
import '../../board/wood_board.dart';
import '../../settings/settings_screen.dart';

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
  // The opponent's public profile + ranked stats, fetched once when the game
  // loads (REV-75). Null for a guest opponent or until the fetch returns.
  PublicProfile? _oppProfile;
  bool _oppFetchStarted = false;

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

  /// Reads the opponent's public profile once (rank label + tap-to-view stats,
  /// REV-75). Skipped for a guest opponent (no `users` doc).
  void _maybeFetchOpponent(OnlineGame g, String myUid) {
    if (_oppFetchStarted) return;
    _oppFetchStarted = true;
    final oppUid = g.opponentUid(myUid);
    if (g.infoFor(oppUid)['isGuest'] == true) return;
    PlayerProfileService.instance.fetch(oppUid).then((p) {
      if (mounted && p != null) setState(() => _oppProfile = p);
    });
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
          _maybeFetchOpponent(g, myUid);
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
              decoration: BoxDecoration(gradient: headerGradient(context)),
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
                        opponentProfile: _oppProfile,
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
    required this.opponentProfile,
  });

  final OnlineGame game;
  final String myUid;
  final AppSettings settings;
  final AppStrings strings;
  final BoardMove? move;
  final String? infoMessage;
  final VoidCallback onInfoDismissed;
  final VoidCallback onLeave;

  /// Opponent's public profile for the rank label + tap-to-view stats (REV-75);
  /// null for a guest opponent or until the one-shot fetch returns.
  final PublicProfile? opponentProfile;

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
    final oppName = opp['name'] as String? ?? '—';
    final oppPhoto = opp['photo'] as String?;

    return Stack(
      children: [
        Column(
          children: [
            _TopBar(title: strings.onlinePlay, onLeave: onLeave),
            _PlayerStrip(
              name: oppName,
              photoUrl: oppPhoto,
              score: game.game.scoreFor(oppColor),
              coin: settings.opponentCoin,
              active: !game.isFinished && !isMyTurn,
              rank: opponentProfile?.stats.rank,
              // Tap the opponent to view their full online stats (REV-75).
              onTap: opponentProfile == null
                  ? null
                  : () {
                      SoundService.instance.playSfx(Sfx.button);
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _OpponentStatsSheet(
                          name: opponentProfile!.name ?? oppName,
                          photoUrl: opponentProfile!.photoUrl ?? oppPhoto,
                          level: opponentProfile!.level,
                          stats: opponentProfile!.stats,
                          strings: strings,
                        ),
                      );
                    },
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
              rank: (me != null && !me.isGuest) ? me.online.rank : null,
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
            myUid: myUid,
            isGuest: me?.isGuest ?? false,
            currentStreak: me?.online.currentStreak ?? 0,
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
    this.rank,
    this.onTap,
  });

  final String name;
  final String? photoUrl;
  final int score;
  final CoinColor coin;
  final bool active;

  /// The player's rank, shown as a compact badge above the name (REV-75); null
  /// for a guest or an unknown opponent.
  final Rank? rank;

  /// Tapping the strip opens the player's full online stats (opponent only).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasUrl = url != null && url.isNotEmpty;
    final palette = coinPalettes[coin]!;
    final strings = AppStrings.of(context);
    final r = rank;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 0.96 : 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? GameColors.accent : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: GameColors.onAccent.withValues(alpha: 0.12),
                  backgroundImage: hasUrl ? NetworkImage(url) : null,
                  child: hasUrl
                      ? null
                      : const Icon(Icons.person_rounded,
                          size: 18, color: GameColors.onAccent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (r != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.military_tech, size: 12, color: r.color),
                            const SizedBox(width: 3),
                            Text(
                              strings.rankTitle(r.id),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: Color.alphaBlend(
                                    const Color(0x33000000), r.color),
                              ),
                            ),
                            if (onTap != null) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.info_outline,
                                  size: 11, color: GameColors.inkSoft),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                      ],
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: GameColors.ink,
                        ),
                      ),
                    ],
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
            ),
          ),
        ),
      );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.game,
    required this.myColor,
    required this.strings,
    required this.myUid,
    required this.isGuest,
    required this.currentStreak,
    required this.onMenu,
  });

  final OnlineGame game;
  final Disc myColor;
  final AppStrings strings;
  final String myUid;
  final bool isGuest;

  /// The player's current win streak, read live from the profile so the stats
  /// row reflects the just-applied reward.
  final int currentStreak;
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
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
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
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: GameColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${game.game.scoreFor(Disc.black)} - ${game.game.scoreFor(Disc.white)}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: GameColors.inkSoft,
                    ),
                  ),
                  // Trophy / rank reward — signed-in players only (guests earn
                  // nothing, REV-57). Revealed once the server writes the
                  // history doc for this game (REV-73/74).
                  if (!isGuest)
                    StreamBuilder<HistoryEntry?>(
                      stream: ProgressHistoryService.instance
                          .watchReward(myUid, game.id),
                      builder: (context, snap) {
                        final entry = snap.data;
                        if (entry == null) return const SizedBox(height: 4);
                        return _RewardSection(
                          entry: entry,
                          currentStreak: currentStreak,
                          strings: strings,
                        );
                      },
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
      ),
    );
  }
}

/// The trophy change + rank progress + match stats, shown under the result
/// once the server reward lands (REV-74). Animates the trophy delta in.
class _RewardSection extends StatelessWidget {
  const _RewardSection({
    required this.entry,
    required this.currentStreak,
    required this.strings,
  });

  final HistoryEntry entry;
  final int currentStreak;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final trophies = entry.trophies;
    final delta = entry.trophyDelta;
    final rank = rankFor(trophies);
    final rankedUp =
        delta > 0 && rankFor(trophies - delta).id != rank.id;

    final Color deltaColor = delta > 0
        ? const Color(0xFF1F9D57)
        : delta < 0
            ? const Color(0xFFC0392B)
            : GameColors.inkSoft;
    final String deltaText =
        delta > 0 ? '+$delta' : delta < 0 ? '$delta' : '±0';

    return Column(
      children: [
        const SizedBox(height: 18),
        const Divider(height: 1),
        const SizedBox(height: 16),
        // Animated trophy delta.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: 22, color: deltaColor),
              const SizedBox(width: 6),
              Text(
                '$deltaText ${strings.trophies}',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: deltaColor,
                ),
              ),
            ],
          ),
        ),
        if (rankedUp) ...[
          const SizedBox(height: 8),
          Text(
            strings.rankUp,
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: rank.color,
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Rank badge + progress toward the next rank.
        RankBadge(rank: rank, trophies: trophies),
        const SizedBox(height: 8),
        _RankProgressBar(trophies: trophies, strings: strings),
        const SizedBox(height: 16),
        // Match stats.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatCell(label: strings.matchFlipped, value: '${entry.flipped}'),
            _StatCell(label: strings.matchMargin, value: '${entry.scoreDiff}'),
            _StatCell(label: strings.matchStreak, value: '$currentStreak'),
          ],
        ),
      ],
    );
  }
}

/// A thin progress bar from the current rank floor to the next rank, or a full
/// bar labelled "top rank" once Efsane is reached.
class _RankProgressBar extends StatelessWidget {
  const _RankProgressBar({required this.trophies, required this.strings});

  final int trophies;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final toNext = trophiesToNext(trophies);
    final rank = rankFor(trophies);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: rankProgress(trophies),
            minHeight: 7,
            backgroundColor: const Color(0xFFE7E2D6),
            valueColor: AlwaysStoppedAnimation<Color>(rank.color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          toNext == null ? strings.topRank : '$trophies (+$toNext)',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: GameColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: GameColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: GameColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet showing an opponent's full online record, opened by tapping the
/// opponent strip during a match (REV-75).
class _OpponentStatsSheet extends StatelessWidget {
  const _OpponentStatsSheet({
    required this.name,
    required this.photoUrl,
    required this.level,
    required this.stats,
    required this.strings,
  });

  final String name;
  final String? photoUrl;
  final int level;
  final OnlineStats stats;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasUrl = url != null && url.isNotEmpty;
    final winRatePercent = (stats.winRate * 100).round();
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: GameColors.onAccent.withValues(alpha: 0.12),
                  backgroundImage: hasUrl ? NetworkImage(url) : null,
                  child: hasUrl
                      ? null
                      : const Icon(Icons.person_rounded,
                          size: 24, color: GameColors.onAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: GameColors.ink,
                        ),
                      ),
                      Text(
                        '${strings.level} $level',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: GameColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                RankBadge(rank: stats.rank, trophies: stats.trophies),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCell(label: strings.statsWins, value: '${stats.wins}'),
                _StatCell(label: strings.statsLosses, value: '${stats.losses}'),
                _StatCell(label: strings.statsDraws, value: '${stats.draws}'),
                _StatCell(
                    label: strings.statsWinRate, value: '%$winRatePercent'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCell(
                    label: strings.matchStreak,
                    value: '${stats.currentStreak}'),
                _StatCell(
                    label: strings.statsBestStreak,
                    value: '${stats.bestStreak}'),
                _StatCell(
                    label: strings.statsBestScoreDiff,
                    value: '${stats.bestScoreDiff}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
