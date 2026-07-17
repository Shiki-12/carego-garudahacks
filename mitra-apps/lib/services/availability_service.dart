import '../core/api_service.dart';

/// Toggle ketersediaan mitra online/offline (PUT /mitra/availability).
///
/// Dipakai tombol tengah tiap shell (Standby⇄Aktif / Aktif⇄Libur). Server
/// yang menyimpan status; client hanya mengirim niat & memantul hasilnya.
class AvailabilityService {
  final ApiService api;

  const AvailabilityService(this.api);

  /// PUT /mitra/availability {is_available}. Mengembalikan status final
  /// dari server bila ada, jika tidak memantulkan nilai yang dikirim.
  Future<bool> setAvailable(bool isAvailable) {
    return api.put<bool>(
      '/mitra/availability',
      body: {'is_available': isAvailable},
      parse: (data) {
        if (data is Map && data['is_available'] is bool) {
          return data['is_available'] as bool;
        }
        return isAvailable;
      },
    );
  }
}
