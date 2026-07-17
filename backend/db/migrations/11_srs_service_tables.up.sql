-- Migration 11 — Align schema with SRS feature contracts.
-- Adds scheduling/pricing/cancellation columns to bookings and creates the
-- service-specific tables required by SRS-04 (caregiver), SRS-05 (rental),
-- SRS-06 (order management), SRS-07 (chat), SRS-08 (notifications), SRS-09 (wallet).
-- All existing columns are preserved; new columns are nullable so prior inserts keep working.

-- === bookings: unified booking record for all service types ===
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS service_type TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS provider_name TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS total_price INTEGER;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS notes TEXT;

-- Caregiver-specific (SRS-04)
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS caregiver_id INTEGER;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS booking_date DATE;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS start_time TIME;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS duration_hours INTEGER;

-- Rental-specific (SRS-05)
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS equipment_id INTEGER;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS rental_start_date DATE;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS rental_end_date DATE;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS duration INTEGER;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS duration_unit TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS delivery_address TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS deposit_amount INTEGER;

-- Ambulance / order-management (SRS-06)
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS pickup_location TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS pickup_lat DECIMAL(10,7);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS pickup_lng DECIMAL(10,7);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS destination TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS dest_lat DECIMAL(10,7);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS dest_lng DECIMAL(10,7);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS distance_km DECIMAL(6,2);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS patient_name TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS cancel_reason TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- === booking_status_history (SRS-06) ===
CREATE TABLE IF NOT EXISTS booking_status_history (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER REFERENCES bookings(id),
    from_status TEXT,
    to_status TEXT NOT NULL,
    changed_by INTEGER REFERENCES users(id),
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- === caregiver_profiles (SRS-04) ===
CREATE TABLE IF NOT EXISTS caregiver_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id),
    provider_id INTEGER REFERENCES providers(id),
    name TEXT NOT NULL DEFAULT '',
    specialization TEXT NOT NULL,
    experience_years INTEGER DEFAULT 0,
    hourly_rate INTEGER NOT NULL,
    bio TEXT,
    certifications TEXT[],
    photo_url TEXT,
    rating NUMERIC(2,1) DEFAULT 0,
    reviews INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- === equipment (SRS-05) ===
CREATE TABLE IF NOT EXISTS equipment (
    id SERIAL PRIMARY KEY,
    provider_id INTEGER REFERENCES providers(id),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    specifications JSONB,
    daily_rate INTEGER NOT NULL,
    weekly_rate INTEGER,
    deposit INTEGER DEFAULT 0,
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    images TEXT[],
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- === conversations + messages (SRS-07) ===
CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    booking_id INTEGER REFERENCES bookings(id),
    participant_1 INTEGER NOT NULL REFERENCES users(id),
    participant_2 INTEGER NOT NULL REFERENCES users(id),
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL REFERENCES conversations(id),
    sender_id INTEGER NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    type TEXT DEFAULT 'text',
    image_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- === transactions (SRS-09) ===
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    wallet_id INTEGER NOT NULL REFERENCES wallets(id),
    title TEXT NOT NULL,
    amount INTEGER NOT NULL,
    is_credit BOOLEAN NOT NULL,
    balance_after INTEGER NOT NULL,
    reference_type TEXT,
    reference_id INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- === notifications: additional data payload (SRS-08 §5.3) ===
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS data JSONB;
ALTER TABLE notification_preferences ADD COLUMN IF NOT EXISTS chat_messages BOOLEAN DEFAULT TRUE;

-- === Indexes for the new access patterns ===
CREATE INDEX IF NOT EXISTS idx_bookings_service_type ON bookings(service_type);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_transactions_wallet ON transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_available ON caregiver_profiles(is_available);
CREATE INDEX IF NOT EXISTS idx_equipment_available ON equipment(is_available);

-- === Seed caregiver profiles (SRS-04 example data) ===
INSERT INTO caregiver_profiles (name, specialization, experience_years, hourly_rate, bio, certifications, photo_url, rating, reviews, is_available)
VALUES
('Siti Aminah', 'Perawatan Lansia', 6, 75000, 'Caregiver berpengalaman untuk pendampingan lansia di rumah, termasuk bantuan aktivitas harian, pengingat obat, dan pemantauan kondisi ringan.', ARRAY['Sertifikat Caregiver Lansia', 'Basic Life Support'], 'https://example.com/images/caregivers/siti-aminah.png', 4.9, 84, TRUE),
('Budi Santoso', 'Perawatan Pasca Operasi', 4, 85000, 'Caregiver dengan fokus pemulihan pasca operasi dan perawatan luka ringan di rumah.', ARRAY['Sertifikat Perawatan Luka', 'Basic Life Support'], 'https://example.com/images/caregivers/budi-santoso.png', 4.7, 51, TRUE)
ON CONFLICT DO NOTHING;

-- === Seed equipment (SRS-05 example data) ===
INSERT INTO equipment (name, category, description, specifications, daily_rate, weekly_rate, deposit, stock, images, is_available)
VALUES
('Bed Pasien Elektrik', 'bed', 'Tempat tidur pasien elektrik 3 posisi untuk perawatan di rumah, dilengkapi pengaman samping dan roda pengunci.', '{"Tipe":"Elektrik 3 posisi","Kapasitas":"Maks. 180 kg","Fitur":"Remote, pagar samping, roda pengunci"}', 200000, 1200000, 500000, 3, ARRAY['https://example.com/images/equipment/bed-elektrik.png'], TRUE),
('Kursi Roda Standar', 'wheelchair', 'Kursi roda lipat standar untuk mobilitas pasien sehari-hari.', '{"Tipe":"Lipat","Kapasitas":"Maks. 120 kg","Fitur":"Rem tangan, pijakan kaki lipat"}', 50000, 300000, 200000, 5, ARRAY['https://example.com/images/equipment/kursi-roda.png'], TRUE),
('Tabung Oksigen 1m3', 'oxygen', 'Tabung oksigen medis lengkap dengan regulator untuk kebutuhan terapi di rumah.', '{"Kapasitas":"1 m3","Kelengkapan":"Regulator + humidifier"}', 75000, 450000, 300000, 4, ARRAY['https://example.com/images/equipment/oksigen.png'], TRUE)
ON CONFLICT DO NOTHING;
