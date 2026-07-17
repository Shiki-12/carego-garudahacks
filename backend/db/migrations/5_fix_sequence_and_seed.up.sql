-- Fix the sequence for users table so it syncs with manually inserted rows
SELECT setval('users_id_seq', COALESCE((SELECT MAX(id) FROM users), 1));

-- Seed the requested patient2 user
INSERT INTO users (name, email, password_hash, role)
VALUES ('patient2', 'patient2@gmail.com', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient')
ON CONFLICT (email) DO NOTHING;

-- Initialize wallet for the seeded user
INSERT INTO wallets (user_id, balance) 
SELECT id, 0 FROM users WHERE email = 'patient2@gmail.com'
ON CONFLICT (user_id) DO NOTHING;
