# 00 — Production Readiness Standard

> Definition of Done, gerbang rilis, dan matriks tech-debt → produksi.
> Berlaku untuk Backend, CAREGO App, dan CAREGO Mitra.

---

## 1. Prinsip

Sebuah fitur disebut **production-ready** hanya jika ia benar di tiga lapis
sekaligus: **kontrak** (API stabil & terdokumentasi), **ketahanan** (gagal dengan
anggun, tidak kehilangan/menggandakan data), dan **operasional** (bisa diamati,
di-deploy, dan di-rollback). "UI-nya jalan di emulator" bukan salah satu dari
ketiganya.

---

## 2. Definition of Done (DoD) — wajib untuk setiap fitur

Sebuah fitur (mis. "Order Management", "Live GPS driver", "Chat") baru boleh
ditandai ✅ selesai jika **semua** poin di bawah terpenuhi.

### 2.1 Kontrak & Data
- [ ] Endpoint terdefinisi mengikuti [`01_BACKEND_API_CONTRACT.md`](./01_BACKEND_API_CONTRACT.md) (envelope, error, paginasi).
- [ ] Semua perubahan skema lewat migrasi berurutan baru; migrasi diuji `up` di DB kosong.
- [ ] Field name identik di backend, CAREGO App, dan Mitra (tidak ada penerjemahan diam-diam di client).
- [ ] Tidak ada data dummy in-memory yang tersisa di jalur produksi; UI membaca dari API.

### 2.2 Keamanan & Otorisasi
- [ ] Setiap endpoint yang butuh identitas divalidasi lewat auth handler terpusat (bukan `userId` mentah dari body — lihat §5 di doc 01 & doc 02).
- [ ] Otorisasi objek diperiksa: pemilik/penerima pesanan saja yang bisa mengaksesnya.
- [ ] Input divalidasi & di-sanitasi; query pakai tagged template (parameterized).
- [ ] Tidak ada secret hardcoded; semua lewat Encore secrets.

### 2.3 Ketahanan (Resilience)
- [ ] Semua jalur gagal ditangani: network error, timeout, 4xx/5xx, dependency down (WAHA/FCM/OSRM) punya fallback yang terdefinisi.
- [ ] Operasi kritikal **idempoten** atau terlindung dari duplikasi (mis. double-tap "Terima pesanan").
- [ ] Transisi status divalidasi state machine di backend (bukan hanya di UI).
- [ ] Aksi uang/stok berjalan dalam transaksi database tunggal.

### 2.4 Observability
- [ ] Log terstruktur pada titik penting (bukan `console.log` liar) — lihat doc 09.
- [ ] Event penting tercatat di `activity_logs` / audit trail (mis. `booking_status_history`).
- [ ] Error server tidak membocorkan detail internal ke user; pesan user dalam Bahasa Indonesia.

### 2.5 Kualitas
- [ ] Ada test: minimal unit test untuk logika (harga, state machine, auth) + satu happy-path integration test endpoint.
- [ ] Lulus lint & type-check (tidak ada `any` di TypeScript; `flutter analyze` bersih).
- [ ] Empty state, loading state, dan error state ada di setiap layar yang memuat data.

### 2.6 Dokumentasi
- [ ] Endpoint didokumentasikan di `docs-new/api/endpoints.md` atau `docs/mitra/api/endpoints.md`.
- [ ] Status di roadmap/IMPLEMENTATION_STATUS diperbarui jujur.

---

## 3. Gerbang Rilis (Release Gates)

Rilis melewati tiga gerbang. Tidak boleh loncat.

| Gerbang | Nama | Kriteria lulus |
|---------|------|----------------|
| G0 | **Dev complete** | DoD §2.1–2.3 terpenuhi di lingkungan lokal; demo happy-path jalan end-to-end backend↔app. |
| G1 | **Staging verified** | Deploy ke Encore staging; DoD §2.4–2.5 terpenuhi; uji di device fisik (GPS, push, background). Uji jalur gagal, bukan hanya happy path. |
| G2 | **Production** | Monitoring & alert aktif; rollback teruji; data migrasi aman di DB berisi data nyata (bukan hanya DB kosong). |

---

## 4. Klasifikasi Kritikalitas (untuk memprioritaskan kekokohan)

| Kelas | Contoh fitur | Standar ekstra |
|-------|--------------|----------------|
| **Kritikal-nyawa** | Dispatch ambulans darurat, live GPS driver | Timeout ketat, fallback ganda, tidak boleh silent-fail; notifikasi darurat harus menembus mode senyap sesuai batas OS. |
| **Kritikal-uang/stok** | Pembayaran, potong saldo, stok rental | Transaksi DB atomik, idempotency key, audit trail wajib. |
| **Penting** | Order lifecycle, chat, auth | State machine tervalidasi backend; rate limiting. |
| **Standar** | Profil, katalog, notifikasi non-darurat | DoD dasar. |

