# Tenant Registry Logo Configuration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Kiracı koduyla merkez `tenant_registry` satırındaki
`logo_rest_api_url`, `logo_firm_nr`, `logo_period_nr`, `logo_db` ve
`updated_at` değerlerini güvenli, offline-first ve manuel ayarları koruyan Logo
REST başlangıç yapılandırmasına dönüştürmek.

**Architecture:** Merkez satırı `jsonDecode` kullanan tipli bir model/servisle
okunacak, tenant'a bağlı tek JSON cache kaydında tutulacak ve ayrı bir seeder
ile mevcut secret alanlar korunarak `LogoTigerSettingsStore`'a uygulanacak.
`PostgrestTenantService` aynı merkez yanıtını tenant URL çözümü için de
kullanacak; manuel Tiger ayarı, aktif firma/dönem seçimi ve mevcut fallback
zinciri önceliğini koruyacak.

**Tech Stack:** Flutter, Dart, `package:http`, SharedPreferences, Riverpod
olmayan mevcut store sınıfları, `flutter_test`, `http/testing`.

---

## Uygulama İlkeleri

- Tasarım kaynağı:
  `docs/plans/2026-07-29-tenant-registry-logo-config-design.md`
- Uygulama sırasında @test-driven-development ve
  @verification-before-completion becerilerini kullan.
- Her production değişikliğinden önce ilgili failing test yaz.
- Yeni Dart dosyalarında `.cursorrules` Türkçe dosya başlığı, sınıf/metot ve
  değişken dokümantasyonunu uygula.
- Registry'den secret okuma; `apiKey`, `password`, `clientId`,
  `clientSecret` ve access token'a dokunma.
- `logo_firm_nr` / `logo_period_nr` bootstrap varsayılanıdır;
  `ActiveCompanyStore` etkin seçimini değiştirme.
- UI'ya dokunma. Bu sürümde yeni kaynak etiketi ve yeni l10n anahtarı yok.
- Kullanıcının mevcut untracked `tmp_mbt_analysis/` ve
  `tmp_scrcpy_analysis/` dosyalarını stage etme.

### Kesin merkez sorgusu

```text
GET {saasOrigin}/merkez/tenant_registry
  ?code=eq.{uriEncodedTenantCode}
  &select=code,rest_base_url,display_name,is_active,logo_rest_api_url,
          logo_firm_nr,logo_period_nr,logo_db,updated_at
  &limit=1
```

Header:

```text
Accept: application/json
Accept-Profile: public
```

---

### Task 1: Tipli Tenant Registry Satırı

**Files:**
- Create: `lib/core/tenant/tenant_registry_row.dart`
- Create: `test/core/tenant/tenant_registry_row_test.dart`

**Step 1: Write the failing tests**

Tam satır, null Logo alanları, integer'ın string gelmesi ve geçersiz zorunlu
alan tiplerini kapsa:

```dart
void main() {
  group('TenantRegistryRow.fromJson', () {
    test('tam merkez satırını tipli modele çevirir', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'lovan',
        'rest_base_url': 'https://pg.example.com/lovan',
        'display_name': 'Lovan',
        'is_active': true,
        'logo_rest_api_url': 'http://logo.example/api/v1',
        'logo_firm_nr': 401,
        'logo_period_nr': 1,
        'logo_db': 'TIGER3',
        'updated_at': '2026-07-29T08:00:00Z',
      });

      expect(row.code, 'lovan');
      expect(row.logoRestApiUrl, 'http://logo.example/api/v1');
      expect(row.logoFirmNr, 401);
      expect(row.logoPeriodNr, 1);
      expect(row.logoDb, 'TIGER3');
      expect(row.updatedAt, DateTime.utc(2026, 7, 29, 8));
    });

    test('nullable Logo alanlarını kabul eder', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'aqua',
        'rest_base_url': null,
        'display_name': null,
        'is_active': true,
        'logo_rest_api_url': null,
        'logo_firm_nr': null,
        'logo_period_nr': null,
        'logo_db': null,
        'updated_at': null,
      });

      expect(row.logoRestApiUrl, isNull);
      expect(row.logoFirmNr, isNull);
      expect(row.updatedAt, isNull);
    });

    test('sayısal string firma ve dönemi kabul eder', () {
      final row = TenantRegistryRow.fromJson({
        'code': 'aqua',
        'is_active': true,
        'logo_firm_nr': '401',
        'logo_period_nr': '01',
      });

      expect(row.logoFirmNr, 401);
      expect(row.logoPeriodNr, 1);
    });

    test('code boşsa FormatException fırlatır', () {
      expect(
        () => TenantRegistryRow.fromJson({'code': '', 'is_active': true}),
        throwsFormatException,
      );
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/core/tenant/tenant_registry_row_test.dart
```

Expected: FAIL; `tenant_registry_row.dart` ve `TenantRegistryRow` henüz yok.

**Step 3: Write the minimal model**

Model immutable olsun. `fromJson` trim uygulasın, integer alanlarında yalnızca
pozitif değerleri kabul etsin ve `updated_at` için UTC'ye normalize edilmiş
`DateTime?` üretsin:

