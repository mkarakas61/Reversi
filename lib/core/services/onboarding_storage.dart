import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that the welcome tour has been shown (REV-103).
///
/// Deliberately not part of [AppSettings]: this is a one-shot record of
/// something that happened, not a preference the player sets, and putting it in
/// the settings object would mean every settings save rewrites it.
class OnboardingStorage {
  const OnboardingStorage();

  static const _tourSeenKey = 'onboarding_tour_seen';

  /// False on a fresh install — that is the only time the tour runs by itself.
  Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tourSeenKey) ?? false;
  }

  /// Called when the tour is finished *or* skipped: skipping is an answer too,
  /// and re-showing a tour the player dismissed would be worse than not
  /// showing it at all. "How to Play" stays reachable from the menu and
  /// Settings, so nothing is lost for good.
  Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourSeenKey, true);
  }
}