---

## 5. Matriks Tech-Debt → Produksi

Utang teknis yang **sudah diketahui** dari `decisions.md` dan wiki. Semua ini harus
diselesaikan (atau diterima secara sadar dengan mitigasi) sebelum G2.

| # | Tech debt (sumber) | Risiko produksi | Aksi wajib sebelum G2 |
|---|--------------------|-----------------|-----------------------|
| TD-01 | Token opaque 64-char di tabel `sessions` (ADR-002) | Setiap request auth = 1 query DB; tidak ada refresh/rotasi | Tetap boleh untuk MVP, tapi tambah index + expiry cleanup job + rotasi saat login. Pertimbangkan JWT akses pendek + refresh untuk skala. Lihat doc 02 §3. |
| TD-02 | Foto profil Base64 di kolom `users.photo_url` (ADR-008) | Row membengkak, latensi query, tak bisa CDN | **Wajib migrasi ke object storage** (S3/GCS) sebelum produksi; simpan URL saja. Doc 06 §7. |
| TD-03 | Google OAuth simulasi — `googleId` diterima mentah (endpoints.md `/auth/google`) | Siapa pun bisa mengaku sebagai google_id mana pun | **Wajib verifikasi id_token Google di server** sebelum produksi. Doc 02 §4. |
| TD-04 | `/ambulance/book` hanya terima `userId`+`providerId`; GPS/harga/nama pasien tidak tersimpan (WIKI-02) | Data pesanan tidak lengkap; harga tak terekam | Perluas payload booking + kolom `bookings` sesuai SRS-06 §5.3. Doc 07 §4. |
| TD-05 | `userId` dikirim dari body request (banyak endpoint) | Klien bisa mengaku sebagai user lain | Ambil identitas dari token via auth handler, **abaikan `userId` dari body** untuk keputusan otorisasi. Doc 01 §5, doc 02 §5. |
| TD-06 | WebSocket ambulans hanya placeholder (roadmap "Cancelled/deferred") | Tidak ada tracking realtime | Implementasi realtime transport (WS atau SSE) sesuai doc 03. |
| TD-07 | Chat & Notifikasi belum ada backend (WIKI-05) | Fitur inti mitra↔pasien tidak berfungsi | Implementasi sesuai doc 04 & 05. |
| TD-08 | Data Flutter dummy in-memory (Mitra & sebagian App) | Bukan produk | Ganti dengan panggilan API + state yang benar. Doc 08. |
| TD-09 | Tidak ada CI/CD, test, atau monitoring (roadmap "Future") | Regresi tak terdeteksi, outage buta | Pipeline + test + logging/alert. Doc 09. |
| TD-10 | Nominatim/OSRM publik dipakai langsung dari client (ADR-009) | Rate limit ToS, tak ada SLA, kebocoran UA | Untuk produksi: proxy lewat backend / self-host / provider berbayar dengan caching. Doc 03 §6. |
| TD-11 | Password seed lemah (`admin123`, `password123`) di migrasi | Akun default bisa dibajak | Hapus/rotasi seed akun di environment produksi. Doc 02 §7. |

---

## 6. Anti-pattern yang dilarang di kode produksi

1. **Menghitung status/harga final di client sebagai kebenaran.** Client boleh
   menampilkan estimasi; backend yang menetapkan.
2. **Memercayai `userId`/`role` dari body request.** Identitas datang dari token.
3. **`console.log` sebagai logging produksi.** Gunakan logger terstruktur.
4. **Silent catch tanpa aksi.** Setiap catch harus menaikkan error, fallback
   terdefinisi, atau log — bukan menelan diam-diam kecuali memang by-design (mis.
   fetch saldo → 0) dan itu didokumentasikan.
5. **Perubahan skema tanpa migrasi.** Dilarang `ALTER TABLE` manual di DB.
6. **Menggabungkan UI patient & mitra dalam satu build tanpa scope peran.** Satu
   akun = satu peran (lihat SRS-07 mitra & doc 02 §6).

---

## 7. Cara memakai checklist ini

Salin blok DoD (§2) ke setiap PR fitur sebagai daftar centang. PR tidak di-merge ke
`main` jika ada kotak DoD relevan yang kosong tanpa penjelasan. Gerbang G1/G2
ditandai di roadmap masing-masing (`docs-new/context/roadmap.md`,
`docs/mitra/IMPLEMENTATION_STATUS.md`).
</content>