```dart
class TenantRegistryRow {
  final String code;
  final String? restBaseUrl;
  final String? displayName;
  final bool isActive;
  final String? logoRestApiUrl;
  final int? logoFirmNr;
  final int? logoPeriodNr;
  final String? logoDb;
  final DateTime? updatedAt;

  const TenantRegistryRow({
    required this.code,
    required this.isActive,
    this.restBaseUrl,
    this.displayName,
    this.logoRestApiUrl,
    this.logoFirmNr,
    this.logoPeriodNr,
    this.logoDb,
    this.updatedAt,
  });

  factory TenantRegistryRow.fromJson(Map<String, dynamic> json) {
    final code = _text(json['code']);
    if (code == null) {
      throw const FormatException('tenant_registry code boş');
    }
    return TenantRegistryRow(
      code: code,
      restBaseUrl: _text(json['rest_base_url']),
      displayName: _text(json['display_name']),
      isActive: json['is_active'] == true,
      logoRestApiUrl: _text(json['logo_rest_api_url']),
      logoFirmNr: _positiveInt(json['logo_firm_nr']),
      logoPeriodNr: _positiveInt(json['logo_period_nr']),
      logoDb: _text(json['logo_db']),
      updatedAt: _date(json['updated_at']),
    );
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int? _positiveInt(Object? value) {
    final parsed = value is int ? value : int.tryParse('${value ?? ''}');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static DateTime? _date(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toUtc();
  }
}
```

**Step 4: Run tests and analyze**

Run:

```bash
dart format lib/core/tenant/tenant_registry_row.dart \
  test/core/tenant/tenant_registry_row_test.dart
flutter test test/core/tenant/tenant_registry_row_test.dart
flutter analyze lib/core/tenant/tenant_registry_row.dart \
  test/core/tenant/tenant_registry_row_test.dart
```

Expected: PASS; analyze yeni hata üretmez.

**Step 5: Commit**

```bash
git add lib/core/tenant/tenant_registry_row.dart \
  test/core/tenant/tenant_registry_row_test.dart
git commit -m "feat(tenant): registry satır modelini ekle"
```

---

### Task 2: Merkez Tenant Registry HTTP Servisi

**Files:**
- Create: `lib/core/tenant/merkez_tenant_registry_service.dart`
- Create: `test/core/tenant/merkez_tenant_registry_service_test.dart`

**Step 1: Write the failing HTTP tests**

`MockClient` ile exact path, query ve header; başarılı satır, boş dizi,
inactive satır, HTTP 500, malformed JSON ve timeout senaryolarını yaz:

```dart
test('kiracı koduyla kesin kolonları ve limit 1 ister', () async {
  late http.Request captured;
  final client = MockClient((request) async {
    captured = request;
    return http.Response(
      '[{"code":"lovan","is_active":true,'
      '"logo_rest_api_url":"http://logo/api/v1",'
      '"logo_firm_nr":401,"logo_period_nr":1,'
      '"logo_db":"TIGER3","updated_at":"2026-07-29T08:00:00Z"}]',
      200,
    );
  });

  final row = await MerkezTenantRegistryService(
    client: client,
  ).fetch(
    tenantCode: 'lovan',
    saasOrigin: 'https://api.retailex.app',
  );

  expect(captured.url.path, '/merkez/tenant_registry');
  expect(captured.url.queryParameters['code'], 'eq.lovan');
  expect(captured.url.queryParameters['limit'], '1');
  expect(
    captured.url.queryParameters['select'],
    MerkezTenantRegistryService.selectColumns,
  );
  expect(captured.headers['Accept-Profile'], 'public');
  expect(row?.logoFirmNr, 401);
});

test('inactive satırı uygulanabilir sonuç olarak döndürmez', () async {
  final client = MockClient(
    (_) async => http.Response(
      '[{"code":"lovan","is_active":false}]',
      200,
    ),
  );

  final row = await MerkezTenantRegistryService(client: client).fetch(
    tenantCode: 'lovan',
    saasOrigin: 'https://api.retailex.app',
  );

  expect(row, isNull);
});
```

Diğer testlerin beklenen sonucu `null` olmalı; servis best-effort davranmalı ve
HTTP/parse hatasını login'e fırlatmamalı.

**Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/core/tenant/merkez_tenant_registry_service_test.dart
```

Expected: FAIL; servis henüz tanımlı değil.

**Step 3: Implement the service**

`Uri.replace(queryParameters: ...)` kullan; query string'i elle birleştirme:

```dart
class MerkezTenantRegistryService {
  static const String selectColumns =
      'code,rest_base_url,display_name,is_active,'
      'logo_rest_api_url,logo_firm_nr,logo_period_nr,logo_db,updated_at';

  final http.Client client;
  final Duration timeout;

  const MerkezTenantRegistryService({
    required this.client,
    this.timeout = const Duration(seconds: 4),
  });

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
      queryParameters: {
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
      debugPrint(
        'MerkezTenantRegistryService.fetch başarısız: '
        '${error.runtimeType}',
      );
      return null;
    }
  }
}
```

Log mesajına response body, tenant URL query'si veya secret koyma.

**Step 4: Run tests and analyze**

Run:

```bash
dart format lib/core/tenant/merkez_tenant_registry_service.dart \
  test/core/tenant/merkez_tenant_registry_service_test.dart
