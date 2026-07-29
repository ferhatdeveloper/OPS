// Dosya Adı: postgrest_tenant_service.dart
// Açıklama: Kiracı çözümle + prefs + Postgres/PostgREST aktif bağlam
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../service/postgres_service.dart';
import '../logo/logo_tenant_config_seeder.dart';
import '../logo/logo_tiger_settings_store.dart';
import 'merkez_tenant_registry_service.dart';
import 'tenant_connection_resolver.dart';
import 'tenant_context.dart';
import 'tenant_logo_config_cache.dart';
import 'tenant_logo_config_store.dart';
import 'tenant_registry_row.dart';
import 'tenant_store.dart';

/// {@template tenant_apply_result}
/// Login öncesi kiracı uygulama sonucu.
/// {@endtemplate}
class TenantApplyResult {
  /// [ok]: Başarılı mı
  final bool ok;

  /// [context]: Uygulanan bağlam (başarılıysa)
  final TenantContext? context;

  /// [errorKey]: l10n anahtarı (başarısızsa)
  final String? errorKey;

  /// [errorDetail]: Teknik detay
  final String? errorDetail;

  /// [usedOfflineCache]: Offline son kiracı kullanıldı
  final bool usedOfflineCache;

  /// {@macro tenant_apply_result}
  const TenantApplyResult({
    required this.ok,
    this.context,
    this.errorKey,
    this.errorDetail,
    this.usedOfflineCache = false,
  });
}

/// {@template postgrest_tenant_service}
/// Login akışında kiracı kodunu çözümler, kaydeder ve Postgres bağlamına bağlar.
/// Logo REST ayrı kalır; ActiveCompanyStore firma/dönem ile uyumludur.
///
/// Offline politika:
/// 1. Giriş satırı boş + kayıtlı kiracı yok → hata (`auth.tenant_required`)
/// 2. Ağ yok / registry başarısız → SaaS slug URL yerel hesaplanır; kayıtlı
///    bağlam varsa aynı kod için cache kullanılır
/// 3. Giriş boş ama prefs dolu → son kiracı ile devam (`usedOfflineCache`)
///
/// Kullanım örneği:
/// ```dart
/// final r = await PostgrestTenantService().applyTenantCode('lovan');
/// print(r.ok);
/// ```
/// {@endtemplate}
class PostgrestTenantService {
  /// [store]: Prefs kalıcılık
  final TenantStore store;

  /// [syncPostgres]: PostgresService tenant bağlamını güncelle
  final bool syncPostgres;

  /// [httpClient]: Registry lookup (opsiyonel probe)
  final http.Client? httpClient;

  /// [allowOfflineLastTenant]: Ağ/boş girişte son kiracıya izin
  final bool allowOfflineLastTenant;

  /// Registry probe zaman aşımı
  final Duration registryTimeout;

  /// [logoConfigStore]: Tenant'a bağlı Logo registry cache deposu
  final TenantLogoConfigStore logoConfigStore;

  /// [logoSeeder]: Logo cache → Tiger ayarları seed politikası
  final LogoTenantConfigSeeder logoSeeder;

  /// [now]: Test edilebilir zaman kaynağı (TTL hesabı)
  final DateTime Function() now;

  /// [registryCacheTtl]: Logo cache yenileme süresi
  final Duration registryCacheTtl;

  /// {@macro postgrest_tenant_service}
  PostgrestTenantService({
    this.store = const TenantStore(),
    this.syncPostgres = true,
    this.httpClient,
    this.allowOfflineLastTenant = true,
    this.registryTimeout = const Duration(seconds: 4),
    this.logoConfigStore = const TenantLogoConfigStore(),
    LogoTenantConfigSeeder? logoSeeder,
    DateTime Function()? now,
    this.registryCacheTtl = const Duration(minutes: 15),
  })  : logoSeeder = logoSeeder ??
            LogoTenantConfigSeeder(tigerStore: LogoTigerSettingsStore()),
        now = now ?? DateTime.now;

  /// Bellekteki / prefs'teki aktif bağlamı Postgres'e yeniden uygular.
  ///
  /// Ağ beklemesi yapmaz; aynı kiracıya ait Logo registry cache'i varsa
  /// offline seed olarak yeniden uygulanır.
  Future<TenantContext?> restoreActiveContext() async {
    final ctx = await store.load();
    if (ctx.isEmpty) return null;
    _bindPostgres(ctx);
    await _applyCachedLogoConfig(ctx.tenantCode);
    return ctx;
  }

