import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/profile/profile_scope.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/online_game_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';
import 'online_game_screen.dart';

/// Shown once matched: the opponent's name, photo, level and basic online
/// record (from the game's playerInfo snapshot), alongside the player. Tapping
/// "Start" enters the live game. Leaving here (back or "Main Menu") aborts the
/// match for both players — the game is cancelled, the opponent's client sees
/// it and exits too, and nobody is penalised.
class OpponentPreviewScreen extends StatefulWidget {
  const OpponentPreviewScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<OpponentPreviewScreen> createState() => _OpponentPreviewScreenState();
}

class _OpponentPreviewScreenState extends State<OpponentPreviewScreen> {
  // True once we've started the game or left, so we never double-navigate or
  // cancel a match that is actually starting.
  bool _left = false;

  Future<void> _leaveToMenu() async {
    if (_left) return;
    _left = true;
    SoundService.instance.playSfx(Sfx.button);
    unawaited(OnlineGameService.instance.cancel(widget.gameId));
    if (mounted) Navigator.of(context).pop();
  }

  void _bounceCancelled() {
    if (_left) return;
    _left = true;
    if (mounted) Navigator.of(context).pop();
  }

  void _start() {
    if (_left) return;
    _left = true; // starting, not leaving — don't cancel on the way out
    SoundService.instance.playSfx(Sfx.button);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OnlineGameScreen(gameId: widget.gameId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final me = ProfileScope.of(context).profile;
    final myUid = me?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveToMenu();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: headerGradient(context)),
          child: SafeArea(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('games')
                  .doc(widget.gameId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                final data = snapshot.data!.data()!;
                // Opponent aborted the match before it started — leave too.
                if (data['status'] == 'cancelled' && !_left) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _bounceCancelled());
                }
                final playerInfo =
                    (data['playerInfo'] as Map<String, dynamic>? ?? {});
                final uids =
                    (data['playerUids'] as List<dynamic>? ?? []).cast<String>();
                final opponentUid = uids.firstWhere(
                  (u) => u != myUid,
                  orElse: () => '',
                );
                final opponent =
                    playerInfo[opponentUid] as Map<String, dynamic>? ?? {};

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Spacer(),
                      Text(
                        strings.opponentFound.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PlayerLine(
                        name: me?.displayName ?? strings.playerYou,
                        photoUrl: me?.photoUrl,
                        level: me?.level ?? 1,
                        strings: strings,
                        highlight: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _PlayerLine(
                        name: opponent['name'] as String? ?? '—',
                        photoUrl: opponent['photo'] as String?,
                        level: (opponent['level'] as num?)?.toInt() ?? 1,
                        strings: strings,
                        wins: (opponent['wins'] as num?)?.toInt() ?? 0,
                        losses: (opponent['losses'] as num?)?.toInt() ?? 0,
                        draws: (opponent['draws'] as num?)?.toInt() ?? 0,
                        showRecord: true,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: GameColors.onAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _start,
                          child: Text(
                            strings.startGame,
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _leaveToMenu,
                        child: Text(
                          strings.mainMenu,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.name,
    required this.photoUrl,
    required this.level,
    required this.strings,
    this.highlight = false,
    this.showRecord = false,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  final String name;
  final String? photoUrl;
  final int level;
  final AppStrings strings;
  final bool highlight;
  final bool showRecord;
  final int wins;
  final int losses;
  final int draws;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasUrl = url != null && url.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlight ? 0.95 : 0.88),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: GameColors.onAccent.withValues(alpha: 0.12),
            backgroundImage: hasUrl ? NetworkImage(url) : null,
            child: hasUrl
                ? null
                : const Icon(Icons.person_rounded,
                    size: 26, color: GameColors.onAccent),
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
                    fontSize: 18,
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
                if (showRecord)
                  Text(
                    '${strings.statsWins}: $wins · ${strings.statsLosses}: $losses · ${strings.statsDraws}: $draws',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: GameColors.inkSoft,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
