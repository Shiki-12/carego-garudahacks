# 08 — Flutter Client Standard

> Standar klien Flutter yang **dipakai kedua aplikasi** (CAREGO App & CAREGO Mitra),
> sehingga pemanggilan API, penanganan error, dan state konsisten.

Basis konvensi: `docs-new/development/coding-style.md`. UI copy Indonesia, identifier
kode Inggris. Mitra memakai tema Teal (`0xFF0D9488`); struktur di bawah tema-agnostik.

---

## 1. Prinsip

1. **Client tidak pernah jadi sumber kebenaran** untuk status/harga/otorisasi
   (doc 00 §6). UI menampilkan; backend menetapkan.
2. **Semua data dari API**, bukan dummy in-memory (TD-08). Setiap layar data punya
   loading/empty/error state.
3. **Satu lapisan `ApiService`** membungkus envelope, auth, error, retry — dipakai
   seragam kedua app.

---

## 2. Lapisan `ApiService` (envelope + auth + error)

Membungkus kontrak doc 01 (envelope `ok/data`/`ok/error`, `Authorization: Bearer`).

```dart
class ApiService {
  final String baseUrl;            // dari env (§3)
  final TokenStore tokens;

  Future<T> _request<T>(String method, String path,
      {Map<String, dynamic>? body, T Function(dynamic)? parse}) async {
    final token = await tokens.read();
    final res = await http.Request(method, Uri.parse('$baseUrl$path'))
        .let((r) {
          r.headers['Content-Type'] = 'application/json';
          if (token != null) r.headers['Authorization'] = 'Bearer $token';
          if (body != null) r.body = jsonEncode(body);
          return r;
        })
        .send()
        .timeout(const Duration(seconds: 15));           // timeout wajib

    final text = await res.stream.bytesToString();
    final json = jsonDecode(text);

    if (json['ok'] == true) {
      final data = json['data'];
      return parse != null ? parse(data) : data as T;
    }
    // envelope error → ApiException dengan code + pesan Indonesia siap tampil
    final err = json['error'] ?? {};
    throw ApiException(err['code'] ?? 'UNKNOWN', err['message'] ?? 'Terjadi kesalahan',
        httpStatus: res.statusCode);
  }

  Future<T> get<T>(String p, {T Function(dynamic)? parse}) => _request('GET', p, parse: parse);
  Future<T> post<T>(String p, Map<String, dynamic> b, {T Function(dynamic)? parse}) =>
      _request('POST', p, body: b, parse: parse);
  // put/delete serupa
}

class ApiException implements Exception {
  final String code;      // logika client (mis. 'INVALID_STATUS')
  final String message;   // teks Indonesia siap tampil
  final int? httpStatus;
  ApiException(this.code, this.message, {this.httpStatus});
}
```

- **Timeout** di setiap request (default 15 dtk; ketat untuk kritikal-nyawa).
- Parser abaikan field tak dikenal (forward-compatible — doc 01 §11).
- 401 (`UNAUTHENTICATED`) → hapus token, arahkan ke login.

---

## 3. Konfigurasi environment (bukan hardcode)

```dart
// dijalankan dengan: flutter run --dart-define=API_BASE=https://staging.carego...
class Env {
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:4000');
  static const wsBase  = String.fromEnvironment('WS_BASE',  defaultValue: 'ws://localhost:4000');
}
```

- Tiga environment: `local` (localhost:4000, doc 09), `staging`, `production`.
- Tidak ada URL/secret hardcoded di kode (coding-style General Rules; doc 02 §7).

---

## 4. Penyimpanan aman (token & sesi)

- Token sesi & FCM token di **`flutter_secure_storage`** (Keychain/Keystore),
  **bukan** `SharedPreferences` biasa (doc 02 §3.2).

```dart
class TokenStore {
  final _s = const FlutterSecureStorage();
  Future<void> write(String t) => _s.write(key: 'session_token', value: t);
  Future<String?> read() => _s.read(key: 'session_token');
  Future<void> clear() => _s.delete(key: 'session_token');   // saat logout
}
```

