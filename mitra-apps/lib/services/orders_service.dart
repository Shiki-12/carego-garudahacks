import '../core/api_service.dart';
import '../models/mitra_order.dart';

/// Akses pesanan mitra (doc 07 §5-6, endpoint doc 01 §4).
///
/// Semua panggilan lewat [ApiService] (envelope, auth Bearer, timeout, error
/// Indonesia). Status & harga ditetapkan backend — service ini tidak menghitung
/// apa pun sendiri (doc 00 §6).
class OrdersService {
  final ApiService api;

  const OrdersService(this.api);

  /// GET /mitra/orders — daftar pesanan untuk provider ini (difilter server
  /// berdasarkan identitas token, doc 07 §2). Grup tab via [statusGroup]:
  /// 'waiting' | 'active' | 'history'. Terbungkus paginasi (doc 01 §7).
  Future<Paginated<MitraOrder>> list({
    String? statusGroup,
    int limit = 20,
    int offset = 0,
  }) {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (statusGroup != null) 'status': statusGroup,
    };
    final qs = query.entries.map((e) => '${e.key}=${e.value}').join('&');
    return api.get<Paginated<MitraOrder>>(
      '/mitra/orders?$qs',
      parse: (data) => Paginated.fromJson(data, MitraOrder.fromJson),
    );
  }

  /// POST /mitra/orders/:id/accept (doc 07 §5).
  ///
  /// Race broadcast: mitra pertama menang; yang lain menerima 409
  /// (`INVALID_STATUS`/`CONFLICT`) → tampilkan "pesanan sudah diambil".
  /// Idempotency-Key mencegah double-tap memproses ganda (doc 01 §8).
  Future<MitraOrder> accept(int id, {required String idempotencyKey}) {
    return api.post<MitraOrder>(
      '/mitra/orders/$id/accept',
      headers: {'Idempotency-Key': idempotencyKey},
      parse: (data) => MitraOrder.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// POST /mitra/orders/:id/reject (doc 07 §5).
  Future<void> reject(int id, {String? reason}) {
    return api.post<void>(
      '/mitra/orders/$id/reject',
      body: {if (reason != null) 'reason': reason},
      parse: (_) {},
    );
  }

  /// PUT /mitra/orders/:id/status — transisi berjalan (doc 07 §6).
  /// Backend menegakkan transisi legal (assertTransition, doc 01 §6).
  Future<MitraOrder> updateStatus(int id, OrderStatus status) {
    return api.put<MitraOrder>(
      '/mitra/orders/$id/status',
      body: {'status': status.wire},
      parse: (data) => MitraOrder.fromJson((data as Map).cast<String, dynamic>()),
    );
  }
}
