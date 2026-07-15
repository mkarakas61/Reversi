import {getAuth} from "firebase-admin/auth";

/**
 * True when a Firebase Auth user has no linked provider — i.e. an anonymous
 * guest. Pure so it's unit-testable without the Admin SDK; the authoritative
 * check is the provider list, never a client-supplied flag (spoof-proof).
 */
export function isGuestUser(providerData: {providerId: string}[]): boolean {
  return providerData.length === 0;
}

/** Authoritative (server-side) guest check for a uid. */
export async function isGuest(uid: string): Promise<boolean> {
  const record = await getAuth().getUser(uid);
  return isGuestUser(record.providerData);
}
