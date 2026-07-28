// Dosya Adı: openrouter_model_catalog_test.dart
// Açıklama: OpenRouter model listesi parse / fallback / popüler filtre testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:exfin_ops/core/ai/openrouter_model_catalog.dart';
import 'package:exfin_ops/core/ai/openrouter_model_list_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OpenRouterModelCatalog.parse', () {
    test('data dizisinden id/name çıkarır', () {
      const body = '''
{
  "data": [
    {"id": "openai/gpt-4o-mini", "name": "GPT-4o Mini"},
    {"id": "anthropic/claude-3.5-haiku", "name": "Claude 3.5 Haiku"},
    {"id": "", "name": "empty"},
    {"name": "no-id"}
  ]
}
''';
      final list = OpenRouterModelCatalog.parseModelsJson(body);
      expect(list.length, 2);
      expect(list[0].id, 'openai/gpt-4o-mini');
      expect(list[0].name, 'GPT-4o Mini');
      expect(list[1].id, 'anthropic/claude-3.5-haiku');
    });

    test('bozuk JSON → boş liste', () {
      expect(OpenRouterModelCatalog.parseModelsJson('{not-json'), isEmpty);
    });

    test('data yok → boş liste', () {
      expect(OpenRouterModelCatalog.parseModelsJson('{}'), isEmpty);
      expect(
        OpenRouterModelCatalog.parseModelsJson('{"data":"x"}'),
        isEmpty,
      );
    });
  });

  group('OpenRouterModelCatalog.filterPopular', () {
    test('allowlist sırasına göre keser', () {
      final raw = [
        const OpenRouterModelInfo(id: 'zzz/other', name: 'Other'),
        const OpenRouterModelInfo(
          id: 'deepseek/deepseek-chat',
          name: 'DeepSeek',
        ),
        const OpenRouterModelInfo(
          id: 'openai/gpt-4o-mini',
          name: 'Mini',
        ),
        const OpenRouterModelInfo(
          id: 'openai/gpt-4o',
          name: '4o',
        ),
      ];
      final filtered = OpenRouterModelCatalog.filterPopular(raw);
      expect(filtered.map((e) => e.id).toList(), [
        'openai/gpt-4o-mini',
        'openai/gpt-4o',
        'deepseek/deepseek-chat',
      ]);
    });

    test('eşleşme yoksa allowlist fallback', () {
      final filtered = OpenRouterModelCatalog.filterPopular(const [
        OpenRouterModelInfo(id: 'unknown/x', name: 'X'),
      ]);
      expect(filtered, OpenRouterModelCatalog.fallbackAllowlist);
    });
  });

  group('OpenRouterModelCatalog.fallbackAllowlist', () {
    test('openai/gpt-4o-mini ve claude/gemini/deepseek slug içerir', () {
      final ids = OpenRouterModelCatalog.fallbackAllowlist
          .map((e) => e.id)
          .toList();
      expect(ids, contains('openai/gpt-4o-mini'));
      expect(ids.any((id) => id.startsWith('anthropic/')), isTrue);
      expect(ids.any((id) => id.startsWith('google/')), isTrue);
      expect(ids.any((id) => id.startsWith('deepseek/')), isTrue);
    });
  });

  group('OpenRouterModelListService', () {
    test('API başarılı → popüler filtreli liste', () async {
      final payload = jsonEncode({
        'data': [
          {'id': 'openai/gpt-4o-mini', 'name': 'GPT-4o Mini'},
          {'id': 'noise/model', 'name': 'Noise'},
          {'id': 'google/gemini-2.0-flash-001', 'name': 'Gemini Flash'},
        ],
      });
      final svc = OpenRouterModelListService(
        httpClient: MockClient((req) async {
          expect(req.method, 'GET');
          expect(req.url.path, endsWith('/models'));
          expect(req.headers['Authorization'], 'Bearer sk-or-test');
          return http.Response(payload, 200);
        }),
      );
      final result = await svc.loadModels(apiKey: 'sk-or-test');
      expect(result.fromApi, isTrue);
      expect(result.models.map((e) => e.id), [
        'openai/gpt-4o-mini',
        'google/gemini-2.0-flash-001',
      ]);
    });

    test('key yok → fallback allowlist', () async {
      var called = false;
      final svc = OpenRouterModelListService(
        httpClient: MockClient((req) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      final result = await svc.loadModels(apiKey: null);
      expect(called, isFalse);
      expect(result.fromApi, isFalse);
      expect(result.models, OpenRouterModelCatalog.fallbackAllowlist);
    });

    test('HTTP hata → fallback allowlist', () async {
      final svc = OpenRouterModelListService(
        httpClient: MockClient((req) async {
          return http.Response('error', 500);
        }),
      );
      final result = await svc.loadModels(apiKey: 'sk-or-test');
      expect(result.fromApi, isFalse);
      expect(result.models, OpenRouterModelCatalog.fallbackAllowlist);
    });

    test('ağ istisnası → fallback allowlist', () async {
      final svc = OpenRouterModelListService(
        httpClient: MockClient((req) async {
          throw Exception('network');
        }),
      );
      final result = await svc.loadModels(apiKey: 'sk-or-test');
      expect(result.fromApi, isFalse);
      expect(result.models, OpenRouterModelCatalog.fallbackAllowlist);
    });
  });
}
