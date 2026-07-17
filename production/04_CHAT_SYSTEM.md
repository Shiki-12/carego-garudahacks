# 04 — Chat System

> Pesan realtime antara pasien (CAREGO App) dan mitra (CAREGO Mitra) lewat backend yang sama.
> Kelas kritikalitas: **Penting**. Basis: `docs-new/wiki/WIKI_05_Realtime_Chat_and_Notifications.md`.

Prototipe: UI chat sudah ada (ChatListPage, ChatPage/ChatRoomScreen), tetapi
**belum ada backend** (TD-07). Dokumen ini menetapkan model dan transport produksi.

---

## 1. Prinsip

1. **DB adalah sumber kebenaran**, WebSocket hanya transport cepat. Pesan disimpan
   dulu, lalu di-broadcast. Client offline mengambil via REST saat buka.
2. **Satu percakapan terikat konteks**: umumnya per-booking (pasien ↔ mitra untuk
   pesanan tertentu), sehingga otorisasi jelas.
3. **Optimistic UI** di client, tapi status akhir (`sent/delivered/read`) dari server.

---

## 2. Model data

```sql
CREATE TABLE conversations (
  id           BIGSERIAL PRIMARY KEY,
  booking_id   INTEGER REFERENCES bookings(id),   -- konteks (nullable utk chat umum)
  patient_id   INTEGER NOT NULL REFERENCES users(id),
  provider_id  INTEGER NOT NULL REFERENCES providers(id),
  last_message_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (booking_id, patient_id, provider_id)
);

CREATE TABLE messages (
  id              BIGSERIAL PRIMARY KEY,
  conversation_id BIGINT NOT NULL REFERENCES conversations(id),
  sender_id       INTEGER NOT NULL REFERENCES users(id),
  type            TEXT NOT NULL DEFAULT 'text',   -- 'text' | 'image' | 'system'
  body            TEXT,                            -- teks; utk image: caption
  image_url       TEXT,                            -- object storage, BUKAN Base64 (TD-02)
  status          TEXT NOT NULL DEFAULT 'sent',    -- 'sent' | 'delivered' | 'read'
  client_msg_id   TEXT,                            -- idempotency dari client
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at);
CREATE INDEX idx_conv_patient ON conversations(patient_id, last_message_at DESC);
CREATE INDEX idx_conv_provider ON conversations(provider_id, last_message_at DESC);
```

Peserta percakapan hanya dua: `patient_id` dan `provider_id`. Otorisasi = pengirim/
pembaca harus salah satu dari keduanya (doc 02 §6).

---

## 3. REST (sumber kebenaran)

| Method + Path | Guna |
|---------------|------|
| `GET /chat/conversations?limit=&offset=` | daftar percakapan user (patient atau provider) |
| `GET /chat/conversations/:id/messages?before=&limit=` | riwayat pesan (paginasi ke belakang) |
| `POST /chat/conversations/:id/messages` | kirim pesan (idempoten via `clientMsgId`) |
| `POST /chat/conversations/:id/read` | tandai terbaca s/d pesan terakhir |
| `POST /chat/conversations` | mulai percakapan (biasanya otomatis saat order dibuat) |

```typescript
// POST /chat/conversations/:id/messages
export const sendMessage = api(
  { expose: true, auth: true, method: "POST", path: "/chat/conversations/:id/messages" },
  async ({ id, type, body, imageUrl, clientMsgId }: SendMessageReq) => {
    const { userID } = getAuthData()!;
    const conv = await db.queryRow`
      SELECT patient_id, provider_id FROM conversations WHERE id = ${id}
    `;
    if (!conv) throw APIError.notFound("Percakapan tidak ditemukan");
    await assertParticipant(userID, conv);            // otorisasi

    // idempotency: kalau clientMsgId sudah ada, kembalikan pesan lama
    if (clientMsgId) {
      const dup = await db.queryRow`
        SELECT * FROM messages WHERE conversation_id = ${id} AND client_msg_id = ${clientMsgId}
      `;
      if (dup) return ok(toDto(dup));
    }
    const msg = await db.queryRow`
      INSERT INTO messages (conversation_id, sender_id, type, body, image_url, client_msg_id)
      VALUES (${id}, ${userID}, ${type}, ${body}, ${imageUrl}, ${clientMsgId})
      RETURNING *
    `;
    await db.exec`UPDATE conversations SET last_message_at = NOW() WHERE id = ${id}`;
    await fanoutMessage(conv, msg);        // WS ke lawan bicara (§4)
    await queuePush(conv, msg);            // FCM bila offline (doc 05)
    return ok(toDto(msg));
  }
);
```

