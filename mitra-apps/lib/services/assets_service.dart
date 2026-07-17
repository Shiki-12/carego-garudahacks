import '../core/api_service.dart';
import '../models/mitra_asset.dart';
import '../models/mitra_order.dart' show Paginated;

/// CRUD aset mitra (SRS-03/04/05) lewat endpoint per [AssetKind]:
/// `/mitra/caregivers`, `/mitra/ambulances`, `/mitra/rental/items`.
///
/// Semua panggilan lewat [ApiService] (envelope, Bearer, timeout, error
/// Indonesia). Menggantikan data dummy in-memory ManagementPage (TD-08).
class AssetsService {
  final ApiService api;

  const AssetsService(this.api);

  /// GET koleksi. Server memfilter berdasarkan identitas token (mitra ini).
  /// Toleran dua bentuk balasan: terbungkus paginasi `{items,...}` atau list
  /// polos `[...]` (doc 01 §7 vs backend awal).
  Future<List<MitraAsset>> list(AssetKind kind,
      {int limit = 50, int offset = 0}) {
    return api.get<List<MitraAsset>>(
      '${kind.path}?limit=$limit&offset=$offset',
      parse: (data) {
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => MitraAsset.fromJson(e.cast<String, dynamic>()))
              .toList();
        }
        return Paginated.fromJson(data, MitraAsset.fromJson).items;
      },
    );
  }

  /// POST — tambah aset baru (agency). Body diserahkan pemanggil agar tiap
  /// jenis mengirim field spesifiknya (doc endpoints.md).
  Future<MitraAsset> create(AssetKind kind, Map<String, dynamic> body) {
    return api.post<MitraAsset>(
      kind.path,
      body: body,
      parse: (data) => MitraAsset.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// PUT — ubah aset (mis. toggle ketersediaan). Path `${kind.path}/:id`.
  Future<MitraAsset> update(AssetKind kind, int id, Map<String, dynamic> body) {
    return api.put<MitraAsset>(
      '${kind.path}/$id',
      body: body,
      parse: (data) => MitraAsset.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// Toggle ketersediaan satu aset (dipakai Switch pada kartu).
  Future<MitraAsset> setAvailable(AssetKind kind, int id, bool value) {
    return update(kind, id, {'is_available': value});
  }

  /// DELETE — hapus aset.
  Future<void> remove(AssetKind kind, int id) {
    return api.delete<void>('${kind.path}/$id', parse: (_) {});
  }
}