flutter test test/core/tenant/merkez_tenant_registry_service_test.dart
flutter analyze lib/core/tenant/merkez_tenant_registry_service.dart \
  test/core/tenant/merkez_tenant_registry_service_test.dart
```

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/core/tenant/merkez_tenant_registry_service.dart \
  test/core/tenant/merkez_tenant_registry_service_test.dart
git commit -m "feat(tenant): merkez registry servisini ekle"
```

---

### Task 3: Tenant'a Bağlı Logo Registry Cache'i

**Files:**
- Create: `lib/core/tenant/tenant_logo_config_cache.dart`
- Create: `lib/core/tenant/tenant_logo_config_store.dart`
- Create: `test/core/tenant/tenant_logo_config_store_test.dart`

**Step 1: Write the failing cache tests**

SharedPreferences mock ile round-trip, tenant izolasyonu, malformed JSON ve
clear testlerini yaz:

```dart
setUp(() {
  SharedPreferences.setMockInitialValues({});
});

test('Logo cache tüm kesin registry alanlarını round-trip eder', () async {
  const store = TenantLogoConfigStore();
  final cache = TenantLogoConfigCache(
    tenantCode: 'lovan',
    logoRestApiUrl: 'http://logo/api/v1',
    logoFirmNr: 401,
    logoPeriodNr: 1,
    logoDb: 'TIGER3',
    registryUpdatedAt: DateTime.utc(2026, 7, 29, 8),
    fetchedAt: DateTime.utc(2026, 7, 29, 9),
  );

  await store.save(cache);

  final loaded = await store.loadForTenant('LOVAN');
  expect(loaded?.logoFirmNr, 401);
  expect(loaded?.registryUpdatedAt, cache.registryUpdatedAt);
});

test('başka tenant cache kaydını okuyamaz', () async {
  const store = TenantLogoConfigStore();
  await store.save(
    TenantLogoConfigCache(
      tenantCode: 'lovan',
      fetchedAt: DateTime.utc(2026, 7, 29),
    ),
  );

  expect(await store.loadForTenant('aqua'), isNull);
});
```

**Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/core/tenant/tenant_logo_config_store_test.dart
```

Expected: FAIL; model/store yok.

**Step 3: Implement one-key JSON cache**

Kısmi SharedPreferences yazımını önlemek için tek JSON key kullan:

```dart
class TenantLogoConfigCache {
  final String tenantCode;
  final String? logoRestApiUrl;
  final int? logoFirmNr;
  final int? logoPeriodNr;
  final String? logoDb;
  final DateTime? registryUpdatedAt;
  final DateTime fetchedAt;

  const TenantLogoConfigCache({
    required this.tenantCode,
    required this.fetchedAt,
    this.logoRestApiUrl,
    this.logoFirmNr,
    this.logoPeriodNr,
    this.logoDb,
    this.registryUpdatedAt,
  });

  factory TenantLogoConfigCache.fromRegistry(
    TenantRegistryRow row, {
    required DateTime fetchedAt,
  }) {
    return TenantLogoConfigCache(
      tenantCode: row.code.trim().toLowerCase(),
      logoRestApiUrl: row.logoRestApiUrl,
      logoFirmNr: row.logoFirmNr,
      logoPeriodNr: row.logoPeriodNr,
      logoDb: row.logoDb,
      registryUpdatedAt: row.updatedAt,
      fetchedAt: fetchedAt.toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_code': tenantCode,
        'logo_rest_api_url': logoRestApiUrl,
        'logo_firm_nr': logoFirmNr,
        'logo_period_nr': logoPeriodNr,
        'logo_db': logoDb,
        'updated_at': registryUpdatedAt?.toIso8601String(),
        'fetched_at': fetchedAt.toIso8601String(),
      };

  factory TenantLogoConfigCache.fromJson(Map<String, dynamic> json) {
    final fetchedAt = DateTime.tryParse('${json['fetched_at'] ?? ''}');
    if (fetchedAt == null) throw const FormatException('fetched_at geçersiz');
    return TenantLogoConfigCache(
      tenantCode: '${json['tenant_code'] ?? ''}'.trim().toLowerCase(),
      logoRestApiUrl: json['logo_rest_api_url']?.toString(),
      logoFirmNr: json['logo_firm_nr'] as int?,
      logoPeriodNr: json['logo_period_nr'] as int?,
      logoDb: json['logo_db']?.toString(),
      registryUpdatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
      fetchedAt: fetchedAt.toUtc(),
    );
  }
}

class TenantLogoConfigStore {
  static const String prefsCache = 'ops_tenant_logo_registry_cache_v1';

  const TenantLogoConfigStore();

  Future<void> save(TenantLogoConfigCache cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsCache, jsonEncode(cache.toJson()));
  }

