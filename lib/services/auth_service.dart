import '../core/api_service.dart';
import '../core/token_store.dart';

/// Profil user ringkas dari backend (`/auth/*`).
class AuthUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? photoUrl;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.photoUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        role: (j['role'] ?? 'patient') as String,
        phone: j['phone'] as String?,
        photoUrl: j['photo_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'photo_url': photoUrl,
      };
}

/// Auth customer (endpoint `/auth/*`). Menyimpan token sesi + profil ke
/// [TokenStore] begitu server membalas, sehingga panggilan berikutnya
/// otomatis membawa `Authorization: Bearer`.
class AuthService {
  final ApiService api;
  final TokenStore tokens;

  const AuthService(this.api, this.tokens);

  /// POST /auth/register — daftar akun baru (langsung login).
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    return _persist(data as Map<String, dynamic>);
  }

  /// POST /auth/login — masuk dengan email + kata sandi.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final data = await api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _persist(data as Map<String, dynamic>);
  }

  /// Hapus sesi lokal (logout).
  Future<void> logout() => tokens.clear();

  Future<AuthUser?> currentUser() async {
    final cached = await tokens.readUser();
    return cached == null ? null : AuthUser.fromJson(cached);
  }

  Future<bool> get isLoggedIn => tokens.isLoggedIn;

  Future<AuthUser> _persist(Map<String, dynamic> data) async {
    final token = (data['token'] ?? '') as String;
    final user = AuthUser.fromJson((data['user'] as Map).cast<String, dynamic>());
    if (token.isNotEmpty) await tokens.writeSession(token);
    await tokens.writeUser(user.toJson());
    return user;
  }
}
