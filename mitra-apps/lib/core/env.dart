/// Konfigurasi environment (doc 08 §3).
///
/// Base URL default = Encore Cloud staging (backend live). Override ke lokal:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:4000
///               --dart-define=WS_BASE=ws://10.0.2.2:4000
///
/// Tiga environment: local, staging (default), production (doc 09).
class Env {
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://staging-garudahacks-wtk2.encr.app',
  );

  static const wsBase = String.fromEnvironment(
    'WS_BASE',
    defaultValue: 'wss://staging-garudahacks-wtk2.encr.app',
  );
}
