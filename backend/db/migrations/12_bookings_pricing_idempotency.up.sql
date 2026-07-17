-- Migration 12 — POST /bookings production support (docs/production 01 §8, 06 §5-6, 07 §4).
-- Up-only; all additions guarded with IF NOT EXISTS so it is safe on populated DBs.

-- === bookings: ambulance fleet class (ALS | BLS | Jenazah) ===
-- Server-side pricing keys off this column (doc 07 §4.2). Nullable for non-ambulance.
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS fleet_type TEXT;

-- === bookings: scheduled_at for caregiver/rental scheduled orders (doc 06 §5) ===
-- Referenced by POST /bookings; not created by earlier migrations.
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ;

-- === Idempotency keys for money/stock-critical actions (doc 01 §8) ===
-- A repeated request with the same key returns the stored response with no side effects.
CREATE TABLE IF NOT EXISTS idempotency_keys (
    key           TEXT PRIMARY KEY,
    user_id       INTEGER REFERENCES users(id),
    endpoint      TEXT NOT NULL,
    response_json JSONB NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- === Indexes supporting booking list/dispatch queries (doc 06 §6) ===
CREATE INDEX IF NOT EXISTS idx_bookings_user_created
    ON bookings(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_provider_status
    ON bookings(provider_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_status_active
    ON bookings(status)
    WHERE status IN ('pending', 'accepted', 'on_the_way', 'in_progress');
CREATE INDEX IF NOT EXISTS idx_bsh_booking
    ON booking_status_history(booking_id, created_at);
