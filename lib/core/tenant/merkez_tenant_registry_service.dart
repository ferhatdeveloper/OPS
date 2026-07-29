// Dosya Adı: merkez_tenant_registry_service.dart
// Açıklama: Merkez `tenant_registry` satırını tipli okuyan best-effort servis
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'postgrest_tenant_defaults.dart';
import 'tenant_connection_resolver.dart';
import 'tenant_registry_row.dart';

/// {@template merkez_tenant_registry_service}
/// Merkez PostgREST `tenant_registry` tablosundan tek kiracı satırını okur.
///
/// HTTP transport, timeout, header üretimi ve JSON parse sorumluluğu bu
/// sınıftadır. Servis best-effort çalışır: boş dizi, aktif olmayan satır,
/// 2xx dışı yanıt, timeout ve geçersiz JSON durumlarında `null` döndürür ve
/// login akışına hata fırlatmaz.
///
/// Kullanım örneği:
/// ```dart
/// final row = await MerkezTenantRegistryService(client: http.Client()).fetch(
///   tenantCode: 'lovan',
///   saasOrigin: 'https://api.retailex.app',
/// );
/// ```
/// {@endtemplate}
class MerkezTenantRegistryService {
  /// [selectColumns]: PostgREST `select` parametresinin kesin içeriği.
  static const String selectColumns =
      'code,rest_base_url,display_name,is_active,'
      'logo_rest_api_url,logo_firm_nr,logo_period_nr,logo_db,updated_at';

  /// [client]: HTTP transport (test için inject edilir)
  final http.Client client;

  /// [timeout]: Merkez isteği zaman aşımı
  final Duration timeout;

  /// {@macro merkez_tenant_registry_service}
  const MerkezTenantRegistryService({
    required this.client,
    this.timeout = const Duration(seconds: 4),
  });

  /// {@template merkez_tenant_registry_service_fetch}
  /// Kiracı koduna ait aktif merkez satırını getirir.
  ///
  /// Parametreler:
  /// - [tenantCode]: Kiracı kodu (normalize edilir)
  /// - [saasOrigin]: Etkin SaaS kökü
  ///
  /// Dönüş değeri:
  /// - [TenantRegistryRow]: Aktif satır; uygulanabilir sonuç yoksa `null`
  /// {@endtemplate}
  Future<TenantRegistryRow?> fetch({
    required String tenantCode,
    required String saasOrigin,
  }) async {
    final code = tenantCode.trim().toLowerCase();
    if (code.isEmpty) return null;

    final base = TenantConnectionResolver.buildMerkezRestBaseUrl(
      origin: saasOrigin,
    );
    final uri = Uri.parse('$base/tenant_registry').replace(
      queryParameters: <String, String>{
        'code': 'eq.$code',
        'select': selectColumns,
        'limit': '1',
      },
    );

    try {
      final response = await client.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Accept-Profile': PostgrestTenantDefaults.defaultSchema,
        },
      ).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
        return null;
      }

      final row = TenantRegistryRow.fromJson(
        Map<String, dynamic>.from(decoded.first as Map),
      );
      return row.isActive ? row : null;
    } on Object catch (error) {
      // Gövde, URL query ve secret loglanmaz — yalnızca hata tipi.
      debugPrint(
        'MerkezTenantRegistryService.fetch başarısız: ${error.runtimeType}',
      );
      return null;
    }
  }
}
