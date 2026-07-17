# 02 — Auth & Security

> Standar identitas, sesi, dan otorisasi untuk Backend, CAREGO App, dan CAREGO Mitra.
> Rujukan pola auth handler ada di [`01_BACKEND_API_CONTRACT.md`](./01_BACKEND_API_CONTRACT.md) §5.

Basis prototipe (dari `docs-new/wiki/WIKI_01_Authentication_and_Security.md`):
bcrypt 10 rounds, token opaque 64-char hex di tabel `sessions` (7 hari), OTP 6 digit
5 menit via WAHA. Dokumen ini menaikkannya ke production grade.

---

## 1. Model identitas & peran

Satu backend melayani dua aplikasi. Pemisahan **bukan** di server, melainkan di
**scope peran** pada sesi.

| Sumber | Peran (`users.role`) | Scope token | App |
|--------|----------------------|-------------|-----|
| Pasien | `patient` | `patient` | CAREGO App |
| Mitra caregiver | `provider` + `provider_type=caregiver` | `provider:caregiver` | CAREGO Mitra |
| Mitra ambulans | `provider` + `provider_type=ambulance` | `provider:ambulance` | CAREGO Mitra |
| Mitra rental | `provider` + `provider_type=rental` | `provider:rental` | CAREGO Mitra |
| Admin | `admin` | `admin` | Panel admin |

**Aturan role-lock (SRS-07 Mitra):** satu akun = satu peran. Registrasi mitra
menetapkan `provider_type` **permanen**; tidak ada peralihan peran pada akun yang sama.
Backend menolak endpoint di luar scope token (§6).

---

## 2. Hashing & penyimpanan kredensial

- **Password:** bcrypt cost **12** untuk produksi (naik dari 10 prototipe;
  seimbangkan dengan latensi target < 250 ms). Simpan hanya hash.
- **Tidak pernah** menyimpan password plaintext, mengirim balik hash ke client,
  atau menaruh password di log.
- Validasi kekuatan minimal saat set/ubah: ≥ 8 karakter. Tolak daftar password
  umum (mis. `password123`).

```typescript
import bcrypt from "bcrypt";
const BCRYPT_COST = 12;
const hash = await bcrypt.hash(plainPassword, BCRYPT_COST);
const okPw = await bcrypt.compare(input, user.password_hash);
```

---

## 3. Sesi & token

Prototipe: opaque token 64-char hex di `sessions`, expiry 7 hari (ADR-002, TD-01).
Dipertahankan untuk MVP dengan pengerasan berikut sebelum G2:

### 3.1 Pembuatan
```typescript
import { randomBytes } from "crypto";
const token = randomBytes(32).toString("hex"); // 256-bit, unguessable
await db.exec`
  INSERT INTO sessions (user_id, token, expires_at, created_at)
  VALUES (${userId}, ${token}, NOW() + INTERVAL '7 days', NOW())
`;
```

### 3.2 Pengerasan wajib
- **Index** pada `sessions.token` (unik) dan `sessions.expires_at`.
- **Cleanup job** harian menghapus sesi kedaluwarsa (Encore cron).
- **Rotasi**: terbitkan token baru saat login; sediakan `POST /auth/logout` yang
  menghapus baris sesi; sediakan `POST /auth/logout-all` (hapus semua sesi user).
- **Transport**: token hanya via header `Authorization: Bearer`, tidak pernah di URL/query
  (kecuali WS handshake yang tak bisa set header — lihat doc 03/04, dan itu pun via
  ticket sekali-pakai, bukan token utama).
- **Penyimpanan client**: `flutter_secure_storage` (Keychain/Keystore), **bukan**
  `SharedPreferences` biasa (doc 08 §4).

### 3.3 Rate limiting (kritikal-keamanan)
| Aksi | Batas |
|------|-------|
| OTP send | 1/menit & 5/jam per nomor |
| Verifikasi OTP | 5 percobaan per kode, lalu kode hangus |
| Login gagal | back-off eksponensial setelah 5 gagal berturut per akun/IP |

---

## 4. OTP (WhatsApp via WAHA)

Prototipe: kode 6 digit, expiry 5 menit, tabel `otp_codes`, kirim via WAHA dengan
fallback `console.log` (WIKI-01).

Produksi:
- Kode di-generate server-side (`randomInt(100000, 999999)`), simpan **hash** kode
  (bukan plaintext) + `expires_at` + `attempts`.
- **Fallback `console.log` DILARANG di produksi** — itu membocorkan OTP ke log. Bila
  WAHA down, kembalikan `UPSTREAM_UNAVAILABLE` (503) dan jangan tandai terkirim.
- Satu OTP aktif per nomor; kirim baru meng-invalidate yang lama.
- Setelah verifikasi sukses, hapus/nonaktifkan kode segera (one-time use).

```typescript
// verify
const rec = await db.queryRow`
  SELECT id, code_hash, expires_at, attempts FROM otp_codes
  WHERE phone = ${phone} AND consumed_at IS NULL
  ORDER BY created_at DESC LIMIT 1
