/// SRS-07: Tipe & entitas mitra. Menentukan shell mana yang dirender.
/// `provider_type` bersifat immutable setelah registrasi (FR-RX-02).
enum MitraProviderType { caregiver, ambulance, rental }

enum MitraEntityType { agency, independent }

class MitraRole {
  final MitraProviderType type;

  /// null untuk rental (FR-RX-06 — rental tanpa pembedaan entitas).
  final MitraEntityType? entity;

  const MitraRole({required this.type, this.entity});

  bool get isAgency => entity == MitraEntityType.agency;
  bool get isIndependent => entity == MitraEntityType.independent;

  /// Judul peran untuk header auth/onboarding.
  String get roleTitle {
    switch (type) {
      case MitraProviderType.caregiver:
        return "Caregiver";
      case MitraProviderType.ambulance:
        return "Driver Ambulans";
      case MitraProviderType.rental:
        return "Rental Alat Medis";
    }
  }

  /// Nama entitas dummy untuk header shell.
  String get displayName {
    switch (type) {
      case MitraProviderType.caregiver:
        return isAgency ? "Panti Jompo Sejahtera" : "Caregiver Mandiri";
      case MitraProviderType.ambulance:
        return isAgency ? "RS Harapan Bunda" : "Driver Mandiri";
      case MitraProviderType.rental:
        return "Toko Alkes Sehat";
    }
  }
}