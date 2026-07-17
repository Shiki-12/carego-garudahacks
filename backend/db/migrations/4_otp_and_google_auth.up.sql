-- Add phone and google_id to users
ALTER TABLE users ADD COLUMN phone TEXT UNIQUE;
ALTER TABLE users ADD COLUMN google_id TEXT UNIQUE;

-- OTP Codes table
CREATE TABLE otp_codes (
    id SERIAL PRIMARY KEY,
    identifier TEXT NOT NULL, -- email or phone number
    code TEXT NOT NULL,
    method TEXT NOT NULL, -- 'email' or 'whatsapp'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '5 minutes'
);

-- Update existing user passwords to proper bcrypt hashes
UPDATE users SET password_hash = '$2b$10$L6M1EpcGaIDLA7l2gY6mE.9/uVscSZtAt4Tev5/nJlAsKcq.45vl6' WHERE email = 'admin@carego.id';
UPDATE users SET password_hash = '$2b$10$BzE/tt6HjjJ8KMCzaGdKzOLrjVj45PxNDrtJthXahQ4iuenUsvjAa' WHERE email = 'patient@carego.id';