  Future<TenantLogoConfigCache?> loadForTenant(String tenantCode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsCache);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final cache = TenantLogoConfigCache.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return cache.tenantCode == tenantCode.trim().toLowerCase()
          ? cache
          : null;
    } on Object {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsCache);
  }
}
```

`fromJson` için null integer cast'lerini güvenli yardımcı metodla ele al;
malformed JSON testi production kodunu belirlesin.

**Step 4: Run tests and analyze**

Run:

```bash
dart format lib/core/tenant/tenant_logo_config_cache.dart \
  lib/core/tenant/tenant_logo_config_store.dart \
  test/core/tenant/tenant_logo_config_store_test.dart
flutter test test/core/tenant/tenant_logo_config_store_test.dart
flutter analyze lib/core/tenant/tenant_logo_config_cache.dart \
  lib/core/tenant/tenant_logo_config_store.dart \
  test/core/tenant/tenant_logo_config_store_test.dart
```

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/core/tenant/tenant_logo_config_cache.dart \
  lib/core/tenant/tenant_logo_config_store.dart \
  test/core/tenant/tenant_logo_config_store_test.dart
git commit -m "feat(tenant): Logo registry cache ekle"
```

---

### Task 4: Manuel Override Metadata'sı ve Logo Seeder

**Files:**
- Modify: `lib/core/logo/logo_tiger_settings_store.dart`
- Create: `lib/core/logo/logo_tenant_config_seeder.dart`
- Create: `test/core/logo/logo_tenant_config_seeder_test.dart`
- Modify: `lib/modules/field_sales/sync/view/logo_rest_settings_screen.dart:174-185`

**Step 1: Write failing seeder tests**

Test fixture'da Tiger store'a mevcut secret'ları yaz. İlk registry seed,
secret koruma, manuel override, daha eski/yeni `updated_at`, geçersiz URL ve
null alanların mevcut değeri silmemesini doğrula:

```dart
test('registry seed Logo alanlarını uygular ve secretları korur', () async {
  final tigerStore = LogoTigerSettingsStore();
  await tigerStore.save(
    const LogoTigerConfig(
      baseUrl: '',
      apiKey: 'api-secret',
      username: 'logo-user',
      password: 'password',
      clientId: 'client',
      clientSecret: 'client-secret',
      firmNr: 1,
      periodNr: 1,
    ),
    markManualOverride: false,
  );
  final cache = TenantLogoConfigCache(
    tenantCode: 'lovan',
    logoRestApiUrl: 'http://logo.example/api/v1',
    logoFirmNr: 401,
    logoPeriodNr: 2,
    logoDb: 'TIGER3',
    registryUpdatedAt: DateTime.utc(2026, 7, 29, 8),
    fetchedAt: DateTime.utc(2026, 7, 29, 9),
  );

  final applied = await LogoTenantConfigSeeder(
    tigerStore: tigerStore,
  ).apply(cache);
  final loaded = await tigerStore.loadRaw();

  expect(applied, isTrue);
  expect(loaded.normalizedBaseUrl, 'http://logo.example/api/v1');
  expect(loaded.firmNr, 401);
  expect(loaded.periodNr, 2);
  expect(loaded.logoDb, 'TIGER3');
  expect(loaded.apiKey, 'api-secret');
  expect(loaded.password, 'password');
});

test('manuel override registry tarafından ezilmez', () async {
  final tigerStore = LogoTigerSettingsStore();
  await tigerStore.save(
    const LogoTigerConfig(
      baseUrl: 'http://manual.example/api/v1',
      firmNr: 999,
    ),
  );

  final applied = await LogoTenantConfigSeeder(
    tigerStore: tigerStore,
  ).apply(registryCache);

  expect(applied, isFalse);
  expect((await tigerStore.loadRaw()).firmNr, 999);
});
```

**Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/core/logo/logo_tenant_config_seeder_test.dart
```

Expected: FAIL; seeder ve metadata API'si yok.

**Step 3: Add metadata without changing secret behavior**

`LogoTigerSettingsStore` içine şu key ve API'leri ekle:

```dart
static const String keyManualOverride = 'logo_tiger_manual_override';
static const String keyRegistryTenantCode =
    'logo_tiger_registry_tenant_code';
static const String keyRegistryUpdatedAt =
    'logo_tiger_registry_updated_at';

Future<bool> hasManualOverride() async {
  final prefs = await _prefs();
  return prefs.getBool(keyManualOverride) ?? false;
}

Future<void> save(
  LogoTigerConfig config, {
  bool markManualOverride = true,
}) async {
  // Mevcut save gövdesini aynen koru.
  // Gövdenin sonunda:
  await prefs.setBool(keyManualOverride, markManualOverride);
}

Future<void> markRegistrySeed({
  required String tenantCode,
  DateTime? updatedAt,
}) async {
  final prefs = await _prefs();
  await prefs.setBool(keyManualOverride, false);
  await prefs.setString(
    keyRegistryTenantCode,
    tenantCode.trim().toLowerCase(),
  );
  if (updatedAt == null) {
    await prefs.remove(keyRegistryUpdatedAt);
  } else {
    await prefs.setString(
      keyRegistryUpdatedAt,
      updatedAt.toUtc().toIso8601String(),
    );
  }
}
```

Seeder minimal birleştirme yapsın:

```dart
class LogoTenantConfigSeeder {
  final LogoTigerSettingsStore tigerStore;

