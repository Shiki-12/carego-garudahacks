# 03 — Realtime GPS Tracking

> Live location driver ambulans, dari device Mitra → backend → CAREGO App pasien.
> Kelas kritikalitas: **Kritikal-nyawa** (doc 00 §4). Fallback tak boleh silent.

Basis: `docs-new/wiki/WIKI_02_Ambulance_Dispatch_System.md` (geolocator, Nominatim,
OSRM, MapPickerScreen), `docs/mitra/api/endpoints.md` (`PUT /mitra/ambulances/:id/location`).
WebSocket ambulans prototipe hanya placeholder (TD-06). Dokumen ini menetapkan
implementasi realtime yang benar.

---

## 1. Gambaran alur

```
Driver (CAREGO Mitra)          Backend (Encore)            Pasien (CAREGO App)
─────────────────────          ────────────────            ───────────────────
geolocator stream  ──PUT──►  simpan last_lat/long,     
(saat status                  simpan ke fleet + broadcast
 in_progress)                 ke channel booking:{id}  ──WS/SSE──►  peta bergerak
                              (throttle server-side)               + ETA
```

Tiga tanggung jawab terpisah:
1. **Ingest** — driver mengirim posisi (§3).
2. **Fan-out** — backend menyebarkan ke pasien yang berhak (§4).
3. **Konsumsi** — pasien menampilkan marker bergerak + ETA (§5).

---

## 2. Kapan tracking aktif (privasi + baterai)

- Live location **hanya** menyala saat driver punya order berstatus
  `accepted → on_the_way → in_progress`. Di luar itu: **mati** (jangan lacak driver 24/7).
- Saat order `completed`/`cancelled`: hentikan stream, hapus channel, backend berhenti
  menyimpan posisi baru.
- Pasien hanya bisa melihat lokasi driver untuk **booking miliknya** yang sedang aktif
  (otorisasi objek — doc 02 §6).
