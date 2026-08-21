import {getAuth} from "firebase-admin/auth";
import {
  getFirestore,
  FieldValue,
  Query,
  Timestamp,
} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";

// The Admin app is initialized once in index.ts.

/// How long a finished match may be kept after one of its players deleted
/// their account. The privacy policy promises "name and photo removed, kept at
/// most 12 months", so this constant is a commitment to users, not a tuning
/// knob — changing it means changing the published text first.
export const RETENTION_DAYS = 365;
const RETENTION_MS = RETENTION_DAYS * 24 * 60 * 60 * 1000;

/// Firestore caps a batch at 500 writes; stay under it with room for the
/// occasional extra delete queued alongside a document.
const BATCH_LIMIT = 400;

/// The instant a match must have been anonymized before to be past the
/// retention promise. Anything stamped at or before this goes; a match with no
/// `anonymizedAt` at all is never selected, because nobody deleted an account
/// on it.
export function retentionCutoffMs(
  nowMs: number,
  retentionMs: number = RETENTION_MS,
): number {
  return nowMs - retentionMs;
}

/// Deletes the caller's account and everything the app stores about them
/// (REV-90). Play requires an in-app deletion path, and the privacy policy
/// names this exact route: Ayarlar → Uygulama & Hesap → Hesabımı sil.
///
/// A callable rather than a client-side `user.delete()`: the client can delete
/// its own auth user but not its Firestore records — the rules make profiles,
/// history and leaderboard rows server-owned — and a half-deleted account
/// (auth gone, data left) is worse than none. Running server-side also side-
/// steps `requires-recent-login`, which would otherwise force a re-sign-in
/// prompt in the middle of an irreversible action.
///
/// Order matters: data first, auth user last. If anything fails in between the
/// account still exists and the player can try again; deleting auth first would
/// orphan the rest with no signed-in caller left to clean it up.
export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }

  const db = getFirestore();
  const now = FieldValue.serverTimestamp();

  // 1. Any queue ticket, so no match can be made mid-deletion.
  await db.collection("matchmaking").doc(uid).delete();

  // 2. Games. An active one is cancelled — the same terminal state the sweep
  //    uses, so the opponent is freed to matchmake and neither side is
  //    rewarded. A finished one is kept as a match record but stripped of the
  //    leaver's name and photo, and stamped so the retention job can find it.
  const games = await db
    .collection("games")
    .where("playerUids", "array-contains", uid)
    .get();

  let batch = db.batch();
  let writes = 0;
  const flush = async (force = false) => {
    if (writes >= BATCH_LIMIT || (force && writes > 0)) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  };

  for (const doc of games.docs) {
    const g = doc.data();
    // A merging set with a nested map, rather than a dotted update path: the
    // uid is data, and building "playerInfo.<uid>.name" would hand it to the
    // path parser. Merge reaches the same two leaves and leaves the
    // opponent's entry untouched.
    const update: Record<string, unknown> = {
      playerInfo: {[uid]: {name: null, photo: null}},
      deletedPlayers: FieldValue.arrayUnion(uid),
      anonymizedAt: now,
    };
    if (g.status === "active") {
      update.status = "cancelled";
      update.cancelledReason = "account deleted";
      update.cancelledAt = now;
    }
    batch.set(doc.ref, update, {merge: true});
    writes++;
    await flush();
  }

  // 3. Match history (users/{uid}/history/*).
  const history = await db
    .collection("users")
    .doc(uid)
    .collection("history")
    .get();
  for (const doc of history.docs) {
    batch.delete(doc.ref);
    writes++;
    await flush();
  }

  // 4. Every week's leaderboard row. Listed rather than queried: the rows live
  //    under leaderboards/{week}/players/{uid}, so there is exactly one
  //    candidate per week and no index is needed.
  const weeks = await db.collection("leaderboards").listDocuments();
  for (const week of weeks) {
    batch.delete(week.collection("players").doc(uid));
    writes++;
    await flush();
  }

  // 5. The profile itself — balances, trophies, owned items.
  batch.delete(db.collection("users").doc(uid));
  writes++;
  await flush(true);

  // 6. The auth user, last: after this the caller no longer exists.
  await getAuth().deleteUser(uid);

  logger.info(
    `Deleted account ${uid}: ${games.size} game(s) anonymized, ` +
      `${history.size} history row(s), ${weeks.length} leaderboard week(s)`
  );
  return {ok: true, games: games.size, history: history.size};
});

/// Enforces the 12-month promise: once a match has carried a deleted player's
/// anonymized record for [RETENTION_DAYS], the match document itself goes.
///
/// Runs daily rather than monthly so a single failed run cannot push a record
/// past the promised window by weeks. Deleting the game does not touch the
/// remaining player's own stats — those live in their `history` subcollection,
/// which is written per player and never read back from the game.
export const purgeExpiredMatchRecords = onSchedule(
  "every day 04:30",
  async () => {
    const db = getFirestore();
    const cutoff = Timestamp.fromMillis(retentionCutoffMs(Date.now()));

    const expired: Query = db
      .collection("games")
      .where("anonymizedAt", "<=", cutoff)
      .limit(BATCH_LIMIT);

    let purged = 0;
    // Loop so a backlog larger than one batch still clears, without ever
    // holding more than BATCH_LIMIT deletes in flight.
    for (;;) {
      const snap = await expired.get();
      if (snap.empty) break;
      const batch = db.batch();
      for (const doc of snap.docs) batch.delete(doc.ref);
      await batch.commit();
      purged += snap.size;
      if (snap.size < BATCH_LIMIT) break;
    }

    if (purged > 0) {
      logger.info(`retention: purged ${purged} expired match record(s)`);
    }
  }
);
