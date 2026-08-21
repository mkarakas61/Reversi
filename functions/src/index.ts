import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions/v2";
import {onCall} from "firebase-functions/v2/https";

initializeApp();

// europe-west1 is close to the Firestore eur3 (europe-west) location, keeping
// function-to-database latency low. Matchmaking, result validation and XP
// awarding (REV-43 / REV-50) will be added here as the online phases land.
setGlobalOptions({region: "europe-west1", maxInstances: 10});

/// Connectivity check used to validate the Functions pipeline end to end.
/// Returns the caller's uid (if signed in) so the client can confirm auth is
/// wired through to callable functions.
export const ping = onCall((request) => {
  return {
    pong: true,
    uid: request.auth?.uid ?? null,
    at: Date.now(),
  };
});

// Matchmaking: pairs waiting players into a game (REV-43).
export {onMatchmakingTicketWritten} from "./matchmaking";

// End-of-game rewards: replays the move log to validate the result, then awards
// XP, level, ranked stats and coins to both players (REV-50).
export {onGameFinished} from "./finish_game";

// Cleanup sweep: cancels games stuck `active` after both players disconnected,
// so an abandoned match doesn't linger forever (REV-48 edge case).
export {sweepAbandonedGames} from "./sweep";

// Store: buys a catalog item with coins, server-authoritative (REV-66).
export {purchaseItem} from "./purchase";

// Rematch: offers/answers a rematch on a finished game and opens the new one
// through the server, so colours and rewards stay honest (REV-98).
export {requestRematch, respondRematch} from "./rematch";

// Account deletion (REV-90): the in-app deletion path Play requires, plus the
// daily job that enforces the 12-month retention promise in the privacy policy.
export {deleteAccount, purgeExpiredMatchRecords} from "./delete_account";
