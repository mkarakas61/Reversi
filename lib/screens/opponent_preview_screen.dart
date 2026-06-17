import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../game/profile_scope.dart';
import '../l10n/app_strings.dart';
import '../services/sound_service.dart';
import '../theme/game_theme.dart';

/// Shown once matched: the opponent's name, photo, level and basic online
/// record (from the game's playerInfo snapshot), alongside the player. The
/// "Start" action wires into the live game in REV-47.
class OpponentPreviewScreen extends StatelessWidget {
  const OpponentPreviewScreen({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final me = ProfileScope.of(context).profile;
    final myUid = me?.uid;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: bannerGradient),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('games')
                .doc(gameId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              final data = snapshot.data!.data()!;
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
                        onPressed: () {
                          SoundService.instance.playSfx(Sfx.button);
                          // Live online gameplay is wired in REV-47.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(strings.onlineComingSoon)),
                          );
                        },
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
                      onPressed: () {
                        SoundService.instance.playSfx(Sfx.button);
                        Navigator.of(context).maybePop();
                      },
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
