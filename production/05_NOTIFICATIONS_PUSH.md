# 05 — Notifications & Push (FCM)

> Push notification untuk kedua app via Firebase Cloud Messaging, dengan DB sebagai
> sumber kebenaran. Basis: `docs-new/wiki/WIKI_05_Realtime_Chat_and_Notifications.md` (TD-07).

Kelas kritikalitas bervariasi: **darurat dispatch ambulans = Kritikal-nyawa**
(harus menembus mode senyap sebatas izin OS); notifikasi biasa = **Standar**.

---

## 1. Prinsip

1. **DB dulu, push kemudian.** Setiap notifikasi ditulis ke tabel `notifications`
   sebagai catatan, lalu dikirim sebagai push. In-app list membaca dari DB, bukan dari
   payload push (push bisa hilang).
2. **Push bersifat best-effort.** Jangan jadikan satu-satunya jalur untuk info penting;
   selalu ada REST list + realtime WS sebagai pelengkap.
3. **Kategori menentukan perilaku** (channel Android, prioritas, suara).

---

## 2. Model data

```sql
CREATE TABLE notifications (
  id          BIGSERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id),
  category    TEXT NOT NULL,          -- 'order_new' | 'order_update' | 'chat' | 'emergency' | 'system'
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  data        JSONB,                  -- deep-link: {bookingId, conversationId, ...}
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notif_user ON notifications(user_id, created_at DESC);

CREATE TABLE user_devices (
  id          BIGSERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id),
  fcm_token   TEXT NOT NULL UNIQUE,
  platform    TEXT NOT NULL,          -- 'android' | 'ios'
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE notification_preferences (
  user_id     INTEGER PRIMARY KEY REFERENCES users(id),
  order_updates BOOLEAN DEFAULT TRUE,
  chat          BOOLEAN DEFAULT TRUE,
  promotions    BOOLEAN DEFAULT TRUE
  -- 'emergency' TIDAK bisa dimatikan untuk mitra ambulans on-duty
);
```

---

## 3. Kategori & channel

| `category` | Untuk | Channel Android / prioritas | Suara |
|-----------|-------|-----------------------------|-------|
| `emergency` | Mitra ambulans: permintaan darurat | `emergency`, `IMPORTANCE_HIGH`, full-screen intent | ringtone keras, override senyap (sebatas izin OS) |
| `order_new` | Mitra: pesanan baru masuk | `orders`, high | default |
| `order_update` | Pasien: status pesanan berubah | `orders`, default | default |
| `chat` | Kedua: pesan baru | `chat`, default | default |
| `system` | Kedua: pengumuman | `system`, low | senyap |

**Darurat (Kritikal-nyawa):** channel Android khusus dengan suara custom + full-screen
intent, agar driver melihat permintaan walau layar terkunci. Ini yang membuat CAREGO
Mitra berguna sebagai alat kerja. Uji di device fisik (G1) — perilaku full-screen intent
& Doze mode tak bisa diverifikasi di emulator.

---

## 4. Backend — kirim notifikasi

```typescript
// dipanggil dari service lain (bookings, chat, dispatch)
export async function notify(userId: number, n: NotifPayload): Promise<void> {
  // 1) tulis ke DB (sumber kebenaran)
  await db.exec`
    INSERT INTO notifications (user_id, category, title, body, data)
    VALUES (${userId}, ${n.category}, ${n.title}, ${n.body}, ${JSON.stringify(n.data ?? {})})
  `;
  // 2) cek preferensi (emergency selalu lolos)
  if (n.category !== "emergency" && !(await prefAllows(userId, n.category))) return;
  // 3) ambil device token & kirim FCM
  const devices = await db.query`SELECT fcm_token, platform FROM user_devices WHERE user_id = ${userId}`;
  for await (const d of devices) {
    try {
      await fcm.send(buildMessage(d, n));   // firebase-admin
    } catch (e) {
      if (isUnregistered(e)) await db.exec`DELETE FROM user_devices WHERE fcm_token = ${d.fcm_token}`;
      else log.error("fcm_send_failed", { userId, err: String(e) });   // jangan silent
    }
  }
}
```

- **Token stale**: hapus token yang ditolak FCM (`messaging/registration-token-not-registered`).
- **firebase-admin** diinisialisasi dari service account via Encore secret (doc 02 §7).
- **Data message vs notification message**: gunakan data payload agar app mengontrol
  tampilan (terutama untuk `emergency` full-screen), sertakan `data.bookingId` /
  `data.conversationId` untuk deep-link.

### Endpoint terkait
| Method + Path | Guna |
|---------------|------|
| `POST /notifications/devices` | daftarkan/refresh FCM token (auth) |
| `DELETE /notifications/devices/:token` | hapus saat logout |
| `GET /notifications?limit=&offset=` | list in-app (dari DB) |
| `POST /notifications/read-all` | tandai semua terbaca |
| `POST /notifications/:id/read` | tandai satu terbaca |
| `PUT /notifications/preferences` | ubah preferensi |

---

## 5. Client Flutter (kedua app)

```dart
// setelah login: daftarkan token
final token = await FirebaseMessaging.instance.getToken();
await api.post('/notifications/devices', {'fcmToken': token, 'platform': _platform()});
FirebaseMessaging.instance.onTokenRefresh.listen((t) =>
    api.post('/notifications/devices', {'fcmToken': t, 'platform': _platform()}));

// foreground: tampilkan lokal + refresh badge dari DB
FirebaseMessaging.onMessage.listen((m) => _showLocal(m));
// tap notifikasi: deep-link
FirebaseMessaging.onMessageOpenedApp.listen((m) => _routeFromData(m.data));
```

- **Minta izin notifikasi** saat onboarding (iOS wajib; Android 13+ wajib
  `POST_NOTIFICATIONS`).
- **Hapus token saat logout** (`DELETE /notifications/devices/:token`) agar device tak
  menerima notifikasi user berikutnya.
- **Badge & list** selalu di-refresh dari `GET /notifications`, bukan dari akumulasi
  push (push bisa terlewat saat app mati).
- **Emergency channel** (mitra ambulans): buat `AndroidNotificationChannel` prioritas
  max dengan `sound` custom saat init; tangani `onBackgroundMessage`.

---

## 6. Kapan mengirim apa (integrasi lintas fitur)

| Peristiwa | Penerima | Category |
|-----------|----------|----------|
| Pasien buat booking → cocok mitra | Mitra terkait | `order_new` (ambulans darurat → `emergency`) |
| Mitra terima/tolak/ubah status | Pasien pemilik | `order_update` |
| Pesan chat baru & penerima offline | Lawan bicara | `chat` |
| Driver tiba / perjalanan selesai | Pasien | `order_update` |
| Verifikasi akun mitra oleh admin | Mitra | `system` |

Semua pemicu ini memanggil `notify()` — satu fungsi, satu perilaku konsisten di kedua app.

---

## 7. Checklist notifikasi (tempel di PR)

- [ ] Tulis ke `notifications` DB sebelum push (sumber kebenaran).
- [ ] Token disimpan/di-refresh; token stale dihapus; token dihapus saat logout.
- [ ] Preferensi dihormati; `emergency` tak bisa dimatikan untuk mitra on-duty.
- [ ] Channel `emergency` full-screen + suara keras diuji di device fisik (G1).
- [ ] Data payload berisi deep-link (`bookingId`/`conversationId`).
- [ ] In-app list & badge dari DB, bukan akumulasi push.
- [ ] firebase-admin credential via Encore secret; kegagalan FCM di-log (tanpa silent).
- [ ] Izin notifikasi diminta (iOS + Android 13+).
</content>
