import 'api_service.dart';
import 'env.dart';
import 'token_store.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/rental_service.dart';
import '../services/order_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/wallet_service.dart';

/// Service locator sederhana (singleton global) untuk app customer.
///
/// Diinisialisasi sekali di main() sebelum runApp. Menyediakan instance
/// bersama ApiService, TokenStore, dan service domain.
class Services {
  Services._();
  static final Services I = Services._();

  late final TokenStore tokens;
  late final ApiService api;
  late final AuthService auth;
  late final CaregiverService caregiver;
  late final RentalService rental;
  late final OrderService order;
  late final ChatService chat;
  late final NotificationService notification;
  late final WalletService wallet;

  /// Callback opsional yang dipasang UI untuk menangani logout paksa (401).
  void Function()? onUnauthenticated;

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    tokens = TokenStore();
    api = ApiService(
      baseUrl: Env.apiBase,
      tokens: tokens,
      onUnauthenticated: () async => onUnauthenticated?.call(),
    );
    auth = AuthService(api, tokens);
    caregiver = CaregiverService(api);
    rental = RentalService(api);
    order = OrderService(api);
    chat = ChatService(api);
    notification = NotificationService(api);
    wallet = WalletService(api);
    _initialized = true;
  }
}
