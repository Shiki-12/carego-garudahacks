# 01 — Backend & API Contract

> Kontrak API tunggal yang diikuti Backend, CAREGO App, dan CAREGO Mitra.
> Bila dokumen lain menyebut "sesuai kontrak API", inilah rujukannya.

Basis: Encore.ts + PostgreSQL "carego" (lihat `docs-new/context/architecture.md`).
Konvensi nama mengikuti `docs-new/development/coding-style.md`:
`camelCase` untuk endpoint & field JSON, `snake_case` untuk kolom DB, path `kebab-case`.

---

## 1. Aturan umum

1. **Transport:** HTTPS wajib di staging & produksi. WSS untuk realtime.
2. **Format:** JSON in/out, UTF-8. Waktu selalu **ISO-8601 UTC** (`2026-07-17T09:30:00Z`).
3. **Uang:** integer Rupiah, tanpa desimal (`230000`), field selalu diakhiri makna jelas (`totalPrice`, `priceDaily`).
4. **Bahasa:** pesan untuk user = Indonesia; log & kode = Inggris.
5. **Backend adalah sumber kebenaran** untuk status, harga final, stok, dan otorisasi.

---

## 2. Envelope Response (WAJIB, seragam)

Prototipe saat ini mengembalikan bentuk campur (kadang objek langsung, kadang
`{success:true}`). Untuk produksi, **semua** endpoint memakai satu envelope:

### Sukses
```json
{
  "ok": true,
  "data": { "...": "payload spesifik endpoint" }
}
```

### Gagal
```json
{
  "ok": false,
  "error": {
    "code": "INVALID_STATUS",
    "message": "Pesanan sudah selesai dan tidak dapat dibatalkan",
    "details": { "field": "status" }
  }
}
```

- `code` — konstanta `SCREAMING_SNAKE_CASE` yang stabil (dipakai client untuk logika).
- `message` — teks Indonesia siap tampil ke user.
- `details` — opsional, untuk validasi per-field.
- List selalu dibungkus: `data: { items: [...], total, limit, offset }` (lihat §7).

> **Migrasi bertahap:** endpoint lama (`/auth/login` dll.) boleh dipertahankan
> sampai kedua app di-update, tapi endpoint **baru** wajib envelope ini. Tandai
> endpoint lama sebagai `v0` di dokumentasi hingga dimigrasi.

### Helper Encore
```typescript
// backend/shared/response.ts
export type Ok<T> = { ok: true; data: T };
export type Err = { ok: false; error: { code: string; message: string; details?: unknown } };

export function ok<T>(data: T): Ok<T> {
  return { ok: true, data };
}

// Gunakan APIError Encore untuk status HTTP yang benar, bungkus pesan Indonesia:
import { APIError, ErrCode } from "encore.dev/api";
export function fail(code: string, message: string, http: ErrCode = ErrCode.InvalidArgument): never {
  // code = konstanta domain kita; http = pemetaan ke status Encore
  throw APIError.aborted(message).withDetails({ code }); // contoh; pilih ErrCode sesuai kasus
}
```

---

## 3. Pemetaan Error → HTTP

| Situasi | `error.code` | HTTP | Encore ErrCode |
|---------|--------------|------|----------------|
| Input tidak valid | `VALIDATION_ERROR` | 400 | `InvalidArgument` |
| Tidak terautentikasi | `UNAUTHENTICATED` | 401 | `Unauthenticated` |
| Tidak berwenang atas objek | `FORBIDDEN` | 403 | `PermissionDenied` |
| Objek tidak ditemukan | `NOT_FOUND` | 404 | `NotFound` |
| Konflik state / duplikasi | `INVALID_STATUS` / `CONFLICT` | 409 | `FailedPrecondition` / `AlreadyExists` |
| Rate limit | `RATE_LIMITED` | 429 | `ResourceExhausted` |
| Dependency down (WAHA/FCM/OSRM) | `UPSTREAM_UNAVAILABLE` | 503 | `Unavailable` |
| Bug tak terduga | `INTERNAL` | 500 | `Internal` |

Aturan: **jangan** bocorkan stack/SQL ke client. `message` selalu aman ditampilkan.

---

## 4. Konvensi Method & Path

Prototipe memakai POST untuk hampir semua (termasuk baca). Untuk produksi:

- **GET** untuk baca murni tanpa efek samping (list, detail). Boleh query param.
- **POST** untuk membuat / aksi (`/bookings`, `/bookings/:id/accept`).
- **PUT/PATCH** untuk update (`/mitra/availability`, `/bookings/:id/status`).
- **DELETE** untuk hapus.

> Encore mendukung path param (`/bookings/:id`) dan query param. Tetap konsisten:
> `kebab-case` untuk segmen path, `camelCase` untuk query & body.

Contoh kanonik lintas domain:

