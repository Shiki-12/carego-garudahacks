-- Migration 13 — Seed providers and backfill provider_id links.
-- Fixes audit blocker B3: providers table was empty, so any booking that
-- references provider_id failed the bookings_provider_id_fkey constraint.
-- Up-only; idempotent via fixed IDs + ON CONFLICT so it is safe to re-run.

-- === Seed provider organizations (one per service domain) ===
-- Fixed IDs let us backfill dependent rows deterministically.
INSERT INTO providers (id, user_id, service_type, is_available)
VALUES
    (1, NULL, 'caregiver', TRUE),
    (2, NULL, 'rental', TRUE),
    (3, NULL, 'ambulance', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Keep the sequence ahead of the manually-assigned IDs.
SELECT setval('providers_id_seq', GREATEST((SELECT MAX(id) FROM providers), 1));

-- === Backfill existing catalog rows to their provider ===
UPDATE caregiver_profiles SET provider_id = 1 WHERE provider_id IS NULL;
UPDATE equipment          SET provider_id = 2 WHERE provider_id IS NULL;