  /// Login: kiracı kodunu çözümle + kaydet + bağla.
  ///
  /// Parametreler:
  /// - [rawInput]: Kullanıcı kiracı kodu / URL (boşsa offline last)
  ///
  /// Dönüş değeri:
  /// - [TenantApplyResult]: Sonuç
  Future<TenantApplyResult> applyTenantCode(String rawInput) async {
    final input = rawInput.trim();
    final saasOrigin = await store.loadSaasOrigin();
    final cached = await store.load();

    if (input.isEmpty) {
      if (allowOfflineLastTenant && cached.isNotEmpty) {
        _bindPostgres(cached);
        return TenantApplyResult(
          ok: true,
          context: cached,
          usedOfflineCache: true,
        );
      }
      return const TenantApplyResult(
        ok: false,
        errorKey: 'auth.tenant_required',
      );
    }

    try {
      var resolved = TenantConnectionResolver.resolveFromInput(
        input,
        saasOrigin: saasOrigin,
      );

      // Logo bootstrap kayıtlı rest URL kısa devresinden bağımsız çalışır.
      final registryRow = await _fetchRegistryIfNeeded(
        resolved.tenantCode,
        saasOrigin: saasOrigin,
      );

      final registryRestUrl = registryRow?.restBaseUrl?.trim() ?? '';
      if (registryRestUrl.isNotEmpty) {
        final normalized = TenantConnectionResolver.normalizeBaseUrl(
          registryRestUrl,
        );
        resolved = resolved.copyWith(
          remoteRestUrl: TenantConnectionResolver.rewriteRestUrlForSaasOrigin(
            normalized,
            saasOrigin: saasOrigin,
          ),
          source: 'tenant_registry',
        );
      } else if (cached.isNotEmpty &&
          cached.tenantCode.toLowerCase() ==
              resolved.tenantCode.toLowerCase() &&
          cached.remoteRestUrl.trim().isNotEmpty) {
        // Aynı kod için kayıtlı rest URL tercih et (özel deploy / registry).
        // SaaS kök değişince TenantStore remoteRestUrl’yi zaten temizler;
        // burada startsWith(origin) ile özel deploy URL’lerini düşürme.
        resolved = resolved.copyWith(
          remoteRestUrl: cached.remoteRestUrl.trim(),
          schema: cached.schema,
          source: 'cached',
        );
      }

      final ctx = TenantContext.fromResolve(
        resolved,
        apiKey: cached.apiKey,
        jwt: cached.jwt,
        merkezRestUrl: cached.merkezRestUrl ??
            TenantConnectionResolver.buildMerkezRestBaseUrl(
              origin: saasOrigin,
            ),
        displayName: cached.displayName ?? resolved.tenantCode,
      );

      await store.save(ctx);
      _bindPostgres(ctx);

      return TenantApplyResult(
        ok: true,
        context: ctx,
        usedOfflineCache: resolved.usedOfflineCache,
      );
    } on FormatException catch (e) {
      // Ağ yok + geçerli kod: son kayıtlı aynı kod veya SaaS URL ile devam
      if (allowOfflineLastTenant && cached.isNotEmpty) {
        final codeMatch = input.isNotEmpty &&
            cached.tenantCode.toLowerCase() == input.toLowerCase();
        if (codeMatch || input.isEmpty) {
          try {
            _bindPostgres(cached);
            return TenantApplyResult(
              ok: true,
              context: cached,
              usedOfflineCache: true,
              errorDetail: e.message,
            );
          } catch (bindError) {
            debugPrint(
              'PostgrestTenantService FormatException bind: $bindError',
            );
          }
        }
      }
      return TenantApplyResult(
        ok: false,
        errorKey: 'auth.tenant_invalid',
        errorDetail: e.message,
      );
    } catch (e) {
      debugPrint('PostgrestTenantService.applyTenantCode: $e');
      // Offline: hesaplanan SaaS URL ile yine de kaydet
      try {
        final fallback = TenantConnectionResolver.resolveFromInput(
          input,
          saasOrigin: saasOrigin,
        );
        final ctx = TenantContext.fromResolve(
          fallback.copyWith(usedOfflineCache: true, source: 'saas_slug'),
          merkezRestUrl: TenantConnectionResolver.buildMerkezRestBaseUrl(
            origin: saasOrigin,
          ),
        );
        await store.save(ctx);
        _bindPostgres(ctx);
        return TenantApplyResult(
          ok: true,
          context: ctx,
          usedOfflineCache: true,
          errorDetail: e.toString(),
        );
      } catch (fallbackError) {
        debugPrint(
          'PostgrestTenantService.applyTenantCode fallback: $fallbackError',
        );
        if (allowOfflineLastTenant && cached.isNotEmpty) {
          try {
            _bindPostgres(cached);
            return TenantApplyResult(
              ok: true,
              context: cached,
              usedOfflineCache: true,
              errorDetail: e.toString(),
            );
          } catch (bindError) {
            debugPrint(
              'PostgrestTenantService.applyTenantCode cache bind: $bindError',
            );
          }
        }
        return TenantApplyResult(
          ok: false,
          errorKey: 'auth.tenant_resolve_failed',
          errorDetail: '$e | $fallbackError',
        );
      }
    }
  }

