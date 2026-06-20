import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../game/profile_scope.dart';
import '../l10n/app_strings.dart';
import '../services/online_game_service.dart';
import '../services/sound_service.dart';
import '../theme/wood_theme.dart';
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
        backgroundColor: Wood.cream,
        body: Container(
          decoration: const BoxDecoration(gradient: WoodDeco.darkBackground),
          child: SafeArea(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('games')
                  .doc(widget.gameId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: CircularProgressIndicator(color: Wood.cream2),
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
                        style: WoodText.heading(
                          19,
                          color: Wood.cream2,
                          spacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 120,
                          height: 2,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0x00B8860B),
                                Wood.gold,
                                Color(0x00B8860B),
                              ],
                            ),
                          ),
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
                      const SizedBox(height: 14),
                      Text(
                        'VS',
                        style: WoodText.heading(26, color: Wood.goldSoft),
                      ),
                      const SizedBox(height: 14),
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
                        child: WoodButton(
                          label: strings.startGame,
                          onTap: _start,
                          variant: WoodButtonVariant.dark,
                          height: 54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _leaveToMenu,
                        child: Text(
                          strings.mainMenu,
                          style: WoodText.body(15, color: const Color(0xFFE9CF94), weight: FontWeight.w700),
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
    final isMyCard = highlight;
    final gradient = isMyCard ? WoodDeco.cardGradient : const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEEE1C6), Color(0xFFE0CFAE)],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        border: Border.all(color: const Color(0x4D7A5634), width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0x1F5A3D26),
            backgroundImage: hasUrl ? NetworkImage(url) : null,
            child: hasUrl
                ? null
                : const Icon(
                    Icons.person_rounded,
                    size: 26,
                    color: Color(0xFF5A3D26),
                  ),
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
                  style: WoodText.heading(18, color: Wood.ink),
                ),
                Text(
                  '${strings.level} $level',
                  style: WoodText.body(13, color: Wood.inkSoft2, weight: FontWeight.w600),
                ),
                if (showRecord)
                  Text(
                    '${strings.statsWins}: $wins · ${strings.statsLosses}: $losses · ${strings.statsDraws}: $draws',
                    style: WoodText.body(12, color: Wood.inkSoft2, weight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
