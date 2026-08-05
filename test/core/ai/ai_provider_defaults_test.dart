// Dosya Adı: ai_provider_defaults_test.dart
// Açıklama: Özel OpenRouter varsayılan key persist testi
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/core/ai/ai_provider_defaults.dart';
import 'package:exfin_ops/core/ai/ai_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiProviderDefaults', () {
    test('dart-define yoksa ensurePersisted no-op', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      // Test binary’sinde OPENROUTER_API_KEY define yok → boş
      final wrote = await AiProviderDefaults.ensurePersisted(store);
      expect(wrote, isFalse);
      expect(AiProviderDefaults.openRouterApiKey, isEmpty);
    });
  });
}
