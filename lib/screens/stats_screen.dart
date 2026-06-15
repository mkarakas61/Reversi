import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/game_stats.dart';
import '../services/stats_storage.dart';
import '../theme/game_theme.dart';

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
                    title: strings.statistics,
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

/// Win/loss/draw pie chart with a colour-keyed legend.
class _ResultPieChart extends StatelessWidget {
  const _ResultPieChart({required this.stats});

  final GameStats stats;

  static const _winColor = GameColors.accent;
  static const _lossColor = GameColors.accent2;
  static const _drawColor = Color(0xFFFFC83D);

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
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                        color: GameColors.inkSoft,
                      ),
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
          foregroundColor: GameColors.accent2,
          side: const BorderSide(color: GameColors.accent2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(0, size.height * 0.82)
      ..close();
  }

  @override
  bool shouldReclip(_HeaderClipper old) => false;
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
          onTap: onTap,
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