  /// {@template postgrest_tenant_service_fetch_registry}
  /// Merkez registry satırını TTL politikasıyla getirir ve Logo seed'ini
  /// uygular.
  ///
  /// Algoritma:
  /// 1. Aktif kiracının Logo cache'i taze ise HTTP yapılmaz, cache seed edilir.
  /// 2. [httpClient] yoksa mevcut cache seed edilir.
  /// 3. Fetch başarılıysa cache yazılır ve seed uygulanır.
  /// 4. Fetch başarısızsa son geçerli cache korunur ve seed edilir.
  ///
  /// Dönüş değeri:
  /// - [TenantRegistryRow]: Taze merkez satırı; yoksa `null`
  /// {@endtemplate}
  Future<TenantRegistryRow?> _fetchRegistryIfNeeded(
    String tenantCode, {
    required String saasOrigin,
  }) async {
    final code = tenantCode.trim().toLowerCase();
    if (code.isEmpty) return null;

    final cached = await _loadLogoCache(code);
    if (cached != null && cached.isFresh(now: now(), ttl: registryCacheTtl)) {
      await _seedLogoCache(cached);
      return null;
    }

    final client = httpClient;
    if (client == null) {
      if (cached != null) await _seedLogoCache(cached);
      return null;
    }

    final row = await MerkezTenantRegistryService(
      client: client,
      timeout: registryTimeout,
    ).fetch(tenantCode: code, saasOrigin: saasOrigin);

    if (row == null) {
      // Ağ / registry hatası son geçerli cache'i bozmaz.
      if (cached != null) await _seedLogoCache(cached);
      return null;
    }

    if (row.hasLogoConfig) {
      final fresh = TenantLogoConfigCache.fromRegistry(row, fetchedAt: now());
      try {
        await logoConfigStore.save(fresh);
      } catch (e) {
        debugPrint('tenant Logo cache kaydedilemedi: ${e.runtimeType}');
      }
      await _seedLogoCache(fresh);
    } else if (cached != null) {
      await _seedLogoCache(cached);
    }

    return row;
  }

  /// Aktif kiracıya ait Logo cache'ini offline seed olarak uygular.
  Future<void> _applyCachedLogoConfig(String tenantCode) async {
    final cached = await _loadLogoCache(tenantCode.trim().toLowerCase());
    if (cached == null) return;
    await _seedLogoCache(cached);
  }

  Future<TenantLogoConfigCache?> _loadLogoCache(String tenantCode) async {
    if (tenantCode.isEmpty) return null;
    try {
      return await logoConfigStore.loadForTenant(tenantCode);
    } catch (e) {
      debugPrint('tenant Logo cache okunamadı: ${e.runtimeType}');
      return null;
    }
  }

  Future<void> _seedLogoCache(TenantLogoConfigCache cache) async {
    if (!cache.hasLogoConfig) return;
    try {
      await logoSeeder.apply(cache);
    } catch (e) {
      debugPrint('tenant Logo seed uygulanamadı: ${e.runtimeType}');
    }
  }

  void _bindPostgres(TenantContext ctx) {
    if (!syncPostgres || ctx.isEmpty) return;
    PostgresService.instance.setActiveTenantContext(
      tenantCode: ctx.tenantCode,
      remoteRestUrl: ctx.remoteRestUrl,
      schema: ctx.schema,
      apiKey: ctx.apiKey,
      jwt: ctx.jwt,
    );
  }
}
