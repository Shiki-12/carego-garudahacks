import '../core/api_service.dart';
import '../core/token_store.dart';
import '../model.dart/mitra_role.dart';
import '../models/mitra_session.dart';

/// Auth mitra (doc 02 §9, endpoint `/mitra/auth/*`).
///
/// Semua panggilan lewat [ApiService] (envelope, timeout, error Indonesia).
/// Token sesi disimpan di [TokenStore] (Keychain/Keystore, doc 08 §4) begitu
/// server membalas. Role-lock (SRS-07): peran final ditetapkan server pada
/// sesi, bukan dipilih ulang client.
class AuthService {
  final ApiService api;
  final TokenStore tokens;

  const AuthService(this.api, this.tokens);

  /// Nilai wire provider_type sesuai kontrak backend.
  static String providerWire(MitraProviderType t) {
    switch (t) {
      case MitraProviderType.caregiver:
        return 'caregiver';
      case MitraProviderType.ambulance:
        return 'ambulance';
      case MitraProviderType.rental:
        return 'rental';
    }
  }

  static String entityWire(MitraEntityType? e) {
    // Rental tanpa entitas → default 'independent' agar payload tetap valid.
    switch (e) {
      case MitraEntityType.agency:
        return 'agency';
      case MitraEntityType.independent:
      case null:
        return 'independent';
    }
  }

  /// POST /mitra/auth/register — daftar mitra baru + provider_type immutable.
  /// Menyimpan token sesi bila server membalasnya (auto-login).
  Future<MitraSession> register({
    required String name,
    required String phone,
    required String password,
    required MitraRole role,
  }) async {
    final session = await api.post<MitraSession>(
      '/mitra/auth/register',
      body: {
        'name': name,
        'phone': phone,
        'password': password,
        'provider_type': providerWire(role.type),
        'entity_type': entityWire(role.entity),
      },
      parse: _parseSession,
    );
    await _persist(session);
    return session;
  }

  /// POST /mitra/auth/login — masuk dengan No. HP + kata sandi.
  Future<MitraSession> login({
    required String phone,
    required String password,
  }) async {
    final session = await api.post<MitraSession>(
      '/mitra/auth/login',
      body: {'phone': phone, 'password': password},
      parse: _parseSession,
    );
    await _persist(session);
    return session;
  }

  /// Hapus sesi lokal (logout). Backend token dianggap stateless (doc 02 §3).
  Future<void> logout() => tokens.clear();

  MitraSession _parseSession(dynamic data) =>
      MitraSession.fromJson((data as Map).cast<String, dynamic>());

  Future<void> _persist(MitraSession session) async {
    if (session.token.isNotEmpty) {
      await tokens.writeSession(session.token);
    }
  }
}
