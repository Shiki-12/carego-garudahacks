# 07 — Mitra ↔ Patient Integration

> Bagaimana CAREGO App (pasien/penerima layanan) dan CAREGO Mitra (penyedia layanan)
> bekerja sama lewat **satu backend**. Ini jawaban langsung atas: "bagaimana CAREGO
> Mitra bisa bekerja dengan baik dengan CAREGO app."

Basis: `docs/mitra/api/endpoints.md`, `docs-new/api/endpoints.md`, SRS-06,
`docs-new/wiki/WIKI_06_Payment_and_Order_Management.md`.

---

## 1. Gambaran besar

Pasien dan Mitra **tidak** saling memanggil langsung. Keduanya berbicara ke backend
Encore yang sama; backend adalah mediator, penegak status, penghitung harga, dan
pemilik data. Pemisahan aplikasi murni di **scope peran** pada token (doc 02 §1).

```
CAREGO App (patient)                BACKEND                    CAREGO Mitra (provider)
────────────────────                ───────                    ───────────────────────
POST /bookings ───────────────►  buat booking(pending),
  {service, lokasi, ...}          hitung harga, cari mitra
                                  → notify mitra (doc 05)  ──►  order_new / emergency
                                                               GET /mitra/orders
                              ◄── (pasien menunggu)             POST /mitra/orders/:id/accept
      order_update  ◄──────────  ubah status→accepted,
      (push+WS)                  buat conversation (doc 04),
                                  broadcast                ──►  mulai kerja / tracking
      live GPS (doc 03) ◄───────  fan-out lokasi  ◄───────────  PUT /fleets/:id/location
      chat (doc 04)     ◄──────►  simpan+relay    ◄──────────►  chat
      order_update      ◄───────  status→completed ◄──────────  PUT /orders/:id/status
```

---

## 2. Satu pesanan, dua sudut pandang

Objek yang sama (`bookings` row) tampil beda di tiap app:

| | CAREGO App (pasien) | CAREGO Mitra (provider) |
|---|---------------------|-------------------------|
| Baca | `GET /bookings` (miliknya) | `GET /mitra/orders` (untuk provider-nya) |
| Aksi | buat, batal | terima, tolak, ubah status |
| Filter tab | Aktif / Selesai / Batal | Menunggu / Aktif / Riwayat |
| Otorisasi | `user_id = self` | `provider_id = self.providerId` |

Tidak ada duplikasi data — satu baris, difilter oleh identitas token.

---

## 3. State machine terpadu (pemetaan resmi)

Backend adalah penegak tunggal (doc 01 §6). Enum ringkas pasien (SRS-06) dipetakan ke
langkah dispatch mitra:

| Status kanonik | Arti | Tampilan pasien | Tampilan mitra | Pemicu |
|----------------|------|-----------------|----------------|--------|
| `pending` | Menunggu mitra | "Mencari penyedia…" | Tab **Menunggu** | pasien `POST /bookings` |
| `accepted` | Diterima mitra | "Dikonfirmasi" | Tab **Aktif** | mitra `accept` |
| `on_the_way` | Driver menuju (ambulans) | "Menuju lokasi" + peta | perjalanan tahap 1 | driver mulai jalan |
| `in_progress` | Layanan berjalan | "Sedang berlangsung" | perjalanan/kerja | mulai layanan |
| `completed` | Selesai | "Selesai" | Tab **Riwayat** | mitra `completed` |
| `cancelled` | Dibatalkan | "Dibatalkan" | Tab **Riwayat** | pasien/mitra batal |
| `rejected` | Ditolak mitra | kembali cari mitra lain | — | mitra `reject` |

Transisi legal ada di `assertTransition` (doc 01 §6). Contoh: `completed → cancelled`
**ditolak** backend walau UI salah menampilkan tombol.

> Catatan pemetaan: label pasien "confirmed" (SRS-06) = status kanonik `accepted`.
> Client pasien boleh menampilkan teks "Dikonfirmasi"; nilai yang disimpan tetap `accepted`.

---

## 4. Pembuatan booking (payload lengkap — TD-04)

Prototipe `/ambulance/book` kurang data. Payload produksi:

```typescript
// POST /bookings   (scope: patient)
interface CreateBookingReq {
  serviceType: "ambulance" | "caregiver" | "rental";
  providerId?: number;         // bila pasien memilih mitra spesifik; else broadcast
  // ambulans:
  pickupLat?: number; pickupLng?: number; pickupAddress?: string;
  destLat?: number;   destLng?: number;   destAddress?: string;
  fleetType?: "ALS" | "BLS" | "Jenazah";
  // caregiver/rental:
  scheduledAt?: string;        // ISO-8601
  rentalItemId?: number; rentalDays?: number;
  patientName: string;
  notes?: string;
}
```

Backend saat menerima:
1. Validasi input & scope (`patient`).
2. **Hitung harga di server** (jangan percaya harga client):
   - Ambulans: `total = baseFare + pricePerKm × ceil(distanceKm)` — ALS 150k/15k,
     BLS 100k/10k, Jenazah 200k/12k (doc 03 §6). `distanceKm` via OSRM (proxy) atau
     Haversine×1.3 fallback.
   - Rental: `total = price_daily × rentalDays` (atau `price_weekly` bila ≥ 7 hari).
   - Caregiver: sesuai tarif personil/paket.
3. Simpan `bookings` (status `pending`) + baris `booking_status_history`.
4. **Idempotency-Key** untuk cegah double-booking (doc 01 §8).
5. Notify mitra (doc 05): `order_new`, atau `emergency` untuk ambulans darurat.