  const LogoTenantConfigSeeder({
    required this.tigerStore,
  });

  Future<bool> apply(TenantLogoConfigCache cache) async {
    if (await tigerStore.hasManualOverride()) return false;
    final url = cache.logoRestApiUrl?.trim() ?? '';
    if (url.isEmpty || LogoTigerUrls.normalizeBaseUrl(url).isEmpty) {
      return false;
    }
    final current = await tigerStore.loadRaw();
    final next = current.copyWith(
      baseUrl: url,
      firmNr: cache.logoFirmNr ?? current.firmNr,
      periodNr: cache.logoPeriodNr ?? current.periodNr,
      logoDb: cache.logoDb?.trim().isNotEmpty == true
          ? cache.logoDb!.trim()
          : current.logoDb,
    );
    await tigerStore.save(next, markManualOverride: false);
    await tigerStore.markRegistrySeed(
      tenantCode: cache.tenantCode,
      updatedAt: cache.registryUpdatedAt,
    );
    return true;
  }
}
```

Seeder'a `lastRegistryUpdatedAt` okuması ekleyip eski/eşit registry
`updated_at` değerinin daha yeni seed'i ezmesini engelle. `updated_at` null ise
yalnızca daha önce registry seed'i yokken uygula.

Settings ekranındaki açık kullanıcı kaydı `save(tiger)` çağrısını korur; default
`markManualOverride: true` olduğu için davranış açıktır. Bridge'in
`syncFromServerSettings` içindeki kullanıcı kaynaklı kayıt çağrısı da manuel
kalır.

**Step 4: Run focused tests**

Run:

```bash
dart format lib/core/logo/logo_tiger_settings_store.dart \
  lib/core/logo/logo_tenant_config_seeder.dart \
  lib/modules/field_sales/sync/view/logo_rest_settings_screen.dart \
  test/core/logo/logo_tenant_config_seeder_test.dart
flutter test test/core/logo/logo_tenant_config_seeder_test.dart
flutter test test/core/logo/logo_server_url_bridge_test.dart
flutter analyze lib/core/logo/logo_tiger_settings_store.dart \
  lib/core/logo/logo_tenant_config_seeder.dart \
  lib/modules/field_sales/sync/view/logo_rest_settings_screen.dart
```

Expected: PASS; secret koruma ve override testleri geçer.

**Step 5: Commit**

```bash
git add lib/core/logo/logo_tiger_settings_store.dart \
  lib/core/logo/logo_tenant_config_seeder.dart \
  lib/modules/field_sales/sync/view/logo_rest_settings_screen.dart \
  test/core/logo/logo_tenant_config_seeder_test.dart
git commit -m "feat(logo): tenant registry seed politikasını ekle"
```

---

### Task 5: Registry Fetch, TTL ve Tenant Çözüm Entegrasyonu

**Files:**
- Modify: `lib/core/tenant/postgrest_tenant_service.dart`
- Modify: `test/core/tenant/postgrest_tenant_registry_probe_test.dart`

**Step 1: Replace regex expectations with failing integration tests**

Mevcut testlerde exact `select` beklentisini yeni sabite geçir. Şu yeni
senaryoları ekle:

```dart
test('registry Logo alanlarını cache ve Tiger storea seed eder', () async {
  final client = MockClient((_) async {
    return http.Response(
      '[{"code":"lovan",'
      '"rest_base_url":"https://pg.example.com/lovan",'
      '"is_active":true,'
      '"logo_rest_api_url":"http://logo.example/api/v1",'
      '"logo_firm_nr":401,"logo_period_nr":1,'
      '"logo_db":"TIGER3",'
      '"updated_at":"2026-07-29T08:00:00Z"}]',
      200,
    );
  });

  final result = await PostgrestTenantService(
    syncPostgres: false,
    httpClient: client,
  ).applyTenantCode('lovan');

  expect(result.ok, isTrue);
  final cache = await const TenantLogoConfigStore().loadForTenant('lovan');
  expect(cache?.logoFirmNr, 401);
  expect((await LogoTigerSettingsStore().loadRaw()).logoDb, 'TIGER3');
});

test('cached remote URL Logo registry fetchini atlatmaz', () async {
  var calls = 0;
  await const TenantStore().save(
    const TenantContext(
      tenantCode: 'lovan',
      remoteRestUrl: 'https://cached.example/lovan',
    ),
  );
  final client = MockClient((_) async {
    calls++;
    return http.Response(
      '[{"code":"lovan","is_active":true,'
      '"logo_rest_api_url":"http://logo/api/v1",'
      '"logo_firm_nr":401,"logo_period_nr":1}]',
      200,
    );
  });

  await PostgrestTenantService(
    syncPostgres: false,
    httpClient: client,
  ).applyTenantCode('lovan');

  expect(calls, 1);
});
```

TTL için `clock` bağımlılığı ekleme; constructor'a
`DateTime Function() now = DateTime.now` inject et. Cache taze ise çağrı yok,
TTL doluysa çağrı var, yenileme hatasında eski cache korunur testlerini ekle.
Varsayılan TTL: 15 dakika.

**Step 2: Run focused tests to verify they fail**

Run:

```bash
flutter test test/core/tenant/postgrest_tenant_registry_probe_test.dart
```

Expected: FAIL; Logo cache/seeder entegrasyonu ve yeni select yok.

**Step 3: Refactor `PostgrestTenantService`**

Eski `_tryResolveFromMerkezRegistry` regex metodunu kaldır. Constructor'a
test edilebilir bağımlılıklar ekle:

```dart
final TenantLogoConfigStore logoConfigStore;
final LogoTenantConfigSeeder logoSeeder;
final DateTime Function() now;
final Duration registryCacheTtl;

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
          LogoTenantConfigSeeder(
            tigerStore: LogoTigerSettingsStore(),
          ),
      now = now ?? DateTime.now;