- Cantumkan consent lokasi di UI mitra ("Lokasi Anda dibagikan ke pasien selama
  perjalanan").

---

## 3. Ingest — driver mengirim posisi

### 3.1 Client Flutter (Mitra, DriverShell)
```dart
StreamSubscription<Position>? _posSub;

void _startTracking(int bookingId) {
  _posSub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // meter — kirim hanya jika bergerak ≥20 m
    ),
  ).listen((pos) {
    _sendLocation(bookingId, pos.latitude, pos.longitude, pos.heading, pos.speed);
  });
}

void _stopTracking() { _posSub?.cancel(); _posSub = null; }
```

- **Background location** (PRD Mitra): butuh izin `locationAlways` + foreground service
  (Android) / background modes (iOS). Tampilkan notifikasi persisten "CAREGO Mitra
  melacak perjalanan". Uji di device fisik (bukan emulator) — G1.
- **Throttle client**: `distanceFilter` + minimal interval (mis. maksimum 1 kirim / 3 dtk)
  agar hemat baterai & kuota.
- **Buffer offline**: bila jaringan putus, simpan titik terakhir; kirim titik terbaru
  saat pulih (jangan banjiri backlog — cukup posisi terkini).

### 3.2 Endpoint ingest
```typescript
// PUT /mitra/fleets/:fleetId/location   (scope: provider:ambulance)
export const updateFleetLocation = api(
  { expose: true, auth: true, method: "PUT", path: "/mitra/fleets/:fleetId/location" },
  async ({ fleetId, lat, lng, heading, speed, bookingId }: LocationUpdate) => {
    const { providerId } = getAuthData()!;
    // otorisasi: fleet milik provider ini
    const fleet = await db.queryRow`
      SELECT id FROM provider_fleets WHERE id = ${fleetId} AND provider_id = ${providerId}
    `;
    if (!fleet) throw APIError.permissionDenied("Armada bukan milik Anda");

    await db.exec`
      UPDATE provider_fleets
      SET last_lat = ${lat}, last_long = ${lng}, last_heading = ${heading},
          last_location_at = NOW()
      WHERE id = ${fleetId}
    `;
    // fan-out ke pasien pemilik booking
    if (bookingId) await publishLocation(bookingId, { lat, lng, heading, speed });
    return ok({ received: true });
  }
);
```

- Simpan **posisi terkini saja** di `provider_fleets` (bukan histori penuh tiap tik).
  Jika butuh jejak perjalanan untuk audit, tulis ke tabel `trip_locations` dengan
  sampling lebih jarang (mis. tiap 30 dtk), bukan setiap update.

---

## 4. Fan-out — backend → pasien

Encore.ts mendukung **streaming/WebSocket API**. Gunakan channel per-booking.

### 4.1 Endpoint stream (pasien subscribe)
```typescript
// GET /realtime/track/:bookingId  (WebSocket, auth via ticket — lihat §4.3)
export const trackBooking = api.streamOut<TrackHandshake, LocationEvent>(
  { expose: true, auth: true, path: "/realtime/track/:bookingId" },
  async ({ bookingId }, stream) => {
    const { userID } = getAuthData()!;
    const booking = await db.queryRow`
      SELECT user_id, status FROM bookings WHERE id = ${bookingId}
    `;
    if (!booking || String(booking.user_id) !== userID)
      throw APIError.permissionDenied("Akses ditolak");
    if (booking.status === "completed" || booking.status === "cancelled") {
      await stream.close(); return;
    }
    // daftarkan stream ke registry channel booking:{id}
    subscribe(bookingId, stream);
  }
);
```

### 4.2 Registry & publish (in-memory + fallback)
```typescript
const channels = new Map<number, Set<Stream<LocationEvent>>>();
function subscribe(bookingId: number, s: Stream<LocationEvent>) {
  (channels.get(bookingId) ?? channels.set(bookingId, new Set()).get(bookingId)!).add(s);
}
async function publishLocation(bookingId: number, ev: LocationEvent) {
  const subs = channels.get(bookingId);
  if (!subs) return;
  for (const s of subs) { try { await s.send(ev); } catch { subs.delete(s); } }
}
```

> **Catatan skala:** `Map` in-memory hanya benar untuk **satu instance**. Untuk >1
> instance backend, ganti registry dengan **Redis Pub/Sub** (atau Encore Pub/Sub topic)
> agar update dari instance A sampai ke subscriber di instance B. Tandai ini sebelum G2
> jika deploy multi-instance.

### 4.3 Auth pada WebSocket
Header `Authorization` sering tak bisa diset di klien WS. Pola aman:
1. Client `POST /realtime/ticket` (auth Bearer normal) → dapat **ticket sekali-pakai**,
   TTL 60 dtk, terikat ke `userID`.
2. Client buka WS `?ticket=...`. Backend menukar ticket → identitas, lalu hapus ticket.
Jangan pernah menaruh token sesi utama di query string (bisa masuk log).

### 4.4 Throttle & heartbeat
- Backend meneruskan maksimum ~1 update/2 dtk per channel (koalescing titik terbaru).
- Kirim ping/heartbeat tiap 30 dtk; jika gagal, tutup & biarkan client reconnect.

---

## 5. Konsumsi — peta pasien

- `flutter_map` + tile OpenStreetMap; marker ambulans di-animate antar titik
  (interpolasi) agar mulus, bukan meloncat.
- Tampilkan ETA: hitung ulang jarak sisa via OSRM saat titik baru (throttle), atau
  Haversine ×1.3 sebagai fallback (WIKI-02).
- **Reconnect**: bila WS putus, coba sambung ulang tiap 3 dtk; tampilkan state "Mencari
  sinyal…" — **jangan** diam seolah masih live (kelas kritikal-nyawa).
- Bila tidak ada update > N dtk, tandai posisi "usang" di UI, bukan pura-pura terkini.

---

## 6. Geocoding & routing untuk produksi (TD-10)

Prototipe memakai Nominatim & OSRM publik langsung dari client (ADR-009). Untuk produksi:

- **Proxy lewat backend**, jangan panggil dari client langsung:
  - Kontrol `User-Agent` sesuai ToS Nominatim (wajib), sembunyikan dari device.
  - **Cache** hasil reverse/forward geocoding & rute (kunci: koordinat dibulatkan).
  - Terapkan rate limit sisi backend agar tak melanggar ToS layanan publik.
- Pertimbangkan self-host OSRM/Nominatim atau provider berbayar (Mapbox/Google) dengan
  SLA untuk jalur kritikal-nyawa.
- Format koordinat OSRM tetap **`lng,lat`** (mudah tertukar — sumber bug WIKI-02).
- Fallback jarak: Haversine × 1.3 bila OSRM gagal; **log** kejadian fallback (jangan
  telan diam).

```typescript
// GET /geo/route?fromLat=&fromLng=&toLat=&toLng=  (backend proxy + cache)
// GET /geo/reverse?lat=&lng=
// GET /geo/search?q=            (forward, countrycodes=id)
```

Pricing ambulans tetap dihitung **di backend** (doc 07): ALS 150k/15k-per-km,
BLS 100k/10k, Jenazah 200k/12k; `total = baseFare + pricePerKm × ceil(distanceKm)`.
Client hanya menampilkan estimasi.

---

## 7. Skema pendukung

```sql
-- kolom pada provider_fleets (armada)
ALTER TABLE provider_fleets
  ADD COLUMN last_lat DOUBLE PRECISION,
  ADD COLUMN last_long DOUBLE PRECISION,
  ADD COLUMN last_heading DOUBLE PRECISION,
  ADD COLUMN last_location_at TIMESTAMPTZ;

-- opsional: jejak perjalanan untuk audit (sampling jarang)
CREATE TABLE trip_locations (
  id BIGSERIAL PRIMARY KEY,
  booking_id INTEGER NOT NULL REFERENCES bookings(id),
  fleet_id INTEGER NOT NULL REFERENCES provider_fleets(id),
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_trip_locations_booking ON trip_locations(booking_id, recorded_at);
```

---

## 8. Checklist GPS (tempel di PR)

- [ ] Tracking hanya aktif saat order `accepted/on_the_way/in_progress`; mati setelah selesai.
- [ ] Izin `locationAlways` + foreground service; diuji di device fisik (G1).
- [ ] Throttle client (`distanceFilter` + interval) & throttle server (koalescing).
- [ ] Otorisasi: driver hanya update fleet miliknya; pasien hanya track booking miliknya.
- [ ] WS auth via ticket sekali-pakai; token utama tidak di query string.
- [ ] Reconnect + state "sinyal hilang"/"posisi usang" (tanpa silent-fail — kritikal-nyawa).
- [ ] Geocoding/routing di-proxy backend + cache + rate limit (TD-10).
- [ ] Harga & ETA final dihitung backend; fallback Haversine di-log.
- [ ] Registry siap multi-instance (Redis/Pub-Sub) bila deploy > 1 instance.
</content>
