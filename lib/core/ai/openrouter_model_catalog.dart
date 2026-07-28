// Dosya Adı: openrouter_model_catalog.dart
// Açıklama: OpenRouter model parse, popüler filtre ve sabit allowlist
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

/// {@template open_router_model_info}
/// OpenRouter model kimliği + görünen ad.
///
/// Kullanım örneği:
/// ```dart
/// const m = OpenRouterModelInfo(id: 'openai/gpt-4o-mini', name: 'GPT-4o Mini');
/// ```
/// {@endtemplate}
class OpenRouterModelInfo {
  /// [id]: OpenRouter slug (örn. openai/gpt-4o-mini)
  final String id;

  /// [name]: Kullanıcıya gösterilen ad
  final String name;

  /// {@macro open_router_model_info}
  const OpenRouterModelInfo({
    required this.id,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenRouterModelInfo && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'OpenRouterModelInfo($id)';
}

/// {@template open_router_model_catalog}
/// OpenRouter `/models` JSON parse + popüler filtre + offline allowlist.
/// {@endtemplate}
class OpenRouterModelCatalog {
  OpenRouterModelCatalog._();

  /// Key yok / API hata durumunda kullanılan sabit slug listesi.
  static const List<OpenRouterModelInfo> fallbackAllowlist = [
    OpenRouterModelInfo(id: 'openai/gpt-4o-mini', name: 'GPT-4o Mini'),
    OpenRouterModelInfo(id: 'openai/gpt-4o', name: 'GPT-4o'),
    OpenRouterModelInfo(id: 'openai/gpt-4.1-mini', name: 'GPT-4.1 Mini'),
    OpenRouterModelInfo(
      id: 'anthropic/claude-sonnet-4',
      name: 'Claude Sonnet 4',
    ),
    OpenRouterModelInfo(
      id: 'anthropic/claude-3.5-sonnet',
      name: 'Claude 3.5 Sonnet',
    ),
    OpenRouterModelInfo(
      id: 'anthropic/claude-3.5-haiku',
      name: 'Claude 3.5 Haiku',
    ),
    OpenRouterModelInfo(
      id: 'google/gemini-2.0-flash-001',
      name: 'Gemini 2.0 Flash',
    ),
    OpenRouterModelInfo(
      id: 'google/gemini-2.5-flash-preview',
      name: 'Gemini 2.5 Flash',
    ),
    OpenRouterModelInfo(
      id: 'deepseek/deepseek-chat',
      name: 'DeepSeek Chat',
    ),
    OpenRouterModelInfo(
      id: 'deepseek/deepseek-r1',
      name: 'DeepSeek R1',
    ),
    OpenRouterModelInfo(
      id: 'meta-llama/llama-3.3-70b-instruct',
      name: 'Llama 3.3 70B',
    ),
    OpenRouterModelInfo(
      id: 'qwen/qwen-2.5-72b-instruct',
      name: 'Qwen 2.5 72B',
    ),
    OpenRouterModelInfo(
      id: 'mistralai/mistral-small-3.1-24b-instruct',
      name: 'Mistral Small 3.1',
    ),
    OpenRouterModelInfo(id: 'x-ai/grok-3-mini', name: 'Grok 3 Mini'),
  ];

  /// Allowlist id sırası (popüler filtre sırası)
  static List<String> get preferredIds =>
      fallbackAllowlist.map((e) => e.id).toList(growable: false);

  /// {@template open_router_model_catalog_parse}
  /// OpenRouter `GET /models` gövdesini parse eder.
  ///
  /// Parametreler:
  /// - [body]: Ham JSON string
  ///
  /// Dönüş değeri:
  /// - [List]: Geçerli id’li modeller (bozuk JSON → boş)
  /// {@endtemplate}
  static List<OpenRouterModelInfo> parseModelsJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return const [];
      final data = decoded['data'];
      if (data is! List) return const [];
      final out = <OpenRouterModelInfo>[];
      for (final item in data) {
        if (item is! Map) continue;
        final id = '${item['id'] ?? ''}'.trim();
        if (id.isEmpty) continue;
        final nameRaw = '${item['name'] ?? ''}'.trim();
        out.add(
          OpenRouterModelInfo(
            id: id,
            name: nameRaw.isNotEmpty ? nameRaw : id,
          ),
        );
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// {@template open_router_model_catalog_filter}
  /// API listesini allowlist id sırasına göre filtreler.
  /// Eşleşme yoksa [fallbackAllowlist] döner.
  ///
  /// Parametreler:
  /// - [models]: Ham API modelleri
  ///
  /// Dönüş değeri:
  /// - [List]: Popüler / allowlist sırası
  /// {@endtemplate}
  static List<OpenRouterModelInfo> filterPopular(
    List<OpenRouterModelInfo> models,
  ) {
    if (models.isEmpty) return fallbackAllowlist;
    final byId = <String, OpenRouterModelInfo>{
      for (final m in models) m.id: m,
    };
    final filtered = <OpenRouterModelInfo>[];
    for (final id in preferredIds) {
      final hit = byId[id];
      if (hit != null) filtered.add(hit);
    }
    if (filtered.isEmpty) return fallbackAllowlist;
    return filtered;
  }
}