```

`applyTenantCode` içinde remote URL cache dalından bağımsız Logo bootstrap
çalıştır:

```dart
final registryRow = await _fetchRegistryIfNeeded(
  resolved.tenantCode,
  saasOrigin: saasOrigin,
);
if (registryRow?.restBaseUrl?.trim().isNotEmpty == true) {
  final normalized = TenantConnectionResolver.normalizeBaseUrl(
    registryRow!.restBaseUrl!,
  );
  resolved = resolved.copyWith(
    remoteRestUrl: TenantConnectionResolver.rewriteRestUrlForSaasOrigin(
      normalized,
      saasOrigin: saasOrigin,
    ),
    source: 'tenant_registry',
  );
} else if (cached tenant URL koşulu) {
  // Mevcut cached remote URL davranışını koru.
}
```

`_fetchRegistryIfNeeded` algoritması:

1. Aktif tenant Logo cache'ini yükle.
2. Cache tazeyse seeder'a uygula ve HTTP yapmadan `null` döndür.
3. `httpClient == null` ise cache'i uygula ve `null` döndür.
4. `MerkezTenantRegistryService.fetch` çağır.
5. Satır geldiyse `TenantLogoConfigCache.fromRegistry` oluştur, kaydet, seed
   et ve satırı döndür.
6. Fetch başarısızsa eski cache'i seed et, `null` döndür.

Önemli: Registry başarısızken mevcut cached `remoteRestUrl` korunmalı; SaaS
slug ile üzerine yazılmamalı.

**Step 4: Run tenant regression tests**

Run:

```bash
dart format lib/core/tenant/postgrest_tenant_service.dart \
  test/core/tenant/postgrest_tenant_registry_probe_test.dart
flutter test test/core/tenant/
flutter analyze lib/core/tenant/postgrest_tenant_service.dart \
  test/core/tenant/postgrest_tenant_registry_probe_test.dart
```

Expected: Tüm tenant testleri PASS. Eski
`aynı kod cache → registry çağrılmaz` testi yeni TTL politikasına göre
`taze Logo cache → registry çağrılmaz` olarak güncellenmiş olmalı.

**Step 5: Commit**

```bash
git add lib/core/tenant/postgrest_tenant_service.dart \
  test/core/tenant/postgrest_tenant_registry_probe_test.dart
git commit -m "feat(tenant): registry Logo bootstrapını bağla"
```

---

### Task 6: Logo Endpoint Kaynak Önceliği ve Offline Restore

**Files:**
- Modify: `lib/core/logo/logo_server_url_bridge.dart`
- Modify: `test/core/logo/logo_server_url_bridge_test.dart`
- Modify: `lib/core/tenant/postgrest_tenant_service.dart`
- Modify: `lib/view/auto_login_bootstrap.dart:96-109`
- Create: `test/core/tenant/postgrest_tenant_logo_restore_test.dart`

**Step 1: Write failing priority and restore tests**

Kaynak sırasını açıkça doğrula:

```dart
test('manuel Tiger URL registry seedinden önceliklidir', () async {
  final store = LogoTigerSettingsStore();
  await store.save(
    const LogoTigerConfig(
      baseUrl: 'http://manual.example/api/v1',
      apiKey: 'secret',
    ),
  );

  final resolved = await LogoServerUrlBridge.resolve();

  expect(resolved.source, LogoUrlSource.tigerStore);
  expect(resolved.baseUrl, 'http://manual.example/api/v1');
});

test('registry seed kaynak bilgisini tenantRegistry döndürür', () async {
  final store = LogoTigerSettingsStore();
  await store.save(
    const LogoTigerConfig(baseUrl: 'http://registry.example/api/v1'),
    markManualOverride: false,
  );
  await store.markRegistrySeed(
    tenantCode: 'lovan',
    updatedAt: DateTime.utc(2026, 7, 29),
  );
  await const TenantStore().save(
    const TenantContext(
      tenantCode: 'lovan',
      remoteRestUrl: 'https://api.retailex.app/lovan',
    ),
  );

  final resolved = await LogoServerUrlBridge.resolve();

  expect(resolved.source, LogoUrlSource.tenantRegistry);
});
```

Restore testinde HTTP client olmadan Tenant Logo cache'inin seeder'a yeniden
uygulandığını doğrula.

**Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/core/logo/logo_server_url_bridge_test.dart
flutter test test/core/tenant/postgrest_tenant_logo_restore_test.dart
```

