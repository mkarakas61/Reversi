import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/leaderboard_entry.dart';
import '../../../core/profile/profile_scope.dart';
import '../../../core/services/leaderboard_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';
import '../../../shared/widgets/guest_upsell_card.dart';
import '../../menu/widgets/profile_chip.dart' show ProfileAvatar;

/// Ranked leaderboard: Weekly/All-Time period × Level/Wins metric, top 50 plus
/// "your rank". Reached from the main menu whenever there's an online
/// identity (Google or guest) — guests see a sign-in upsell instead of the
/// table, since ranked stats are Google-only (REV-57 never writes for them).
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardPeriod _period = LeaderboardPeriod.weekly;
  LeaderboardMetric _metric = LeaderboardMetric.wins;

  late Future<List<LeaderboardEntry>> _topFuture;
  Future<({int rank, String value})>? _rankFuture;

  @override
  void initState() {
    super.initState();
    _topFuture = LeaderboardService.instance.top(_period, _metric);
  }

  void _reload() {
    setState(() {
      _topFuture = LeaderboardService.instance.top(_period, _metric);
      _rankFuture = null; // recomputed lazily once we have the profile
    });
  }

  Future<({int rank, String value})> _computeMyRank(Profile profile) async {
    final strings = AppStrings.of(context);
    int myValue;
    String display;
    if (_period == LeaderboardPeriod.allTime) {
      if (_metric == LeaderboardMetric.level) {
        myValue = profile.xp;
        display = '${strings.level} ${profile.level}';
      } else {
        myValue = profile.online.wins;
        display = '$myValue';
      }
    } else {
      final mine =
          await LeaderboardService.instance.myWeeklyEntry(profile.uid);
      if (_metric == LeaderboardMetric.level) {
        myValue = mine?.xpGained ?? 0;
        display = '+$myValue XP';
      } else {
        myValue = mine?.wins ?? 0;
        display = '$myValue';
      }
    }
    final rank =
        await LeaderboardService.instance.myRank(_period, _metric, myValue);
    return (rank: rank, value: display);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final profile = ProfileScope.of(context).profile;

    return Scaffold(
      backgroundColor: pageSurfaceColor(context),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: pageBackgroundGradient(context)),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: headerGradient(context)),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    title: strings.leaderboard,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: profile == null
                        ? const SizedBox.shrink()
                        : profile.isGuest
                            ? ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 6, 16, 24),
                                children: const [GuestUpsellCard()],
                              )
                            : _buildBody(strings, profile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppStrings strings, Profile profile) {
    _rankFuture ??= _computeMyRank(profile);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _PeriodMetricPicker(
          period: _period,
          metric: _metric,
          strings: strings,
          onPeriodChanged: (p) {
            _period = p;
            _reload();
          },
          onMetricChanged: (m) {
            _metric = m;
            _reload();
          },
        ),
        const SizedBox(height: 14),
        FutureBuilder<({int rank, String value})>(
          future: _rankFuture,
          builder: (context, snap) {
            final data = snap.data;
            if (data == null) return const SizedBox.shrink();
            return _YourRankCard(
              rank: data.rank,
              value: data.value,
              strings: strings,
            );
          },
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<LeaderboardEntry>>(
          future: _topFuture,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final entries = snap.data!;
            if (entries.isEmpty) {
              return _EmptyState(message: strings.leaderboardEmpty);
            }
            return Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  _LeaderboardRow(
                    rank: i + 1,
                    entry: entries[i],
                    metric: _metric,
                    period: _period,
                    strings: strings,
                    isMe: entries[i].uid == profile.uid,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PeriodMetricPicker extends StatelessWidget {
  const _PeriodMetricPicker({
    required this.period,
    required this.metric,
    required this.strings,
    required this.onPeriodChanged,
    required this.onMetricChanged,
  });

  final LeaderboardPeriod period;
  final LeaderboardMetric metric;
  final AppStrings strings;
  final ValueChanged<LeaderboardPeriod> onPeriodChanged;
  final ValueChanged<LeaderboardMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SegmentedButton<LeaderboardPeriod>(
          segments: [
            ButtonSegment(
              value: LeaderboardPeriod.weekly,
              label: Text(strings.leaderboardWeekly),
            ),
            ButtonSegment(
              value: LeaderboardPeriod.allTime,
              label: Text(strings.leaderboardAllTime),
            ),
          ],
          selected: {period},
          onSelectionChanged: (s) => onPeriodChanged(s.first),
        ),
        const SizedBox(height: 8),
        SegmentedButton<LeaderboardMetric>(
          segments: [
            ButtonSegment(
              value: LeaderboardMetric.wins,
              label: Text(strings.statsWins),
            ),
            ButtonSegment(
              value: LeaderboardMetric.level,
              label: Text(strings.level),
            ),
          ],
          selected: {metric},
          onSelectionChanged: (s) => onMetricChanged(s.first),
        ),
      ],
    );
  }
}

class _YourRankCard extends StatelessWidget {
  const _YourRankCard({
    required this.rank,
    required this.value,
    required this.strings,
  });

  final int rank;
  final String value;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: GameColors.accent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              strings.leaderboardYourRank,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '#$rank',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.metric,
    required this.period,
    required this.strings,
    required this.isMe,
  });

  final int rank;
  final LeaderboardEntry entry;
  final LeaderboardMetric metric;
  final LeaderboardPeriod period;
  final AppStrings strings;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final value = metric == LeaderboardMetric.wins
        ? '${entry.wins ?? 0}'
        : period == LeaderboardPeriod.allTime
            ? '${strings.level} ${entry.level ?? 1}'
            : '+${entry.xpGained ?? 0} XP';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? GameColors.accent.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: isMe ? Border.all(color: GameColors.accent, width: 1.4) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: GameColors.inkSoft,
              ),
            ),
          ),
          ProfileAvatar(photoUrl: entry.photoUrl, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.displayName ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: GameColors.ink,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: GameColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: GameColors.inkSoft,
            ),
          ),
        ),
      ),
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
                  fontSize: 18,
                  letterSpacing: 1.8,
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
