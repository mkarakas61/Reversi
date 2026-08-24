import 'package:cloud_functions/cloud_functions.dart';

import '../store/coin_packs.dart';

/// Why a coin pack could not be bought.
enum BillingFailure {
  /// Play Billing is not wired up — the app is not on Play, there are no
  /// products, and there is nothing to open. The only value this enum takes
  /// today, and the reason the store shows the packs as "coming soon" rather
  /// than as buttons that fail.
  unavailable,

  /// Not signed in. Coins are credited to an account; there has to be one.
  notSignedIn,

  /// The player closed the Play sheet. Nothing was charged.
  cancelled,

  /// Play took the money but the server would not credit the coins. The
  /// receipt survives, so this is a "try again", never a lost purchase.
  notCredited,

  /// Network, timeout, anything unexpected.
  failed,
}

class BillingResult {
  const BillingResult.success(this.coins) : failure = null;
  const BillingResult.failed(this.failure) : coins = 0;

  final BillingFailure? failure;

  /// Coins credited by this purchase; 0 on failure.
  final int coins;

  bool get ok => failure == null;
}

/// Buying coins with real money (REV-72).
///
/// **Deliberately incomplete, and it says so.** The Play purchase flow cannot
/// exist yet: Play only returns products that are defined in Play Console, and
/// the app has not been uploaded there — the publisher decision comes first
/// (PROGRESS.md, 2026-08-23). Writing the flow now would mean shipping weeks of
/// code that nobody has ever run, in the one area famous for breaking quietly.
///
/// So this class is the seam, not the implementation. Everything around it is
/// real and tested — the pack catalogue, the store rows, the server function
/// that credits a verified purchase — and [available] is the single switch that
/// decides whether the store shows packs for sale or as coming soon.
///
/// **What turns it on**, once Play Console has the three products:
///   1. Add the `in_app_purchase` plugin.
///   2. [available] becomes `InAppPurchase.instance.isAvailable()`.
///   3. [buy] queries the three product ids, launches the purchase, waits for
///      the purchase stream, and hands the purchase token to [_redeem].
///   4. Complete the purchase with Play *after* [_redeem] succeeds, so a
///      crash in between leaves the purchase pending and Play replays it.
/// The server half is already written and idempotent, so step 4 replaying is
/// safe: `redeemCoinPack` credits one receipt exactly once.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  /// Whether coin packs can be bought at all right now.
  ///
  /// False everywhere today. The store asks this instead of hard-coding
  /// "coming soon", so the day billing lands the shop window changes with it.
  Future<bool> available() async => false;

  /// Buys [pack] through Play and credits the coins.
  Future<BillingResult> buy(CoinPack pack) async {
    if (!await available()) {
      return const BillingResult.failed(BillingFailure.unavailable);
    }
    // Unreachable until the steps in this class's doc comment are done. It is
    // written as a refusal rather than a half-flow on purpose: a purchase path
    // that runs but cannot finish takes money and gives nothing.
    return const BillingResult.failed(BillingFailure.unavailable);
  }

  /// Hands a verified-by-Play purchase to the server, which checks it with
  /// Google and credits the coins. The client never says how many coins a pack
  /// is worth — that number lives in `functions/src/coin_packs.ts`.
  // ignore: unused_element
  Future<BillingResult> _redeem(CoinPack pack, String purchaseToken) async {
    try {
      final response = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('redeemCoinPack').call<dynamic>({
        'packId': pack.id,
        'purchaseToken': purchaseToken,
      });
      final coins = (response.data as Map?)?['coins'];
      return BillingResult.success(coins is int ? coins : pack.coins);
    } on FirebaseFunctionsException catch (e) {
      return BillingResult.failed(
        e.code == 'unauthenticated'
            ? BillingFailure.notSignedIn
            : BillingFailure.notCredited,
      );
    } catch (_) {
      return const BillingResult.failed(BillingFailure.failed);
    }
  }
}
