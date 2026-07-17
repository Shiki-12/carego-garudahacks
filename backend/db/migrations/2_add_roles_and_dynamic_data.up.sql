-- Add roles to users
ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'patient';

-- Wallets
CREATE TABLE wallets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) UNIQUE,
    balance INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recommendations
CREATE TABLE recommendations (
    id SERIAL PRIMARY KEY,
    service_type TEXT NOT NULL,
    title TEXT NOT NULL,
    tag_label TEXT NOT NULL,
    tag_color TEXT NOT NULL,
    rating NUMERIC(3, 1) DEFAULT 0.0,
    reviews INTEGER DEFAULT 0,
    price TEXT NOT NULL,
    image TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed an admin user, a patient user, their wallets, and default recommendations
INSERT INTO users (id, name, email, role) VALUES (1, 'Admin', 'admin@carego.id', 'admin') ON CONFLICT DO NOTHING;
INSERT INTO users (id, name, email, role) VALUES (2, 'Patient A', 'patient@carego.id', 'patient') ON CONFLICT DO NOTHING;

INSERT INTO wallets (user_id, balance) VALUES (2, 250000) ON CONFLICT DO NOTHING;

INSERT INTO recommendations (service_type, title, tag_label, tag_color, rating, reviews, price, image) VALUES 
('ambulance', 'Ambulance BLS', 'Tersedia 24 Jam', 'bg-teal-600', 4.9, 120, 'Mulai Rp 350.000', 'https://images.unsplash.com/photo-1587559070757-f72a388edbba?q=80&w=2070&auto=format&fit=crop'),
('hotel', 'Hotel Sehat Sentosa', 'Diskon 15%', 'bg-orange-500', 4.7, 80, 'Mulai Rp 250.000/malam', 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=2070&auto=format&fit=crop'),
('rental', 'Bed Pasien Elektrik', 'Sewa Mingguan', 'bg-blue-500', 4.8, 60, 'Rp 75.000/hari', 'https://images.unsplash.com/photo-1505692794401-e00661eb1a47?q=80&w=2070&auto=format&fit=crop');
