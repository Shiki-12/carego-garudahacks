-- Add password to users
ALTER TABLE users ADD COLUMN password_hash TEXT DEFAULT '';

-- Sessions table for token-based auth
CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '7 days'
);

-- Activity logs for audit trail
CREATE TABLE activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    user_name TEXT NOT NULL,
    user_role TEXT NOT NULL,
    action TEXT NOT NULL,
    detail TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Set default admin password (plain text "admin123" - in production use bcrypt)
UPDATE users SET password_hash = 'admin123' WHERE email = 'admin@carego.id';
UPDATE users SET password_hash = 'patient123' WHERE email = 'patient@carego.id';
