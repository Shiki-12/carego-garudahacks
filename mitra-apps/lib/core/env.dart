/// Konfigurasi environment (doc 08 §3).
///
/// Base URL TIDAK boleh hardcode di kode. Jalankan dengan mis:
///   flutter run --dart-define=API_BASE=https://staging.carego.example
///               --dart-define=WS_BASE=wss://staging.carego.example
///
/// Tiga environment: local (default), staging, production (doc 09).
class Env {
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:4000',
  );

  static const wsBase = String.fromEnvironment(
    'WS_BASE',
    defaultValue: 'ws://localhost:4000',
  );
}
