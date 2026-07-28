// Dosya Adı: ai_image_generation_test.dart
// Açıklama: AiGateway generateImage no-key / unsupported + OpenAI parse
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:exfin_ops/core/ai/ai_gateway.dart';
import 'package:exfin_ops/core/ai/ai_image.dart';
import 'package:exfin_ops/core/ai/ai_provider.dart';
import 'package:exfin_ops/core/ai/ai_settings_store.dart';
import 'package:exfin_ops/core/ai/clients/openai_compatible_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiGateway generateImage', () {
    test('key yoksa noKey', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      final gateway = AiGateway(store: store);
      final result = await gateway.generateImage(
        const AiImageRequest(
          prompt: 'test product ad',
          width: 1080,
          height: 1080,
        ),
      );
      expect(result.status, AiImageStatus.noKey);
      expect(result.l10nKey, 'ai.no_api_key');
    });

    test('Anthropic unsupported (fallback key yok)', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      await store.saveApiKey(AiProvider.anthropic, 'sk-ant-test');
      await store.setActiveProvider(AiProvider.anthropic);
      final gateway = AiGateway(store: store);
      final result = await gateway.generateImage(
        const AiImageRequest(
          prompt: 'x',
          width: 1024,
          height: 1024,
        ),
      );
      expect(result.status, AiImageStatus.unsupported);
      expect(result.l10nKey, 'ai.image_unsupported');
    });

    test('Anthropic → OpenRouter fallback seçilir (key varsa)', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      await store.saveApiKey(AiProvider.anthropic, 'sk-ant-test');
      await store.saveApiKey(AiProvider.openRouter, 'sk-or-test');
      await store.setActiveProvider(AiProvider.anthropic);
      final gateway = AiGateway(store: store);
      // Gerçek HTTP yok — fallback key seçimi noKey/error olabilir;
      // unsupported olmamalı (fallback denendi).
      final result = await gateway.generateImage(
        const AiImageRequest(
          prompt: 'x',
          width: 1024,
          height: 1024,
        ),
      );
      expect(result.status, isNot(AiImageStatus.unsupported));
      expect(
        result.provider,
        anyOf(AiProvider.openRouter, isNull),
      );
    });
  });

  group('OpenAiCompatibleClient image parse', () {
    test('parseImageB64 data.b64_json', () {
      final tiny = base64Encode([1, 2, 3, 4]);
      final body = jsonEncode({
        'data': [
          {'b64_json': tiny},
        ],
      });
      final bytes = OpenAiCompatibleClient.parseImageB64(body);
      expect(bytes, isNotNull);
      expect(bytes, [1, 2, 3, 4]);
    });
  });
}
