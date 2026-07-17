import 'package:flutter/widgets.dart';

import 'api_service.dart';
import 'env.dart';
import 'token_store.dart';
import '../services/auth_service.dart';
import '../services/availability_service.dart';
import '../services/assets_service.dart';
import '../services/orders_service.dart';

/// Composition root sederhana (doc 08 §9) — satu instance [ApiService]
/// dipakai seragam semua layar/service, tanpa dependency injection berat
/// (setState prototipe dipertahankan, ADR-005).
class Services {
  Services._();
  static final Services I = Services._();

  /// Navigator global agar 401 dari mana pun bisa mengarahkan ke root login
  /// tanpa akses [BuildContext] di lapisan service (doc 08 §2).
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final TokenStore tokens = const TokenStore();

  late final ApiService api = ApiService(
    baseUrl: Env.apiBase,
    tokens: tokens,
    onUnauthenticated: _handleUnauthenticated,
  );

  late final OrdersService orders = OrdersService(api);

  late final AuthService auth = AuthService(api, tokens);

  late final AvailabilityService availability = AvailabilityService(api);

  late final AssetsService assets = AssetsService(api);

  /// Callback saat 401 (token invalid/kedaluwarsa): sesi sudah dibersihkan
  /// [ApiService], tinggal kembalikan ke akar (RoleSelectionPage). Menghapus
  /// seluruh stack agar tak ada layar terkunci yang tertinggal (doc 02 §3).
  Future<void> _handleUnauthenticated() async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.popUntil((route) => route.isFirst);
  }
}
