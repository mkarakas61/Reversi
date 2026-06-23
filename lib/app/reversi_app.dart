import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/l10n/app_strings.dart';
import '../core/services/analytics_service.dart';
import '../core/settings/app_settings.dart';
import '../features/game/game_screen.dart';
import '../features/menu/main_menu_screen.dart';
import '../features/online/online_match_screen.dart';
import '../features/settings/settings_screen.dart';

class ReversiApp extends StatelessWidget {
  const ReversiApp({
    super.key,
    required this.analytics,
    required this.settings,
  });

  final AnalyticsService analytics;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: settings,
      child: Builder(
        builder: (context) {
          final locale = SettingsScope.of(context).settings.locale;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Reversi',
            locale: locale,
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
                  return Navigator.of(context).push(
                    _gameRoute(
                      OnlineMatchScreen(
                        onOpenSettings: () => openSettings(context),
                      ),
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
