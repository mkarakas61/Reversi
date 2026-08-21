import 'package:flutter_test/flutter_test.dart';
import 'package:reversi/core/services/onboarding_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one-off reset ticket: testers who already saw (or skipped) the tour on an
/// older build get it back exactly once, and nothing else on the device moves.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = OnboardingStorage();

  test('fresh install shows the tour and then remembers it', () async {
    SharedPreferences.setMockInitialValues({});
    await storage.applyPendingReset();
    expect(await storage.hasSeenTour(), isFalse);
    await storage.markTourSeen();
    expect(await storage.hasSeenTour(), isTrue);
  });

  test('a device from an older build forgets the flag once', () async {
    SharedPreferences.setMockInitialValues({'onboarding_tour_seen': true});

    // First launch on the new build: the ticket is missing, so the tour returns.
    await storage.applyPendingReset();
    expect(await storage.hasSeenTour(), isFalse);

    // The player sees it, and from then on it stays seen — later launches run
    // the reset again and it does nothing, so the tour never loops.
    await storage.markTourSeen();
    await storage.applyPendingReset();
    expect(await storage.hasSeenTour(), isTrue);
    await storage.applyPendingReset();
    expect(await storage.hasSeenTour(), isTrue);
  });

  test('the reset touches nothing but the tour flag', () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_tour_seen': true,
      'settings_board': 'marble',
      'game_stats_v1': '{"wins":3}',
      'saved_game_v1': 'board-state',
    });

    await storage.applyPendingReset();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_board'), 'marble');
    expect(prefs.getString('game_stats_v1'), '{"wins":3}');
    expect(prefs.getString('saved_game_v1'), 'board-state');
  });
}
