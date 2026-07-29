// Dosya Adı: tenant_logo_config_fetcher.dart
// Açıklama: Kullanıcı isteğiyle merkez tenant_registry'den Logo ayarı çeker
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'merkez_tenant_registry_service.dart';
import 'tenant_logo_config_cache.dart';
import 'tenant_logo_config_store.dart';
import 'tenant_store.dart';

/// {@template tenant_logo_fetch_outcome}
/// "Kiracı kodundan çek" sonucunu taşır.
/// {@endtemplate}
class TenantLogoFetchOutcome {
  /// [ok]: Uygulanabilir bir Logo ayarı bulundu mu
  final bool ok;

  /// [cache]: Bulunan Logo yapılandırması (secret içermez)
  final TenantLogoConfigCache? cache;

  /// [fromCache]: Merkeze ulaşılamadı, yerel kayıt kullanıldı mı
  final bool fromCache;

  /// [errorKey]: Kullanıcıya gösterilecek hata l10n anahtarı
  final String? errorKey;

  /// {@macro tenant_logo_fetch_outcome}
  const TenantLogoFetchOutcome({
    required this.ok,
    this.cache,
    this.fromCache = false,
    this.errorKey,
  });
}

/// {@template tenant_logo_config_fetcher}
/// Aktif kiracı kodu ile merkez `tenant_registry` satırındaki Logo
/// başlangıç değerlerini çeker; başarılıysa yerel cache'e yazar.
///
/// Politika:
/// 1. Kiracı kodu yoksa istek atılmaz.
/// 2. Merkez yanıtı uygulanabilirse cache güncellenir.
/// 3. Merkez ulaşılamazsa son geçerli cache bozulmadan kullanılır.
/// 4. Secret alanlar (api key, parola, client secret) registry'den gelmez.
///
/// Kullanım örneği:
/// ```dart
/// final outcome = await TenantLogoConfigFetcher(
///   client: http.Client(),
/// ).fetchForActiveTenant();
/// ```
/// {@endtemplate}
class TenantLogoConfigFetcher {
  /// [client]: HTTP transport (çağıran kapatır)
  final http.Client client;

  /// [tenantStore]: Aktif kiracı bağlamı
  final TenantStore tenantStore;

  /// [configStore]: Logo cache kalıcılığı
  final TenantLogoConfigStore configStore;

  /// [timeout]: Merkez isteği zaman aşımı
  final Duration timeout;

  /// [now]: Test edilebilir zaman kaynağı
  final DateTime Function() now;

  /// {@macro tenant_logo_config_fetcher}
  TenantLogoConfigFetcher({
    required this.client,
    this.tenantStore = const TenantStore(),
    this.configStore = const TenantLogoConfigStore(),
    this.timeout = const Duration(seconds: 6),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  /// {@template tenant_logo_config_fetcher_fetch}
  /// Kiracı koduna ait Logo ayarını getirir.
  ///
  /// Parametreler:
  /// - [tenantCode]: Açık kiracı kodu; boşsa kayıtlı aktif kiracı kullanılır
  ///
  /// Dönüş değeri:
  /// - [TenantLogoFetchOutcome]: Ayar veya hata anahtarı (exception fırlatmaz)
  /// {@endtemplate}
  Future<TenantLogoFetchOutcome> fetchForActiveTenant({
    String? tenantCode,
  }) async {
    final explicit = tenantCode?.trim() ?? '';
    final code = (explicit.isNotEmpty
            ? explicit
            : (await tenantStore.load()).tenantCode)
        .trim()
        .toLowerCase();

    if (code.isEmpty) {
      return const TenantLogoFetchOutcome(
        ok: false,
        errorKey: 'field_sales.logo_registry_no_tenant',
      );
    }

    final saasOrigin = await tenantStore.loadSaasOrigin();
    final row = await MerkezTenantRegistryService(
      client: client,
      timeout: timeout,
    ).fetch(tenantCode: code, saasOrigin: saasOrigin);

    if (row != null && row.hasLogoConfig) {
      final fresh = TenantLogoConfigCache.fromRegistry(row, fetchedAt: now());
      try {
        await configStore.save(fresh);
      } on Object catch (error) {
        debugPrint('tenant Logo cache kaydedilemedi: ${error.runtimeType}');
      }
      return TenantLogoFetchOutcome(ok: true, cache: fresh);
    }

    final cached = await _loadCache(code);
    if (cached != null && cached.hasLogoConfig) {
      return TenantLogoFetchOutcome(ok: true, cache: cached, fromCache: true);
    }

    return const TenantLogoFetchOutcome(
      ok: false,
      errorKey: 'field_sales.logo_registry_not_found',
    );
  }

  Future<TenantLogoConfigCache?> _loadCache(String code) async {
    try {
      return await configStore.loadForTenant(code);
    } on Object catch (error) {
      debugPrint('tenant Logo cache okunamadı: ${error.runtimeType}');
      return null;
    }
  }
}
