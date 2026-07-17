import { db } from "../db/db";
import log from "encore.dev/log";

// Internal helper to persist an in-app notification row (docs/production/05).
// Used by booking flows to notify a mitra of a new order, or a patient of updates.
// Never throws into the caller's critical path — a failed notification must not roll
// back a committed booking.

export interface NotifyInput {
  userId: number;
  type: string; // e.g. 'order_new' | 'order_update' | 'emergency'
  title: string;
  message: string;
  data?: Record<string, unknown>;
}

export async function notifyUser(input: NotifyInput): Promise<void> {
  try {
    await db.exec`
      INSERT INTO notifications (user_id, type, title, message, data)
      VALUES (${input.userId}, ${input.type}, ${input.title}, ${input.message},
              ${input.data ?? null})
    `;
  } catch (err) {
    // Log and swallow: notification delivery is best-effort, not transactional.
    log.error("failed to persist notification", {
      userId: input.userId,
      type: input.type,
      error: err instanceof Error ? err.message : String(err),
    });
  }
}

// Resolve the user_id of every candidate mitra for a broadcast, or a single mitra
// when a providerId is supplied. Only available + matching service_type providers
// are considered (doc 07 §8). verification_status is not present in the current
// providers schema, so availability + service match is the current gate.
export async function findCandidateMitraUserIds(
  serviceType: string,
  providerId?: number,
): Promise<number[]> {
  const rows = providerId
    ? db.query`
        SELECT user_id FROM providers
        WHERE id = ${providerId} AND service_type = ${serviceType} AND is_available = TRUE
      `
    : db.query`
        SELECT user_id FROM providers
        WHERE service_type = ${serviceType} AND is_available = TRUE
      `;
  const ids: number[] = [];
  for await (const row of rows) {
    if (row.user_id != null) ids.push(Number(row.user_id));
  }
  return ids;
}
