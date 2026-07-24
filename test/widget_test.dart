import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/app/reversi_app.dart';
import 'package:reversi/core/auth/auth_scope.dart';
import 'package:reversi/core/game/reversi_game.dart';
import 'package:reversi/core/profile/profile_scope.dart';
import 'package:reversi/core/services/analytics_service.dart';
import 'package:reversi/core/services/settings_storage.dart';
import 'package:reversi/core/settings/app_settings.dart';
import 'package:reversi/features/board/wood_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    final settings =
        SettingsController(const AppSettings(), SettingsStorage());
    final auth = AuthController(null);
    await tester.pumpWidget(
      ReversiApp(
        analytics: AnalyticsService(),
        settings: settings,
        auth: auth,
        profile: ProfileController(auth),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the main menu', (tester) async {
    await pumpApp(tester);

    expect(find.text('REVERSI'), findsOneWidget);
    expect(find.text('Single Player'), findsOneWidget);
    expect(find.text('Two Players'), findsOneWidget);
  });

  testWidgets('starting a two player game renders the board and cards',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Two Players'));
    await tester.pumpAndSettle();

    // Two-player flow now asks for a time limit first.
    expect(find.text('Choose time limit'), findsOneWidget);
    await tester.tap(find.text('No time limit'));
    await tester.pump(); // start route transition
    await tester.pump(const Duration(milliseconds: 400));

    // Player names follow the chosen coin colours (defaults: black & white).
    expect(find.text('Black'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.byType(WoodBoard), findsOneWidget);
  });

  testWidgets('timed two player game shows a countdown that resets per turn',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Two Players'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 sec limit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // route fade
    await tester.pump(const Duration(milliseconds: 800)); // entry animation

    // Clock starts at 0:30 once the entrance settles.
    expect(find.text('0:30'), findsOneWidget);

    // After three seconds it has counted down.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('0:27'), findsOneWidget);

    // Black plays a move; the clock resets for white.
    final state = tester.state<State>(find.byType(WoodBoard));
    final board = state.widget as WoodBoard;
    board.onCellTap(const Position(2, 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('0:30'), findsOneWidget);

    // Let the flip animation finish so no timers are left mid-flight.
    await tester.pump(const Duration(milliseconds: 1100));
  });

  testWidgets('single player flow shows difficulty selection', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Single Player'));
    await tester.pumpAndSettle();

    expect(find.text('Choose difficulty'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);

    await tester.tap(find.text('Normal'));
    await tester.pump(); // start route transition
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(WoodBoard), findsOneWidget);
    // Human is "You", AI opponent shows its difficulty in parentheses.
    expect(find.text('You'), findsOneWidget);
    expect(find.text('AI (Normal)'), findsOneWidget);
  });

  testWidgets('can switch to Turkish from settings', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();

    // The coin section sits below the board grid, so scroll it into view
    // first. Finding its Turkish labels confirms the locale switch propagated
    // app-wide.
    await tester.scrollUntilVisible(find.text('Senin taşın'), 200);
    expect(find.text('Senin taşın'), findsOneWidget);
    expect(find.text('Taş rengi'), findsOneWidget);
  });
}
