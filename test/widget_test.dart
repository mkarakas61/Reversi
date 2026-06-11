import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/main.dart';
import 'package:reversi/services/analytics_service.dart';
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
    await tester.pumpWidget(ReversiApp(analytics: AnalyticsService()));
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
    // Human is "You", AI opponent is "Aria".
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Aria'), findsOneWidget);
  });

  testWidgets('can toggle to Turkish from the menu', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text('İki Oyuncu'), findsOneWidget);
  });
}
