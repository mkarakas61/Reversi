/// ISO-8601 week identifier for a date, e.g. "2026-W25". Mirrors
/// `functions/src/leaderboard.ts` — used to key `leaderboards/{weekId}`.
String weekId(DateTime date) {
  final utc = DateTime.utc(date.year, date.month, date.day);
  final thursday = utc.add(Duration(days: 4 - utc.weekday)); // Mon=1..Sun=7
  final isoYear = thursday.year;
  final yearStart = DateTime.utc(isoYear, 1, 1);
  final weekNum = ((thursday.difference(yearStart).inDays + 1) / 7).ceil();
  return '$isoYear-W${weekNum.toString().padLeft(2, '0')}';
}