Expected: FAIL; `tenantRegistry` enum değeri ve restore seed'i yok.

**Step 3: Implement source metadata and offline restore**

`LogoUrlSource` enum'una `tenantRegistry` ekle. Tiger base URL doluyken kaynak
seçimi:

```dart
final tigerStore = LogoTigerSettingsStore();
final tiger = tigerOverride ?? await tigerStore.loadRaw();
if (tiger.baseUrl.trim().isNotEmpty) {
  final manual = tigerOverride != null ||
      await tigerStore.hasManualOverride();
  return LogoResolvedEndpoint(
    baseUrl: LogoTigerUrls.normalizeBaseUrl(tiger.baseUrl),
    apiKey: tiger.apiKey,
    source: manual
        ? LogoUrlSource.tigerStore
        : LogoUrlSource.tenantRegistry,
  );
}
```

`restoreActiveContext` tenant context'i yükledikten sonra aynı tenant'a ait
`TenantLogoConfigStore` cache'ini yükleyip seeder'a uygulasın:

```dart
final logoCache = await logoConfigStore.loadForTenant(ctx.tenantCode);
if (logoCache != null) {
  await logoSeeder.apply(logoCache);
}
```

`AutoLoginBootstrap._restoreContext` mevcut
`PostgrestTenantService().restoreActiveContext()` çağrısını korur. Ağ
yenilemesi login/apply akışında TTL ile yapılır; auto-login'i ağ beklemesine
bağlama. Bu dosyada production kod değişikliği gerekmiyorsa stage etme ve
commit'e dahil etme.

**Step 4: Run Logo and restore regression tests**

Run:

```bash
dart format lib/core/logo/logo_server_url_bridge.dart \
  lib/core/tenant/postgrest_tenant_service.dart \
  test/core/logo/logo_server_url_bridge_test.dart \
  test/core/tenant/postgrest_tenant_logo_restore_test.dart
flutter test test/core/logo/
flutter test test/core/tenant/
flutter analyze lib/core/logo/logo_server_url_bridge.dart \
  lib/core/tenant/postgrest_tenant_service.dart
```

Expected: PASS.

**Step 5: Commit**

```bash
git add lib/core/logo/logo_server_url_bridge.dart \
  lib/core/tenant/postgrest_tenant_service.dart \
  test/core/logo/logo_server_url_bridge_test.dart \
  test/core/tenant/postgrest_tenant_logo_restore_test.dart
git commit -m "feat(logo): registry kaynak önceliğini tamamla"
```

---

### Task 7: Muhasebe ve Saha Satış Güvenlik Regresyonları

**Files:**
- Modify: `test/core/logo/logo_tiger_rest_client_test.dart`
- Modify: `test/core/logo/logo_tenant_config_seeder_test.dart`
- Modify: `test/core/tenant/postgrest_tenant_registry_probe_test.dart`

**Step 1: Add failing domain regression tests**

Şunları doğrudan assert et:

1. Registry `logo_firm_nr=401`, `logo_period_nr=1` seed eder.
2. Kullanıcı daha sonra firma/dönem seçtiğinde
   `ActiveCompanyStore`/client çağrısında etkin seçim kullanılır; registry
   değerleri seçimi sessizce değiştirmez.
3. Tenant `lovan` cache'i `aqua` girişinde uygulanmaz.
4. `is_active=false` Logo store'u değiştirmez.
5. Registry yanıtı secret benzeri ekstra kolonlar içerse bile model/store
   bunları taşımaz.
6. `loadSafeSnapshot()` secret değerleri değil yalnızca boolean varlık
   bilgilerini döndürür.

Örnek secret testi:

```dart
test('registry seed safe snapshotta secret sızdırmaz', () async {
  final store = LogoTigerSettingsStore();
  await store.save(
    const LogoTigerConfig(
      baseUrl: '',
      apiKey: 'api-secret',
      password: 'password-secret',
      clientId: 'client-id',
      clientSecret: 'client-secret',
    ),
    markManualOverride: false,
  );

  await LogoTenantConfigSeeder(tigerStore: store).apply(registryCache);
  final snapshot = await store.loadSafeSnapshot();

  expect(snapshot.toString(), isNot(contains('api-secret')));
  expect(snapshot.toString(), isNot(contains('password-secret')));
  expect(snapshot['hasApiKey'], isTrue);
  expect(snapshot['hasPassword'], isTrue);
});
```

**Step 2: Run tests to verify any missing guarantees fail**

Run:

```bash
flutter test test/core/logo/logo_tiger_rest_client_test.dart
flutter test test/core/logo/logo_tenant_config_seeder_test.dart
flutter test test/core/tenant/postgrest_tenant_registry_probe_test.dart
```

Expected: Yeni testlerden en az biri önce FAIL; mevcut davranışta garanti
eksikliği görünür.

**Step 3: Implement only minimal fixes**

Testin gösterdiği eksikliği ilgili domain sınıfında düzelt. Şu sınırları koru:

- `ActiveCompanyStore` seçimini registry seed'inden güncelleme.
- Job queue migration veya yeni UI ekleme.
- Registry response body'yi loglama.
- Secret alanları tenant model/cache'e ekleme.

