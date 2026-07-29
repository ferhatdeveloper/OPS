// Dosya Adı: logo_tenant_config_seeder_test.dart
// Açıklama: Tenant registry → Logo Tiger seed politikası birim testleri
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exfin_ops/core/logo/logo_tenant_config_seeder.dart';
import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_settings_store.dart';
import 'package:exfin_ops/core/tenant/tenant_logo_config_cache.dart';

/// [_registryCache]: Varsayılan test registry cache kaydı.
TenantLogoConfigCache _registryCache({
  String tenantCode = 'lovan',
  String? url = 'http://logo.example:32001/api/v1',
  int? firmNr = 401,
  int? periodNr = 2,
  String? logoDb = 'TIGER3',
  DateTime? updatedAt,
  DateTime? fetchedAt,
}) {
  return TenantLogoConfigCache(
    tenantCode: tenantCode,
    logoRestApiUrl: url,
    logoFirmNr: firmNr,
    logoPeriodNr: periodNr,
    logoDb: logoDb,
    registryUpdatedAt: updatedAt ?? DateTime.utc(2026, 7, 29, 8),
    fetchedAt: fetchedAt ?? DateTime.utc(2026, 7, 29, 9),
  );
}

/// [_seedSecrets]: Tiger store'a secret dolu bir başlangıç kaydı yazar.
Future<LogoTigerSettingsStore> _seedSecrets({
  String baseUrl = '',
  int firmNr = 1,
  int periodNr = 1,
  String? logoDb,
}) async {
  final store = LogoTigerSettingsStore();
  await store.save(
    LogoTigerConfig(
      baseUrl: baseUrl,
      apiKey: 'api-secret',
      username: 'logo-user',
      password: 'password-secret',
      clientId: 'client-id',
      clientSecret: 'client-secret',
      firmNr: firmNr,
      periodNr: periodNr,
      logoDb: logoDb,
    ),
    markManualOverride: false,
  );
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LogoTenantConfigSeeder.apply', () {
    test('registry seed Logo alanlarını uygular ve secretları korur', () async {
      final tigerStore = await _seedSecrets();

      final applied = await LogoTenantConfigSeeder(
        tigerStore: tigerStore,
      ).apply(_registryCache());
      final loaded = await tigerStore.loadRaw();

      expect(applied, isTrue);
      expect(loaded.normalizedBaseUrl, 'http://logo.example:32001/api/v1');
      expect(loaded.firmNr, 401);
      expect(loaded.periodNr, 2);
      expect(loaded.logoDb, 'TIGER3');
      expect(loaded.apiKey, 'api-secret');
      expect(loaded.username, 'logo-user');
      expect(loaded.password, 'password-secret');
      expect(loaded.clientId, 'client-id');
      expect(loaded.clientSecret, 'client-secret');
    });

    test('registry seed manuel override işaretini set etmez', () async {
      final tigerStore = await _seedSecrets();

      await LogoTenantConfigSeeder(tigerStore: tigerStore)
          .apply(_registryCache());

      expect(await tigerStore.hasManualOverride(), isFalse);
    });

    test('registry seed access tokena dokunmaz', () async {
      final tigerStore = await _seedSecrets();
      await tigerStore.saveAccessToken(
        'token-secret',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      await LogoTenantConfigSeeder(tigerStore: tigerStore)
          .apply(_registryCache());

      expect(await tigerStore.getAccessToken(), 'token-secret');
    });

    test('manuel override registry tarafından ezilmez', () async {
      final tigerStore = LogoTigerSettingsStore();
      await tigerStore.save(
        const LogoTigerConfig(
          baseUrl: 'http://manual.example:32001/api/v1',
          firmNr: 999,
        ),
      );

      final applied = await LogoTenantConfigSeeder(
        tigerStore: tigerStore,
      ).apply(_registryCache());
      final loaded = await tigerStore.loadRaw();

      expect(applied, isFalse);
      expect(loaded.firmNr, 999);
      expect(loaded.normalizedBaseUrl, 'http://manual.example:32001/api/v1');
    });

    test('boş Logo URL seed yapmaz', () async {
      final tigerStore = await _seedSecrets();

      final applied = await LogoTenantConfigSeeder(
        tigerStore: tigerStore,
      ).apply(_registryCache(url: null));

      expect(applied, isFalse);
      expect((await tigerStore.loadRaw()).firmNr, 1);
    });

    test('geçersiz Logo URL seed yapmaz', () async {
      final tigerStore = await _seedSecrets();

      final applied = await LogoTenantConfigSeeder(
        tigerStore: tigerStore,
      ).apply(_registryCache(url: '://'));

      expect(applied, isFalse);
      expect((await tigerStore.loadRaw()).baseUrl, isEmpty);
    });

    test('null firma / dönem mevcut değerleri silmez', () async {
      final tigerStore = await _seedSecrets(firmNr: 7, periodNr: 3);

      final applied = await LogoTenantConfigSeeder(
        tigerStore: tigerStore,
      ).apply(_registryCache(firmNr: null, periodNr: null));
      final loaded = await tigerStore.loadRaw();

      expect(applied, isTrue);
      expect(loaded.firmNr, 7);
      expect(loaded.periodNr, 3);
    });

    test('boş logo_db mevcut değeri silmez', () async {
      final tigerStore = await _seedSecrets(logoDb: 'MEVCUT');

      await LogoTenantConfigSeeder(tigerStore: tigerStore)
          .apply(_registryCache(logoDb: null));

      expect((await tigerStore.loadRaw()).logoDb, 'MEVCUT');
    });

    test('daha yeni registry updated_at seedi yeniler', () async {
      final tigerStore = await _seedSecrets();
      final seeder = LogoTenantConfigSeeder(tigerStore: tigerStore);

      await seeder.apply(
        _registryCache(updatedAt: DateTime.utc(2026, 7, 29, 8)),
      );
      final applied = await seeder.apply(
        _registryCache(
          url: 'http://yeni.example:32001/api/v1',
          firmNr: 555,
          updatedAt: DateTime.utc(2026, 7, 30, 8),
        ),
      );
      final loaded = await tigerStore.loadRaw();

      expect(applied, isTrue);
      expect(loaded.firmNr, 555);
      expect(loaded.normalizedBaseUrl, 'http://yeni.example:32001/api/v1');
    });

    test('eski registry updated_at daha yeni seedi ezmez', () async {
      final tigerStore = await _seedSecrets();
      final seeder = LogoTenantConfigSeeder(tigerStore: tigerStore);

      await seeder.apply(
        _registryCache(updatedAt: DateTime.utc(2026, 7, 30, 8)),
      );
      final applied = await seeder.apply(
        _registryCache(
          url: 'http://eski.example:32001/api/v1',
          firmNr: 111,
          updatedAt: DateTime.utc(2026, 7, 29, 8),
        ),
      );
      final loaded = await tigerStore.loadRaw();

      expect(applied, isFalse);
      expect(loaded.firmNr, 401);
      expect(loaded.normalizedBaseUrl, 'http://logo.example:32001/api/v1');
    });

    test('aynı registry updated_at tekrar seed etmez', () async {
      final tigerStore = await _seedSecrets();
      final seeder = LogoTenantConfigSeeder(tigerStore: tigerStore);
      final at = DateTime.utc(2026, 7, 29, 8);

      await seeder.apply(_registryCache(updatedAt: at));
      final applied = await seeder.apply(_registryCache(updatedAt: at));

      expect(applied, isFalse);
    });

    test('updated_at null ise yalnızca ilk seedde uygulanır', () async {
      final tigerStore = await _seedSecrets();
      final seeder = LogoTenantConfigSeeder(tigerStore: tigerStore);

      final first = await seeder.apply(
        _registryCache(updatedAt: null, url: 'http://ilk.example:32001'),
      );
      final second = await seeder.apply(
        _registryCache(updatedAt: null, url: 'http://ikinci.example:32001'),
      );

      expect(first, isTrue);
      expect(second, isFalse);
      expect(
        (await tigerStore.loadRaw()).normalizedBaseUrl,
        'http://ilk.example:32001/api/v1',
      );
    });

    test('farklı tenant cachei eski updated_at ile de uygulanır', () async {
      final tigerStore = await _seedSecrets();
      final seeder = LogoTenantConfigSeeder(tigerStore: tigerStore);

      await seeder.apply(
        _registryCache(
          tenantCode: 'lovan',
          updatedAt: DateTime.utc(2026, 7, 30, 8),
        ),
      );
      final applied = await seeder.apply(
        _registryCache(
          tenantCode: 'aqua',
          url: 'http://aqua.example:32001/api/v1',
          firmNr: 22,
          updatedAt: DateTime.utc(2026, 7, 20, 8),
        ),
      );
      final loaded = await tigerStore.loadRaw();

      expect(applied, isTrue);
      expect(loaded.firmNr, 22);
      expect(loaded.normalizedBaseUrl, 'http://aqua.example:32001/api/v1');
    });

    test('seed sonrası registry işareti tenant ve tarihi saklar', () async {
      final tigerStore = await _seedSecrets();

      await LogoTenantConfigSeeder(tigerStore: tigerStore).apply(
        _registryCache(updatedAt: DateTime.utc(2026, 7, 29, 8)),
      );
      final mark = await tigerStore.lastRegistrySeed();

      expect(mark.tenantCode, 'lovan');
      expect(mark.updatedAt, DateTime.utc(2026, 7, 29, 8));
    });

    test('kullanıcı manuel kaydı registry işaretini geçersiz kılar', () async {
      final tigerStore = await _seedSecrets();
      final seeder = LogoTenantConfigSeeder(tigerStore: tigerStore);
      await seeder.apply(_registryCache());

      await tigerStore.save(
        const LogoTigerConfig(
          baseUrl: 'http://manual.example:32001/api/v1',
          firmNr: 999,
        ),
      );
      final applied = await seeder.apply(
        _registryCache(updatedAt: DateTime.utc(2026, 8, 1)),
      );

      expect(await tigerStore.hasManualOverride(), isTrue);
      expect(applied, isFalse);
      expect((await tigerStore.loadRaw()).firmNr, 999);
    });

    test('force manuel overrideı kullanıcı onayıyla ezer', () async {
      final tigerStore = await _seedSecrets();
      await tigerStore.save(
        const LogoTigerConfig(
          baseUrl: 'http://manual.example:32001/api/v1',
          apiKey: 'api-secret',
          username: 'logo-user',
          password: 'password-secret',
          clientId: 'client-id',
          clientSecret: 'client-secret',
          firmNr: 999,
        ),
      );

      final applied = await LogoTenantConfigSeeder(
        tigerStore: tigerStore,
      ).apply(_registryCache(), force: true);
      final loaded = await tigerStore.loadRaw();

      expect(applied, isTrue);
      expect(loaded.normalizedBaseUrl, 'http://logo.example:32001/api/v1');
      expect(loaded.firmNr, 401);
      expect(loaded.periodNr, 2);
      expect(await tigerStore.hasManualOverride(), isFalse);
      expect(loaded.apiKey, 'api-secret');
      expect(loaded.password, 'password-secret');
      expect(loaded.clientSecret, 'client-secret');
    });

    test('force aynı updated_at ile tekrar uygulanır', () async {
      final tigerStore = await _seedSecrets();
      final seeder = LogoTenantConfigSeeder(tigerStore: tigerStore);
      final at = DateTime.utc(2026, 7, 29, 8);
      await seeder.apply(_registryCache(updatedAt: at));

      final applied = await seeder.apply(
        _registryCache(
          updatedAt: at,
          url: 'http://tekrar.example:32001/api/v1',
        ),
        force: true,
      );

      expect(applied, isTrue);
      expect(
        (await tigerStore.loadRaw()).normalizedBaseUrl,
        'http://tekrar.example:32001/api/v1',
      );
    });

    test('force geçersiz Logo URLi yine uygulamaz', () async {
      final tigerStore = await _seedSecrets(baseUrl: 'http://var.example:32001');

      final applied = await LogoTenantConfigSeeder(
        tigerStore: tigerStore,
      ).apply(_registryCache(url: '://'), force: true);

      expect(applied, isFalse);
    });

    test('registry seed safe snapshotta secret sızdırmaz', () async {
      final tigerStore = await _seedSecrets();

      await LogoTenantConfigSeeder(tigerStore: tigerStore)
          .apply(_registryCache());
      final snapshot = await tigerStore.loadSafeSnapshot();

      expect(snapshot.toString(), isNot(contains('api-secret')));
      expect(snapshot.toString(), isNot(contains('password-secret')));
      expect(snapshot.toString(), isNot(contains('client-secret')));
      expect(snapshot['hasApiKey'], isTrue);
      expect(snapshot['hasPassword'], isTrue);
      expect(snapshot['hasClientId'], isTrue);
      expect(snapshot['hasClientSecret'], isTrue);
    });
  });

  group('LogoTigerSettingsStore manuel override metadatası', () {
    test('varsayılan save manuel override işaretler', () async {
      final store = LogoTigerSettingsStore();

      await store.save(
        const LogoTigerConfig(baseUrl: 'http://manual.example:32001'),
      );

      expect(await store.hasManualOverride(), isTrue);
    });

    test('markManualOverride false işareti kaldırır', () async {
      final store = LogoTigerSettingsStore();
      await store.save(
        const LogoTigerConfig(baseUrl: 'http://manual.example:32001'),
      );

      await store.save(
        const LogoTigerConfig(baseUrl: 'http://registry.example:32001'),
        markManualOverride: false,
      );

      expect(await store.hasManualOverride(), isFalse);
    });

    test('hiç kayıt yokken manuel override false döner', () async {
      expect(await LogoTigerSettingsStore().hasManualOverride(), isFalse);
    });

    test('markRegistrySeed null updated_at kaydını temizler', () async {
      final store = LogoTigerSettingsStore();
      await store.markRegistrySeed(
        tenantCode: 'LOVAN',
        updatedAt: DateTime.utc(2026, 7, 29, 8),
      );

      await store.markRegistrySeed(tenantCode: 'lovan');
      final mark = await store.lastRegistrySeed();

      expect(mark.tenantCode, 'lovan');
      expect(mark.updatedAt, isNull);
    });
  });
}
