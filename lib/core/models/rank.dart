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

class Rank {
  const Rank(this.id, this.minTrophies, this.color);

  final RankId id;

  /// Inclusive trophy floor for this rank (mirrors trophy.ts).
  final int minTrophies;

  /// Identity colour (REV-60 ramp).
  final Color color;
}

/// Ascending by [minTrophies]. Thresholds mirror `RANKS` in trophy.ts exactly.
const List<Rank> kRanks = [
  Rank(RankId.caylak, 0, Color(0xFFA9744F)),
  Rank(RankId.acemi, 30, Color(0xFF8E9AAB)),
  Rank(RankId.kalfa, 100, Color(0xFFC89331)),
  Rank(RankId.usta, 250, Color(0xFF0E8C7E)),
  Rank(RankId.buyukusta, 550, Color(0xFF7A4FB5)),
  Rank(RankId.efsane, 1000, Color(0xFFF0A81E)),
];

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
