import 'package:flutter/material.dart';

/// Status kanonik pesanan (doc 07 §3, state machine doc 01 §6).
///
/// Nilai string identik dengan backend (satu kontrak — doc 00 §2.1).
/// `unknown` menampung status baru yang belum dikenal client agar parsing
/// forward-compatible (doc 01 §11) — bukan crash.
enum OrderStatus {
  pending('pending', 'Menunggu', Colors.orange),
  accepted('accepted', 'Diterima', Color(0xff3B82F6)),
  onTheWay('on_the_way', 'Menuju Lokasi', Color(0xff3B82F6)),
  inProgress('in_progress', 'Berlangsung', Color(0xff8B5CF6)),
  completed('completed', 'Selesai', Color(0xff059669)),
  cancelled('cancelled', 'Dibatalkan', Colors.redAccent),
  rejected('rejected', 'Ditolak', Colors.redAccent),
  unknown('unknown', 'Tidak diketahui', Colors.grey);

  final String wire;
  final String label;
  final Color color;

  const OrderStatus(this.wire, this.label, this.color);

  static OrderStatus fromWire(String? value) {
    for (final s in OrderStatus.values) {
      if (s.wire == value) return s;
    }
    return OrderStatus.unknown;
  }

  /// Grup tab Mitra (doc 07 §2): Menunggu / Aktif / Riwayat.
  bool get isWaiting => this == OrderStatus.pending;

  bool get isActive =>
      this == OrderStatus.accepted ||
      this == OrderStatus.onTheWay ||
      this == OrderStatus.inProgress;

  bool get isHistory =>
      this == OrderStatus.completed ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.rejected;
}

/// Satu pesanan dari sudut pandang Mitra (doc 07 §2).
///
/// Sumber kebenaran: backend. Client hanya menampilkan; harga (integer Rupiah,
/// doc 01 §3) dihitung server, tak pernah client.
class MitraOrder {
  final int id;
  final String code;
  final String patientName;
  final String serviceLabel;
  final String scheduleLabel;
  final int totalPrice;
  final OrderStatus status;

  const MitraOrder({
    required this.id,
    required this.code,
    required this.patientName,
    required this.serviceLabel,
    required this.scheduleLabel,
    required this.totalPrice,
    required this.status,
  });

  /// Forward-compatible: abaikan field tak dikenal, toleran tipe (doc 01 §11).
  factory MitraOrder.fromJson(Map<String, dynamic> json) {
    return MitraOrder(
      id: _asInt(json['id']),
      code: (json['code'] ?? '#${json['id'] ?? ''}').toString(),
      patientName: (json['patientName'] ?? 'Pasien').toString(),
      serviceLabel: (json['serviceLabel'] ??
              json['service'] ??
              json['serviceType'] ??
              '-')
          .toString(),
      scheduleLabel:
          (json['scheduleLabel'] ?? json['schedule'] ?? '-').toString(),
      totalPrice: _asInt(json['totalPrice']),
      status: OrderStatus.fromWire(json['status']?.toString()),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Format Rupiah dari integer (doc 01 §3), mis. 600000 → "Rp600.000".
  String get priceLabel {
    final s = totalPrice.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp$buf';
  }
}

/// Halaman terbungkus untuk list (doc 01 §7): `items/total/limit/offset`.
class Paginated<T> {
  final List<T> items;
  final int total;
  final int limit;
  final int offset;

  const Paginated({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory Paginated.fromJson(
    dynamic data,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final map = (data as Map?) ?? const {};
    final rawItems = (map['items'] as List?) ?? const [];
    return Paginated(
      items: rawItems
          .whereType<Map>()
          .map((e) => itemFromJson(e.cast<String, dynamic>()))
          .toList(),
      total: (map['total'] as num?)?.toInt() ?? rawItems.length,
      limit: (map['limit'] as num?)?.toInt() ?? 20,
      offset: (map['offset'] as num?)?.toInt() ?? 0,
    );
  }
}
