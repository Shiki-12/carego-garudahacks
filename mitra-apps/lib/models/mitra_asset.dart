/// Jenis aset mitra yang dikelola (SRS-03/04/05). Menentukan endpoint & label.
enum AssetKind {
  caregiver('/mitra/caregivers', 'Personil', 'Personil'),
  ambulance('/mitra/ambulances', 'Armada/Alat', 'Armada'),
  rentalItem('/mitra/rental/items', 'Katalog Rental', 'Item');

  /// Basis path koleksi (doc endpoints.md §Specific Services).
  final String path;

  /// Judul layar ManagementPage yang memetakan ke jenis ini.
  final String title;

  /// Kata benda tunggal untuk copy ("Tambah $noun").
  final String noun;

  const AssetKind(this.path, this.title, this.noun);

  /// Resolusi dari judul ManagementPage (dipertahankan agar shell lama tetap
  /// memakai string title yang sama).
  static AssetKind fromTitle(String title) {
    switch (title) {
      case 'Armada/Alat':
        return AssetKind.ambulance;
      case 'Katalog Rental':
        return AssetKind.rentalItem;
      case 'Personil':
      default:
        return AssetKind.caregiver;
    }
  }
}

/// Aset generik mitra (personil / armada / item rental).
///
/// Sumber kebenaran: backend. Parsing forward-compatible (doc 01 §11):
/// field tak dikenal diabaikan, tipe toleran, tanpa crash. `detail` dirakit
/// dari beberapa kemungkinan field agar satu kartu generik cukup untuk ketiga
/// jenis tanpa mengunci skema backend.
class MitraAsset {
  final int id;
  final String name;
  final String detail;
  final bool available;

  const MitraAsset({
    required this.id,
    required this.name,
    required this.detail,
    required this.available,
  });

  factory MitraAsset.fromJson(Map<String, dynamic> json) {
    return MitraAsset(
      id: _asInt(json['id']),
      name: (json['name'] ??
              json['plate'] ??
              json['plate_number'] ??
              json['title'] ??
              '-')
          .toString(),
      detail: _detailFrom(json),
      available: _asBool(json['is_available'] ?? json['available'] ?? true),
    );
  }

  /// Rakit baris detail dari field yang tersedia (toleran skema).
  static String _detailFrom(Map<String, dynamic> json) {
    // Prioritaskan detail eksplisit bila backend menyediakannya.
    final explicit = json['detail'] ?? json['description'];
    if (explicit != null && explicit.toString().isNotEmpty) {
      return explicit.toString();
    }
    final parts = <String>[
      for (final key in const [
        'specialty',
        'experience',
        'type',
        'equipment',
        'stock',
        'price',
        'rate',
      ])
        if (json[key] != null && json[key].toString().isNotEmpty)
          json[key].toString(),
    ];
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }
}
