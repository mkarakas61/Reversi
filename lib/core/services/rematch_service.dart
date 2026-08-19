import 'package:cloud_functions/cloud_functions.dart';

import '../models/online_game.dart';

/// Result of a rematch call — the state the server settled on.
class RematchResult {
  const RematchResult({required this.status, this.gameId});

  final RematchStatus status;

  /// The rematch game, set when [status] is [RematchStatus.accepted].
  final String? gameId;

  static const failed = RematchResult(status: RematchStatus.declined);
}

/// Rematch calls (REV-98).
///
/// Callables rather than Firestore writes: the security rules make a finished
/// game read-only to clients, and the rematch game has to be created by the
/// server anyway — a client that could open a game directly could choose its
/// own opponent and colour, and farm trophies and coins.
///
/// Nothing here reports success back to the caller by itself. The server writes
/// the answer onto the game document both players are already streaming, so the
/// UI follows the document rather than the call's return value; the returned
/// [RematchResult] only saves the offering player one round trip.
class RematchService {
  RematchService._();
  static final RematchService instance = RematchService._();

  /// Functions are deployed to europe-west1 (next to the eur3 Firestore), so
  /// the default us-central1 instance would 404.
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Offers a rematch — or accepts the opponent's standing offer, when both
  /// players tap at the same moment. The server decides which.
  Future<RematchResult> request(String gameId) =>
      _call('requestRematch', {'gameId': gameId});

  /// Accepts the opponent's offer.
  Future<RematchResult> accept(String gameId) =>
      _call('respondRematch', {'gameId': gameId, 'accept': true});

  /// Refuses the opponent's offer, or withdraws your own — the server treats
  /// both as "this offer no longer stands", which is all either side needs.
  Future<RematchResult> decline(String gameId) =>
      _call('respondRematch', {'gameId': gameId, 'accept': false});

  Future<RematchResult> _call(String name, Map<String, dynamic> data) async {
    try {
      final res = await _functions.httpsCallable(name).call<dynamic>(data);
      final map = (res.data as Map?)?.cast<String, dynamic>() ?? const {};
      final status = switch (map['status'] as String?) {
        'accepted' => RematchStatus.accepted,
        'pending' => RematchStatus.pending,
        _ => RematchStatus.declined,
      };
      return RematchResult(status: status, gameId: map['gameId'] as String?);
    } catch (_) {
      // A failed call leaves the document untouched, so the UI simply stays
      // where it was and the player can tap again. Losing the network at the
      // end of a game should not throw an error card over the result.
      return RematchResult.failed;
    }
  }
}
