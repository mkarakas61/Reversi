import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/auth/auth_scope.dart';
import '../core/l10n/app_strings.dart';
import '../core/profile/profile_scope.dart';
import '../core/services/analytics_service.dart';
import '../core/services/sound_service.dart';
import '../core/settings/app_settings.dart';
import '../features/game/game_screen.dart';
import '../features/menu/main_menu_screen.dart';
import '../features/online/screens/matchmaking_screen.dart';
import '../features/settings/settings_screen.dart';

/// Lets screens react to navigation (to switch background music per screen).
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

class ReversiApp extends StatelessWidget {
  const ReversiApp({
    super.key,
    required this.analytics,
    required this.settings,
    required this.auth,
    required this.profile,
  });

  final AnalyticsService analytics;
  final SettingsController settings;
  final AuthController auth;
  final ProfileController profile;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: settings,
      child: AuthScope(
        controller: auth,
        child: ProfileScope(
          controller: profile,
          child: Builder(
            builder: (context) {
              final appSettings = SettingsScope.of(context).settings;
              final locale = appSettings.locale;
              // Keep the audio engine in sync with the latest preferences.
              SoundService.instance.applySettings(
                soundEnabled: appSettings.soundEnabled,
                musicEnabled: appSettings.musicEnabled,
              );
              return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Reversi',
            locale: locale,
            navigatorObservers: [routeObserver],
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (locale != null) return locale;
              if (deviceLocale != null) {
                for (final supported in supportedLocales) {
                  if (supported.languageCode == deviceLocale.languageCode) {
                    return supported;
                  }
                }
              }
              return const Locale('en');
            },
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF7B4A24),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF3A2419),
              fontFamily: 'Roboto',
            ),
            home: Builder(
              builder: (context) => MainMenuScreen(
                onStartOnline: () {
                  SoundService.instance.playSfx(Sfx.button);
                  return Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MatchmakingScreen(),
                    ),
                  );
                },
                onStartGame: (mode, difficulty, timeLimit) {
                  return Navigator.of(context).push(
                    _gameRoute(
                      GameScreen(
                        analytics: analytics,
                        mode: mode,
                        difficulty: difficulty,
                        timeLimit: timeLimit,
                        onOpenSettings: () => openSettings(context),
                      ),
                    ),
                  );
                },
                onContinueGame: (saved) {
                  return Navigator.of(context).push(
                    _gameRoute(
                      GameScreen(
                        analytics: analytics,
                        mode: saved.mode,
                        difficulty: saved.difficulty,
                        timeLimit: saved.timeLimit,
                        initialGame: saved.game,
                        onOpenSettings: () => openSettings(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
            },
          ),
        ),
      ),
    );
  }
}

Future<void> openSettings(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
  );
}

PageRoute<void> _gameRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
