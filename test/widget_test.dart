import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/game/app_settings.dart';
import 'package:reversi/main.dart';
import 'package:reversi/services/analytics_service.dart';
import 'package:reversi/services/settings_storage.dart';
import 'package:reversi/widgets/wood_board.dart';
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
    await tester.pumpWidget(
      ReversiApp(analytics: AnalyticsService(), settings: settings),
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
    await tester.pump(); // start route transition
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Black'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.byType(WoodBoard), findsOneWidget);
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

    // The settings screen re-renders in Turkish immediately, confirming the
    // locale switch propagated app-wide.
    expect(find.text('Senin taşın'), findsOneWidget);
    expect(find.text('Taş rengi'), findsOneWidget);
  });
}
