// Dosya Adı: tenant_store.dart
// Açıklama: Kiracı PostgREST bağlamını SharedPreferences ile kalıcı tutar
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:shared_preferences/shared_preferences.dart';

import 'postgrest_tenant_defaults.dart';
import 'tenant_context.dart';

/// {@template tenant_store}
/// Son kiracı kodu / PostgREST URL'ini prefs'e yazar; bellek oturumunu günceller.
///
/// Kullanım örneği:
/// ```dart
/// const store = TenantStore();
/// await store.save(TenantContext(
///   tenantCode: 'lovan',
///   remoteRestUrl: 'https://api.retailex.app/lovan',
/// ));
/// print(TenantStore.current?.tenantCode);
/// ```
/// {@endtemplate}
class TenantStore {
  /// [prefsTenantCode]: Kiracı kodu
  static const String prefsTenantCode = 'ops_tenant_code';

  /// [prefsRemoteRestUrl]: PostgREST base URL
  static const String prefsRemoteRestUrl = 'ops_tenant_remote_rest_url';

  /// [prefsSchema]: Accept-Profile şeması
  static const String prefsSchema = 'ops_tenant_schema';

  /// [prefsApiKey]: Opsiyonel API key
  static const String prefsApiKey = 'ops_tenant_api_key';

  /// [prefsJwt]: Opsiyonel JWT
  static const String prefsJwt = 'ops_tenant_jwt';

  /// [prefsMerkezRestUrl]: Merkez registry URL
  static const String prefsMerkezRestUrl = 'ops_tenant_merkez_rest_url';

  /// [prefsDisplayName]: Görünen ad
  static const String prefsDisplayName = 'ops_tenant_display_name';

  /// [prefsResolvedAt]: Çözümleme zamanı
  static const String prefsResolvedAt = 'ops_tenant_resolved_at';

  /// [prefsSaasOrigin]: SaaS kök override
  static const String prefsSaasOrigin = 'ops_postgrest_saas_origin';

  /// Bellekteki aktif bağlam
  static TenantContext? _current;

  /// [current]: Son kaydedilen / yüklenen bağlam
  static TenantContext? get current => _current;

  /// {@macro tenant_store}
  const TenantStore();

  /// Prefs'ten yükler; belleği günceller.
  Future<TenantContext> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ctx = TenantContext(
      tenantCode: prefs.getString(prefsTenantCode) ?? '',
      remoteRestUrl: prefs.getString(prefsRemoteRestUrl) ?? '',
      schema: prefs.getString(prefsSchema) ??
          PostgrestTenantDefaults.defaultSchema,
      apiKey: prefs.getString(prefsApiKey),
      jwt: prefs.getString(prefsJwt),
      merkezRestUrl: prefs.getString(prefsMerkezRestUrl),
      displayName: prefs.getString(prefsDisplayName),
      resolvedAtIso: prefs.getString(prefsResolvedAt),
    );
    _current = ctx.isEmpty ? null : ctx;
    return ctx;
  }

  /// SaaS kök: dart-define > prefs override > varsayılan.
  Future<String> loadSaasOrigin() async {
    final defined = PostgrestTenantDefaults.webSaasOriginDefine
        .trim()
        .replaceAll(RegExp(r'/+$'), '');
    if (defined.isNotEmpty) return defined;
    final override = await loadSaasOriginOverride();
    return override.isEmpty
        ? PostgrestTenantDefaults.saasOrigin
        : override;
  }

  /// Prefs'teki ham override (boş = varsayılan kullanılıyor).
  Future<String> loadSaasOriginOverride() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(prefsSaasOrigin) ?? '').trim();
  }

  /// Override tanımlı mı?
  Future<bool> hasSaasOriginOverride() async {
    final o = await loadSaasOriginOverride();
    return o.isNotEmpty;
  }

  /// SaaS kökünü kaydeder.
  ///
  /// Origin değişince kayıtlı `remoteRestUrl` / merkez URL temizlenir
  /// (aynı kiracı kodu yeni kök altında yeniden çözümlensin).
  /// Boş kayıt → varsayılana döner (prefs anahtarı silinir).
  Future<void> saveSaasOrigin(String origin) async {
    final prefs = await SharedPreferences.getInstance();
    final previousRaw = (prefs.getString(prefsSaasOrigin) ?? '').trim();
    final previousEffective = previousRaw.isEmpty
        ? PostgrestTenantDefaults.effectiveSaasOrigin
        : previousRaw;
    final o = origin.trim().replaceAll(RegExp(r'/+$'), '');
    final nextEffective =
        o.isEmpty ? PostgrestTenantDefaults.effectiveSaasOrigin : o;

    if (o.isEmpty) {
      await prefs.remove(prefsSaasOrigin);
    } else {
      await prefs.setString(prefsSaasOrigin, o);
    }

    if (previousEffective != nextEffective) {
      await prefs.remove(prefsRemoteRestUrl);
      await prefs.remove(prefsMerkezRestUrl);
      // Bellek bağlamı geçersiz; kiracı kodu prefs'te kalır.
      _current = null;
    }
  }

  /// Bağlamı prefs + belleğe yazar.
  Future<void> save(TenantContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsTenantCode, context.tenantCode.trim());
    await prefs.setString(prefsRemoteRestUrl, context.remoteRestUrl.trim());
    await prefs.setString(
      prefsSchema,
      context.schema.trim().isEmpty
          ? PostgrestTenantDefaults.defaultSchema
          : context.schema.trim(),
    );

    await _setOrRemove(prefs, prefsApiKey, context.apiKey);
    await _setOrRemove(prefs, prefsJwt, context.jwt);
    await _setOrRemove(prefs, prefsMerkezRestUrl, context.merkezRestUrl);
    await _setOrRemove(prefs, prefsDisplayName, context.displayName);
    await _setOrRemove(prefs, prefsResolvedAt, context.resolvedAtIso);

    _current = context.isEmpty ? null : context;
  }

  /// Yalnızca kiracı kodunu hatırlar (URL henüz yoksa).
  Future<void> saveTenantCodeOnly(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsTenantCode, code.trim());
  }

  /// Kaydı temizler.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsTenantCode);
    await prefs.remove(prefsRemoteRestUrl);
    await prefs.remove(prefsSchema);
    await prefs.remove(prefsApiKey);
    await prefs.remove(prefsJwt);
    await prefs.remove(prefsMerkezRestUrl);
    await prefs.remove(prefsDisplayName);
    await prefs.remove(prefsResolvedAt);
    _current = null;
  }

  /// Test / sıcak reload için bellek sıfırlama.
  static void resetMemory() {
    _current = null;
  }

  Future<void> _setOrRemove(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, v);
    }
  }
}
