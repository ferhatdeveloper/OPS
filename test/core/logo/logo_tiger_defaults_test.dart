// Dosya Adı: logo_tiger_defaults_test.dart
// Açıklama: Özel test Logo Tiger varsayılan doldurma birim testleri
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:exfin_ops/core/logo/logo_tiger_defaults.dart';
import 'package:exfin_ops/core/logo/logo_tiger_settings_store.dart';
import 'package:exfin_ops/core/logo/logo_tiger_urls.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogoTigerDefaults', () {
    test('fillEmpty boş alanları canlı test kimliğiyle doldurur', () {
      final filled = LogoTigerDefaults.fillEmpty(
        const LogoTigerConfig(baseUrl: ''),
      );

      expect(filled.baseUrl, contains(LogoTigerUrls.defaultHost));
      expect(filled.apiKey, LogoTigerDefaults.apiKey);
      expect(filled.clientId, LogoTigerDefaults.clientId);
      expect(filled.clientSecret, LogoTigerDefaults.clientSecret);
      expect(filled.username, LogoTigerDefaults.username);
      expect(filled.password, LogoTigerDefaults.password);
      expect(filled.hasAuthCredentials, isTrue);
      expect(filled.canPush, isTrue);
    });

    test('fillEmpty dolu alanları ezmez', () {
      const existing = LogoTigerConfig(
        baseUrl: 'http://192.0.2.10:32001/api/v1',
        apiKey: 'KEEP',
        username: 'U',
        password: 'P',
        clientId: 'C',
        clientSecret: 'S',
      );
      final filled = LogoTigerDefaults.fillEmpty(existing);
      expect(filled.baseUrl, existing.baseUrl);
      expect(filled.apiKey, 'KEEP');
      expect(filled.username, 'U');
    });
  });

  group('LogoTigerSettingsStore defaults', () {
    test('boş prefs → ensureDefaultsPersisted tüm alanları yazar', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LogoTigerSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );

      expect(await store.isEnabled(), isTrue);
      final wrote = await store.ensureDefaultsPersisted();
      expect(wrote, isTrue);

      final raw = await store.loadRaw();
      expect(raw.baseUrl, contains('185.86.15.238'));
      expect(raw.apiKey, LogoTigerDefaults.apiKey);
      expect(raw.clientId, LogoTigerDefaults.clientId);
      expect(raw.username, LogoTigerDefaults.username);
      expect(await store.isEnabled(), isTrue);
    });
  });
}
