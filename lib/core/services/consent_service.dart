import 'package:cloud_firestore/cloud_firestore.dart';

import '../legal/legal_links.dart';

/// Marketing consent — the permission to e-mail a player about new games and
/// updates (REV-117).
///
/// Kept separate from the notification permission the operating system asks
/// for: "tell me about my match" and "tell me about a new game" are different
/// promises, and only the second one needs consent. Default is **off** and the
/// player can withdraw at any time.
///
/// Storage is two documents per consent type:
///  - `users/{uid}/consents/{type}` — the current answer, overwritten on every
///    change, so reading the toggle state is a single get with no index.
///  - `users/{uid}/consents/{type}/log/{autoId}` — the append-only record of
///    every answer ever given. Proof of consent is our burden, so the history
///    is written once and never rewritten; the security rules enforce that.
///
/// Nothing here sends anything. The sending side (provider, sender domain,
/// İYS registration) is REV-115 and depends on which publisher the game ships
/// under — but the consent has to be collected from day one, because it cannot
/// be obtained retroactively from players who already signed up.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  /// Consent to receive e-mail about new games and updates.
  static const String marketingEmail = 'marketingEmail';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String type) =>
      _db.collection('users').doc(uid).collection('consents').doc(type);

  /// The player's current answer, or null if they have never been asked —
  /// which is what decides whether the one-time prompt appears.
  Future<bool?> current(String uid, String type) async {
    try {
      final snap = await _doc(uid, type).get();
      return snap.data()?['granted'] as bool?;
    } catch (_) {
      // Offline or unreachable: treat as "don't know". The prompt simply waits
      // for a launch with a connection rather than asking a question whose
      // answer we could not store.
      return null;
    }
  }

  /// Records an answer — granting **or** withdrawing. Writes the current state
  /// and appends to the log in one batch, so the two can never disagree.
  ///
  /// [source] says where the answer came from ('prompt' or 'settings'), and
  /// the policy version is stamped so a later change to the published text can
  /// be told apart from consent given under this one.
  Future<bool> record({
    required String uid,
    required String type,
    required bool granted,
    required String source,
  }) async {
    try {
      final doc = _doc(uid, type);
      final batch = _db.batch()
        ..set(doc, {
          'type': type,
          'granted': granted,
          'at': FieldValue.serverTimestamp(),
          'policyVersion': LegalLinks.policyVersion,
          'source': source,
        })
        ..set(doc.collection('log').doc(), {
          'type': type,
          'granted': granted,
          'at': FieldValue.serverTimestamp(),
          'policyVersion': LegalLinks.policyVersion,
          'source': source,
        });
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Whether the one-time consent prompt should open.
///
/// Pure so the rule is testable and stated in one place: only a signed-in
/// player who has never answered is asked. Guests are never asked — there is
/// no address to write to, and a guest leaves no server-side record at all.
bool shouldAskConsent({
  required bool signedIn,
  required bool isGuest,
  required bool? currentAnswer,
}) {
  if (!signedIn || isGuest) return false;
  return currentAnswer == null;
}
