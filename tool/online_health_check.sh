#!/usr/bin/env bash
# Asks, once a day, whether the online backend is still alive — and says so out
# loud when it is not.
#
# Written after the outage of 2026-10-26: the project's billing was switched
# off on 16 October and every Cloud Function died with it. Online was dead for
# ten days and nobody noticed, because the app dressed the failure as "your
# opponent did not join" and the only other witness was a log nobody reads.
#
# A Cloud Billing budget alert would not have caught it — a budget warns that
# spending went UP, and a disabled project spends nothing. So this check runs
# outside Google entirely, on Mustafa's Mac, and asks the one question that
# matters: did the five-minute sweep actually run recently?
#
# `sweepAbandonedGames` is the liveness probe because it is scheduled: a
# healthy backend logs it every five minutes whether or not anyone is playing.
# Polling a callable instead would prove nothing, since `ping` demands IAM auth
# and answers an outside caller with 403 whether the backend is well or dead.
#
# Exit codes: 0 healthy · 1 degraded (capacity) · 2 down · 3 could not tell.
set -uo pipefail

# launchd hands a job a bare PATH, and the firebase CLI is a `#!/usr/bin/env
# node` script — without this it dies with "env: node: No such file".
export PATH="/usr/local/bin:$PATH"

PROJECT="reversi-3a506"
ACCOUNT="mustafakarakas1071@gmail.com"
FIREBASE="${FIREBASE_BIN:-/usr/local/bin/firebase}"
LOG="$HOME/Library/Logs/reversi-health.log"

# The sweep runs every 5 minutes, so 40 entries is a little over three hours —
# which is also the window we judge. Judging by entry count alone would keep
# reporting this morning's outage long after it healed; the question is whether
# the backend is well NOW.
ENTRIES=40
WINDOW_HOURS=3

say() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M')" "$1" | tee -a "$LOG"; }

# Nags only on bad news, and only through Notification Center: a daily "all
# well" popup is a notification people learn to dismiss without reading.
notify() {
  /usr/bin/osascript -e "display notification \"$1\" with title \"Reversi online\" sound name \"Basso\"" 2>/dev/null || true
}

mkdir -p "$(dirname "$LOG")"

# The log API fails outright often enough that one bad answer must not read as
# an outage — that would cry wolf and the alert would stop being believed.
out=""
for attempt in 1 2 3; do
  out="$("$FIREBASE" functions:log --only sweepAbandonedGames -n "$ENTRIES" \
    --project "$PROJECT" --account "$ACCOUNT" 2>&1)"
  grep -q "Failed to retrieve log entries" <<<"$out" || break
  sleep 5
done

if grep -q "Failed to retrieve log entries" <<<"$out"; then
  say "BELİRSİZ · Google log servisi cevap vermedi (3 deneme). Durum bilinmiyor."
  exit 3
fi

# Timestamps are ISO-8601 and zero-padded, so a plain string comparison orders
# them correctly and needs no date parsing per line.
cutoff="$(date -u -v-${WINDOW_HOURS}H '+%Y-%m-%dT%H:%M:%S')"
recent="$(awk -v c="$cutoff" '$1 >= c' <<<"$out")"

if [ -z "${recent//[[:space:]]/}" ]; then
  say "ÇÖKTÜ · Son ${WINDOW_HOURS} saatte hiç süpürme kaydı yok. Zamanlayıcı ölü."
  notify "Son ${WINDOW_HOURS} saattir sunucudan ses yok — online muhtemelen bozuk."
  exit 2
fi

if grep -qi "billing is disabled" <<<"$recent"; then
  say "ÇÖKTÜ · Faturalandırma kapalı. Online tamamen ölü."
  notify "Faturalandırma kapalı — online çalışmıyor. Cloud Billing'i kontrol et."
  exit 2
fi

# A successful run leaves a plain informational entry; "W …aborted" ones are
# Cloud Run refusing to start an instance and prove the opposite.
alive="$(grep -c " I sweepabandonedgames:" <<<"$recent" || true)"
aborted="$(grep -ci "no available instance" <<<"$recent" || true)"

if [ "$alive" -eq 0 ]; then
  say "ÇÖKTÜ · Son ${WINDOW_HOURS} saatte tek bir başarılı süpürme yok (${aborted} reddedildi)."
  notify "Zamanlanmış süpürme çalışmıyor — online muhtemelen bozuk."
  exit 2
fi

if [ "$aborted" -gt 0 ]; then
  say "AKSIYOR · ${alive} başarılı süpürme, ${aborted} 'örnek yok' reddi. Kapasite dalgalı."
  notify "Sunucu aksıyor: ${aborted} istek örnek bulamadı. Eşleşme gecikebilir."
  exit 1
fi

say "SAĞLAM · ${alive} başarılı süpürme, reddedilen yok."
exit 0