---

## 5. State per layar (loading/empty/error)

Setiap layar yang memuat data **wajib** menangani empat kondisi (doc 00 §2.5). Pola
`setState` prototipe (ADR-005) boleh dipertahankan; yang wajib adalah kelengkapan state.

```dart
enum ViewState { loading, data, empty, error }

// build:
switch (_state) {
  ViewState.loading => const Center(child: CircularProgressIndicator()),
  ViewState.error   => ErrorView(message: _errMsg, onRetry: _load),   // pesan Indonesia + retry
  ViewState.empty   => const EmptyView(text: 'Belum ada data'),
  ViewState.data    => _buildList(),
};
```

- **Error** selalu punya tombol "Coba lagi" dan pesan Indonesia (dari `ApiException.message`).
- **Jangan** menampilkan spinner selamanya bila request gagal (silent-fail terlarang).

---

## 6. Realtime (WS) di client

- Pola koneksi seragam untuk chat (doc 04 §5) dan GPS (doc 03 §5): ambil ticket →
  connect WS → listen → reconnect 3 dtk saat putus → tarik state terlewat via REST.
- Tampilkan indikator koneksi ("Menyambungkan ulang…") — jangan diam seolah live.

```dart
void _scheduleReconnect() {
  if (_disposed) return;
  Future.delayed(const Duration(seconds: 3), _connect);
}
```

---

## 7. Retry & idempotency

- **Retry** hanya untuk operasi **idempoten** atau yang dilindungi Idempotency-Key
  (doc 01 §8). Untuk `POST /bookings` dan kirim pesan: sertakan `clientMsgId`/
  `Idempotency-Key` agar retry aman.
- Backoff sederhana untuk error jaringan sementara; jangan retry membabi-buta pada 4xx.

---

## 8. Konsistensi UI (WAJIB — batasan proyek)

- **Salin design system yang ada**; dilarang membuat komponen/gaya yang tak konsisten.
- Mitra: tema Teal (`kPrimaryDarkColor 0xff0D9488`, `kPrimarylightColor 0xff2DD4BF`,
  `kBackgroundColor 0xffF0FDF4`), font & kartu rounded sesuai template
  (`IMPLEMENTATION_STATUS.md`).
- **Role-lock (SRS-07):** satu akun = satu peran. Setelah auth, resolve shell sesuai
  `provider_type` (Driver/Rental/Caregiver) — jangan gabung UI patient & mitra tanpa
  scope peran (doc 00 §6, doc 02 §1).

---

## 9. Struktur folder (referensi)

```
lib/
├── core/
│   ├── env.dart              # Env.apiBase / wsBase
│   ├── api_service.dart      # ApiService + ApiException
│   ├── token_store.dart      # secure storage
│   └── ws_client.dart        # koneksi WS + reconnect
├── models/                   # DTO (fromJson yang forward-compatible)
├── services/                 # ChatService, LocationService, NotificationService
├── presentation/             # layar (shell per peran untuk Mitra)
└── constants.dart / size_confige.dart
```

---

## 10. Checklist client (tempel di PR Flutter)

- [ ] Semua data dari API; tidak ada dummy in-memory di jalur produksi (TD-08).
- [ ] Semua panggilan lewat `ApiService` (envelope, auth Bearer, timeout, error Indonesia).
- [ ] Base URL dari `--dart-define`, bukan hardcode; tanpa secret di kode.
- [ ] Token di `flutter_secure_storage`; dihapus saat logout.
- [ ] Setiap layar data: loading/empty/error + tombol coba lagi.
- [ ] WS: ticket + reconnect + tarik state terlewat; indikator koneksi.
- [ ] Retry hanya untuk operasi idempoten/ber-Idempotency-Key.
- [ ] UI konsisten dengan design system; role-lock dipatuhi.
- [ ] `flutter analyze` bersih.
</content>
