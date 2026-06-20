import 'package:flutter/material.dart';

import '../game/profile_scope.dart';
import '../l10n/app_strings.dart';
import '../models/online_stats.dart';
import '../models/xp_level.dart';
import 'online_stats_screen.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';
import '../theme/game_theme.dart';
import '../theme/wood_theme.dart';

/// The player's profile: avatar, name, level/XP and a summary of their online
/// record, plus sign-out. Reached from the menu profile chip. Level/XP and the
/// online stats are server-written (Cloud Functions); until the online phases
/// land they read as level 1 / 0 — the screen renders the live values either
/// way.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final profile = ProfileScope.of(context).profile;

    // If the player signs out while on this screen, return to the menu.
    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: GameColors.creamTop,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: creamShellGradient),
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 130,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: WoodDeco.barGradient,
                  border:
                      Border(bottom: BorderSide(color: Wood.gold, width: 2)),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    title: strings.profile,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      children: [
                        _Avatar(photoUrl: profile.photoUrl),
                        const SizedBox(height: 14),
                        Text(
                          profile.displayName ?? '',
                          textAlign: TextAlign.center,
                          style: WoodText.heading(24, color: Wood.ink),
                        ),
                        const SizedBox(height: 14),
                        _LevelCard(
                          level: profile.level,
                          xp: profile.xp,
                          label: strings.level,
                        ),
                        const SizedBox(height: 14),
                        _OnlineRecordCard(
                          stats: profile.online,
                          strings: strings,
                        ),
                        const SizedBox(height: 28),
                        _SignOutButton(label: strings.signOut),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasUrl = url != null && url.isNotEmpty;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: WoodDeco.cardGradient,
          boxShadow: [
            BoxShadow(
              color: Color(0x2E3E2A1E),
              offset: Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0x1F5A3D26),
          backgroundImage: hasUrl ? NetworkImage(url) : null,
          child: hasUrl
              ? null
              : const Icon(Icons.person_rounded,
                  size: 48, color: Color(0xFF5A3D26)),
        ),
      ),
    );
  }
}

/// Level badge plus a progress bar toward the next level. The exact XP curve is
/// formalized in REV-40; here the bar fills proportionally within the current
/// 100-XP band so it animates meaningfully once the server awards XP.
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.xp,
    required this.label,
  });

  final int level;
  final int xp;
  final String label;

  @override
  Widget build(BuildContext context) {
    final progress = XpLevel.levelProgress(xp);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [GameColors.accent, GameColors.onAccent],
                  ),
                ),
                child: Text(
                  '$level',
                  style: WoodText.heading(20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label $level',
                      style: WoodText.heading(18, color: Wood.ink),
                    ),
                    Text(
                      '$xp XP',
                      style: WoodText.body(13,
                          color: Wood.inkSoft, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: GameColors.onAccent.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(GameColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineRecordCard extends StatelessWidget {
  const _OnlineRecordCard({required this.stats, required this.strings});

  final OnlineStats stats;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final winRate = (stats.winRate * 100).round();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.onlineStatistics,
                  style: WoodText.heading(16, color: Wood.ink),
                ),
              ),
              GestureDetector(
                onTap: () {
                  SoundService.instance.playSfx(Sfx.button);
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const OnlineStatsScreen(),
                  ));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.viewAll,
                      style: WoodText.body(12,
                          color: Wood.accent, weight: FontWeight.w700),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: GameColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(value: '${stats.wins}', label: strings.statsWins),
              _Stat(value: '${stats.losses}', label: strings.statsLosses),
              _Stat(value: '${stats.draws}', label: strings.statsDraws),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: '%$winRate', label: strings.statsWinRate),
              _Stat(
                value: '${stats.currentStreak}',
                label: strings.statsCurrentStreak,
              ),
              _Stat(
                value: '${stats.bestStreak}',
                label: strings.statsBestStreak,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: WoodText.heading(22, color: Wood.accent),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: WoodText.body(11.5,
                color: Wood.inkSoft, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Wood.danger,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Wood.dangerShadow, offset: Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            SoundService.instance.playSfx(Sfx.button);
            AuthService.instance.signOut();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 9),
              Text(
                label,
                style: WoodText.heading(16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WoodDeco.card(),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 12),
          _RoundButton(icon: Icons.chevron_left, onTap: onBack),
          Expanded(
            child: Center(
              child: Text(
                title.toUpperCase(),
                style: WoodText.heading(22, color: Colors.white, spacing: 2.2),
              ),
            ),
          ),
          const SizedBox(width: 54),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x29ECD9BB),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () {
            SoundService.instance.playSfx(Sfx.button);
            onTap();
          },
          child: SizedBox(
            width: 42,
            height: 38,
            child: Icon(icon, color: Wood.creamDim, size: 22),
          ),
        ),
      ),
    );
  }
}