---

## 5. Dispatch: mitra menerima / menolak

```typescript
// POST /mitra/orders/:id/accept   (scope: provider:*)
export const acceptOrder = api(
  { expose: true, auth: true, method: "POST", path: "/mitra/orders/:id/accept" },
  async ({ id }: { id: number }) => {
    const { providerId } = getAuthData()!;
    return db.tx(async (tx) => {
      const b = await tx.queryRow`SELECT status, provider_id FROM bookings WHERE id = ${id} FOR UPDATE`;
      if (!b) throw APIError.notFound("Pesanan tidak ditemukan");
      // race: pesanan broadcast — mitra pertama yang menerima menang
      if (b.status !== "pending") throw APIError.failedPrecondition("Pesanan sudah diambil/tidak tersedia");
      assertTransition("pending", "accepted");
      await tx.exec`
        UPDATE bookings SET status='accepted', provider_id=${providerId}, updated_at=NOW()
        WHERE id = ${id}
      `;
      await tx.exec`
        INSERT INTO booking_status_history (booking_id, from_status, to_status, changed_by)
        VALUES (${id}, 'pending', 'accepted', ${getAuthData()!.userID})
      `;
      await createConversation(id, b);      // doc 04 §7: chat otomatis
      await notifyPatient(id, "order_update", "Pesanan Anda diterima");  // doc 05
      return ok({ id, status: "accepted" });
    });
  }
);
```

- **`FOR UPDATE`** mengunci baris → dua mitra tak bisa menerima booking broadcast yang sama.
- Mitra pertama menang; yang lain dapat `409 FailedPrecondition` → UI menampilkan
  "Pesanan sudah diambil".
- **Reject** (`POST /mitra/orders/:id/reject`): jika booking ditujukan ke satu mitra,
  status → `rejected` lalu backend broadcast ulang ke mitra lain; jika broadcast, cukup
  hapus mitra ini dari kandidat.

---

## 6. Update status berjalan

```typescript
// PUT /mitra/orders/:id/status   { status: 'on_the_way' | 'in_progress' | 'completed' }
```
- Setiap transisi lewat `assertTransition` + tulis history + `notifyPatient`.
- `completed` untuk ambulans → hentikan tracking (doc 03 §2), finalisasi harga,
  proses pembayaran/potong saldo (doc 01 §9, transaksi).
- `completed` untuk rental → kembalikan stok saat item dikembalikan
  (`stock_count = stock_count + qty`).

---

## 7. Pembayaran & saldo (kritikal-uang)

- Saldo/wallet dipotong **di backend, dalam transaksi**, saat titik yang disepakati
  (mis. saat `completed` atau saat booking dikonfirmasi, sesuai kebijakan WIKI-06).
- Catat `wallet_transactions` (debit pasien, kredit/settlement mitra).
- **Idempotency** wajib agar retry tak memotong dua kali (doc 01 §8).
- Jangan pernah menghitung/menetapkan jumlah bayar di client.

---

## 8. Ketersediaan mitra & pencocokan

- Mitra toggle `is_available` via `PUT /mitra/availability` (online/libur). Hanya mitra
  `is_available = true` & `verification_status = 'verified'` yang jadi kandidat dispatch.
- Untuk ambulans: cocokkan berdasarkan jarak (fleet `last_lat/long`) + `fleetType`.
- Untuk caregiver/rental: cocokkan berdasarkan layanan/lokasi/jadwal.

---

## 9. Titik integrasi lintas fitur (peta cepat)

| Peristiwa | Doc terkait |
|-----------|-------------|
| Notifikasi order/darurat | 05 §6 |
| Chat otomatis per booking | 04 §7 |
| Live GPS saat `on_the_way`/`in_progress` | 03 §2 |
| State machine & history | 01 §6 |
| Harga/uang/stok transaksi | 01 §8-9, 07 §7 |
| Otorisasi scope + kepemilikan | 02 §6 |

---

## 10. Skenario end-to-end (ambulans darurat)

```
1. Pasien: POST /bookings {serviceType:'ambulance', pickup, dest, fleetType:'ALS'}
   → backend hitung harga, simpan pending, kirim EMERGENCY ke mitra terdekat.
2. Mitra driver: terima full-screen notif → POST /mitra/orders/:id/accept
   → status accepted, conversation dibuat, pasien dapat order_update.
3. Driver: mulai jalan → PUT status on_the_way + stream GPS (PUT /fleets/:id/location)
   → pasien lihat ambulans bergerak + ETA di peta.
4. Chat bila perlu (alamat detail) → real-time via WS, tersimpan di DB.
5. Tiba & layani → PUT status in_progress → completed.
6. Backend potong saldo (transaksi + idempotency), catat wallet_transactions,
   hentikan tracking, arsipkan percakapan.
```

Setiap langkah: status ditetapkan backend, tercatat di history, kedua app melihat versi
konsisten yang sama.

---

## 11. Checklist integrasi (tempel di PR lintas-app)

- [ ] Field name & status identik di backend, App, Mitra (satu kontrak — doc 01).
- [ ] Harga/status/otorisasi ditetapkan backend, bukan client.
- [ ] Dispatch broadcast aman-race (`FOR UPDATE`, mitra pertama menang).
- [ ] Setiap transisi status → history + notifikasi pasien.
- [ ] Chat & GPS aktif sesuai lifecycle order.
- [ ] Pembayaran transaksional + idempoten.
- [ ] Hanya mitra verified + available yang jadi kandidat.
</content>
