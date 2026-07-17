import '../model.dart/mitra_role.dart';

/// Sesi mitra hasil auth (doc 02 §3): token + peran yang dikunci server.
///
/// `provider_type` menentukan shell (role-lock, SRS-07) dan bersifat immutable
/// setelah registrasi (FR-RX-02). Parsing forward-compatible (doc 01 §11):
/// field tak dikenal diabaikan; nilai enum asing → fallback aman.
class MitraSession {
  final String token;
  final MitraRole role;
  final String displayName;

  const MitraSession({
    required this.token,
    required this.role,
    required this.displayName,
  });

  factory MitraSession.fromJson(Map<String, dynamic> json) {
    // Token bisa berada langsung atau di bawah key umum backend.
    final token =
        (json['token'] ?? json['session_token'] ?? json['access_token'] ?? '')
            .toString();

    return MitraSession(
      token: token,
      role: MitraRole(
        type: _providerFromWire(json['provider_type']),
        entity: _entityFromWire(json['entity_type']),
      ),
      displayName: (json['name'] ?? json['display_name'] ?? '').toString(),
    );
  }

  static MitraProviderType _providerFromWire(dynamic v) {
    switch (v?.toString()) {
      case 'ambulance':
        return MitraProviderType.ambulance;
      case 'rental':
        return MitraProviderType.rental;
      case 'caregiver':
      default:
        return MitraProviderType.caregiver;
    }
  }

  static MitraEntityType? _entityFromWire(dynamic v) {
    switch (v?.toString()) {
      case 'agency':
        return MitraEntityType.agency;
      case 'independent':
        return MitraEntityType.independent;
      default:
        return null; // rental tanpa entitas (FR-RX-06).
    }
  }
}
