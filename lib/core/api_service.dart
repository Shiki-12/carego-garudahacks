import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Error terstruktur dari backend. Encore membalas error sebagai JSON
/// `{ "code": "...", "message": "...", "details": {...} }` dengan status HTTP
/// yang sesuai. `message` aman ditampilkan ke user (bahasa Indonesia).
class ApiException implements Exception {
  final String code;
  final String message;
  final int? httpStatus;

  const ApiException(this.code, this.message, {this.httpStatus});

  bool get isUnauthenticated =>
      httpStatus == 401 || code == 'unauthenticated' || code == 'UNAUTHENTICATED';

  bool get isConflict =>
      httpStatus == 409 || code == 'already_exists' || code == 'failed_precondition';

  @override
  String toString() => 'ApiException($code, $httpStatus): $message';
}

/// Lapisan tunggal pemanggil HTTP backend untuk app customer.
///
/// Menangani: header `Authorization: Bearer <token>`, timeout, decode JSON,
/// pemetaan error jaringan/timeout → pesan Indonesia, dan pembersihan token
/// saat 401. Sebagian besar endpoint backend membalas JSON polos; endpoint
/// yang membungkus `{ ok, data }` (mis. POST /bookings) otomatis di-unwrap.
class ApiService {
  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client;
  final Duration timeout;

  /// Dipanggil saat 401 — mis. arahkan kembali ke layar login.
  final Future<void> Function()? onUnauthenticated;

  ApiService({
    required this.baseUrl,
    required this.tokens,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.onUnauthenticated,
  }) : _client = client ?? http.Client();

  Future<dynamic> get(String path) => _request('GET', path);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _request('POST', path, body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _request('PUT', path, body: body);

  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await tokens.readSession();
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      final request = http.Request(method, uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) request.body = jsonEncode(body);

      final streamed = await _client.send(request).timeout(timeout);
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        'TIMEOUT',
        'Permintaan melebihi batas waktu. Periksa koneksi Anda dan coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        'NETWORK_ERROR',
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (_) {
      throw const ApiException(
        'NETWORK_ERROR',
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }

    return _handle(res);
  }

  Future<dynamic> _handle(http.Response res) async {
    dynamic json;
    if (res.body.isNotEmpty) {
      try {
        json = jsonDecode(res.body);
      } on FormatException {
        json = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Unwrap envelope { ok: true, data } bila ada; jika tidak, kembalikan apa adanya.
      if (json is Map && json['ok'] == true && json.containsKey('data')) {
        return json['data'];
      }
      return json;
    }

    // Error: Encore membalas { code, message, details }.
    final code = (json is Map ? json['code'] : null)?.toString() ?? 'UNKNOWN';
    final message = (json is Map ? json['message'] : null)?.toString() ??
        'Terjadi kesalahan. Silakan coba lagi.';

    final exception = ApiException(code, message, httpStatus: res.statusCode);

    if (exception.isUnauthenticated) {
      await tokens.clear();
      if (onUnauthenticated != null) await onUnauthenticated!();
    }

    throw exception;
  }

  void dispose() => _client.close();
}
