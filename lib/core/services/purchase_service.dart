import 'package:cloud_functions/cloud_functions.dart';

/// Why a purchase did not go through, in the terms the player needs to hear.
enum PurchaseFailure {
  /// Not signed in — guests have no balance and no place to record ownership.
  notSignedIn,

  /// The balance is short. The price is the server's word, not the client's.
  notEnoughCoins,

  /// Already owned. Not really a failure: nothing was charged and the item is
  /// theirs, so the app should just refresh rather than apologise.
  alreadyOwned,

  /// The server does not know this id — an item removed from the catalogue, or
  /// a build newer than the deployed function.
  unknownItem,

  /// Network, timeout, anything else. Nothing was charged.
  failed,
}

/// Result of one purchase attempt.
class PurchaseResult {
  const PurchaseResult.success() : failure = null;
  const PurchaseResult.failed(this.failure);

  final PurchaseFailure? failure;

  bool get ok => failure == null;
}

/// Buying a store item with coins (REV-66).
///
/// Everything that matters happens in the `purchaseItem` callable: the price
/// list lives on the server, and the balance check, the debit and the ownership
/// write are one transaction. The client sends an id and nothing else — it
/// cannot name a price, and it cannot write `coins` or `ownedItems` itself
/// (the security rules let a player write only their name and photo).
///
/// Nothing here updates the balance locally. The profile document is streamed,
/// so the new balance and the new item arrive the same way every other
/// server-owned number does. A client-side guess would only ever be a
/// prettier way of being wrong.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// Functions are deployed to europe-west1 (next to the eur3 Firestore), so
  /// the default us-central1 instance would 404.
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<PurchaseResult> buy(String itemId) async {
    try {
      await _functions
          .httpsCallable('purchaseItem')
          .call<dynamic>({'itemId': itemId});
      return const PurchaseResult.success();
    } on FirebaseFunctionsException catch (e) {
      return PurchaseResult.failed(_failureFor(e.code));
    } catch (_) {
      return const PurchaseResult.failed(PurchaseFailure.failed);
    }
  }

  /// Maps the callable's error codes onto [PurchaseFailure]. The codes are the
  /// ones `purchase.ts` throws; anything unexpected is treated as a plain
  /// failure, which is the safe reading — the server charges nothing unless
  /// the whole transaction commits.
  PurchaseFailure _failureFor(String code) {
    switch (code) {
      case 'unauthenticated':
        return PurchaseFailure.notSignedIn;
      case 'failed-precondition':
        return PurchaseFailure.notEnoughCoins;
      case 'already-exists':
        return PurchaseFailure.alreadyOwned;
      case 'not-found':
      case 'invalid-argument':
        return PurchaseFailure.unknownItem;
      default:
        return PurchaseFailure.failed;
    }
  }
}