**Step 4: Run domain suites**

Run:

```bash
dart format test/core/logo/logo_tiger_rest_client_test.dart \
  test/core/logo/logo_tenant_config_seeder_test.dart \
  test/core/tenant/postgrest_tenant_registry_probe_test.dart
flutter test test/core/logo/
flutter test test/core/tenant/
flutter test test/modules/field_sales/companies/
```

Expected: PASS. Son test yolu repoda yoksa önce `test/modules/field_sales`
altındaki mevcut company test yolunu `rg --files` ile belirle; olmayan yolu
komuta ekleme.

**Step 5: Commit**

```bash
git add test/core/logo/logo_tiger_rest_client_test.dart \
  test/core/logo/logo_tenant_config_seeder_test.dart \
  test/core/tenant/postgrest_tenant_registry_probe_test.dart
git add <yalnızca-testlerin-gerektirdiği-production-dosyaları>
git commit -m "test(logo): tenant firma dönem sınırlarını doğrula"
```

---

### Task 8: Dokümantasyon ve Tam Doğrulama

**Files:**
- Modify: `docs/plans/2026-07-26-postgrest-tenant-login.md`
- Modify: `lib/core/logo/README.md`
- Modify: `lib/core/tenant/README.md` (yalnızca mevcutsa)

**Step 1: Update architecture documentation**

Şunları belgele:

- kesin registry kolonları;
- endpoint/header ve mevcut anonim erişim riski;
- manuel Tiger > tenant registry > Logo REST > `api_config` önceliği;
- TTL/offline cache davranışı;
- registry firma/döneminin bootstrap, kullanıcı seçiminin etkin kaynak olması;
- secret alanların registry kapsamı dışında olması.

Yeni README oluşturma; yalnızca var olan klasör README'sini güncelle.

**Step 2: Verify formatting and static analysis**

Run:

```bash
dart format --output=none --set-exit-if-changed \
  lib/core/tenant lib/core/logo \
  test/core/tenant test/core/logo
flutter analyze lib/core/tenant lib/core/logo \
  test/core/tenant test/core/logo
```

Expected: exit 0.

**Step 3: Run focused and full regression tests**

Run:

```bash
flutter test test/core/tenant/
flutter test test/core/logo/
flutter test
```

Expected: tüm komutlar PASS. Full suite'te önceden var olan unrelated hata
çıkarsa tam komutu, test adını ve bunun bu diff ile ilişkisini kaydet; hatayı
gizleme.

**Step 4: Inspect diff and secret safety**

Run:

```bash
git diff --check
git diff --stat
git status --short
rg -n "logo_rest_api_url|logo_firm_nr|logo_period_nr|logo_db|updated_at" \
  lib/core/tenant lib/core/logo test/core/tenant test/core/logo
rg -n "api_key|client_secret|password|access_token" \
  lib/core/tenant/tenant_registry_row.dart \
  lib/core/tenant/tenant_logo_config_cache.dart
```

Expected:

- `git diff --check` temiz.
- Son `rg` komutu yeni tenant registry model/cache dosyalarında eşleşme
  döndürmez.
- `tmp_mbt_analysis/` ve `tmp_scrcpy_analysis/` stage edilmemiştir.

**Step 5: Commit documentation**

```bash
git add docs/plans/2026-07-26-postgrest-tenant-login.md
test -f lib/core/logo/README.md && git add lib/core/logo/README.md
test -f lib/core/tenant/README.md && git add lib/core/tenant/README.md
git commit -m "docs: tenant Logo kaynak politikasını güncelle"
```

---

## Uygulama Sonu Kontrol Listesi

- [ ] Merkez sorgusu kesin beş Logo kolonunu ve `updated_at` alanını ister.
- [ ] Regex parse tamamen kaldırılmıştır.
- [ ] Inactive/boş/bozuk registry mevcut fallback'i bozmaz.
- [ ] Aynı tenant remote URL cache'i Logo bootstrap'ını atlatmaz.
- [ ] Taze Logo cache'i gereksiz HTTP çağrısını engeller.
- [ ] Offline restore tenant'a ait cache'i uygular.
- [ ] Manuel Tiger ayarı registry tarafından ezilmez.
- [ ] Secret alanlar registry modelinde/cache'inde yoktur.
- [ ] Firma/dönem registry'den bootstrap olur; aktif kullanıcı seçimi korunur.
- [ ] Farklı tenant cache'i uygulanmaz.
- [ ] UI redesign ve yeni hardcoded metin yoktur.
- [ ] Focused testler, analyze ve mümkünse tam `flutter test` geçer.
- [ ] Kullanıcının mevcut untracked dosyaları stage edilmemiştir.

## Execution Handoff

Plan complete and saved to
`docs/plans/2026-07-29-tenant-registry-logo-config.md`. Two execution options:

**1. Subagent-Driven (this session)** - Her task için yeni uygulama ajanı,
task aralarında inceleme ve hızlı iterasyon. REQUIRED SUB-SKILL:
superpowers:subagent-driven-development.

**2. Parallel Session (separate)** - Ayrı worktree/session açıp
superpowers:executing-plans ile checkpoint'ler halinde uygulama.

