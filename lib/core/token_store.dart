import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan sesi lokal app customer: token + profil user ringkas.
///
/// Untuk hackathon memakai SharedPreferences (cukup untuk token bearer).
/// Dihapus saat logout / 401.
class TokenStore {
  static const _kToken = 'session_token';
  static const _kUser = 'session_user';

  Future<void> writeSession(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kToken, token);
  }

  Future<String?> readSession() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kToken);
  }

  Future<void> writeUser(Map<String, dynamic> user) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUser, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> readUser() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kUser);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isLoggedIn async => (await readSession())?.isNotEmpty ?? false;

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kToken);
    await sp.remove(_kUser);
  }
}
