# 09 — Deployment, Observability & Testing

> Cara men-deploy, mengamati, dan menguji platform CAREGO sampai layak produksi.
> Menutup TD-09 (tidak ada CI/CD, test, atau monitoring). Berlaku untuk semua komponen.

---

## 1. Environment

Tiga lingkungan, konfigurasi via env (doc 08 §3), **tanpa** rahasia di kode.

| Env | Backend | DB | Tujuan |
|-----|---------|----|--------|
| `local` | Encore run (localhost:4000) | Encore-managed Postgres | dev harian; WAHA Docker (port 3000) untuk OTP |
| `staging` | Encore Cloud/self-host | DB terpisah berisi data uji | verifikasi G1 (device fisik) |
| `production` | Encore Cloud/self-host | DB produksi | rilis G2 |

- Rahasia (WAHA, Google client secret, FCM service account, storage creds) lewat
  **Encore secrets** per environment (doc 02 §7).
- Migrasi berjalan otomatis & berurutan saat deploy (doc 06 §1). Verifikasi migrasi aman
  di DB berisi data sebelum production (G2).

---

## 2. CI/CD (menutup TD-09)

Pipeline minimal pada setiap PR ke `main`:

```
1. Lint & type-check   → tsc --noEmit (backend, no `any`) ; flutter analyze (kedua app)
2. Unit test           → logika harga, state machine, auth, geocoding (§4)
3. Integration test    → happy-path endpoint utama terhadap DB ephemeral
4. Build               → encore build ; flutter build apk/appbundle
5. Migrasi check       → jalankan semua migrasi di DB kosong; gagal = blok merge
```

- **Gate merge**: PR tak boleh masuk `main` bila lint/type/test gagal, atau kotak DoD
  relevan (doc 00 §2) kosong tanpa alasan.
- Deploy ke `staging` otomatis saat merge ke `main`; deploy `production` manual/tag
  setelah G1 lulus.
- Konvensi commit: `Component: description` (coding-style.md), mis. `bookings: add cancel endpoint`.

---

## 3. Observability (menutup TD-09)

### 3.1 Logging terstruktur (bukan `console.log` — doc 00 §6)
```typescript
import log from "encore.dev/log";
log.info("booking_created", { bookingId, userId, serviceType, totalPrice });
log.error("fcm_send_failed", { userId, err: String(e) });
```
- Event kunci berlevel: `info` untuk alur normal, `warn` untuk fallback (mis. OSRM →
  Haversine, doc 03 §6), `error` untuk kegagalan. **Tidak ada silent catch** (doc 00 §6).
- **Jangan** log data sensitif: password, OTP, token, isi pesan chat (doc 02 §8, doc 04 §6).

### 3.2 Metrics & tracing
- Encore menyediakan tracing request bawaan — pakai untuk melihat latensi per endpoint.
- Metrik yang dipantau: p95 latensi, rate 5xx, kegagalan FCM, kegagalan upstream
  (WAHA/OSRM), koneksi WS aktif, lama dispatch (pending→accepted).

### 3.3 Alerting
- Alert untuk: lonjakan 5xx, upstream down, kegagalan migrasi, **dispatch ambulans
  tak terlayani** (pending > ambang — kelas kritikal-nyawa).

### 3.4 Audit trail
- `activity_logs` (keamanan, doc 02 §8) & `booking_status_history` (lifecycle, doc 06 §5)
  adalah audit trail wajib; jangan hard-delete.

---

## 4. Testing pyramid

| Lapis | Cakupan | Contoh CAREGO |
|-------|---------|---------------|
| **Unit** (banyak) | logika murni | perhitungan harga ambulans (ALS/BLS/Jenazah), `assertTransition` state machine, verifikasi OTP, Haversine fallback |
| **Integration** (sedang) | endpoint ↔ DB | `POST /bookings` → row tersimpan + history; `accept` race dua mitra (`FOR UPDATE`) hanya satu menang |
| **E2E/Widget** (sedikit) | alur kritikal | login→booking→accept→track→complete; widget test state loading/empty/error |

Wajib minimal (doc 00 §2.5): unit test untuk setiap logika kritikal (harga, state,
auth) + satu happy-path integration test per endpoint baru.

Uji **jalur gagal**, bukan hanya happy path (doc 00 §3, G1): timeout, upstream down,
4xx/5xx, double-tap, reconnect WS.

### 4.1 Uji device fisik (G1)
Hal yang **tak bisa** diverifikasi di emulator dan wajib di device nyata:
- Background location & foreground service driver (doc 03 §3).
- Full-screen intent + ringtone darurat FCM (doc 05 §3), perilaku Doze/senyap.
- Izin lokasi/notifikasi Android 13+/iOS.

---

## 5. Rollback & data safety

- **Rollback kode**: deploy versi sebelumnya (Encore mendukung rollback deploy).
- **Migrasi**: up-only; untuk membatalkan perubahan skema, tulis migrasi maju baru yang
  mengoreksi — jangan hapus migrasi lama. Karena itu **uji migrasi di salinan DB
  produksi** sebelum G2.
- **Backup DB** terjadwal sebelum rilis besar; verifikasi restore.
- **Feature flag** untuk fitur berisiko (chat, GPS) agar bisa dimatikan tanpa rollback penuh.

---

## 6. Definisi rilis per gerbang (ringkas doc 00 §3)

| Gate | Fokus dokumen ini |
|------|-------------------|
| **G0** Dev complete | lint+unit+integration hijau lokal; demo happy-path end-to-end |
| **G1** Staging verified | deploy staging; uji device fisik (GPS/push/background); uji jalur gagal; logging aktif |
| **G2** Production | monitoring+alert aktif; rollback teruji; migrasi aman di DB berisi data; backup terverifikasi |

---

## 7. Checklist rilis (tempel di PR/rilis)

- [ ] Lint & type-check bersih (backend `tsc`, kedua app `flutter analyze`).
- [ ] Unit + integration test kritikal hijau; jalur gagal diuji.
- [ ] Migrasi jalan bersih di DB kosong & diuji di salinan DB berisi data.
- [ ] Rahasia via Encore secrets per environment; tak ada di kode/git.
- [ ] Logging terstruktur di titik kunci; tak ada `console.log`/silent catch; tak ada data sensitif di log.
- [ ] Metrics & alert aktif (5xx, upstream, dispatch darurat tertunda).
- [ ] Uji device fisik untuk GPS background, push darurat, izin OS (G1).
- [ ] Rollback & backup teruji sebelum G2.
- [ ] Roadmap/IMPLEMENTATION_STATUS diperbarui jujur.

---

## 8. Penutup — satu standar, tiga komponen

Sembilan dokumen (00–09) membentuk **satu standar** yang diikuti Backend, CAREGO App,
dan CAREGO Mitra:

- **00** menetapkan *kapan* sesuatu disebut selesai (DoD, gerbang, tech-debt).
- **01–02** menetapkan *kontrak & keamanan* dasar yang dirujuk semuanya.
- **03–05** menetapkan *fitur realtime* (GPS, chat, notifikasi) yang menghubungkan kedua app.
- **06** menetapkan *data* bersama.
- **07** menetapkan *bagaimana kedua app bekerja sama* lewat backend.
- **08–09** menetapkan *cara membangun klien* dan *cara merilis dengan aman*.

Prinsip yang mengikat semuanya: **backend adalah sumber kebenaran, satu kontrak dua
aplikasi, setiap perubahan skema lewat migrasi, dan "selesai" bukan berarti "UI jalan".**
</content>
