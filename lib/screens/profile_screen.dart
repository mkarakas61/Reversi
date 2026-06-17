import 'package:flutter/material.dart';

import '../game/profile_scope.dart';
import '../l10n/app_strings.dart';
import '../models/online_stats.dart';
import '../models/xp_level.dart';
import 'online_stats_screen.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';
import '../theme/game_theme.dart';

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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: bannerGradient),
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
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: GameColors.ink,
                          ),
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              offset: Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: GameColors.onAccent.withValues(alpha: 0.12),
          backgroundImage: hasUrl ? NetworkImage(url) : null,
          child: hasUrl
              ? null
              : const Icon(Icons.person_rounded,
                  size: 48, color: GameColors.onAccent),
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
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label $level',
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: GameColors.ink,
                      ),
                    ),
                    Text(
                      '$xp XP',
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
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: GameColors.ink,
                  ),
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
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: GameColors.accent,
                      ),
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
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: GameColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: GameColors.inkSoft,
            ),
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
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE0312B),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          SoundService.instance.playSfx(Sfx.button);
          AuthService.instance.signOut();
        },
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w800,
            fontSize: 16,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
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
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 2.2,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Color(0x1F000000), offset: Offset(0, 2)),
                  ],
                ),
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
          onTap: () {
            SoundService.instance.playSfx(Sfx.button);
            onTap();
          },
          child: SizedBox(
            width: 42,
            height: 38,
            child: Icon(icon, color: GameColors.onAccent, size: 24),
          ),
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
          size.width / 2, size.height, size.width, size.height - 36)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_HeaderClipper old) => false;
}