`;
if (!rec || rec.expires_at < new Date()) throw APIError.invalidArgument("Kode OTP tidak valid atau kedaluwarsa");
if (rec.attempts >= 5) throw APIError.resourceExhausted("Terlalu banyak percobaan, minta kode baru");
const match = await bcrypt.compare(inputCode, rec.code_hash);
await db.exec`UPDATE otp_codes SET attempts = attempts + 1 WHERE id = ${rec.id}`;
if (!match) throw APIError.invalidArgument("Kode OTP salah");
await db.exec`UPDATE otp_codes SET consumed_at = NOW() WHERE id = ${rec.id}`;
```

---

## 5. Google OAuth (TD-03 — WAJIB diperbaiki)

Prototipe menerima `googleId` mentah dari client dan memercayainya — siapa pun bisa
mengaku sebagai `google_id` mana pun. **Sebelum produksi, verifikasi `id_token`
Google di server:**

```typescript
import { OAuth2Client } from "google-auth-library";
const client = new OAuth2Client(googleClientId());
const ticket = await client.verifyIdToken({ idToken, audience: googleClientId() });
const payload = ticket.getPayload();
if (!payload?.email_verified) throw APIError.unauthenticated("Akun Google belum terverifikasi");
const googleSub = payload.sub;    // ← identitas tepercaya, BUKAN dari body
const email = payload.email;
```

Client mengirim `idToken` hasil Google Sign-In, **bukan** `googleId`/`email` lepas.

---

## 6. Otorisasi (dua lapis)

### Lapis 1 — Scope peran (endpoint-level)
Endpoint mitra hanya untuk token ber-scope `provider:*`; endpoint pasien untuk
`patient`. Tegakkan di endpoint:

```typescript
function requireScope(want: string) {
  const { scopes } = getAuthData()!;
  if (!scopes.includes(want)) throw APIError.permissionDenied("Akses ditolak untuk peran ini");
}
// contoh: PUT /mitra/orders/:id/status
requireScope("provider:ambulance");
```

### Lapis 2 — Kepemilikan objek (row-level)
Bahkan dengan scope benar, user hanya boleh menyentuh objek miliknya:
- Pasien: hanya booking dengan `user_id = self`.
- Mitra: hanya order dengan `provider_id = self.providerId`.
Cek eksplisit setelah query (lihat doc 01 §5 contoh `cancelBooking`).

**Anti-pattern terlarang:** menyembunyikan tombol di UI dianggap "otorisasi". UI
hanya kosmetik; backend yang menolak.

---

## 7. Secrets & akun seed (TD-11)

- Semua rahasia (WAHA URL/token, Google client secret, FCM service account, DB creds)
  lewat **Encore secrets** (`secret("Name")`), **tidak** hardcoded, **tidak** di git.
- Password seed lemah (`admin123`, `password123`) di migrasi **hanya untuk dev**.
  Migrasi seed diberi guard environment atau seed dilakukan lewat skrip terpisah yang
  tidak jalan di produksi. Di produksi: buat admin awal via prosedur aman lalu rotasi.

```typescript
import { secret } from "encore.dev/config";
const wahaToken = secret("WahaToken");
```

---

## 8. Audit trail

Setiap peristiwa keamanan penting dicatat ke `activity_logs` (sudah ada di skema):
`login_success`, `login_failed`, `otp_sent`, `otp_verified`, `logout`,
`password_changed`, `session_revoked`. Simpan `user_id`, `action`, `ip`, `created_at`
— **tanpa** menyimpan password/OTP/token di dalamnya.

---

## 9. Alur end-to-end (registrasi mitra → sesi)

```
CAREGO Mitra                 Backend                         WAHA
─────────────                ───────                         ────
pilih role (provider_type) 
POST /auth/otp/send  ───────► generate+hash OTP, simpan ───► kirim WA
                     ◄─────── ok{ sent:true }
input kode
POST /auth/otp/verify ──────► cek hash+expiry+attempts
                     ◄─────── ok{ verified:true }
POST /mitra/auth/register ──► bcrypt(pw), buat users(role=provider,
   {phone, pw, provider_type,  provider_type), providers row,
    entity_type, business}     buat session token
                     ◄─────── ok{ token, role, providerType }
   simpan token di secure storage
   → resolve shell sesuai provider_type (role-lock)
```

Alur pasien identik minus `provider_type`/`entity_type`, `role=patient`,
resolve ke home pasien.

---

## 10. Checklist keamanan (tempel di PR)

- [ ] Password bcrypt cost 12; tidak pernah plaintext/log.
- [ ] Token via `Authorization: Bearer`; disimpan di secure storage; ada index+cleanup+rotasi.
- [ ] OTP di-hash, one-time, rate-limited; **tanpa** fallback log di produksi.
- [ ] Google `id_token` diverifikasi server-side (TD-03).
- [ ] Scope peran + kepemilikan objek diperiksa di setiap endpoint sensitif.
- [ ] Identitas dari token, bukan `userId` body (TD-05).
- [ ] Secrets via Encore secrets; seed lemah tidak masuk produksi (TD-11).
- [ ] Peristiwa keamanan tercatat di `activity_logs` tanpa data sensitif.
</content>
