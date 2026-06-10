import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_settings.dart';
import '../l10n/app_strings.dart';
import '../services/game_storage.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onStartGame,
    required this.onContinueGame,
  });

  final ValueChanged<Locale> onLocaleChanged;
  final Future<void> Function(GameMode mode, Difficulty? difficulty)
      onStartGame;
  final Future<void> Function(SavedGame saved) onContinueGame;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _showDifficulty = false;
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

  Future<void> _start(GameMode mode, Difficulty? difficulty) async {
    await widget.onStartGame(mode, difficulty);
    if (!mounted) {
      return;
    }
    setState(() => _showDifficulty = false);
    await _refreshSavedGame();
  }

  Future<void> _continueSaved() async {
    final saved = _savedGame;
    if (saved == null) {
      return;
    }
    await widget.onContinueGame(saved);
    if (mounted) {
      await _refreshSavedGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A2D1D), Color(0xFF251711)],
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: PopupMenuButton<Locale>(
                    tooltip: strings.language,
                    icon: const Icon(Icons.language, color: Color(0xFFFFF1D0)),
                    onSelected: widget.onLocaleChanged,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: Locale('tr'), child: Text('Türkçe')),
                      PopupMenuItem(
                          value: Locale('en'), child: Text('English')),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.appTitle,
                        style: const TextStyle(
                          color: Color(0xFFFFF1D0),
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (!_showDifficulty) ...[
                        if (_savedGame != null) ...[
                          _MenuButton(
                            label: strings.continueGame,
                            icon: Icons.play_arrow,
                            onPressed: () => unawaited(_continueSaved()),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _MenuButton(
                          label: strings.onePlayer,
                          icon: Icons.person,
                          onPressed: () =>
                              setState(() => _showDifficulty = true),
                        ),
                        const SizedBox(height: 16),
                        _MenuButton(
                          label: strings.twoPlayer,
                          icon: Icons.people,
                          onPressed: () =>
                              unawaited(_start(GameMode.twoPlayer, null)),
                        ),
                      ] else ...[
                        Text(
                          strings.chooseDifficulty,
                          style: const TextStyle(
                            color: Color(0xFFE9D8B8),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _MenuButton(
                          label: strings.easy,
                          icon: Icons.sentiment_satisfied,
                          onPressed: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.easy),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MenuButton(
                          label: strings.normal,
                          icon: Icons.sentiment_neutral,
                          onPressed: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.normal),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MenuButton(
                          label: strings.hard,
                          icon: Icons.sentiment_very_dissatisfied,
                          onPressed: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.hard),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _showDifficulty = false),
                          icon: const Icon(Icons.arrow_back,
                              color: Color(0xFFE9D8B8)),
                          label: Text(
                            strings.back,
                            style: const TextStyle(color: Color(0xFFE9D8B8)),
                          ),
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

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE5C58F),
          foregroundColor: const Color(0xFF2A1710),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