| Domain | Method + Path | Guna |
|--------|---------------|------|
| Auth | `POST /auth/login` · `POST /auth/otp/send` · `POST /auth/otp/verify` · `POST /auth/logout` | Sesi |
| Sesi | `GET /auth/me` | Validasi token → user |
| Booking (pasien) | `POST /bookings` · `GET /bookings` · `GET /bookings/:id` · `POST /bookings/:id/cancel` | Siklus pesanan |
| Booking (mitra) | `GET /mitra/orders` · `POST /mitra/orders/:id/accept` · `POST /mitra/orders/:id/reject` · `PUT /mitra/orders/:id/status` | Dispatch |
| Mitra availability | `PUT /mitra/availability` | Online/offline |
| Rental | `GET /mitra/rental/items` · `POST /mitra/rental/items` · `PUT /mitra/rental/items/:id` · `DELETE /mitra/rental/items/:id` | Katalog |
| GPS | `PUT /mitra/fleets/:id/location` · `GET /realtime/track/:bookingId` (WS) | Live tracking |
| Chat | `GET /chat/conversations` · `GET /chat/conversations/:id/messages` · `POST /chat/conversations/:id/messages` · WS `/chat/ws` | Pesan |
| Notif | `POST /notifications/devices` · `GET /notifications` · `POST /notifications/read-all` | Push |

---

## 5. Autentikasi endpoint (POLA WAJIB)

**Masalah prototipe:** banyak endpoint menerima `userId` di body dan memercayainya.
Itu lubang otorisasi (TD-05). Pola produksi memakai **Encore auth handler** yang
mengubah token → identitas terverifikasi, lalu endpoint memakai `getAuthData()`.

```typescript
// backend/auth/auth.ts
import { Header, Gateway } from "encore.dev/api";
import { authHandler } from "encore.dev/auth";
import { db } from "../db/db";

interface AuthParams {
  authorization: Header<"Authorization">; // "Bearer <token>"
}

// Identitas terverifikasi yang tersedia di semua endpoint ber-auth
export interface AuthData {
  userID: string;      // Encore mewajibkan userID string
  role: string;        // 'patient' | 'admin' | ...
  providerId?: number; // diisi bila user adalah mitra
  providerType?: string;
  scopes: string[];    // mis. ['patient'] atau ['provider:ambulance']
}

export const auth = authHandler<AuthParams, AuthData>(async (params) => {
  const token = params.authorization.replace(/^Bearer\s+/i, "");
  const row = await db.queryRow`
    SELECT u.id, u.role, p.id AS provider_id, p.provider_type
    FROM sessions s
    JOIN users u ON u.id = s.user_id
    LEFT JOIN providers p ON p.user_id = u.id
    WHERE s.token = ${token} AND s.expires_at > NOW()
  `;
  if (!row) throw APIError.unauthenticated("Sesi tidak valid atau sudah kedaluwarsa");

  const scopes = row.provider_type
    ? [`provider:${row.provider_type}`]
    : [String(row.role)];

  return {
    userID: String(row.id),
    role: String(row.role),
    providerId: row.provider_id ? Number(row.provider_id) : undefined,
    providerType: row.provider_type ? String(row.provider_type) : undefined,
    scopes,
  };
});

export const gateway = new Gateway({ authHandler: auth });
```

Endpoint yang butuh identitas:

```typescript
import { api } from "encore.dev/api";
import { getAuthData } from "~encore/auth";

export const cancelBooking = api(
  { expose: true, auth: true, method: "POST", path: "/bookings/:id/cancel" },
  async ({ id, reason }: { id: number; reason?: string }) => {
    const { userID } = getAuthData()!;          // ← identitas dari token, BUKAN body
    const booking = await db.queryRow`
      SELECT id, status, user_id FROM bookings WHERE id = ${id}
    `;
    if (!booking) throw APIError.notFound("Pesanan tidak ditemukan");
    if (String(booking.user_id) !== userID)     // ← otorisasi objek
      throw APIError.permissionDenied("Akses ditolak");
    // ... validasi state machine, update, history
    return ok({ id, status: "cancelled" });
  }
);
```

**Aturan keras:** field `userId` di body hanya diperbolehkan untuk endpoint admin
yang bertindak *atas nama* user lain, dan hanya setelah `role === 'admin'` diverifikasi
dari token.

---

## 6. Validasi state machine di server

Client boleh menyembunyikan tombol, tapi **backend yang menegakkan** transisi legal.
Satu tempat, dipakai ulang:

```typescript
// backend/bookings/state.ts
export type BookingStatus =
  | "pending" | "accepted" | "on_the_way" | "in_progress"
  | "completed" | "cancelled" | "rejected";

const ALLOWED: Record<BookingStatus, BookingStatus[]> = {
  pending:     ["accepted", "rejected", "cancelled"],
  accepted:    ["on_the_way", "in_progress", "cancelled"],
  on_the_way:  ["in_progress", "cancelled"],
  in_progress: ["completed", "cancelled"],
  completed:   [],
  cancelled:   [],
  rejected:    [],
};

export function assertTransition(from: BookingStatus, to: BookingStatus): void {
  if (!ALLOWED[from]?.includes(to)) {
    throw APIError.failedPrecondition(
      `Transisi status tidak valid: ${from} → ${to}`
    ).withDetails({ code: "INVALID_STATUS" });
  }
}
```

