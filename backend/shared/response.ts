import { APIError } from "encore.dev/api";

// Uniform success/error envelope per docs/production/01 §2-3.
// Success responses are wrapped in `ok(data)`; failures are thrown as Encore
// APIError so the HTTP status is correct, carrying a stable domain `code` and a
// ready-to-display Indonesian `message`.

export type Ok<T> = { ok: true; data: T };

export function ok<T>(data: T): Ok<T> {
  return { ok: true, data };
}

// Wrapper for a paginated list payload (docs/production/01 §7).
export interface Page<T> {
  items: T[];
  total: number;
  limit: number;
  offset: number;
}

// Stable domain error codes (SCREAMING_SNAKE_CASE) used by clients for logic.
export const ErrorCode = {
  VALIDATION_ERROR: "VALIDATION_ERROR",
  UNAUTHENTICATED: "UNAUTHENTICATED",
  FORBIDDEN: "FORBIDDEN",
  NOT_FOUND: "NOT_FOUND",
  INVALID_STATUS: "INVALID_STATUS",
  CONFLICT: "CONFLICT",
  RATE_LIMITED: "RATE_LIMITED",
  UPSTREAM_UNAVAILABLE: "UPSTREAM_UNAVAILABLE",
  INTERNAL: "INTERNAL",
} as const;

export type ErrorCodeValue = (typeof ErrorCode)[keyof typeof ErrorCode];

// Error constructors that map a domain code -> correct Encore HTTP status
// (docs/production/01 §3). `message` must always be safe to show to the user.
export function validationError(message: string, details?: unknown): APIError {
  return APIError.invalidArgument(message).withDetails({
    code: ErrorCode.VALIDATION_ERROR,
    ...(details ? { details } : {}),
  });
}

export function unauthenticated(message: string): APIError {
  return APIError.unauthenticated(message).withDetails({ code: ErrorCode.UNAUTHENTICATED });
}

export function forbidden(message: string): APIError {
  return APIError.permissionDenied(message).withDetails({ code: ErrorCode.FORBIDDEN });
}

export function notFound(message: string): APIError {
  return APIError.notFound(message).withDetails({ code: ErrorCode.NOT_FOUND });
}

export function invalidStatus(message: string): APIError {
  return APIError.failedPrecondition(message).withDetails({ code: ErrorCode.INVALID_STATUS });
}

export function conflict(message: string): APIError {
  return APIError.alreadyExists(message).withDetails({ code: ErrorCode.CONFLICT });
}
