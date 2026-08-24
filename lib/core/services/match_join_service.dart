import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// What the server said about a pending match.
enum JoinOutcome {
  /// Recorded, waiting for the opponent to say the same.
  waiting,

  /// Both are here — the game has started.
  started,

  /// The 60 seconds ran out, or the match was cancelled while we asked.
  gone,

  /// Network or anything unexpected. Nothing changed server-side.
  failed,
}

/// The join window (REV-114), from the client's side.
///
/// A matched game now opens as `pending` and starts only once both players have
/// said they are present, because matchmaking stopped requiring both of them to
/// be looking at a screen — one may have been notified with the app shut. Every
/// state change here goes through a callable rather than a Firestore write: the
/// security rules only let a client touch an `active` game, and widening that
/// to `pending` would let a player start or cancel a match on their own terms.
class MatchJoinService {
  MatchJoinService._();
  static final MatchJoinService instance = MatchJoinService._();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// "I am here." The second player to call this starts the game.
  Future<JoinOutcome> join(String gameId) async {
    try {
      final result = await _functions
          .httpsCallable('joinGame')
          .call<dynamic>({'gameId': gameId});
      final status = (result.data as Map?)?['status'];
      return switch (status) {
        'active' => JoinOutcome.started,
        'pending' => JoinOutcome.waiting,
        _ => JoinOutcome.gone, // cancelled or finished while we asked
      };
    } on FirebaseFunctionsException catch (e) {
      debugPrint('joinGame failed: ${e.code}');
      return e.code == 'deadline-exceeded' || e.code == 'not-found'
          ? JoinOutcome.gone
          : JoinOutcome.failed;
    } catch (_) {
      return JoinOutcome.failed;
    }
  }

  /// "Not this one." Cancels a match that has not started; an opponent who had
  /// already joined goes back into the queue rather than being dropped.
  ///
  /// Best effort by design — this runs while a screen is being popped, and a
  /// failure here costs nothing that matters: the sweep cancels an unjoined
  /// match within minutes anyway.
  Future<void> leave(String gameId) async {
    try {
      await _functions
          .httpsCallable('leavePendingGame')
          .call<dynamic>({'gameId': gameId});
    } catch (e) {
      debugPrint('leavePendingGame failed: $e');
    }
  }

  /// "They never turned up." Called once the countdown reaches zero: cancels
  /// the match and puts *this* player back in the queue, unpenalised.
  Future<void> abandon(String gameId) async {
    try {
      await _functions
          .httpsCallable('abandonPendingGame')
          .call<dynamic>({'gameId': gameId});
    } catch (e) {
      debugPrint('abandonPendingGame failed: $e');
    }
  }
}
