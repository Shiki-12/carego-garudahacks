-- Seed 10 demo patient accounts with Rp 1,000,000 wallets
-- Password for all: password123
-- Bcrypt hash of 'password123' with 10 rounds

INSERT INTO users (name, email, password_hash, role) VALUES
('Demo User 1', 'demo1@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 2', 'demo2@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 3', 'demo3@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 4', 'demo4@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 5', 'demo5@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 6', 'demo6@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 7', 'demo7@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 8', 'demo8@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 9', 'demo9@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient'),
('Demo User 10', 'demo10@carego.id', '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG', 'patient')
ON CONFLICT (email) DO NOTHING;

-- Create wallets for demo users with Rp 1,000,000 each
INSERT INTO wallets (user_id, balance)
SELECT id, 1000000 FROM users WHERE email LIKE 'demo%@carego.id'
ON CONFLICT (user_id) DO NOTHING;
