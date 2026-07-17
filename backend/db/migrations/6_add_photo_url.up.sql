-- Add photo_url column to users for profile photos (stored as Base64)
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_url TEXT;
