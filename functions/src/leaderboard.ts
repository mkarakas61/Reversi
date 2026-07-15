/**
 * ISO-8601 week identifier for a date, e.g. "2026-W25". Pure so it's easy to
 * unit-test; used to key `leaderboards/{weekId}/players`.
 */
export function weekId(date: Date): string {
  const d = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
  );
  const dayNum = d.getUTCDay() || 7; // Monday=1 ... Sunday=7
  d.setUTCDate(d.getUTCDate() + 4 - dayNum); // Thursday of this ISO week
  const isoYear = d.getUTCFullYear();
  const yearStart = new Date(Date.UTC(isoYear, 0, 1));
  const weekNum = Math.ceil(
    ((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7
  );
  return `${isoYear}-W${String(weekNum).padStart(2, "0")}`;
}
