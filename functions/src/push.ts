import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions/v2";

// Sending push notifications to a player's devices (REV-114).
//
// The tokens live in `users/{uid}/devices/{token}`, written by the app when a
// player grants permission (REV-111). Nothing here decides *whether* someone
// should be notified; callers do that.

/// The Android channel created by MainActivity.kt. A message aimed at a channel
/// that does not exist lands in the system's "Miscellaneous" bucket, so this
/// string has to match the app's — the pair is guarded by a test.
export const ANDROID_CHANNEL_ID = "reversi_general";

/// Error codes Firebase returns for a token that will never work again.
/// Anything else — a timeout, a quota blip — is temporary and must NOT delete
/// the token, or one bad afternoon would silently unsubscribe everybody.
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

export interface PushText {
  title: string;
  body: string;
}

/// The same message in both languages, chosen per device from the `lang` field
/// the app stored with the token.
export type Localized = {tr: PushText; en: PushText};

/// Picks the text for a device's stored language, defaulting to Turkish — the
/// app's primary language and what a device that never recorded one is most
/// likely to be.
export function textFor(localized: Localized, lang: unknown): PushText {
  return lang === "en" ? localized.en : localized.tr;
}

/// Sends [localized] to every device [uid] has registered.
///
/// Returns the number of devices that accepted it. Never throws: a failed
/// notification must not fail the operation that triggered it — a match is
/// still a match if the push does not arrive.
export async function sendToUser(
  uid: string,
  localized: Localized,
  data: Record<string, string>,
): Promise<number> {
  const db = getFirestore();

  let devices;
  try {
    devices = await db.collection("users").doc(uid).collection("devices").get();
  } catch (e) {
    logger.warn(`push: could not read devices for ${uid}`, e);
    return 0;
  }
  if (devices.empty) {
    // Logged rather than passed over in silence: "the player has no registered
    // device" and "the send failed" are indistinguishable from the outside,
    // and the first one is what a broken registration looks like.
    logger.info(`push: ${uid} has no registered devices`);
    return 0;
  }

  const messaging = getMessaging();
  let delivered = 0;

  const results = await Promise.allSettled(
    devices.docs.map(async (doc) => {
      const text = textFor(localized, doc.data().lang);
      await messaging.send({
        token: doc.id,
        notification: {title: text.title, body: text.body},
        // The data payload is what the app acts on when the notification is
        // tapped; the notification block is what the system draws while the
        // app is closed. Both are needed — a data-only message is not shown
        // at all on a killed Android app.
        data,
        android: {
          priority: "high",
          notification: {channelId: ANDROID_CHANNEL_ID},
        },
        apns: {
          payload: {aps: {sound: "default"}},
        },
      });
      return doc.id;
    }),
  );

  const dead: string[] = [];
  results.forEach((result, i) => {
    if (result.status === "fulfilled") {
      delivered++;
      return;
    }
    const code = (result.reason as {code?: string})?.code ?? "";
    if (DEAD_TOKEN_CODES.has(code)) {
      dead.push(devices.docs[i].id);
    } else {
      logger.warn(`push: send failed for ${uid}`, result.reason);
    }
  });

  // A token that Firebase says is gone is gone: the app was uninstalled, or
  // its data cleared. Left in place it would be retried forever, and the
  // device count would drift away from the number of real phones.
  await Promise.allSettled(
    dead.map((token) =>
      db
        .collection("users")
        .doc(uid)
        .collection("devices")
        .doc(token)
        .delete(),
    ),
  );
  if (dead.length > 0) {
    logger.info(`push: pruned ${dead.length} dead token(s) for ${uid}`);
  }

  logger.info(
    `push: delivered to ${delivered}/${devices.size} device(s) for ${uid}`,
  );
  return delivered;
}

/// "An opponent is waiting" — the message that makes queueing worth leaving the
/// app for (REV-114). The join window is named in the body because the whole
/// point is that it expires.
export function opponentFoundText(seconds: number): Localized {
  return {
    tr: {
      title: "Rakip bulundu!",
      body: `Maça katılmak için ${seconds} saniyen var.`,
    },
    en: {
      title: "Opponent found!",
      body: `You have ${seconds} seconds to join the match.`,
    },
  };
}
