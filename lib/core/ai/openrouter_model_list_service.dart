// Dosya Adı: openrouter_model_list_service.dart
// Açıklama: OpenRouter model listesi GET + allowlist fallback
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:http/http.dart' as http;

import 'ai_provider.dart';
import 'openrouter_model_catalog.dart';

/// {@template open_router_model_list_result}
/// Model listesi yükleme sonucu (API veya fallback).
/// {@endtemplate}
class OpenRouterModelListResult {
  /// [models]: Seçilebilir modeller
  final List<OpenRouterModelInfo> models;

  /// [fromApi]: true → API’den; false → allowlist fallback
  final bool fromApi;

  /// {@macro open_router_model_list_result}
  const OpenRouterModelListResult({
    required this.models,
    required this.fromApi,
  });
}

/// {@template open_router_model_list_service}
/// `GET https://openrouter.ai/api/v1/models` — key yok / hata → allowlist.
///
/// Kullanım örneği:
/// ```dart
/// final r = await OpenRouterModelListService().loadModels(apiKey: key);
/// ```
/// {@endtemplate}
class OpenRouterModelListService {
  /// [_http]: Test inject
  final http.Client _http;

  /// [baseUrl]: Trailing slash yok (varsayılan OpenRouter)
  final String baseUrl;

  /// [appTitle]: OpenRouter X-Title
  final String appTitle;

  /// [httpReferer]: OpenRouter HTTP-Referer
  final String httpReferer;

  /// {@macro open_router_model_list_service}
  OpenRouterModelListService({
    http.Client? httpClient,
    String? baseUrl,
    this.appTitle = 'EXFINOPS',
    this.httpReferer = 'https://exfinops.local',
  })  : _http = httpClient ?? http.Client(),
        baseUrl = (baseUrl ?? AiProvider.openRouter.defaultBaseUrl)
            .replaceAll(RegExp(r'/+$'), '');

  /// {@template open_router_model_list_service_load}
  /// Modelleri yükler.
  ///
  /// Parametreler:
  /// - [apiKey]: Boş/null → API çağrılmaz, allowlist
  ///
  /// Dönüş değeri:
  /// - [OpenRouterModelListResult]: Popüler filtreli veya fallback
  /// {@endtemplate}
  Future<OpenRouterModelListResult> loadModels({String? apiKey}) async {
    final key = apiKey?.trim() ?? '';
    if (key.isEmpty) {
      return const OpenRouterModelListResult(
        models: OpenRouterModelCatalog.fallbackAllowlist,
        fromApi: false,
      );
    }
    try {
      final uri = Uri.parse('$baseUrl/models');
      final response = await _http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $key',
          'HTTP-Referer': httpReferer,
          'X-Title': appTitle,
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const OpenRouterModelListResult(
          models: OpenRouterModelCatalog.fallbackAllowlist,
          fromApi: false,
        );
      }
      final parsed = OpenRouterModelCatalog.parseModelsJson(response.body);
      if (parsed.isEmpty) {
        return const OpenRouterModelListResult(
          models: OpenRouterModelCatalog.fallbackAllowlist,
          fromApi: false,
        );
      }
      return OpenRouterModelListResult(
        models: OpenRouterModelCatalog.filterPopular(parsed),
        fromApi: true,
      );
    } catch (_) {
      return const OpenRouterModelListResult(
        models: OpenRouterModelCatalog.fallbackAllowlist,
        fromApi: false,
      );
    }
  }
}
