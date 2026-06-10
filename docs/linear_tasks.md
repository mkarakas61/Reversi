# Linear Task Backlog

Use these tasks when the Linear workspace/team is connected.

## Project: Reversi Android MVP

1. Flutter Android project setup
   - Create and verify Flutter Android project structure.
   - Acceptance: `flutter pub get` succeeds and Android app starts on emulator/device.

2. Reversi rules engine
   - Implement pure Dart board state, legal moves, flipping, forced pass, game over, scoring, winner/draw.
   - Acceptance: unit tests cover standard opening, legal/illegal moves, pass, final score, draw.

3. Local two-player game screen
   - Build one-device two-player game UI with current turn, score, legal move markers, restart flow.
   - Acceptance: a complete local game can be played without invalid state.

4. Classic wood visual theme and animations
   - Add wood-framed board, readable black/white discs, legal move indicators, basic flip animation.
   - Acceptance: board is readable on small Android phone screens in portrait.

5. Turkish and English localization
   - Add TR/EN interface strings and runtime language switcher.
   - Acceptance: app defaults to supported system language and language can be changed in-app.

6. Firebase Analytics integration
   - Add Firebase initialization and analytics events for game start, move, pass, game end, language change.
   - Acceptance: app runs without config in local dev and events are visible after `google-services.json` is supplied.

7. Android test APK build
   - Configure Android build and produce a debug APK.
   - Acceptance: APK installs on a physical Android device and launches in portrait.

8. QA pass
   - Run unit/widget tests and manual gameplay checks.
   - Acceptance: no rule regressions; invalid moves show teaching feedback; game over states are correct.
