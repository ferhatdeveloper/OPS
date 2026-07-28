// Dosya Adı: openrouter_client_test.dart
// Açıklama: OpenAI-uyumlu / gateway request builder + no-key no-op testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/core/ai/ai_chat_message.dart';
import 'package:exfin_ops/core/ai/ai_completion.dart';
import 'package:exfin_ops/core/ai/ai_gateway.dart';
import 'package:exfin_ops/core/ai/ai_provider.dart';
import 'package:exfin_ops/core/ai/ai_provider_config.dart';
import 'package:exfin_ops/core/ai/ai_settings_store.dart';
import 'package:exfin_ops/core/ai/ai_use_case.dart';
import 'package:exfin_ops/core/ai/clients/openai_compatible_client.dart';
import 'package:exfin_ops/core/ai/features/report_insight_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OpenAiCompatibleClient builder', () {
    test('OpenRouter chat/completions URI + Bearer + Referer', () {
      final client = OpenRouterClient();
      final req = client.buildHttpRequest(
        config: AiProviderConfig.defaults(AiProvider.openRouter),
        apiKey: 'test-key-not-logged',
        request: const AiCompletionRequest(
          messages: [
            AiChatMessage(role: AiChatRole.user, content: 'ping'),
          ],
        ),
      );
      expect(req.url.host, 'openrouter.ai');
      expect(req.url.path, endsWith('/chat/completions'));
      expect(req.headers['Authorization'], 'Bearer test-key-not-logged');
      expect(req.headers['HTTP-Referer'], isNotEmpty);
      expect(req.headers['X-Title'], 'EXFINOPS');
      expect(req.body, contains('"model"'));
      expect(req.body, isNot(contains('sk-live')));
    });

    test('parseAssistantText choices.message.content', () {
      const body =
          '{"choices":[{"message":{"role":"assistant","content":"Merhaba"}}]}';
      expect(OpenAiCompatibleClient.parseAssistantText(body), 'Merhaba');
    });
  });

  group('AiGateway no-key', () {
    test('key yoksa noKey + l10n', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      final gateway = AiGateway(store: store);
      final result = await gateway.complete(
        const AiCompletionRequest(
          messages: [
            AiChatMessage(role: AiChatRole.user, content: 'x'),
          ],
        ),
      );
      expect(result.status, AiCompletionStatus.noKey);
      expect(result.l10nKey, 'ai.no_api_key');
    });

    test('use-case model override completeFor', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      await store.saveApiKey(AiProvider.openAi, 'sk-test');
      await store.setActiveProvider(AiProvider.openAi);
      await store.saveUseCaseModel(
        AiUseCase.demandForecastInsight,
        'gpt-4o-mini-forecast',
      );

      String? capturedModel;
      final mock = MockClient((request) async {
        final body = request.body;
        final match = RegExp(r'"model"\s*:\s*"([^"]+)"').firstMatch(body);
        capturedModel = match?.group(1);
        return http.Response(
          '{"choices":[{"message":{"content":"ok"}}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final gateway = AiGateway(
        store: store,
        httpClient: mock,
      );
      final result = await gateway.completeFor(
        AiUseCase.demandForecastInsight,
        const AiCompletionRequest(
          messages: [
            AiChatMessage(role: AiChatRole.user, content: 'talep'),
          ],
        ),
      );
      expect(result.isOk, isTrue);
      expect(capturedModel, 'gpt-4o-mini-forecast');
    });
  });

  group('ReportInsightService', () {
    test('opt-in kapalı → insights_opt_in_required', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AiSettingsStore(
        prefsFactory: SharedPreferences.getInstance,
      );
      await store.saveApiKey(AiProvider.openRouter, 'sk-x');
      await store.setInsightsOptIn(false);
      final service = ReportInsightService(gateway: AiGateway(store: store));
      final r = await service.analyze(
        reportTitle: 'Test',
        rowSummaries: ['a=1'],
      );
      expect(r.l10nKey, 'ai.insights_opt_in_required');
    });

    test('summarizeRows kompakt satır üretir', () {
      final lines = ReportInsightService.summarizeRows([
        {'kod': 'C1', 'tutar': '100'},
        {'kod': 'C2', 'tutar': '50'},
      ]);
      expect(lines, hasLength(2));
      expect(lines.first, contains('kod=C1'));
    });
  });
}
