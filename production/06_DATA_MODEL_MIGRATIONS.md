# 06 — Data Model & Migrations

> Skema terpadu (pasien + mitra) dalam satu database `carego`, dengan aturan migrasi
> yang menjaga integritas. Basis: `docs-new/api/database.md`, `docs/mitra/api/database.md`,
> SRS-06 §5.3.

Kedua app berbagi **satu** database. Tabel pasien dan mitra hidup berdampingan;
booking adalah titik temu keduanya (doc 07).

---

## 1. Aturan migrasi (WAJIB)

1. **Berurutan & up-only.** Encore menjalankan file migrasi terurut otomatis. Nomori
   `1_xxx.up.sql`, `2_xxx.up.sql`, … Jangan pernah mengedit migrasi yang sudah pernah
   jalan; buat migrasi baru.
2. **Tidak ada `ALTER TABLE` manual** di database. Semua perubahan skema lewat file
   migrasi yang di-review (doc 00 §6).
3. **Idempotent bila mungkin**: gunakan `IF NOT EXISTS` untuk objek tambahan; hindari
   asumsi state.
4. **Uji dua arah**: migrasi harus `up` bersih di DB kosong **dan** aman di DB berisi
   data nyata (G2, doc 00 §3). Kolom baru non-null butuh default atau backfill.
5. **Backfill data** untuk kolom baru dilakukan di migrasi yang sama atau skrip terpisah
   yang tercatat.

```
backend/db/migrations/
  1_init.up.sql              # users, wallets, sessions, otp_codes, activity_logs
  2_providers.up.sql         # providers, personnels, fleets, rental_items
  3_bookings.up.sql          # bookings + kolom lengkap + status history
  4_chat.up.sql              # conversations, messages
  5_notifications.up.sql     # notifications, user_devices, preferences
  6_gps.up.sql               # fleet location cols, trip_locations
  7_idempotency.up.sql       # idempotency_keys
```

---

## 2. Entitas inti (ERD ringkas)

```
users ──1:1── wallets
  │  ├──1:1── providers ──1:N── provider_personnels
  │  │             │      ├─1:N── provider_fleets ──1:N── trip_locations
  │  │             │      └─1:N── rental_items
  │  ├──1:N── sessions
  │  ├──1:N── otp_codes
  │  ├──1:N── user_devices
  │  ├──1:N── notifications
  │  └──1:N── activity_logs
  │
bookings ──┬── user_id  → users        (pasien)
           ├── provider_id → providers  (mitra)
           ├──1:N── booking_status_history
           └──1:1── conversations ──1:N── messages
```

---

## 3. `users` & peran

Menampung pasien, mitra, dan admin dengan diskriminator `role`. Mitra menautkan ke
`providers` untuk atribut penyedia.

```sql
CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  phone         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name     TEXT,
  role          TEXT NOT NULL DEFAULT 'patient',  -- 'patient' | 'provider' | 'admin'
  photo_url     TEXT,                              -- URL object storage (BUKAN Base64, TD-02)
  google_sub    TEXT UNIQUE,                       -- id_token.sub terverifikasi (TD-03)
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
```

> **TD-02 (foto Base64):** kolom `photo_url` prototipe menyimpan Base64. Migrasi produksi
> memindah ke object storage (§7) dan menyimpan URL. Backfill: unggah blob lama → ganti
> nilai kolom dengan URL.

---

## 4. `providers` & sub-entitas (mitra)

