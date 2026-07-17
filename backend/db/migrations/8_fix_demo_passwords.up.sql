-- Fix demo user passwords to proper bcrypt hash of 'password123'
-- This hash was generated with bcryptjs: bcrypt.hashSync('password123', 10)
UPDATE users SET password_hash = '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG'
WHERE email LIKE 'demo%@carego.id';

-- Also fix the original patient password
UPDATE users SET password_hash = '$2b$10$rN95H2si4SrS6RgiafGXduEuBmzktWtjQu.KZP5.8u7yg8KQ2bYbG'
WHERE email = 'patient@carego.id';
