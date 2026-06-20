import 'dart:async';

import 'package:flutter/material.dart';

import '../game/game_settings.dart';
import '../game/profile_scope.dart';
import '../l10n/app_strings.dart';
import '../main.dart' show routeObserver;
import '../services/auth_service.dart';
import '../services/game_storage.dart';
import '../services/sound_service.dart';
import '../theme/wood_theme.dart';
import 'matchmaking_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    super.key,
    required this.onStartGame,
    required this.onContinueGame,
  });

  final Future<void> Function(
      GameMode mode, Difficulty? difficulty, TimeLimit timeLimit) onStartGame;
  final Future<void> Function(SavedGame saved) onContinueGame;

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
    final isSignedIn = ProfileScope.of(context).profile != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Wood.cream),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: WoodDeco.pageWash),
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
                          const Icon(Icons.settings, size: 16),
                          const SizedBox(width: 6),
                          Text(strings.settings),
                        ],
                      ),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: _ProfileChip(),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Logo(),
                        const SizedBox(height: 14),
                        Text(
                          strings.appTitle.toUpperCase(),
                          style: WoodText.heading(
                            48,
                            color: Wood.ink,
                            spacing: 8,
                          ).copyWith(
                            shadows: const [
                              Shadow(
                                color: Color(0x80FFFAF0),
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Gold divider.
                        Container(
                          width: 120,
                          height: 2,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0x00B8860B),
                                Wood.gold,
                                Color(0x00B8860B),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.appSubtitle,
                          style: WoodText.body(
                            14,
                            color: Wood.inkSoft2,
                            italic: true,
                          ),
                        ),
                        const SizedBox(height: 34),
                        if (_showDifficulty) ...[
                          Text(
                            strings.chooseDifficulty,
                            style: WoodText.heading(16, color: Wood.ink),
                          ),
                          const SizedBox(height: 18),
                          _MenuButton(
                            label: strings.easy,
                            onTap: () => unawaited(
                              _start(GameMode.singlePlayer, Difficulty.easy,
                                  TimeLimit.none),
                            ),
                          ),
                          const SizedBox(height: 13),
                          _MenuButton(
                            label: strings.normal,
                            onTap: () => unawaited(
                              _start(GameMode.singlePlayer, Difficulty.normal,
                                  TimeLimit.none),
                            ),
                          ),
                          const SizedBox(height: 13),
                          _MenuButton(
                            label: strings.hard,
                            onTap: () => unawaited(
                              _start(GameMode.singlePlayer, Difficulty.hard,
                                  TimeLimit.none),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _BackLink(
                            label: strings.back,
                            onTap: () => setState(() => _showDifficulty = false),
                          ),
                          const SizedBox(height: 22),
                          _MenuButton(
                            label: strings.singlePlayerStatistics,
                            variant: WoodButtonVariant.dark,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const StatsScreen(),
                              ),
                            ),
                          ),
                        ] else if (_showTimeLimit) ...[
                          Text(
                            strings.chooseTimeLimit,
                            style: WoodText.heading(16, color: Wood.ink),
                          ),
                          const SizedBox(height: 18),
                          for (final limit in TimeLimit.values) ...[
                            _MenuButton(
                              label: strings.timeLimitLabel(limit),
                              onTap: () => unawaited(
                                _start(GameMode.twoPlayer, null, limit),
                              ),
                            ),
                            const SizedBox(height: 13),
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
                              variant: WoodButtonVariant.dark,
                              onTap: () => unawaited(_continueSaved()),
                            ),
                            const SizedBox(height: 13),
                          ],
                          _MenuButton(
                            label: strings.onePlayer,
                            onTap: () => setState(() => _showDifficulty = true),
                          ),
                          const SizedBox(height: 13),
                          _MenuButton(
                            label: strings.twoPlayer,
                            onTap: () => setState(() => _showTimeLimit = true),
                          ),
                          if (isSignedIn) ...[
                            const SizedBox(height: 13),
                            _MenuButton(
                              label: strings.onlinePlay,
                              variant: WoodButtonVariant.gold,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const MatchmakingScreen(),
                                ),
                              ),
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
      ),
    );
  }
}

/// The 2×2 opening-position motif, rendered in the dark wooden frame.
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget tile(bool dark) => Container(
          margin: const EdgeInsets.all(3.5),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0x1AF2E6D0), // rgba(242,230,208,.10)
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(dark ? Wood.discWalnut : Wood.discMaple),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF56391F), Color(0xFF3A2410)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Wood.gold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
              mainAxisSize: MainAxisSize.min,
              children: [tile(false), tile(true)]),
          Row(
              mainAxisSize: MainAxisSize.min,
              children: [tile(true), tile(false)]),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.onTap,
    this.variant = WoodButtonVariant.light,
  });

  final String label;
  final VoidCallback onTap;
  final WoodButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return WoodButton(
      label: label,
      variant: variant,
      width: 262,
      height: 56,
      onTap: () {
        SoundService.instance.playSfx(Sfx.button);
        onTap();
      },
    );
  }
}

/// Small cream chip used for the Profile / Settings shortcuts at the top.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: WoodDeco.cardGradient,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x4D7A5634)), // rgba(122,86,52,.3)
        boxShadow: const [
          BoxShadow(
            color: Color(0x213E2A1E),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            SoundService.instance.playSfx(Sfx.button);
            onTap();
          },
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: DefaultTextStyle(
              style: WoodText.body(13, color: Wood.ink, weight: FontWeight.w700),
              child: IconTheme(
                data: const IconThemeData(color: Wood.ink, size: 18),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top-of-menu chip that doubles as the sign-in gate: signed out it offers
/// Google sign-in (offline play still works without it); signed in it shows the
/// player's avatar and name, tapping it to open a sheet with sign-out.
class _ProfileChip extends StatefulWidget {
  const _ProfileChip();

  @override
  State<_ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<_ProfileChip> {
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy) return;
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(strings.signInError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openProfile() {
    SoundService.instance.playSfx(Sfx.button);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final profile = ProfileScope.of(context).profile;

    if (profile == null) {
      return _PillButton(
        onTap: _signIn,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Wood.accent,
                ),
              )
            else
              const Icon(Icons.login_rounded, size: 18),
            const SizedBox(width: 6),
            Text(strings.signIn),
          ],
        ),
      );
    }

    final name = profile.displayName ?? '';
    final firstName = name.isEmpty ? strings.signIn : name.split(' ').first;
    return _PillButton(
      onTap: _openProfile,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(photoUrl: profile.photoUrl, radius: 11),
          const SizedBox(width: 7),
          Text(firstName),
        ],
      ),
    );
  }
}

/// Circular profile photo, falling back to a person icon when there is no URL.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.radius});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasUrl = url != null && url.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0x1F5A3D26), // rgba(90,61,38,.12)
      backgroundImage: hasUrl ? NetworkImage(url) : null,
      child: hasUrl
          ? null
          : Icon(Icons.person_rounded,
              size: radius, color: const Color(0xFF5A3D26)),
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
      onPressed: () {
        SoundService.instance.playSfx(Sfx.button);
        onTap();
      },
      icon: const Icon(Icons.arrow_back, color: Wood.inkSoft, size: 18),
      label: Text(
        label,
        style: WoodText.body(15, color: Wood.inkSoft, weight: FontWeight.w700),
      ),
    );
  }
}
