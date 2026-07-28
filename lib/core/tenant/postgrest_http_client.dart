// Dosya Adı: postgrest_http_client.dart
// Açıklama: Kiracı PostgREST HTTP GET/POST/PATCH istemcisi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../service/postgres_service.dart';

/// {@template postgrest_http_exception}
/// PostgREST HTTP hata sarmalayıcısı.
/// {@endtemplate}
class PostgrestHttpException implements Exception {
  /// [statusCode]: HTTP durum kodu
  final int statusCode;

  /// [message]: Hata metni
  final String message;

  /// [body]: Ham gövde (kısaltılmış)
  final String? body;

  /// {@macro postgrest_http_exception}
  const PostgrestHttpException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() => 'PostgrestHttpException($statusCode): $message';
}

/// {@template postgrest_http_client}
/// Aktif kiracı URL + header ile PostgREST çağrıları.
///
/// Kullanım örneği:
/// ```dart
/// final c = PostgrestHttpClient();
/// final rows = await c.getRows('/users', query: {'username': 'eq.admin'});
/// ```
/// {@endtemplate}
class PostgrestHttpClient {
  /// [httpClient]: Enjekte edilebilir HTTP istemcisi
  final http.Client httpClient;

  /// [postgres]: Aktif kiracı bağlamı
  final PostgresService postgres;

  /// İstek zaman aşımı
  final Duration timeout;

  /// {@macro postgrest_http_client}
  PostgrestHttpClient({
    http.Client? httpClient,
    PostgresService? postgres,
    this.timeout = const Duration(seconds: 20),
  })  : httpClient = httpClient ?? http.Client(),
        postgres = postgres ?? PostgresService.instance;

  /// Aktif PostgREST tabanı dolu mu?
  bool get isConfigured => postgres.activeRemoteRestUrl.trim().isNotEmpty;

  /// GET → JSON dizi (veya tek nesne → tek elemanlı liste).
  Future<List<Map<String, dynamic>>> getRows(
    String path, {
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _uri(path, query);
    final headers = {
      ...postgres.postgrestHeaders(),
      if (extraHeaders != null) ...extraHeaders,
    };
    debugPrint('PostgREST GET $uri');
    final res = await httpClient.get(uri, headers: headers).timeout(timeout);
    return _decodeList(res);
  }

  /// POST → Prefer: return=representation ile satır listesi.
  Future<List<Map<String, dynamic>>> postRow(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? extraHeaders,
    bool returnRepresentation = true,
  }) async {
    final uri = _uri(path, null);
    final headers = {
      ...postgres.postgrestHeaders(),
      if (returnRepresentation) 'Prefer': 'return=representation',
      if (extraHeaders != null) ...extraHeaders,
    };
    debugPrint('PostgREST POST $uri');
    final res = await httpClient
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.trim().isEmpty) return const [];
      return _decodeList(res);
    }
    throw PostgrestHttpException(
      statusCode: res.statusCode,
      message: _errorMessage(res),
      body: res.body,
    );
  }

  /// PATCH → Prefer: return=representation.
  Future<List<Map<String, dynamic>>> patchRows(
    String path, {
    required Map<String, String> query,
    required Map<String, dynamic> body,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _uri(path, query);
    final headers = {
      ...postgres.postgrestHeaders(),
      'Prefer': 'return=representation',
      if (extraHeaders != null) ...extraHeaders,
    };
    final res = await httpClient
        .patch(uri, headers: headers, body: jsonEncode(body))
        .timeout(timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.trim().isEmpty) return const [];
      return _decodeList(res);
    }
    throw PostgrestHttpException(
      statusCode: res.statusCode,
      message: _errorMessage(res),
      body: res.body,
    );
  }

  Uri _uri(String path, Map<String, String>? query) {
    final base = postgres.activeRemoteRestUrl.trim();
    if (base.isEmpty) {
      throw const PostgrestHttpException(
        statusCode: 0,
        message: 'PostgREST URL yok (kiracı bağlamı boş)',
      );
    }
    final p = path.startsWith('/') ? path : '/$path';
    final full = postgres.postgrestUrl(p);
    return Uri.parse(full).replace(queryParameters: query);
  }

  List<Map<String, dynamic>> _decodeList(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw PostgrestHttpException(
        statusCode: res.statusCode,
        message: _errorMessage(res),
        body: res.body,
      );
    }
    final raw = res.body.trim();
    if (raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    if (decoded is Map) {
      return [Map<String, dynamic>.from(decoded)];
    }
    return const [];
  }

  String _errorMessage(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return 'HTTP ${res.statusCode}';
  }
}
