// Dosya Adı: ai_settings_store_test.dart
// Açıklama: AI ayar deposu — OpenRouter API key save/load birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/ai_api_key_editor.dart';
import 'package:exfin_ops/core/ai/ai_provider.dart';
import 'package:exfin_ops/core/ai/ai_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiApiKeyEditor', () {
    test('sk-or-v1-test → persist', () {
      expect(
        AiApiKeyEditor.shouldPersist(
          text: 'sk-or-v1-testabcdefghijklmnopqrstuvwxyz0123456789',
        ),
        isTrue,
      );
    });

    test('maske veya boş → persist yok (overwrite engeli)', () {
      expect(
        AiApiKeyEditor.shouldPersist(text: AiApiKeyEditor.maskToken),
        isFalse,
      );
      expect(AiApiKeyEditor.shouldPersist(text: '  '), isFalse);
      expect(AiApiKeyEditor.shouldPersist(text: ''), isFalse);
    });

    test('displayText hasKey → maske', () {
      expect(
        AiApiKeyEditor.displayText(hasApiKey: true),
        AiApiKeyEditor.maskToken,
      );
      expect(AiApiKeyEditor.displayText(hasApiKey: false), isEmpty);
    });
  });

  group('AiSettingsStore OpenRouter key', () {
    /// Sahte OpenRouter biçimi — gerçek kullanıcı anahtarı değil.
    const fakeOpenRouterKey =
        'sk-or-v1-testabcdefghijklmnopqrstuvwxyz0123456789';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveApiKey + readApiKey OpenRouter roundtrip', () async {
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );

      await store.saveApiKey(AiProvider.openRouter, fakeOpenRouterKey);

      final read = await store.readApiKey(AiProvider.openRouter);
      expect(read, fakeOpenRouterKey);
      expect(read, isNot(contains('sk-or-v1-live')));
    });

    test('loadSnapshot hasApiKey true after OpenRouter save', () async {
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );

      await store.saveApiKey(AiProvider.openRouter, fakeOpenRouterKey);
      await store.setActiveProvider(AiProvider.openRouter);

      final snap = await store.loadSnapshot();
      expect(snap.activeProvider, AiProvider.openRouter);
      expect(snap.configs[AiProvider.openRouter]!.hasApiKey, isTrue);
      expect(snap.configs[AiProvider.openAi]!.hasApiKey, isFalse);
    });

    test('empty saveApiKey clears OpenRouter slot only', () async {
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );

      await store.saveApiKey(AiProvider.openRouter, fakeOpenRouterKey);
      await store.saveApiKey(AiProvider.openAi, 'sk-test-openai-fake');
      await store.saveApiKey(AiProvider.openRouter, '');

      expect(await store.readApiKey(AiProvider.openRouter), isNull);
      expect(await store.readApiKey(AiProvider.openAi), 'sk-test-openai-fake');

      final snap = await store.loadSnapshot();
      expect(snap.configs[AiProvider.openRouter]!.hasApiKey, isFalse);
      expect(snap.configs[AiProvider.openAi]!.hasApiKey, isTrue);
    });

    test('prefs key uses openrouter storageKey (no mismatch)', () async {
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      await store.saveApiKey(AiProvider.openRouter, fakeOpenRouterKey);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ai_api_key_openrouter'), isNotNull);
      expect(prefs.getString('ai_api_key_openrouter'), isNotEmpty);
      expect(prefs.getString('ai_api_key_open_router'), isNull);
      // Ciphertext düz key içermez
      expect(
        prefs.getString('ai_api_key_openrouter'),
        isNot(contains('sk-or-v1-test')),
      );
    });

    test('reload after save keeps hasApiKey (simulates screen re-open)', () async {
      final store1 = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      await store1.saveApiKey(AiProvider.openRouter, fakeOpenRouterKey);
      await store1.setActiveProvider(AiProvider.openRouter);

      // Yeni store örneği = ekran yeniden açılışı
      final store2 = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      final snap = await store2.loadSnapshot();
      expect(snap.configs[AiProvider.openRouter]!.hasApiKey, isTrue);
      expect(
        await store2.readApiKey(AiProvider.openRouter),
        fakeOpenRouterKey,
      );
    });

    test('ttsEnabled varsayılan true; setTtsEnabled false kaydeder', () async {
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      final snap1 = await store.loadSnapshot();
      expect(snap1.ttsEnabled, isTrue);

      await store.setTtsEnabled(false);
      final snap2 = await store.loadSnapshot();
      expect(snap2.ttsEnabled, isFalse);

      await store.setTtsEnabled(true);
      expect((await store.loadSnapshot()).ttsEnabled, isTrue);
    });

    test('cloudTtsEnabled varsayılan true; setCloudTtsEnabled kaydeder',
        () async {
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      expect((await store.loadSnapshot()).cloudTtsEnabled, isTrue);

      await store.setCloudTtsEnabled(false);
      expect((await store.loadSnapshot()).cloudTtsEnabled, isFalse);

      await store.setCloudTtsEnabled(true);
      expect((await store.loadSnapshot()).cloudTtsEnabled, isTrue);
    });

    test('speechLanguage varsayılan auto; setSpeechLanguage kaydeder', () async {
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      expect((await store.loadSnapshot()).speechLanguage, 'auto');

      await store.setSpeechLanguage('en');
      expect((await store.loadSnapshot()).speechLanguage, 'en');

      await store.setSpeechLanguage('ckb');
      expect((await store.loadSnapshot()).speechLanguage, 'ku');

      await store.setSpeechLanguage('auto');
      expect((await store.loadSnapshot()).speechLanguage, 'auto');
    });
  });
}
