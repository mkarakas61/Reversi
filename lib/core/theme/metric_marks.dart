/// The marks the app counts progress in. One place for them so every surface
/// that shows a tally — the leaderboard rows, the profile, the standing trophy
/// indicator — draws the same symbol, and a change lands everywhere at once.
///
/// These are decoration, not words: wherever one appears, the metric is also
/// named in text nearby (the leaderboard's segmented picker) or given to screen
/// readers as `leaderboardUnitWins` / `leaderboardUnitTrophies`.
library;

/// Ranked wins. A medal, kept visually distinct from [kTrophyMark] — the two
/// metrics swap under the same column and must not be mistaken for each other.
const String kWinsMark = '🏅';

/// Trophies — the single progress currency behind ranks (REV-67).
const String kTrophyMark = '🏆';
