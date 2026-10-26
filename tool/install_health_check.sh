#!/usr/bin/env bash
# Installs the daily online health check (tool/online_health_check.sh) as a
# launchd job. Re-run it after changing the check — it replaces the installed
# copy and reloads the job.
#
# The check is copied out of the repo rather than run from it: this repo lives
# under ~/Documents, which macOS protects, and a launchd agent reading it gets
# "Operation not permitted" unless the user grants Full Disk Access. Copying to
# Application Support avoids asking for a privilege the job does not need.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/online_health_check.sh"
DEST_DIR="$HOME/Library/Application Support/Reversi"
DEST="$DEST_DIR/online_health_check.sh"
LABEL="com.mustafakarakas.reversi.health"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

mkdir -p "$DEST_DIR" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cp "$SRC" "$DEST"
chmod +x "$DEST"

cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$DEST</string>
  </array>

  <!-- Every morning at 10:00. If the Mac was asleep then, launchd runs it on
       the next wake rather than skipping the day. -->
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>10</integer>
    <key>Minute</key><integer>0</integer>
  </dict>

  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>

  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/reversi-health.out.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/reversi-health.err.log</string>
</dict>
</plist>
PLISTEOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "Kuruldu: $LABEL (her gün 10:00)"
echo "Kontrol:  $DEST"
echo "Günlük:   $HOME/Library/Logs/reversi-health.log"
echo "Elle çalıştır: launchctl kickstart -p gui/$(id -u)/$LABEL"
