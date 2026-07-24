import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/profile/profile_scope.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/online_stats.dart';
import '../../../core/models/progress_history.dart';
import '../../../core/models/xp_level.dart';
import '../../../core/services/progress_history_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/game_colors.dart';
import '../../../shared/widgets/rank_badge.dart';
import '../../../shared/widgets/guest_upsell_card.dart';

/// Detailed online ranked statistics screen. Reached from the profile screen's
/// online record card. Reads live from [ProfileScope] so it stays in sync with
/// server-written Firestore data without a separate service call.
class OnlineStatsScreen extends StatelessWidget {
  const OnlineStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final profile = ProfileScope.of(context).profile;
    final stats = profile?.online ?? OnlineStats.empty;
    final xp = profile?.xp ?? 0;
    final level = profile?.level ?? 1;
    final isGuest = profile?.isGuest ?? false;

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
                    title: strings.onlineStatistics,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: isGuest
                        ? ListView(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            children: const [GuestUpsellCard()],
                          )
                        : stats.totalGames == 0
                            ? _EmptyState(message: strings.statsOnlineEmpty)
                            : _Body(
                                uid: profile!.uid,
                                stats: stats,
                                xp: xp,
                                level: level,
                                strings: strings,
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

class _Body extends StatelessWidget {
  const _Body({
    required this.uid,
    required this.stats,
    required this.xp,
    required this.level,
    required this.strings,
  });

  final String uid;
  final OnlineStats stats;
  final int xp;
  final int level;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _Section(
          title: strings.rankLabel,
          child: Align(
            alignment: Alignment.centerLeft,
            child: RankBadge(rank: stats.rank, trophies: stats.trophies),
          ),
        ),
        _Section(
          title: '${strings.level} $level',
          child: _XpProgressRow(xp: xp, level: level, strings: strings),
        ),
        _Section(
          title: strings.statsTotalGames,
          child: _OverviewGrid(stats: stats, strings: strings),
        ),
        _Section(
          title: strings.statsResultDistribution,
          child: _ResultPieChart(stats: stats, strings: strings),
        ),
        StreamBuilder<List<HistoryEntry>>(
          stream: ProgressHistoryService.instance.watch(uid),
          builder: (context, snap) {
            final history = snap.data ?? const <HistoryEntry>[];
            if (history.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                _Section(
                  title: strings.statsWinRateTrend,
                  child: _WinRateTrendChart(history: history),
                ),
                _Section(
                  title: strings.statsActivity,
                  child: _ActivityChart(history: history, strings: strings),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _XpProgressRow extends StatelessWidget {
  const _XpProgressRow({
    required this.xp,
    required this.level,
    required this.strings,
  });

  final int xp;
  final int level;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final progress = XpLevel.levelProgress(xp);
    final into = XpLevel.xpIntoLevel(xp);
    final range = XpLevel.xpRangeForLevel(xp);

    return Column(
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
                    '$xp XP',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: GameColors.ink,
                    ),
                  ),
                  Text(
                    '$into / $range XP',
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
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${strings.level} ${level + 1}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: GameColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.stats, required this.strings});

  final OnlineStats stats;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final winRatePercent = (stats.winRate * 100).round();
    final tiles = [
      _StatTile(label: strings.statsTotalGames, value: '${stats.totalGames}'),
      _StatTile(label: strings.statsWinRate, value: '$winRatePercent%'),
      _StatTile(label: strings.statsWins, value: '${stats.wins}'),
      _StatTile(label: strings.statsLosses, value: '${stats.losses}'),
      _StatTile(label: strings.statsDraws, value: '${stats.draws}'),
      _StatTile(
        label: strings.statsCurrentStreak,
        value: '${stats.currentStreak}',
      ),
      _StatTile(
        label: strings.statsBestStreak,
        value: '${stats.bestStreak}',
      ),
      _StatTile(
        label: strings.statsBestScoreDiff,
        value: '${stats.bestScoreDiff}',
      ),
      _StatTile(
        label: strings.statsTotalFlipped,
        value: '${stats.totalFlipped}',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.1,
              color: GameColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

class _ResultPieChart extends StatelessWidget {
  const _ResultPieChart({required this.stats, required this.strings});

  final OnlineStats stats;
  final AppStrings strings;

  static const _winColor = GameColors.accent;
  static const _lossColor = GameColors.accent2;
  static const _drawColor = Color(0xFFFFC83D);

  @override
  Widget build(BuildContext context) {
    final total = stats.totalGames.toDouble();
    final entries = [
      (label: strings.statsWins, value: stats.wins, color: _winColor),
      (label: strings.statsLosses, value: stats.losses, color: _lossColor),
      (label: strings.statsDraws, value: stats.draws, color: _drawColor),
    ].where((e) => e.value > 0).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final entry in entries)
                  PieChartSectionData(
                    value: entry.value.toDouble(),
                    color: entry.color,
                    radius: 52,
                    title: '${(entry.value / total * 100).round()}%',
                    titleStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final entry in entries)
              _LegendItem(color: entry.color, label: entry.label),
          ],
        ),
      ],
    );
  }
}

/// Rolling win-rate trend across the player's recent games: at each point,
/// the win rate over that game and up to the 19 before it (or all games so
/// far, if fewer than 20 have been played).
class _WinRateTrendChart extends StatelessWidget {
  const _WinRateTrendChart({required this.history});

  final List<HistoryEntry> history;

  static const int _window = 20;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < history.length; i++) {
      final start = (i - _window + 1).clamp(0, history.length);
      final windowGames = history.sublist(start, i + 1);
      final wins = windowGames.where((g) => g.isWin).length;
      spots.add(FlSpot(i.toDouble(), wins / windowGames.length * 100));
    }

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: GameColors.accent,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: GameColors.accent.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Games played per week (bar height) with a win/loss/draw color breakdown
/// (stacked segments), for the last 8 weeks that had any activity.
class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.history, required this.strings});

