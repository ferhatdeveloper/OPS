// Dosya Adı: postgrest_tenant_service.dart
// Açıklama: Kiracı çözümle + prefs + Postgres/PostgREST aktif bağlam
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../service/postgres_service.dart';
import 'postgrest_tenant_defaults.dart';
import 'tenant_connection_resolver.dart';
import 'tenant_context.dart';
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

  /// {@macro postgrest_tenant_service}
  PostgrestTenantService({
    this.store = const TenantStore(),
    this.syncPostgres = true,
    this.httpClient,
    this.allowOfflineLastTenant = true,
    this.registryTimeout = const Duration(seconds: 4),
  });

  /// Bellekteki / prefs'teki aktif bağlamı Postgres'e yeniden uygular.
  Future<TenantContext?> restoreActiveContext() async {
    final ctx = await store.load();
    if (ctx.isEmpty) return null;
    _bindPostgres(ctx);
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

      // Aynı kod için kayıtlı rest URL tercih et (özel deploy / registry)
      if (cached.isNotEmpty &&
          cached.tenantCode.toLowerCase() ==
              resolved.tenantCode.toLowerCase() &&
              cached.remoteRestUrl.trim().isNotEmpty) {
        resolved = resolved.copyWith(
          remoteRestUrl: cached.remoteRestUrl,
          schema: cached.schema,
          source: 'cached',
        );
      } else {
        // İsteğe bağlı: merkez tenant_registry probe (başarısız olursa SaaS kalır)
        final fromRegistry = await _tryResolveFromMerkezRegistry(
          resolved.tenantCode,
          saasOrigin: saasOrigin,
        );
        if (fromRegistry != null) {
          resolved = fromRegistry;
        }
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
          _bindPostgres(cached);
          return TenantApplyResult(
            ok: true,
            context: cached,
            usedOfflineCache: true,
            errorDetail: e.message,
          );
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
      } catch (_) {
        if (allowOfflineLastTenant && cached.isNotEmpty) {
          _bindPostgres(cached);
          return TenantApplyResult(
            ok: true,
            context: cached,
            usedOfflineCache: true,
            errorDetail: e.toString(),
          );
        }
        return TenantApplyResult(
          ok: false,
          errorKey: 'auth.tenant_resolve_failed',
          errorDetail: e.toString(),
        );
      }
    }
  }

  /// Merkez `tenant_registry` satırından `rest_base_url` dener.
  /// Başarısız / timeout → null (SaaS slug kalır).
  Future<TenantResolveResult?> _tryResolveFromMerkezRegistry(
    String tenantCode, {
    required String saasOrigin,
  }) async {
    final client = httpClient;
    if (client == null) return null;

    final merkez = TenantConnectionResolver.buildMerkezRestBaseUrl(
      origin: saasOrigin,
    );
    final filter = Uri.encodeQueryComponent(tenantCode);
    final uri = Uri.parse(
      '$merkez/tenant_registry?code=eq.$filter&select=code,rest_base_url,display_name,is_active',
    );

    try {
      final res = await client.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Accept-Profile': PostgrestTenantDefaults.defaultSchema,
        },
      ).timeout(registryTimeout);

      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      // Minimal parse without heavy JSON deps issues — http body is JSON array
      final body = res.body.trim();
      if (!body.startsWith('[') || body == '[]') return null;

      // Lightweight extraction: look for rest_base_url
      final urlMatch = RegExp(
        r'"rest_base_url"\s*:\s*"([^"]+)"',
      ).firstMatch(body);
      final codeMatch = RegExp(r'"code"\s*:\s*"([^"]+)"').firstMatch(body);
      final activeMatch = RegExp(r'"is_active"\s*:\s*(false)').firstMatch(body);
      if (activeMatch != null) return null;

      final restUrl = urlMatch?.group(1)?.trim() ?? '';
      final code = codeMatch?.group(1)?.trim() ?? tenantCode;
      if (restUrl.isEmpty) return null;

      return TenantResolveResult(
        tenantCode: code,
        remoteRestUrl: TenantConnectionResolver.normalizeBaseUrl(restUrl),
        schema: PostgrestTenantDefaults.defaultSchema,
        source: 'tenant_registry',
      );
    } catch (e) {
      debugPrint('tenant_registry probe atlandı: $e');
      return null;
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
