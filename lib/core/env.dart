/// Konfigurasi environment untuk app customer CAREGO.
///
/// Base URL default = Encore Cloud staging. Override saat run untuk lokal:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:4000
///                --dart-define=WS_BASE=ws://10.0.2.2:4000
class Env {
  /// Base URL HTTP backend. Default = Encore Cloud staging (backend live),
  /// override untuk lokal: --dart-define=API_BASE=http://10.0.2.2:4000
  static const _stagingHttp = 'https://staging-garudahacks-wtk2.encr.app';
  static const _stagingWs = 'wss://staging-garudahacks-wtk2.encr.app';

  static String get apiBase {
    const override = String.fromEnvironment('API_BASE');
    return override.isNotEmpty ? override : _stagingHttp;
  }

  /// Base URL WebSocket (chat & ambulans realtime).
  static String get wsBase {
    const override = String.fromEnvironment('WS_BASE');
    return override.isNotEmpty ? override : _stagingWs;
  }
}
