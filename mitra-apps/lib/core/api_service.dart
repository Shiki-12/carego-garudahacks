import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Error terstruktur dari envelope `ok:false` (doc 01 §2-3).
///
/// - [code] konstanta domain SCREAMING_SNAKE_CASE untuk logika client
///   (mis. 'INVALID_STATUS', 'CONFLICT', 'NOT_FOUND').
/// - [message] teks Indonesia siap tampil ke user.
/// - [httpStatus] status HTTP asli (mis. 409 untuk race dispatch, doc 07 §5).
class ApiException implements Exception {
  final String code;
  final String message;
  final int? httpStatus;
  final Object? details;

  const ApiException(
    this.code,
    this.message, {
    this.httpStatus,
    this.details,
  });

  /// True bila ini konflik state / duplikasi (409) — mis. "pesanan sudah
  /// diambil" pada race dispatch (doc 07 §5).
  bool get isConflict =>
      httpStatus == 409 || code == 'INVALID_STATUS' || code == 'CONFLICT';

  bool get isUnauthenticated =>
      httpStatus == 401 || code == 'UNAUTHENTICATED';

  @override
  String toString() => 'ApiException($code, $httpStatus): $message';
}

/// Lapisan tunggal pembungkus kontrak API (doc 01 & doc 08 §2).
///
/// Menangani: envelope `ok/data` | `ok/error`, header `Authorization: Bearer`,
/// timeout wajib, pemetaan network/timeout error → pesan Indonesia, dan
/// pembersihan token pada 401.
class ApiService {
  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client;
  final Duration timeout;

  /// Dipanggil saat 401 (UNAUTHENTICATED) — mis. arahkan ke login.
  final Future<void> Function()? onUnauthenticated;

  ApiService({
    required this.baseUrl,
    required this.tokens,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.onUnauthenticated,
  }) : _client = client ?? http.Client();

  Future<T> get<T>(String path, {T Function(dynamic)? parse}) =>
      _request('GET', path, parse: parse);

  Future<T> post<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(dynamic)? parse,
  }) =>
      _request('POST', path, body: body, extraHeaders: headers, parse: parse);

  Future<T> put<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parse,
  }) =>
      _request('PUT', path, body: body, parse: parse);

  Future<T> delete<T>(String path, {T Function(dynamic)? parse}) =>
      _request('DELETE', path, parse: parse);

  Future<T> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    T Function(dynamic)? parse,
  }) async {
    final token = await tokens.readSession();
    final uri = Uri.parse('$baseUrl$path');

    http.Response res;
    try {
      final request = http.Request(method, uri);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (extraHeaders != null) request.headers.addAll(extraHeaders);
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
    }

    return _handleResponse<T>(res, parse);
  }

  Future<T> _handleResponse<T>(
    http.Response res,
    T Function(dynamic)? parse,
  ) async {
    dynamic json;
    try {
      json = res.body.isEmpty ? null : jsonDecode(res.body);
    } on FormatException {
      throw ApiException(
        'INVALID_RESPONSE',
        'Terjadi kesalahan pada server. Silakan coba lagi.',
        httpStatus: res.statusCode,
      );
    }

    if (json is Map && json['ok'] == true) {
      final data = json['data'];
      return parse != null ? parse(data) : data as T;
    }

    // Envelope error (doc 01 §2). 401 → bersihkan token & callback.
    final err = (json is Map ? json['error'] : null) ?? const {};
    final code = (err['code'] ?? 'UNKNOWN').toString();
    final message =
        (err['message'] ?? 'Terjadi kesalahan. Silakan coba lagi.').toString();

    final exception = ApiException(
      code,
      message,
      httpStatus: res.statusCode,
      details: err['details'],
    );

    if (exception.isUnauthenticated) {
      await tokens.clear();
      if (onUnauthenticated != null) await onUnauthenticated!();
    }

    throw exception;
  }

  void dispose() => _client.close();
}
