// Dosya Adı: logo_server_url_bridge_test.dart
// Açıklama: Sunucu URL → Logo çözümleme birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/logo/logo_server_url_bridge.dart';
import 'package:exfin_ops/core/logo/logo_tiger_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mergeIntoConfig: boş tiger → config aynı kalır (sunucu yok)', () async {
    const cfg = LogoTigerConfig(baseUrl: '');
    final merged = await LogoServerUrlBridge.mergeIntoConfig(cfg);
    expect(merged.baseUrl, isEmpty);
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
}
