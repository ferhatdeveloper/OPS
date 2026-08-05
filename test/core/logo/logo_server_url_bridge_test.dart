// Dosya Adı: logo_server_url_bridge_test.dart
// Açıklama: Sunucu URL → Logo çözümleme birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:exfin_ops/core/logo/logo_server_url_bridge.dart';
import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mergeIntoConfig: boş tiger → özel test default host', () async {
    const cfg = LogoTigerConfig(baseUrl: '');
    final merged = await LogoServerUrlBridge.mergeIntoConfig(cfg);
    expect(merged.baseUrl, contains('185.206.80.132'));
    expect(merged.apiKey, isNotEmpty);
  });

  test('mergeIntoConfig: dolu tiger dokunulmaz', () async {
    const cfg = LogoTigerConfig(
      baseUrl: 'http://192.0.2.10:32001',
      apiKey: 'k',
    );
    final merged = await LogoServerUrlBridge.mergeIntoConfig(cfg);
    expect(merged.baseUrl, contains('32001'));
    expect(merged.apiKey, 'k');
  });

  group('resolve kaynak önceliği', () {
    test('manuel Tiger URL registry seedinden önceliklidir', () async {
      final store = LogoTigerSettingsStore();
      await store.save(
        const LogoTigerConfig(
          baseUrl: 'http://manual.example:32001/api/v1',
          apiKey: 'secret',
        ),
      );

      final resolved = await LogoServerUrlBridge.resolve();

      expect(resolved.source, LogoUrlSource.tigerStore);
      expect(resolved.baseUrl, 'http://manual.example:32001/api/v1');
    });

    test('registry seed kaynak bilgisini tenantRegistry döndürür', () async {
      final store = LogoTigerSettingsStore();
      await store.save(
        const LogoTigerConfig(baseUrl: 'http://registry.example:32001/api/v1'),
        markManualOverride: false,
      );
      await store.markRegistrySeed(
        tenantCode: 'lovan',
        updatedAt: DateTime.utc(2026, 7, 29),
      );

      final resolved = await LogoServerUrlBridge.resolve();

      expect(resolved.source, LogoUrlSource.tenantRegistry);
      expect(resolved.baseUrl, 'http://registry.example:32001/api/v1');
    });

    test('tigerOverride verildiğinde kaynak manuel kabul edilir', () async {
      final store = LogoTigerSettingsStore();
      await store.save(
        const LogoTigerConfig(baseUrl: 'http://registry.example:32001/api/v1'),
        markManualOverride: false,
      );
      await store.markRegistrySeed(tenantCode: 'lovan');

      final resolved = await LogoServerUrlBridge.resolve(
        tigerOverride: const LogoTigerConfig(
          baseUrl: 'http://override.example:32001/api/v1',
        ),
      );

      expect(resolved.source, LogoUrlSource.tigerStore);
      expect(resolved.baseUrl, 'http://override.example:32001/api/v1');
    });

    test('Tiger URL boşsa özel test default host kullanılır', () async {
      final resolved = await LogoServerUrlBridge.resolve(
        tigerOverride: const LogoTigerConfig(baseUrl: ''),
      );

      expect(resolved.baseUrl, contains('185.206.80.132'));
      expect(resolved.source, LogoUrlSource.tigerStore);
      expect(resolved.apiKey, isNotEmpty);
    });

    test('registry seed sonrası manuel kayıt kaynağı tigerStore yapar',
        () async {
      final store = LogoTigerSettingsStore();
      await store.save(
        const LogoTigerConfig(baseUrl: 'http://registry.example:32001/api/v1'),
        markManualOverride: false,
      );
      await store.markRegistrySeed(tenantCode: 'lovan');
      await store.save(
        const LogoTigerConfig(baseUrl: 'http://manual.example:32001/api/v1'),
      );

      final resolved = await LogoServerUrlBridge.resolve();

      expect(resolved.source, LogoUrlSource.tigerStore);
      expect(resolved.baseUrl, 'http://manual.example:32001/api/v1');
    });
  });
}
