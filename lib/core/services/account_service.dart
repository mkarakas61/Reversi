import 'package:cloud_functions/cloud_functions.dart';

import 'auth_service.dart';

/// Account deletion (REV-90).
///
/// The work happens in the `deleteAccount` callable: the security rules make
/// the profile, match history and leaderboard rows server-owned, so a client
/// can delete its own auth user but none of its data — and an auth user
/// deleted on its own would orphan everything else. The server also avoids the
/// `requires-recent-login` re-authentication prompt that `user.delete()` throws
/// in the middle of an irreversible action.
class AccountService {
  AccountService._();
  static final AccountService instance = AccountService._();

  /// Functions are deployed to europe-west1 (next to the eur3 Firestore), so
  /// the default us-central1 instance would 404.
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Deletes the signed-in account and everything stored about it, then signs
  /// out locally so the app never holds a token for a user that is gone.
  ///
  /// Returns false if the call failed, in which case **nothing was deleted**:
  /// the server does its work in one pass and removes the auth user last, so a
  /// failure leaves the account intact and the player can simply try again.
  Future<bool> deleteAccount() async {
    try {
      await _functions.httpsCallable('deleteAccount').call<dynamic>();
    } catch (_) {
      return false;
    }
    // The account is gone server-side; the local session must follow even if
    // signing out hiccups, so this is deliberately not part of the try above.
    await AuthService.instance.signOut();
    return true;
  }
}
