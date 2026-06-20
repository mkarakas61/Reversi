import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../game/profile_scope.dart';
import '../l10n/app_strings.dart';
import '../models/online_stats.dart';
import '../models/xp_level.dart';
import '../theme/wood_theme.dart';

/// Detailed online ranked statistics screen. Reached from the profile screen's
/// online record card. Reads live from [ProfileScope] so it stays in sync with
/// server-written Firestore data without a separate service call.
class OnlineStatsScreen extends StatelessWidget {
  const OnlineStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final controller = ProfileScope.of(context);
    final profile = controller.profile;
    final stats = profile?.online ?? OnlineStats.empty;
    final xp = profile?.xp ?? 0;
    final level = profile?.level ?? 1;

    return Scaffold(
      backgroundColor: Wood.cream,
      appBar: WoodAppBar(
        title: strings.onlineStatistics,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: stats.totalGames == 0
          ? _EmptyState(message: strings.statsOnlineEmpty)
          : _Body(
              stats: stats,
              xp: xp,
              level: level,
              strings: strings,
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.stats,
    required this.xp,
    required this.level,
    required this.strings,
  });

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
                  begin: Alignment(0.7, -0.7),
                  end: Alignment(-0.7, 0.7),
                  colors: [Color(0xFFC9A05A), Color(0xFF8A5E22)],
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
                    '$xp XP',
                    style: WoodText.heading(18, color: Wood.ink),
                  ),
                  Text(
                    '$into / $range XP',
                    style: WoodText.body(12, color: Wood.inkSoft, weight: FontWeight.w600),
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
            backgroundColor: const Color(0x245A3D26),
            valueColor: const AlwaysStoppedAnimation(Wood.gold),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${strings.level} ${level + 1}',
            style: WoodText.body(11, color: Wood.inkSoft, weight: FontWeight.w600),
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
        color: const Color(0xFFEFE3CC),
        border: Border.all(color: const Color(0x297A5634), width: 1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: WoodText.heading(22, color: Wood.ink),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WoodText.body(11.5, color: Wood.inkSoft, weight: FontWeight.w600),
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

  static const _winColor = Wood.accent;
  static const _lossColor = Wood.danger;
  static const _drawColor = Wood.warmGold;

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
                    titleStyle: WoodText.body(13, color: Colors.white, weight: FontWeight.w800),
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
          style: WoodText.body(12.5, color: Wood.inkSoft, weight: FontWeight.w800),
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
          style: WoodText.body(15, color: Wood.inkSoft, weight: FontWeight.w700),
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
      decoration: WoodDeco.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WoodText.heading(16, color: Wood.ink),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

