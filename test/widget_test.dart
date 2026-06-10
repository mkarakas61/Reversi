import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/main.dart';
import 'package:reversi/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the main menu', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(ReversiApp(analytics: AnalyticsService()));
    await tester.pumpAndSettle();

    expect(find.text('Reversi'), findsOneWidget);
    expect(find.text('Single Player'), findsOneWidget);
    expect(find.text('Two Players'), findsOneWidget);
  });

  testWidgets('starting a two player game renders the board and score panel',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(ReversiApp(analytics: AnalyticsService()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Two Players'));
    await tester.pumpAndSettle();

    expect(find.text('Black'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('single player flow shows difficulty selection', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(ReversiApp(analytics: AnalyticsService()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Single Player'));
    await tester.pumpAndSettle();

    expect(find.text('Choose difficulty'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);

    await tester.tap(find.text('Normal'));
    await tester.pumpAndSettle();

    expect(find.text('1 Player · Normal'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('can switch to Turkish locale', (tester) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('en');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(ReversiApp(analytics: AnalyticsService()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();

    expect(find.text('İki Oyuncu'), findsOneWidget);

    await tester.tap(find.text('İki Oyuncu'));
    await tester.pumpAndSettle();

    expect(find.text('Siyah'), findsOneWidget);
  });
}
