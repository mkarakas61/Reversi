import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/game_stats.dart';
import '../services/sound_service.dart';
import '../services/stats_storage.dart';
import '../theme/game_theme.dart';
import '../theme/wood_theme.dart';

/// Lifetime statistics screen, reached from the main menu. Shows totals,
/// streaks, a win/loss/draw pie chart and a per-mode breakdown, plus a
/// "reset statistics" action.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsStorage _storage = StatsStorage();
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _storage.load();
    if (mounted) {
      setState(() => _stats = stats);
    }
  }

  Future<void> _confirmReset() async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.statsResetTitle),
          content: Text(strings.statsResetBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.statsReset),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _storage.reset();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final stats = _stats;

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
                    title: strings.singlePlayerStatistics,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: stats == null
                        ? const Center(child: CircularProgressIndicator())
                        : _StatsBody(
                            stats: stats,
                            onReset: _confirmReset,
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

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats, required this.onReset});

  final GameStats stats;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (stats.totalGames == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            strings.statsEmpty,
            textAlign: TextAlign.center,
            style: WoodText.body(15,
                color: Wood.inkSoft, weight: FontWeight.w600),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _Section(
          title: strings.statsTotalGames,
          child: _OverviewGrid(stats: stats),
        ),
        _Section(
          title: strings.statsResultDistribution,
          child: _ResultPieChart(stats: stats),
        ),
        _Section(
          title: strings.statsByMode,
          child: _ModeBarChart(stats: stats),
        ),
        const SizedBox(height: 18),
        _ResetButton(onTap: onReset),
      ],
    );
  }
}

/// Small 2-column grid of headline numbers: totals, win rate, streaks, best
/// score gap, total flipped discs and total play time.
class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.stats});

  final GameStats stats;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final overall = stats.overall;
    final winRatePercent = (overall.winRate * 100).round();

    final tiles = [
      _StatTile(label: strings.statsTotalGames, value: '${stats.totalGames}'),
      _StatTile(label: strings.statsWinRate, value: '$winRatePercent%'),
      _StatTile(label: strings.statsWins, value: '${overall.wins}'),
      _StatTile(label: strings.statsLosses, value: '${overall.losses}'),
      _StatTile(label: strings.statsDraws, value: '${overall.draws}'),
      _StatTile(
        label: strings.statsCurrentStreak,
        value: '${stats.currentWinStreak}',
      ),
      _StatTile(
        label: strings.statsBestStreak,
        value: '${stats.bestWinStreak}',
      ),
      _StatTile(
        label: strings.statsBestScoreDiff,
        value: '${stats.bestScoreDiff}',
      ),
      _StatTile(
        label: strings.statsTotalFlipped,
        value: '${stats.totalFlippedDiscs}',
      ),
      _StatTile(
        label: strings.statsTotalPlayTime,
        value: strings.formatDuration(stats.totalPlayTimeSeconds),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE3CC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x297A5634)),
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
            style: WoodText.body(11.5,
                color: Wood.inkSoft, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Win/loss/draw pie chart with a colour-keyed legend.
class _ResultPieChart extends StatelessWidget {
  const _ResultPieChart({required this.stats});

  final GameStats stats;

  static const _winColor = Wood.accent; // #9A6B2F
  static const _lossColor = Wood.danger; // #A8442A
  static const _drawColor = Wood.warmGold; // #D8B36A

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final overall = stats.overall;
    final total = overall.totalGames.toDouble();

    final entries = [
      (label: strings.statsWins, value: overall.wins, color: _winColor),
      (label: strings.statsLosses, value: overall.losses, color: _lossColor),
      (label: strings.statsDraws, value: overall.draws, color: _drawColor),
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
                    titleStyle: WoodText.heading(13, color: Colors.white),
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
          style: WoodText.body(12.5,
              color: Wood.inkSoft, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Stacked bar chart of win/loss/draw counts for each [StatsMode] that has
/// at least one recorded game.
class _ModeBarChart extends StatelessWidget {
  const _ModeBarChart({required this.stats});

  final GameStats stats;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final modes = StatsMode.values
        .map((mode) => (mode: mode, record: stats.recordFor(mode)))
        .where((entry) => entry.record.totalGames > 0)
        .toList();

    if (modes.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxGames = modes
        .map((e) => e.record.totalGames)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxGames + 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= modes.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      strings.statsModeLabel(modes[index].mode),
                      textAlign: TextAlign.center,
                      style: WoodText.body(9.5,
                          color: Wood.inkSoft, weight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < modes.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: modes[i].record.totalGames.toDouble(),
                    width: 26,
                    borderRadius: BorderRadius.circular(6),
                    rodStackItems: [
                      BarChartRodStackItem(
                        0,
                        modes[i].record.wins.toDouble(),
                        _ResultPieChart._winColor,
                      ),
                      BarChartRodStackItem(
                        modes[i].record.wins.toDouble(),
                        (modes[i].record.wins + modes[i].record.draws)
                            .toDouble(),
                        _ResultPieChart._drawColor,
                      ),
                      BarChartRodStackItem(
                        (modes[i].record.wins + modes[i].record.draws)
                            .toDouble(),
                        modes[i].record.totalGames.toDouble(),
                        _ResultPieChart._lossColor,
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        label: Text(strings.statsReset),
        style: OutlinedButton.styleFrom(
          foregroundColor: Wood.danger,
          side: const BorderSide(color: Wood.danger, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: WoodText.heading(15, color: Wood.danger),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title.toUpperCase(),
                  style: WoodText.heading(22, color: Colors.white, spacing: 2.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 54), // balances the back button
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