```sql
CREATE TABLE providers (
  id             SERIAL PRIMARY KEY,
  user_id        INTEGER UNIQUE NOT NULL REFERENCES users(id),
  provider_type  TEXT NOT NULL,                 -- 'caregiver' | 'ambulance' | 'rental'
  entity_type    TEXT,                          -- 'agency' | 'independent' (NULL utk rental)
  business_name  TEXT,
  is_available   BOOLEAN DEFAULT FALSE,          -- toggle online/libur
  verification_status TEXT DEFAULT 'pending',    -- 'pending' | 'verified' | 'rejected'
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE provider_personnels (   -- caregiver agency: daftar personil
  id          SERIAL PRIMARY KEY,
  provider_id INTEGER NOT NULL REFERENCES providers(id),
  name        TEXT NOT NULL,
  skill       TEXT,
  status      TEXT DEFAULT 'available',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE provider_fleets (       -- ambulans: armada
  id          SERIAL PRIMARY KEY,
  provider_id INTEGER NOT NULL REFERENCES providers(id),
  plate_number TEXT NOT NULL,
  type        TEXT NOT NULL,          -- 'ALS' | 'BLS' | 'Jenazah'
  status      TEXT DEFAULT 'idle',    -- 'idle' | 'on_duty'
  last_lat    DOUBLE PRECISION,       -- live GPS (doc 03)
  last_long   DOUBLE PRECISION,
  last_heading DOUBLE PRECISION,
  last_location_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE rental_items (          -- rental: katalog alat medis
  id          SERIAL PRIMARY KEY,
  provider_id INTEGER NOT NULL REFERENCES providers(id),
  name        TEXT NOT NULL,
  category    TEXT,
  stock_count INTEGER NOT NULL DEFAULT 0,
  price_daily  INTEGER NOT NULL,      -- Rupiah integer
  price_weekly INTEGER,
  image_url   TEXT,                   -- object storage
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

`entity_type` NULL untuk rental (rental tak punya pembedaan agency/mandiri — SRS-10).

---

## 5. `bookings` (titik temu pasien ↔ mitra)

Prototipe `/ambulance/book` hanya menyimpan `userId`+`providerId` (TD-04). Skema
lengkap sesuai SRS-06 §5.3:

```sql
CREATE TABLE bookings (
  id            SERIAL PRIMARY KEY,
  user_id       INTEGER NOT NULL REFERENCES users(id),      -- pasien
  provider_id   INTEGER REFERENCES providers(id),           -- mitra (NULL saat pending broadcast)
  service_type  TEXT NOT NULL,        -- 'ambulance' | 'caregiver' | 'rental'
  status        TEXT NOT NULL DEFAULT 'pending',
  -- lokasi (ambulans)
  pickup_lat    DOUBLE PRECISION,
  pickup_lng    DOUBLE PRECISION,
  pickup_address TEXT,
  dest_lat      DOUBLE PRECISION,
  dest_lng      DOUBLE PRECISION,
  dest_address  TEXT,
  distance_km   DOUBLE PRECISION,
  -- harga & detail
  total_price   INTEGER,              -- dihitung backend (Rupiah)
  patient_name  TEXT,
  notes         TEXT,
  -- lifecycle
  scheduled_at  TIMESTAMPTZ,          -- caregiver/rental terjadwal
  cancelled_at  TIMESTAMPTZ,
  cancel_reason TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE booking_status_history (
  id          BIGSERIAL PRIMARY KEY,
  booking_id  INTEGER NOT NULL REFERENCES bookings(id),
  from_status TEXT,
  to_status   TEXT NOT NULL,
  changed_by  INTEGER REFERENCES users(id),
  reason      TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

Status & transisi ditegakkan backend (doc 01 §6, doc 07 §3). Setiap perubahan status
menulis satu baris history dalam transaksi yang sama.

---

## 6. Indeks (performa)

```sql
CREATE UNIQUE INDEX idx_sessions_token ON sessions(token);
CREATE INDEX idx_sessions_expires ON sessions(expires_at);
CREATE INDEX idx_bookings_user   ON bookings(user_id, created_at DESC);
CREATE INDEX idx_bookings_provider ON bookings(provider_id, status, created_at DESC);
CREATE INDEX idx_bookings_status ON bookings(status) WHERE status IN ('pending','accepted','on_the_way','in_progress');
CREATE INDEX idx_bsh_booking ON booking_status_history(booking_id, created_at);
CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at);
CREATE INDEX idx_notif_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_rental_provider ON rental_items(provider_id);
```

Partial index pada booking aktif mempercepat query dashboard mitra (`GET /mitra/orders`).

---

## 7. Object storage (TD-02) — foto & gambar

- Simpan blob (foto profil, gambar chat, gambar item rental) di **object storage**
  (S3/GCS/Encore bucket), **bukan** kolom DB.
- DB hanya menyimpan **URL/kunci** (`photo_url`, `image_url`).
- Upload lewat **presigned URL**: client minta URL ke backend → upload langsung ke storage
  → kirim kunci ke backend. Body JSON tak pernah membawa Base64 (doc 01 §10).
- Migrasi dari Base64: skrip baca kolom lama → upload → tulis URL → (opsional) kosongkan
  kolom Base64.

---

## 8. Integritas & konsistensi

- **Foreign key** di semua relasi; hindari orphan.
- **Uang** integer Rupiah; jangan float untuk saldo/harga.
- **Enum sebagai TEXT + CHECK** atau divalidasi di aplikasi (state machine doc 01 §6).
- **Timestamp** `TIMESTAMPTZ`, disimpan UTC.
- **Transaksi** untuk aksi multi-tabel/uang/stok (doc 01 §9); cek `stock_count > 0` di
  `WHERE` untuk cegah stok negatif.
- **Soft vs hard delete**: histori booking/chat/notifikasi jangan di-hard-delete (butuh
  audit/sengketa); gunakan status/arsip.

---

## 9. Checklist skema/migrasi (tempel di PR)

- [ ] Perubahan skema lewat migrasi baru berurutan; tidak edit migrasi lama.
- [ ] `up` bersih di DB kosong **dan** aman di DB berisi data (kolom baru punya default/backfill).
- [ ] FK, index, dan tipe uang integer sudah benar.
- [ ] Blob ke object storage; DB simpan URL (TD-02).
- [ ] Field name identik dengan kontrak API & kedua app (doc 01).
- [ ] Tidak ada seed password lemah di jalur produksi (TD-11, doc 02 §7).
</content>
