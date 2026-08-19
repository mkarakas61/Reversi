import {Timestamp} from "firebase-admin/firestore";

/// The `rematch` field on a finished game document (REV-98).
export type RematchStatus = "pending" | "accepted" | "declined";

export interface RematchState {
  by: string;
  status: RematchStatus;
  at?: Timestamp;
  expiresAt?: Timestamp;
  gameId?: string | null;
}

/// What the server should do with a rematch call, decided from the stored
/// state alone.
///
/// Split out from the callables so the state machine can be tested without a
/// Firestore: every awkward case here (both players tapping at once, a retry
/// arriving after the offer already succeeded, an offer that timed out while
/// the card was on screen) is a race that is hard to reproduce against a live
/// database and easy to pin down in a unit test.
export type RematchAction =
  /// An accepted rematch already exists; hand back its game.
  | {kind: "already-accepted"; gameId: string}
  /// The caller's own offer is still standing — do nothing, report it.
  | {kind: "already-offered"}
  /// The opponent is offering; create the new game.
  | {kind: "accept"}
  /// Nothing live — record a new offer.
  | {kind: "offer"}
  /// Withdraw or refuse the standing offer.
  | {kind: "decline"}
  /// The offer being answered is gone (withdrawn, refused or timed out).
  | {kind: "nothing-to-answer"; status: RematchStatus};

export function isExpired(state: RematchState, nowMs: number): boolean {
  const expiresAt = state.expiresAt;
  if (!expiresAt) return false;
  return expiresAt.toMillis() < nowMs;
}

function isLive(state: RematchState | undefined, nowMs: number): boolean {
  return (
    state !== undefined &&
    state.status === "pending" &&
    !isExpired(state, nowMs)
  );
}

/// "Play again" was tapped.
///
/// Note the third branch: when the opponent's offer is already standing, this
/// tap *accepts* it rather than replacing it with a second offer. Both players
/// tapping at the same moment is the most likely way this feature gets used,
/// and treating the second tap as a fresh offer would leave two offers standing
/// and neither game starting.
export function actionForRequest(
  state: RematchState | undefined,
  callerUid: string,
  nowMs: number
): RematchAction {
  if (state?.status === "accepted" && state.gameId) {
    return {kind: "already-accepted", gameId: state.gameId};
  }
  if (isLive(state, nowMs)) {
    return state!.by === callerUid ? {kind: "already-offered"} : {kind: "accept"};
  }
  return {kind: "offer"};
}

/// An offer was answered — accepted by the opponent, or withdrawn by whoever
/// made it (leaving the result screen withdraws it).
///
/// A stale answer is not an error: the client is simply a moment behind the
/// document it is listening to, and telling the player off for that would be
/// noise. It reports the state it found instead.
export function actionForResponse(
  state: RematchState | undefined,
  callerUid: string,
  accept: boolean,
  nowMs: number
): RematchAction {
  if (state?.status === "accepted" && state.gameId) {
    return {kind: "already-accepted", gameId: state.gameId};
  }
  if (!isLive(state, nowMs)) {
    return {kind: "nothing-to-answer", status: state?.status ?? "declined"};
  }
  if (!accept) return {kind: "decline"};
  // Accepting your own offer would let one player start a game alone.
  if (state!.by === callerUid) return {kind: "already-offered"};
  return {kind: "accept"};
}
