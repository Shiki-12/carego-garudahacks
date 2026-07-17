import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan aman untuk token sesi & FCM (doc 08 §4, doc 02 §3.2).
///
/// Token WAJIB di Keychain/Keystore lewat flutter_secure_storage,
/// BUKAN SharedPreferences biasa. Dihapus saat logout.
class TokenStore {
  static const _kSessionToken = 'session_token';
  static const _kFcmToken = 'fcm_token';

  final FlutterSecureStorage _storage;

  const TokenStore([this._storage = const FlutterSecureStorage()]);

  Future<void> writeSession(String token) =>
      _storage.write(key: _kSessionToken, value: token);

  Future<String?> readSession() => _storage.read(key: _kSessionToken);

  Future<void> writeFcm(String token) =>
      _storage.write(key: _kFcmToken, value: token);

  Future<String?> readFcm() => _storage.read(key: _kFcmToken);

  /// Bersihkan sesi saat logout / 401 (doc 08 §2).
  Future<void> clear() async {
    await _storage.delete(key: _kSessionToken);
    await _storage.delete(key: _kFcmToken);
  }
}
