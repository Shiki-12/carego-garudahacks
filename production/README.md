# CAREGO — Production-Ready Standard

> **Satu standar untuk tiga komponen:** Backend (Encore.ts), CAREGO App (aplikasi
> pasien/penerima layanan), dan CAREGO Mitra (aplikasi penyedia layanan).
>
> Versi 1.0 · Terakhir diperbarui: 2026-07-17 · Bahasa: dokumen (ID), kode & field API (EN)

---

## Kenapa dokumen ini ada

Saat ini seluruh platform CAREGO berstatus **prototipe**: data dummy in-memory di
Flutter, banyak endpoint `/mitra/*` dan `/bookings/*` masih *planned*, dan beberapa
keputusan arsitektur (token opaque, foto Base64 di DB, Google OAuth simulasi) secara
eksplisit ditandai sebagai *tech debt yang harus dimigrasi sebelum produksi*
(lihat `docs-new/context/decisions.md` ADR-002, ADR-008, dan ADR-009).

Dokumen ini adalah **kontrak tunggal** yang harus diikuti oleh Backend, CAREGO App,
dan CAREGO Mitra agar setiap fitur naik dari "prototipe" ke *production grade*
dengan cara yang **konsisten** — bukan tiga tim menebak-nebak sendiri.

Aturan emas:

1. **Backend adalah satu-satunya sumber kebenaran.** UI tidak pernah menghitung
   status, harga final, atau otorisasi sendiri sebagai keputusan akhir.
2. **Satu kontrak API dipakai dua aplikasi.** Pasien dan Mitra memanggil backend
   yang sama; field name, envelope response, dan kode error identik.
3. **Setiap perubahan skema lewat migrasi berurutan** (Encore auto-run). Tidak ada
   perubahan skema manual di database.
4. **Definition of Done bukan "UI jalan"** — lihat checklist di
   [`00_PRODUCTION_READINESS.md`](./00_PRODUCTION_READINESS.md).

---

## Peta Dokumen

| # | Dokumen | Untuk siapa | Isi |
|---|---------|-------------|-----|
| 00 | [Production Readiness Standard](./00_PRODUCTION_READINESS.md) | Semua | Definition of Done, gerbang rilis, matriks tech-debt → produksi |
| 01 | [Backend & API Contract](./01_BACKEND_API_CONTRACT.md) | Backend, kedua app | Envelope response, konvensi POST, pola service Encore, auth handler, error, paginasi, versi |
| 02 | [Auth & Security](./02_AUTH_SECURITY.md) | Backend, kedua app | OTP, hashing, sesi, role & scope (pasien vs mitra), rate limiting, secrets |
| 03 | [Realtime GPS Tracking](./03_REALTIME_GPS.md) | Backend, Mitra, App | Live location driver ambulans: ingest, fan-out (WS/SSE), background location, privasi |
| 04 | [Chat System](./04_CHAT_SYSTEM.md) | Backend, kedua app | Conversation/message model, WebSocket, delivery/read receipt, offline queue |
| 05 | [Notifications & Push (FCM)](./05_NOTIFICATIONS_PUSH.md) | Backend, kedua app | Device token, sinkron DB↔push, kategori, ringtone darurat mitra |
| 06 | [Data Model & Migrations](./06_DATA_MODEL_MIGRATIONS.md) | Backend | Skema terpadu (pasien + mitra), urutan migrasi, indeks, integritas |
| 07 | [Mitra ↔ Patient Integration](./07_MITRA_PATIENT_INTEGRATION.md) | Semua | Siklus pesanan lintas app: booking pasien → dispatch mitra → update balik |
| 08 | [Flutter Client Standard](./08_FLUTTER_CLIENT_STANDARD.md) | Kedua app | ApiService, env config, error handling, state, secure storage, retry |
| 09 | [Deployment, Observability & Testing](./09_DEPLOY_OBSERVABILITY_TESTING.md) | Semua | Environment, CI/CD, logging/metrics, testing pyramid, rollback |

> Baca **00** dan **01** dulu — keduanya adalah fondasi yang dirujuk semua dokumen lain.

---

## Konteks Sistem (ringkas)

```
┌────────────────┐     ┌────────────────┐
│  CAREGO App     │     │  CAREGO Mitra   │
│  (pasien)       │     │  (provider)     │
│  Flutter        │     │  Flutter        │
└───────┬─────────┘     └───────┬────────┘
        │ HTTPS + WSS           │ HTTPS + WSS
        ▼                       ▼
┌──────────────────────────────────────────┐
│          ENCORE.TS BACKEND                │
│  auth · user · bookings · ambulance ·     │
│  caregiver · rental · chat · notification │
│  · realtime · mitra(provider) · admin     │
│                                            │
│  PostgreSQL "carego" (migrasi berurutan)  │
│  WAHA (OTP)  ·  FCM (push)  ·  OSRM/OSM    │
└──────────────────────────────────────────┘
```

- **Kedua aplikasi Flutter berbagi backend yang sama.** Pemisahan bukan di server,
  melainkan di **scope peran** pada token sesi (`patient` vs `provider:*`).
- Sumber SRS pasien: `docs-new/`. Sumber SRS mitra: `docs/mitra/`. Dokumen produksi
  ini **tidak menggantikannya** — ia menetapkan *bagaimana* fitur-fitur itu dibangun
  hingga layak produksi.

---

## Status & Prinsip Penulisan

- Setiap contoh kode di sini adalah **pola referensi (reference implementation)**,
  bukan tempelan copy-paste final. Nama file/field mengikuti konvensi di
  [`01_BACKEND_API_CONTRACT.md`](./01_BACKEND_API_CONTRACT.md).
- Bila sebuah bagian menandai sesuatu sebagai *belum diimplementasikan*, jangan
  mengklaimnya sebagai selesai. Kejujuran status adalah bagian dari standar.
- Perubahan pada dokumen ini harus lewat review yang sama dengan perubahan kode.
</content>
</invoke>
