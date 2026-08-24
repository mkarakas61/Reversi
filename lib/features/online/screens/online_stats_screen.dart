import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/profile/profile_scope.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/online_stats.dart';
import '../../../core/models/progress_history.dart';
import '../../../core/services/progress_history_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/game_colors.dart';
import '../../../core/theme/wood_theme.dart';
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
    final isGuest = profile?.isGuest ?? false;

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
    required this.strings,
  });

  final String uid;
  final OnlineStats stats;
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
          title: strings.statsTotalGames,
          child: _OverviewGrid(stats: stats, strings: strings),
        ),
        _Section(
          title: strings.statsResultDistribution,
          caption: strings.statsResultCaption(stats.totalGames),
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
                  caption: strings.statsTrendCaption(
                    _WinRateTrendChart.window,
                  ),
                  child: _WinRateTrendChart(history: history),
                ),
                _Section(
                  title: strings.statsActivity,
                  caption: strings.statsActivityCaption(
                    _ActivityChart.weeks,
                  ),
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
              _LegendItem(
                color: entry.color,
                label: strings.statsLegendWithCount(entry.label, entry.value),
              ),
          ],
        ),
      ],
    );
  }
}

/// Rolling win-rate trend: at each game, the win rate over that game and the
/// [window] − 1 before it.
///
/// The chart used to draw the line with `titlesData: show: false` — no scale,
/// no zero, no hundred, and nothing saying the vertical axis was a percentage
/// at all. A curve with no axis cannot be read, only admired, so this version
/// labels 0 / 50 / 100, marks the halfway line, and prints where the line ends
/// up (2026-08-24).
///
/// It also refuses to draw below [_minGames]. With three games played the
/// "rolling window" is three games, and the line swings between 0% and 100% on
/// every result — a shape that looks like a trend and is noise.
class _WinRateTrendChart extends StatelessWidget {
  const _WinRateTrendChart({required this.history});

  final List<HistoryEntry> history;

  /// How many games each point averages over, once there are that many.
  static const int window = 20;

  /// Fewest games a point may average over. The window fills up from the first
  /// game, so without this the leftmost point is one game — always 0% or 100% —
  /// and the line opens with a cliff that is an artefact, not a result.
  static const int _minWindow = 5;

  /// Below this there are too few points to draw a line at all.
  static const int _minGames = 8;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (history.length < _minGames) {
      return Text(
        strings.statsTrendNeedsMore(_minGames, history.length),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: GameColors.inkSoft,
        ),
      );
    }

    final spots = <FlSpot>[];
    // Starts at the first game that has a full enough window behind it.
    for (var i = _minWindow - 1; i < history.length; i++) {
      final start = (i - window + 1).clamp(0, history.length);
      final windowGames = history.sublist(start, i + 1);
      final wins = windowGames.where((g) => g.isWin).length;
      spots.add(FlSpot(i.toDouble(), wins / windowGames.length * 100));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: GameColors.inkSoft.withValues(alpha: 0.18),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                // The horizontal axis is "games, oldest to newest". Numbering
                // them would invite the wrong question (which game was #7?);
                // the caption says which way time runs, which is all the line
                // needs.
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 50,
                    // Wide enough for "%100" on one line: at 34 it wrapped, and
                    // the axis read "%10" with a stray "0" under it.
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        '%${value.round()}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          color: GameColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
        ),
        const SizedBox(height: 8),
        // The number the line ends on, spelled out. A reader who takes one
        // thing from the chart should take this.
        Text(
          strings.statsTrendLatest(spots.last.y.round()),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: GameColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Games played per week for the last [weeks] weeks, split by result.
///
/// The bars used to carry no labels at all: no counts, no axis, no idea which
/// end was this week. Now each bar is capped with the number of games it stands
/// for and the two ends of the range are named, so an empty column reads as
/// "no games that week" instead of as a rendering fault (2026-08-24).
class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.history, required this.strings});

  final List<HistoryEntry> history;
  final AppStrings strings;

  static const int weeks = 8;
  static const _winColor = GameColors.accent;
  static const _lossColor = GameColors.accent2;
  static const _drawColor = Color(0xFFFFC83D);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = List.generate(weeks, (_) => <HistoryEntry>[]);
    for (final entry in history) {
      final weeksAgo = now.difference(entry.ts).inDays ~/ 7;
      if (weeksAgo >= 0 && weeksAgo < weeks) {
        buckets[weeks - 1 - weeksAgo].add(entry);
      }
    }

    double maxGames = 1;
    for (final bucket in buckets) {
      if (bucket.length.toDouble() > maxGames) {
        maxGames = bucket.length.toDouble();
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              // Headroom for the count printed above the tallest bar, which
              // would otherwise be clipped by the top of the chart.
              maxY: maxGames * 1.25,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              // Tooltips are how fl_chart draws a label on a bar; they are
              // pinned open (see showingTooltipIndicators) rather than shown on
              // touch, and stripped of their bubble so only the number is left.
              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 2,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                    '${rod.toY.round()}',
                    const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                      color: GameColors.inkSoft,
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < buckets.length; i++)
                  _weekBarGroup(i, buckets[i]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Which end is which. Without it the row of bars has no direction, and
        // a reader can as easily assume the newest week is on the left.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AxisEnd(strings.statsWeeksAgo(weeks)),
            _AxisEnd(strings.statsWeekNow),
          ],
        ),
        const SizedBox(height: 10),
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
      // A week with no games gets no label: "0" over an empty column is noise,
      // and the gap already says it.
      showingTooltipIndicators: total > 0 ? const [0] : const [],
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

/// A label under one end of the activity chart.
class _AxisEnd extends StatelessWidget {
  const _AxisEnd(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          color: GameColors.inkSoft,
        ),
      );
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
  const _Section({required this.title, required this.child, this.caption});

  final String title;
  final Widget child;

  /// One line under the title saying what the chart below actually measures.
  /// The charts on this page had no axes and no explanation, so a line and a
  /// row of bars were shapes rather than information (Mustafa, 2026-08-24).
  final String? caption;

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
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.35,
                color: GameColors.inkSoft,
              ),
            ),
          ],
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
