import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that the welcome tour has been shown (REV-103).
///
/// Deliberately not part of [AppSettings]: this is a one-shot record of
/// something that happened, not a preference the player sets, and putting it in
/// the settings object would mean every settings save rewrites it.
class OnboardingStorage {
  const OnboardingStorage();

  static const _tourSeenKey = 'onboarding_tour_seen';

  /// One-off reset ticket (2026-08-21). The test team installed earlier builds,
  /// so [_tourSeenKey] is already set on their devices and they can no longer
  /// see the welcome tour a new player gets. A device whose stored ticket does
  /// not match this constant forgets the flag **once** ([applyPendingReset]);
  /// after that the tour behaves normally again, so leaving this code in place
  /// is harmless and no build flag is needed.
  ///
  /// Bump the string only when a fresh one-off reset is actually asked for.
  /// It clears nothing but the tour flag — settings, offline statistics and the
  /// saved game are never touched.
  static const _resetTicket = '2026-08-21';
  static const _resetTicketKey = 'onboarding_reset_ticket';

  /// Runs the pending reset, if this device has not had it yet. Called once at
  /// startup, before the menu is built; a no-op on every later launch.
  Future<void> applyPendingReset() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_resetTicketKey) == _resetTicket) return;
    await prefs.setString(_resetTicketKey, _resetTicket);
    await prefs.remove(_tourSeenKey);
  }

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
