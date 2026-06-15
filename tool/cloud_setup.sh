#!/usr/bin/env bash
# Bootstraps the Flutter SDK in a claude.ai/code cloud environment so the
# autonomous build agent can run `flutter analyze` and `flutter test` instead
# of editing code blind. Set this as the environment's setup/maintenance
# command (e.g. `bash tool/cloud_setup.sh`). It is idempotent and cached
# between runs once the environment is snapshotted.
set -euo pipefail

FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"
FLUTTER_CHANNEL="stable"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Cloning Flutter ($FLUTTER_CHANNEL)…"
  git clone --depth 1 -b "$FLUTTER_CHANNEL" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Make flutter/dart available to the agent's later shells.
for profile in "$HOME/.bashrc" "$HOME/.profile"; do
  if [ -f "$profile" ] && ! grep -q 'flutter/bin' "$profile" 2>/dev/null; then
    echo 'export PATH="'"$FLUTTER_DIR"'/bin:$PATH"' >> "$profile"
  fi
done
# Best-effort global symlinks (ignored if not permitted).
ln -sf "$FLUTTER_DIR/bin/flutter" /usr/local/bin/flutter 2>/dev/null || true
ln -sf "$FLUTTER_DIR/bin/dart" /usr/local/bin/dart 2>/dev/null || true

git config --global --add safe.directory "$FLUTTER_DIR" || true

echo "Warming the toolchain…"
flutter --version
flutter precache --universal
flutter pub get

echo "Flutter ready: $(flutter --version | head -1)"
