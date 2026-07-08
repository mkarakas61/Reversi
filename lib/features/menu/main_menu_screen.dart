import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/game/game_settings.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/services/game_storage.dart';
import '../../app/reversi_app.dart' show routeObserver;
import '../../core/profile/profile_scope.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/game_colors.dart' show bannerGradient;
import '../../core/theme/wood_theme.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import 'widgets/menu_button.dart';
import 'widgets/menu_logo.dart';
import 'widgets/pill_button.dart';
import 'widgets/profile_chip.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    super.key,
    required this.onStartGame,
    required this.onContinueGame,
    required this.onStartOnline,
  });

  final Future<void> Function(
          GameMode mode, Difficulty? difficulty, TimeLimit timeLimit)
      onStartGame;
  final Future<void> Function(SavedGame saved) onContinueGame;
  final Future<void> Function() onStartOnline;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with RouteAware, WidgetsBindingObserver {
  bool _showDifficulty = false;
  bool _showTimeLimit = false;
  final GameStorage _storage = GameStorage();
  SavedGame? _savedGame;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshSavedGame());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      // The observer never delivers didPush for the route it is first
      // subscribed on (the initial menu route at launch), so assert the menu
      // track here while the menu is the active screen. playMusic is a no-op
      // if it is already current.
      if (route.isCurrent) {
        SoundService.instance.playMusic(Music.menu);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // Energetic menu track whenever the menu is the active screen.
  @override
  void didPush() => SoundService.instance.playMusic(Music.menu);

  @override
  void didPopNext() => SoundService.instance.playMusic(Music.menu);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SoundService.instance.refreshRingerMode();
      SoundService.instance.resumeMusic();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      SoundService.instance.pauseMusic();
      SoundService.instance.stopAllSfx();
    }
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
    final wood = isWoodTheme(context);
    final headingColor = wood ? WoodTheme.inkScore : Colors.white;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: wood ? WoodTheme.pageBackground : bannerGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: ProfileChip(),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: PillButton(
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
                      const MenuLogo(),
                      const SizedBox(height: 10),
                      Text(
                        strings.appTitle.toUpperCase(),
                        style: wood
                            ? const TextStyle(
                                fontFamily: WoodTheme.displayFont,
                                fontSize: 42,
                                letterSpacing: 6,
                                color: WoodTheme.inkTitle,
                              )
                            : const TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w800,
                                fontSize: 44,
                                letterSpacing: 6,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Color(0x29000000),
                                      offset: Offset(0, 3)),
                                ],
                              ),
                      ),
                      const SizedBox(height: 44),
                      if (_showDifficulty) ...[
                        Text(
                          strings.chooseDifficulty,
                          style: TextStyle(
                            fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: headingColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        MenuButton(
                          label: strings.easy,
                          icon: Icons.sentiment_satisfied_rounded,
                          onTap: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.easy,
                                TimeLimit.none),
                          ),
                        ),
                        const SizedBox(height: 14),
                        MenuButton(
                          label: strings.normal,
                          icon: Icons.sentiment_neutral_rounded,
                          onTap: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.normal,
                                TimeLimit.none),
                          ),
                        ),
                        const SizedBox(height: 14),
                        MenuButton(
                          label: strings.hard,
                          icon: Icons.sentiment_very_dissatisfied_rounded,
                          onTap: () => unawaited(
                            _start(GameMode.singlePlayer, Difficulty.hard,
                                TimeLimit.none),
                          ),
                        ),
                        const SizedBox(height: 20),
                        BackLink(
                          label: strings.back,
                          onTap: () =>
                              setState(() => _showDifficulty = false),
                        ),
                        const SizedBox(height: 28),
                        MenuButton(
                          label: strings.singlePlayerStatistics,
                          icon: Icons.bar_chart_rounded,
                          primary: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const StatsScreen(),
                            ),
                          ),
                        ),
                      ] else if (_showTimeLimit) ...[
                        Text(
                          strings.chooseTimeLimit,
                          style: TextStyle(
                            fontFamily: wood ? WoodTheme.bodyFont : 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: headingColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final limit in TimeLimit.values) ...[
                          MenuButton(
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
                        BackLink(
                          label: strings.back,
                          onTap: () =>
                              setState(() => _showTimeLimit = false),
                        ),
                      ] else ...[
                        if (_savedGame != null) ...[
                          MenuButton(
                            label: strings.continueGame,
                            icon: Icons.play_arrow_rounded,
                            primary: true,
                            onTap: () => unawaited(_continueSaved()),
                          ),
                          const SizedBox(height: 14),
                        ],
                        MenuButton(
                          label: strings.onePlayer,
                          icon: Icons.person_rounded,
                          onTap: () =>
                              setState(() => _showDifficulty = true),
                        ),
                        const SizedBox(height: 14),
                        MenuButton(
                          label: strings.twoPlayer,
                          icon: Icons.people_rounded,
                          onTap: () =>
                              setState(() => _showTimeLimit = true),
                        ),
                        if (ProfileScope.of(context).profile != null) ...[
                          const SizedBox(height: 14),
                          MenuButton(
                            label: strings.onlinePlay,
                            icon: Icons.public_rounded,
                            primary: true,
                            onTap: () => unawaited(widget.onStartOnline()),
                          ),
                        ],
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
