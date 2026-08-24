import 'package:shared_preferences/shared_preferences.dart';

/// Whether this device has already been asked for notification permission, and
/// whether it is worth asking at all (REV-111).
///
/// The decision is split out from [NotificationService] because it is the part
/// with rules in it, and rules are worth testing without Firebase anywhere near
/// them. The service does the plumbing; this says whether the plumbing should
/// run.
class NotificationPrefs {
  const NotificationPrefs();

  static const _askedKey = 'notification_permission_asked';

  /// True once the player has been shown the in-app ask — whichever way they
  /// answered.
  Future<bool> hasAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_askedKey) ?? false;
  }

  /// Recorded for "no" as much as for "yes". A player who declined must not be
  /// asked again on the next queue: on Android 13+ the second system prompt is
  /// never shown anyway, so re-asking would only produce an in-app dialog that
  /// leads nowhere, and on iOS it is simply nagging.
  Future<void> markAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }
}

/// Whether to put the "shall we tell you when an opponent turns up?" question
/// in front of the player right now.
///
/// Every "no" here is deliberate:
///
/// * **Signed out or a guest** — a token is stored under an account, and a
///   guest has no server document at all. Guests leave no trace on the server
///   (REV-53/57) and this must not be the exception that breaks it.
/// * **Already asked** — an answer, including a refusal, is final. Android 13+
///   will not show the system prompt a second time, so asking again produces a
///   dialog that cannot lead anywhere.
/// * **Already granted** — there is nothing to ask; the device just needs
///   registering, which happens without a dialog.
bool shouldAskForNotifications({
  required bool signedIn,
  required bool isGuest,
  required bool alreadyAsked,
  required bool alreadyGranted,
}) {
  if (!signedIn || isGuest) return false;
  if (alreadyAsked || alreadyGranted) return false;
  return true;
}

/// Whether a device token should be written for this player.
///
/// Narrower than [shouldAskForNotifications]: registering happens whenever
/// permission is in hand, including on later launches when nothing is asked.
bool shouldRegisterDevice({
  required bool signedIn,
  required bool isGuest,
  required bool granted,
}) =>
    signedIn && !isGuest && granted;