Setiap perubahan status **wajib** menulis baris ke `booking_status_history`
(from, to, changed_by, reason) dalam transaksi yang sama (lihat doc 06 & 07).

> Catatan: SRS-06 pasien memakai enum ringkas (`pending → confirmed → completed →
> cancelled`). Kontrak terpadu di atas memperluasnya agar mencakup langkah dispatch
> mitra (`accepted/on_the_way/in_progress`). Pemetaan: `confirmed` pasien = `accepted`
> mitra. Doc 07 §3 memuat tabel pemetaan resmi.

---

## 7. Paginasi, filter, sorting

List endpoint **selalu** mengembalikan bentuk terbungkus dan menerima `limit`/`offset`:

```json
// GET /bookings?status=active&limit=20&offset=0
{
  "ok": true,
  "data": {
    "items": [ /* ... */ ],
    "total": 42,
    "limit": 20,
    "offset": 0
  }
}
```

- `limit` default 20, maksimum 100 (backend meng-clamp).
- Filter status memakai grup: `active` = `pending`+`accepted`+`on_the_way`+`in_progress`.
- Default sort: `created_at DESC`. Sertakan indeks pendukung (doc 06 §6).

---

## 8. Idempotency (aksi kritikal-uang/stok)

Untuk `POST /bookings`, potong saldo, dan `accept` pesanan — cegah duplikat akibat
retry/double-tap dengan **Idempotency-Key**:

```
POST /bookings
Idempotency-Key: 7c3f...client-generated-uuid
```

Backend menyimpan `(idempotency_key, response)` selama mis. 24 jam; permintaan
berikutnya dengan key sama mengembalikan respons tersimpan tanpa efek ganda.

```sql
CREATE TABLE idempotency_keys (
  key TEXT PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  endpoint TEXT NOT NULL,
  response_json JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 9. Transaksi database

Aksi yang menyentuh >1 tabel atau uang/stok berjalan atomik:

```typescript
await db.tx(async (tx) => {
  await tx.exec`UPDATE bookings SET status = 'accepted', updated_at = NOW() WHERE id = ${id}`;
  await tx.exec`
    INSERT INTO booking_status_history (booking_id, from_status, to_status, changed_by)
    VALUES (${id}, ${from}, 'accepted', ${changerId})
  `;
  await tx.exec`UPDATE rental_items SET stock_count = stock_count - 1 WHERE id = ${itemId} AND stock_count > 0`;
});
```

Cek `stock_count > 0` di klausa `WHERE` mencegah stok negatif tanpa lock eksplisit.

---

## 10. Rate limiting & ukuran payload

- OTP send: maksimum 1/menit/identifier, 5/jam (doc 02 §3).
- Login: back-off setelah 5 gagal berturut.
- Body maksimum default (mis. 1 MB); upload gambar chat/profil lewat object storage
  (presigned URL), **bukan** Base64 di JSON (TD-02).

---

## 11. Versi & kompatibilitas

- Prefix versi hanya bila breaking: `/v1/...`. Sampai G2, jaga backward-compat.
- Perubahan non-breaking (tambah field opsional) tidak perlu versi baru.
- Client wajib mengabaikan field yang tidak dikenal (forward-compatible parsing).

---

## 12. Struktur service Encore (pola file)

```
backend/
├── shared/response.ts        # ok(), fail(), tipe envelope
├── auth/
│   ├── auth.ts               # authHandler + Gateway
│   ├── api.ts                # login, otp, logout, me
│   └── encore.service.ts
├── bookings/
│   ├── api.ts                # create, list, detail, cancel
│   ├── state.ts              # state machine
│   └── encore.service.ts
├── mitra/                    # provider-facing (dispatch, availability, catalog, fleet)
│   ├── orders.ts
│   ├── availability.ts
│   ├── fleets.ts             # + location ingest
│   └── encore.service.ts
├── chat/ realtime/ notification/ user/ admin/
└── db/
    ├── db.ts                 # SQLDatabase("carego")
    └── migrations/           # berurutan, up-only
```

Setiap file `api.ts` mengikuti urutan: imports → interfaces → helper privat →
endpoint terekspor (coding-style.md §File Organization).

---

## 13. Checklist kontrak (tempel di PR backend)

- [ ] Envelope `ok/data` atau `ok/error` konsisten.
- [ ] `auth: true` + `getAuthData()` untuk semua endpoint ber-identitas; tidak percaya `userId` body.
- [ ] Otorisasi objek diperiksa (pemilik/penerima).
- [ ] State transition lewat `assertTransition` + tulis history.
- [ ] Query parameterized (tagged template).
- [ ] List terbungkus + paginasi + indeks.
- [ ] Aksi uang/stok: transaksi + idempotency.
- [ ] Error dipetakan ke HTTP yang benar, pesan Indonesia aman.
- [ ] Endpoint terdaftar di dokumen API terkait.
</content>