  final List<HistoryEntry> history;
  final AppStrings strings;

  static const int _weeks = 8;
  static const _winColor = GameColors.accent;
  static const _lossColor = GameColors.accent2;
  static const _drawColor = Color(0xFFFFC83D);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = List.generate(_weeks, (_) => <HistoryEntry>[]);
    for (final entry in history) {
      final weeksAgo = now.difference(entry.ts).inDays ~/ 7;
      if (weeksAgo >= 0 && weeksAgo < _weeks) {
        buckets[_weeks - 1 - weeksAgo].add(entry);
      }
    }

    double maxGames = 1;
    for (final bucket in buckets) {
      if (bucket.length.toDouble() > maxGames) maxGames = bucket.length.toDouble();
    }

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              maxY: maxGames,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: const BarTouchData(enabled: false),
              barGroups: [
                for (var i = 0; i < buckets.length; i++)
                  _weekBarGroup(i, buckets[i]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _LegendItem(color: _winColor, label: strings.statsWins),
            _LegendItem(color: _lossColor, label: strings.statsLosses),
            _LegendItem(color: _drawColor, label: strings.statsDraws),
          ],
        ),
      ],
    );
  }

  BarChartGroupData _weekBarGroup(int x, List<HistoryEntry> games) {
    final wins = games.where((g) => g.result == 'win').length;
    final losses = games.where((g) => g.result == 'loss').length;
    final draws = games.where((g) => g.result == 'draw').length;
    final total = (wins + losses + draws).toDouble();
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: total,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
            BarChartRodStackItem(0, wins.toDouble(), _winColor),
            BarChartRodStackItem(
                wins.toDouble(), (wins + losses).toDouble(), _lossColor),
            BarChartRodStackItem(
                (wins + losses).toDouble(), total, _drawColor),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
            color: GameColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), offset: Offset(0, 6)),
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: GameColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
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