- **Gambar**: client upload ke object storage lewat presigned URL (doc 06 §7), lalu
  kirim `imageUrl`. **Jangan** Base64 di body (TD-02, doc 01 §10).

---

## 4. WebSocket (transport cepat)

```typescript
// WS /chat/ws   (auth via ticket sekali-pakai — doc 03 §4.3)
export const chatStream = api.streamInOut<ChatHandshake, ClientEvent, ServerEvent>(
  { expose: true, auth: true, path: "/chat/ws" },
  async (handshake, stream) => {
    const { userID } = getAuthData()!;
    registerUserStream(userID, stream);          // registry per-user
    for await (const ev of stream) {
      if (ev.kind === "typing") relayTyping(userID, ev);
      // pengiriman pesan tetap lewat REST agar tersimpan; WS untuk notify+typing+receipt
    }
  }
);
```

- **Registry per-user** memetakan `userID → stream`. Saat `fanoutMessage`, kirim ke
  stream lawan bicara bila online.
- Sama seperti GPS (doc 03 §4.2): registry `Map` in-memory hanya benar untuk satu
  instance; pakai Redis/Pub-Sub untuk multi-instance.
- **Read receipt**: saat penerima memanggil `/read`, broadcast event `read` ke pengirim
  → UI menampilkan "dibaca" (analog `done_all`).
- **Reconnect**: client sambung ulang tiap 3 dtk; setelah connect, tarik pesan yang
  terlewat via `GET .../messages?before=` (jangan andalkan hanya WS).

---

## 5. Client Flutter (kedua app, pola sama)

```dart
class ChatService {
  WebSocketChannel? _ch;
  final _controller = StreamController<ChatEvent>.broadcast();

  Future<void> connect() async {
    final ticket = await api.post('/realtime/ticket');          // doc 03 §4.3
    _ch = WebSocketChannel.connect(Uri.parse('$wsBase/chat/ws?ticket=${ticket.value}'));
    _ch!.stream.listen(_onEvent, onDone: _scheduleReconnect, onError: (_) => _scheduleReconnect());
  }

  Future<void> send(int convId, String text) async {
    final clientMsgId = _uuid();          // idempotency
    _appendOptimistic(convId, text, clientMsgId);               // optimistic UI
    try {
      final saved = await api.post('/chat/conversations/$convId/messages',
          {'type': 'text', 'body': text, 'clientMsgId': clientMsgId});
      _reconcile(clientMsgId, saved);                           // ganti dgn versi server
    } catch (_) {
      _markFailed(clientMsgId);                                 // tampilkan retry, bukan hilang
    }
  }

  void _scheduleReconnect() => Future.delayed(const Duration(seconds: 3), connect);
}
```

- **Optimistic**: tampilkan segera dengan status "mengirim"; ganti dengan versi server
  saat sukses; tandai gagal + tombol coba lagi bila error (jangan hilang diam-diam).
- **Offline queue**: pesan yang gagal disimpan lokal, dikirim ulang saat online.
- UI copy Indonesia ("Mengirim…", "Gagal — ketuk untuk kirim ulang", "Dibaca").

---

## 6. Otorisasi & privasi

- Hanya `patient_id` & `provider_id` percakapan yang boleh baca/kirim.
- Mitra tidak bisa melihat percakapan mitra lain; pasien tidak bisa melihat percakapan
  pasien lain.
- Konten pesan tidak dipakai untuk keputusan otorisasi/harga.
- Simpan minimal PII; jangan log isi pesan.

---

## 7. Integrasi dengan order & notifikasi

- Saat pasien membuat booking dan mitra menerima, backend **auto-create** percakapan
  ber-`booking_id` sehingga tombol "Chat" di kedua app langsung berfungsi.
- Setiap pesan baru → jika penerima offline (tidak ada stream aktif), kirim **push FCM**
  (doc 05). Jika online, cukup lewat WS.
- Saat order `completed`/`cancelled`, percakapan boleh di-arsip (read-only) sesuai
  kebijakan; jangan hapus histori yang mungkin dibutuhkan untuk sengketa.

---

## 8. Checklist chat (tempel di PR)

- [ ] Pesan disimpan ke DB dulu, baru broadcast (DB = sumber kebenaran).
- [ ] Otorisasi peserta pada setiap kirim/baca.
- [ ] Idempotency via `clientMsgId` (double-send aman).
- [ ] Gambar lewat object storage/presigned URL, bukan Base64 (TD-02).
- [ ] WS auth via ticket; reconnect 3 dtk + tarik pesan terlewat via REST.
- [ ] Optimistic UI dengan status kirim/gagal/dibaca; offline queue.
- [ ] Push FCM saat penerima offline (doc 05).
- [ ] Registry siap multi-instance (Redis/Pub-Sub) bila > 1 instance.
</content>
