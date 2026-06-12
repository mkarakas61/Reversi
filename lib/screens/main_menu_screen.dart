import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_settings.dart';
import '../l10n/app_strings.dart';
import '../services/game_storage.dart';
import '../theme/game_theme.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    super.key,
    required this.onStartGame,
    required this.onContinueGame,
  });

  final Future<void> Function(
          GameMode mode, Difficulty? difficulty, TimeLimit timeLimit)
      onStartGame;
  final Future<void> Function(SavedGame saved) onContinueGame;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _showDifficulty = false;
  bool _showTimeLimit = false;
  final GameStorage _storage = GameStorage();
  SavedGame? _savedGame;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshSavedGame());
  }

  Future<void> _refreshSavedGame() async {
    final saved = await _storage.load();
    if (mounted) {
      setState(() => _savedGame = saved);
    }
  }

  Future<void> _start(
      GameMode mode, Difficulty? difficulty, TimeLimit timeLimit) async {
    await widget.onStartGame(mode, difficulty, timeLimit);
    if (!mounted) return;
    setState(() {
      _showDifficulty = false;
      _showTimeLimit = false;
    });
    await _refreshSavedGame();
  }

  Future<void> _continueSaved() async {
    final saved = _savedGame;
    if (saved == null) return;
    await widget.onContinueGame(saved);
    if (mounted) await _refreshSavedGame();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: bannerGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _PillButton(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.settings, size: 18),
                        const SizedBox(width: 6),
                        Text(strings.settings),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Logo(),
                      const SizedBox(height: 10),
                      Text(
                        strings.appTitle.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w800,
                          fontSize: 44,
                          letterSpacing: 6,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Color(0x29000000), offset: Offset(0, 3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 44),
                      if (_showDifficulty) ...[
                        Text(
                          strings.chooseDifficulty,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _MenuButton(
                          label: strings.easy,
                          icon: Icons.sentiment_satisfied_rounded,
                          onTap: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.easy,
                                TimeLimit.none),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: strings.normal,
                          icon: Icons.sentiment_neutral_rounded,
                          onTap: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.normal,
                                TimeLimit.none),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: strings.hard,
                          icon: Icons.sentiment_very_dissatisfied_rounded,
                          onTap: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.hard,
                                TimeLimit.none),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _BackLink(
                          label: strings.back,
                          onTap: () => setState(() => _showDifficulty = false),
                        ),
                      ] else if (_showTimeLimit) ...[
                        Text(
                          strings.chooseTimeLimit,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final limit in TimeLimit.values) ...[
                          _MenuButton(
                            label: strings.timeLimitLabel(limit),
                            icon: limit == TimeLimit.none
                                ? Icons.all_inclusive_rounded
                                : Icons.timer_outlined,
                            onTap: () => unawaited(
                              _start(GameMode.twoPlayer, null, limit),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const SizedBox(height: 6),
                        _BackLink(
                          label: strings.back,
                          onTap: () => setState(() => _showTimeLimit = false),
                        ),
                      ] else ...[
                        if (_savedGame != null) ...[
                          _MenuButton(
                            label: strings.continueGame,
                            icon: Icons.play_arrow_rounded,
                            primary: true,
                            onTap: () => unawaited(_continueSaved()),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _MenuButton(
                          label: strings.onePlayer,
                          icon: Icons.person_rounded,
                          onTap: () => setState(() => _showDifficulty = true),
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          label: strings.twoPlayer,
                          icon: Icons.people_rounded,
                          onTap: () => setState(() => _showTimeLimit = true),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 2×2 opening-position motif from the app icon, as a small logo.
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget tile(bool dark) => Container(
          margin: const EdgeInsets.all(3),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFFCE9C8),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: dark
                    ? const [Color(0xFF4A5468), Color(0xFF11141D)]
                    : const [Colors.white, Color(0xFFC4C8D2)],
                stops: const [0.0, 0.75],
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [tile(false), tile(true)]),
          Row(mainAxisSize: MainAxisSize.min, children: [tile(true), tile(false)]),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : GameColors.onAccent;
    final bg = primary ? GameColors.accent2 : Colors.white;
    return SizedBox(
      width: 260,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: fg, size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.child, required this.onTap});

  final Widget child;
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
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: GameColors.onAccent,
              ),
              child: IconTheme(
                data: const IconThemeData(color: GameColors.onAccent, size: 20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
