// Dosya Adı: ai_image_generation_test.dart
// Açıklama: AiGateway generateImage no-key / unsupported + OpenAI parse
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'dart:convert';

import 'package:exfin_ops/core/ai/ai_gateway.dart';
import 'package:exfin_ops/core/ai/ai_image.dart';
import 'package:exfin_ops/core/ai/ai_provider.dart';
import 'package:exfin_ops/core/ai/ai_provider_config.dart';
import 'package:exfin_ops/core/ai/ai_settings_store.dart';
import 'package:exfin_ops/core/ai/ai_use_case.dart';
import 'package:exfin_ops/core/ai/clients/openai_compatible_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

    test(
      'generateImageFor chat use-case model override uygulamaz',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = AiSettingsStore(
          prefsFactory: SharedPreferences.getInstance,
        );
        await store.saveApiKey(AiProvider.openRouter, 'sk-or-test');
        await store.setActiveProvider(AiProvider.openRouter);
        await store.saveUseCaseModel(
          AiUseCase.socialMediaImage,
          'openai/gpt-4o-mini',
        );

        String? capturedModel;
        String? capturedPath;
        final tiny = base64Encode([9, 8, 7]);
        final mock = MockClient((request) async {
          capturedPath = request.url.path;
          final match =
              RegExp(r'"model"\s*:\s*"([^"]+)"').firstMatch(request.body);
          capturedModel = match?.group(1);
          return http.Response(
            jsonEncode({
              'data': [
                {'b64_json': tiny},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final gateway = AiGateway(store: store, httpClient: mock);
        final result = await gateway.generateImageFor(
          AiUseCase.socialMediaImage,
          const AiImageRequest(
            prompt: 'ürün reklam',
            width: 1080,
            height: 1080,
          ),
        );
        expect(result.isOk, isTrue);
        expect(capturedPath, endsWith('/images'));
        expect(capturedModel, isNot('openai/gpt-4o-mini'));
        expect(capturedModel, AiProvider.openRouter.defaultImageModel);
      },
    );
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

  group('OpenRouter image request', () {
    test('POST /images + aspect_ratio, dall-e generations değil', () {
      final client = OpenRouterClient();
      final req = client.buildImageHttpRequest(
        config: AiProviderConfig.defaults(AiProvider.openRouter),
        apiKey: 'sk-or-test',
        request: const AiImageRequest(
          prompt: 'product ad',
          width: 1080,
          height: 1920,
        ),
      );
      expect(req.url.path, endsWith('/images'));
      expect(req.url.path, isNot(contains('generations')));
      expect(req.body, contains('"aspect_ratio"'));
      expect(req.body, contains('9:16'));
      expect(req.body, isNot(contains('response_format')));
      expect(req.body, contains(AiProvider.openRouter.defaultImageModel));
      expect(req.body, isNot(contains('dall-e-3')));
    });

    test('OpenAI hâlâ /images/generations + size kullanır', () {
      final client = OpenAiClient();
      final req = client.buildImageHttpRequest(
        config: AiProviderConfig.defaults(AiProvider.openAi),
        apiKey: 'sk-test',
        request: const AiImageRequest(
          prompt: 'product ad',
          width: 1080,
          height: 1080,
        ),
      );
      expect(req.url.path, endsWith('/images/generations'));
      expect(req.body, contains('"size"'));
      expect(req.body, contains('1024x1024'));
      expect(req.body, contains('dall-e-3'));
    });
  });

  group('AiProvider defaultImageModel', () {
    test('Gemini Imagen 4; OpenRouter dall-e değil', () {
      expect(
        AiProvider.gemini.defaultImageModel,
        'imagen-4.0-generate-001',
      );
      expect(
        AiProvider.openRouter.defaultImageModel,
        isNot(contains('dall-e')),
      );
    });
  });
}
