import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/rank.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/game_colors.dart';
import '../../core/theme/wood_theme.dart';
import '../../shared/widgets/rank_badge.dart';

/// The trophy road: the whole rank ladder on one vertical line, ranks hanging
/// off it right/left in turn from Çaylak down to Efsane, with the player's own
/// position marked on the line so progress is read at a glance instead of from
/// a "how many trophies left" number. Opened from the profile's rank card.
class RankRoadScreen extends StatelessWidget {
  const RankRoadScreen({super.key, required this.trophies});

  final int trophies;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final rank = rankFor(trophies);

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
                    title: strings.trophyRoad,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 26, 16, 28),
                      children: [
                        Center(child: RankBadge(rank: rank, trophies: trophies)),
                        const SizedBox(height: 6),
                        Text(
                          strings.youAreHere,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: GameColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _Road(trophies: trophies, strings: strings),
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

/// The road itself: the line and its nodes are painted, the rank cards and the
/// player marker are laid on top.
class _Road extends StatelessWidget {
  const _Road({required this.trophies, required this.strings});

  final int trophies;
  final AppStrings strings;

  /// Vertical space each rank gets on the road.
  static const double _rowHeight = 96;

  /// Width reserved down the middle for the line, its nodes and the marker.
  static const double _gutter = 66;

  static double _nodeY(int index) => _rowHeight * index + _rowHeight / 2;

  /// Where the player sits on the line: on their own rank's node, advanced
  /// toward the next node by their progress through the band.
  static double _markerY(int trophies) {
    final current = kRanks.indexOf(rankFor(trophies));
    if (current == kRanks.length - 1) return _nodeY(current);
    return _nodeY(current) +
        (_nodeY(current + 1) - _nodeY(current)) * rankProgress(trophies);
  }

  @override
  Widget build(BuildContext context) {
    final markerY = _markerY(trophies);
    final rank = rankFor(trophies);

    return SizedBox(
      height: _rowHeight * kRanks.length,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoadPainter(
                trophies: trophies,
                rowHeight: _rowHeight,
                markerY: markerY,
              ),
            ),
          ),
          Column(
            children: [
              for (var i = 0; i < kRanks.length; i++)
                SizedBox(
                  height: _rowHeight,
                  // Çaylak starts on the right, and each rank below it swaps
                  // side so the road zigzags down the line.
                  child: Row(
                    children: [
                      Expanded(
                        child: i.isEven
                            ? const SizedBox.shrink()
                            : _RankStop(
                                rank: kRanks[i],
                                trophies: trophies,
                                strings: strings,
                                alignEnd: true,
                              ),
                      ),
                      const SizedBox(width: _gutter),
                      Expanded(
                        child: i.isEven
                            ? _RankStop(
                                rank: kRanks[i],
                                trophies: trophies,
                                strings: strings,
                                alignEnd: false,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Player marker, centred on the line.
          Positioned(
            top: markerY - 17,
            left: 0,
            right: 0,
            child: Center(child: _Marker(trophies: trophies, color: rank.color)),
          ),
        ],
      ),
    );
  }
}

/// One rank's card, hanging off its side of the road: the title with the
/// trophies it takes to get there. Ranks not yet reached are dimmed; the
/// player's current rank is outlined in its own colour.
class _RankStop extends StatelessWidget {
  const _RankStop({
    required this.rank,
    required this.trophies,
    required this.strings,
    required this.alignEnd,
  });

  final Rank rank;
  final int trophies;
  final AppStrings strings;

  /// Whether the card hugs the road from the left side.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final reached = trophies >= rank.minTrophies;
    final isCurrent = rankFor(trophies).id == rank.id;
    final tint = reached ? rank.color : GameColors.inkSoft;

    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: reached ? 1.0 : 0.62,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? rank.color : const Color(0x14000000),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 5),
                blurRadius: 14,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.military_tech, size: 17, color: tint),
                  const SizedBox(width: 5),
                  Text(
                    strings.rankTitle(rank.id),
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: GameColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${rank.minTrophies} ${strings.trophies}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: GameColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The player's own trophy count, riding the line at their position.
class _Marker extends StatelessWidget {
  const _Marker({required this.trophies, required this.color});

  final int trophies;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$trophies',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the road: the line down the middle, filled up to the player and muted
/// beyond, with a node at every rank.
class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required this.trophies,
    required this.rowHeight,
    required this.markerY,
  });

  final int trophies;
  final double rowHeight;
  final double markerY;

  static const double _lineWidth = 6;
  static const double _nodeRadius = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final topY = rowHeight / 2;
    final bottomY = rowHeight * (kRanks.length - 1) + rowHeight / 2;

    void line(double fromY, double toY, Color color) {
      canvas.drawLine(
        Offset(cx, fromY),
        Offset(cx, toY),
        Paint()
          ..color = color
          ..strokeWidth = _lineWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    // The whole road, then the stretch already travelled in the player's rank
    // colour.
    line(topY, bottomY, GameColors.inkSoft.withValues(alpha: 0.22));
    if (markerY > topY) {
      line(topY, markerY, rankFor(trophies).color);
    }

    for (var i = 0; i < kRanks.length; i++) {
      final rank = kRanks[i];
      final reached = trophies >= rank.minTrophies;
      final center = Offset(cx, rowHeight * i + rowHeight / 2);
      canvas.drawCircle(
        center,
        _nodeRadius,
        Paint()..color = reached ? rank.color : const Color(0xFFF2EEE4),
      );
      canvas.drawCircle(
        center,
        _nodeRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = reached
              ? Colors.white
              : GameColors.inkSoft.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.trophies != trophies ||
      old.rowHeight != rowHeight ||
      old.markerY != markerY;
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
