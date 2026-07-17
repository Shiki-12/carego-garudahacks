import { invalidStatus } from "../shared/response";

// Unified booking state machine (docs/production/01 §6, doc 07 §3). The backend is
// the sole enforcer of legal transitions; clients may only hide buttons.

export type BookingStatus =
  | "pending"
  | "accepted"
  | "on_the_way"
  | "in_progress"
  | "completed"
  | "cancelled"
  | "rejected";

const ALLOWED: Record<BookingStatus, BookingStatus[]> = {
  pending: ["accepted", "rejected", "cancelled"],
  accepted: ["on_the_way", "in_progress", "cancelled"],
  on_the_way: ["in_progress", "cancelled"],
  in_progress: ["completed", "cancelled"],
  completed: [],
  cancelled: [],
  rejected: [],
};

export function assertTransition(from: BookingStatus, to: BookingStatus): void {
  if (!ALLOWED[from]?.includes(to)) {
    throw invalidStatus(`Transisi status tidak valid: ${from} → ${to}`);
  }
}
