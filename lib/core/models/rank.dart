import 'package:flutter/painting.dart' show Color;

/// Trophy (kupa) rank ladder — the Dart mirror of `functions/src/trophy.ts`
/// (REV-73 / REV-67). MUST stay in sync with the server: same ids, same
/// thresholds. The server owns the trophy math and writes `online.trophies`;
/// the client only maps a trophy count to a rank for display (title + colour).
///
/// Colours are the REV-60 rank-identity ramp (bronze-copper → steel-silver →
/// gold-brass → brand turquoise → noble purple → legendary gold); the title
/// text lives in `AppStrings.rankTitle` (TR/EN).
enum RankId { caylak, acemi, kalfa, usta, buyukusta, efsane }

/// The avatar frame art for a rank (REV-61), plus the geometry needed to sit an
/// avatar inside it.
///
/// The frames are 512×512 transparent PNGs, but their openings are neither the
/// same size nor centred on the canvas: the crowned frames (Büyük Usta, Efsane)
/// spend canvas on the crown and wings, so their opening is both smaller and
/// pushed down. Hard-coding one scale would misplace the avatar in four of six
/// frames, so each frame carries its own measured opening instead.
///
/// All three values are fractions of the canvas edge, measured off the alpha
/// channel of the shipped art. To render: draw the frame at
/// `avatarDiameter / openingFraction`, then offset it so `(centerX, centerY)`
/// lands on the avatar's centre.
///
/// [openingFraction] is the largest circle that stays under ~2.5% covered by
/// frame art, not the widest gap: the crowned openings are ellipses (wider than
/// tall), so taking the width would hide an avatar's forehead and chin behind
/// the crown. [centerX] is the symmetry axis for every frame; only [centerY]
/// really moves.
class RankFrame {
  const RankFrame({
    required this.asset,
    required this.openingFraction,
    required this.centerX,
    required this.centerY,
  });

  /// Asset path of the 512×512 transparent frame.
  final String asset;

  /// Diameter of the frame's inner opening, as a fraction of the canvas edge.
  final double openingFraction;

  /// Horizontal centre of that opening, as a fraction of the canvas width.
  final double centerX;

  /// Vertical centre of that opening, as a fraction of the canvas height.
  final double centerY;

  /// Frame edge length needed for an opening of [avatarDiameter].
  double frameSizeFor(double avatarDiameter) =>
      avatarDiameter / openingFraction;
}

class Rank {
  const Rank(this.id, this.minTrophies, this.color, this.frame);

  final RankId id;

  /// Inclusive trophy floor for this rank (mirrors trophy.ts).
  final int minTrophies;

  /// Identity colour (REV-60 ramp).
  final Color color;

  /// Avatar frame art for this rank (REV-61).
  final RankFrame frame;
}

/// Ascending by [minTrophies]. Thresholds mirror `RANKS` in trophy.ts exactly.
const List<Rank> kRanks = [
  Rank(RankId.caylak, 0, Color(0xFFA9744F), _caylakFrame),
  Rank(RankId.acemi, 30, Color(0xFF8E9AAB), _acemiFrame),
  Rank(RankId.kalfa, 100, Color(0xFFC89331), _kalfaFrame),
  Rank(RankId.usta, 250, Color(0xFF0E8C7E), _ustaFrame),
  Rank(RankId.buyukusta, 550, Color(0xFF7A4FB5), _buyukustaFrame),
  Rank(RankId.efsane, 1000, Color(0xFFF0A81E), _efsaneFrame),
];

const _caylakFrame = RankFrame(
  asset: 'assets/frames/tier/caylak.png',
  openingFraction: 0.7281,
  centerX: 0.4990,
  centerY: 0.4961,
);
const _acemiFrame = RankFrame(
  asset: 'assets/frames/tier/acemi.png',
  openingFraction: 0.7267,
  centerX: 0.4990,
  centerY: 0.4961,
);
const _kalfaFrame = RankFrame(
  asset: 'assets/frames/tier/kalfa.png',
  openingFraction: 0.7130,
  centerX: 0.4990,
  centerY: 0.5000,
);
const _ustaFrame = RankFrame(
  asset: 'assets/frames/tier/usta.png',
  openingFraction: 0.6900,
  centerX: 0.4990,
  centerY: 0.4785,
);
const _buyukustaFrame = RankFrame(
  asset: 'assets/frames/tier/buyukusta.png',
  openingFraction: 0.4414,
  centerX: 0.4990,
  centerY: 0.5215,
);
const _efsaneFrame = RankFrame(
  asset: 'assets/frames/tier/efsane.png',
  openingFraction: 0.4929,
  centerX: 0.4990,
  centerY: 0.5469,
);

/// The rank held at [trophies] (never below the first rank, Çaylak).
Rank rankFor(int trophies) {
  var current = kRanks.first;
  for (final r in kRanks) {
    if (trophies >= r.minTrophies) {
      current = r;
    } else {
      break;
    }
  }
  return current;
}

/// Trophies still needed to reach the next rank, or `null` at the top rank.
int? trophiesToNext(int trophies) {
  final idx = kRanks.indexOf(rankFor(trophies));
  if (idx == kRanks.length - 1) return null;
  return kRanks[idx + 1].minTrophies - trophies;
}

/// The trophy band of the rank held at [trophies]: its inclusive floor and the
/// next rank's threshold, which is `null` at the top rank. These are the two
/// numbers shown at the ends of a rank progress bar (so the player reads where
/// the band starts and ends instead of a bare "how many left" count).
(int, int?) rankBand(int trophies) {
  final idx = kRanks.indexOf(rankFor(trophies));
  return (
    kRanks[idx].minTrophies,
    idx == kRanks.length - 1 ? null : kRanks[idx + 1].minTrophies,
  );
}

/// Progress in `[0, 1]` through the current rank band toward the next rank;
/// `1.0` once the top rank is reached. Used by the profile / match-result
/// progress bars (REV-67 display, REV-74).
double rankProgress(int trophies) {
  final current = rankFor(trophies);
  final idx = kRanks.indexOf(current);
  if (idx == kRanks.length - 1) return 1.0;
  final floor = current.minTrophies;
  final ceil = kRanks[idx + 1].minTrophies;
  return ((trophies - floor) / (ceil - floor)).clamp(0.0, 1.0);
}
