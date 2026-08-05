// Dosya Adı: openai_compatible_client.dart
// Açıklama: OpenAI Chat Completions uyumlu HTTP istemci (OpenAI + OpenRouter)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../ai_completion.dart';
import '../ai_image.dart';
import '../ai_provider.dart';
import '../ai_provider_client.dart';
import '../ai_provider_config.dart';

/// {@template openai_compatible_client}
/// `/chat/completions` OpenAI uyumlu istemci.
/// OpenAI ve OpenRouter aynı gövdeyi kullanır; OpenRouter ek header alır.
///
/// Kullanım örneği:
/// ```dart
/// OpenAiCompatibleClient(provider: AiProvider.openAi);
/// ```
/// {@endtemplate}
class OpenAiCompatibleClient implements AiProviderClient {
  /// [provider]: openAi veya openRouter
  @override
  final AiProvider provider;

  /// [_http]: Test inject MockClient
  final http.Client _http;

  /// [appTitle]: OpenRouter X-Title
  final String appTitle;

  /// [httpReferer]: OpenRouter HTTP-Referer
  final String httpReferer;

  /// {@macro openai_compatible_client}
  OpenAiCompatibleClient({
    required this.provider,
    http.Client? httpClient,
    this.appTitle = 'EXFINOPS',
    this.httpReferer = 'https://exfinops.local',
  })  : assert(
          provider == AiProvider.openAi || provider == AiProvider.openRouter,
        ),
        _http = httpClient ?? http.Client();

  /// {@template openai_compatible_build_request}
  /// HTTP isteğini oluşturur (test edilebilir).
  ///
  /// Key Authorization header’a yazılır; log’a yazılmaz.
  /// {@endtemplate}
  http.Request buildHttpRequest({
    required AiProviderConfig config,
    required String apiKey,
    required AiCompletionRequest request,
  }) {
    final base = config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/chat/completions');
    final model = (request.model?.trim().isNotEmpty == true)
        ? request.model!.trim()
        : config.model;
    final body = <String, dynamic>{
      'model': model,
      'messages':
          request.messages.map((m) => m.toOpenAiMultimodalMap()).toList(),
    };
    if (request.temperature != null) {
      body['temperature'] = request.temperature;
    }
    if (request.maxTokens != null) {
      body['max_tokens'] = request.maxTokens;
    }
    final httpReq = http.Request('POST', uri);
    httpReq.headers['Content-Type'] = 'application/json';
    httpReq.headers['Authorization'] = 'Bearer $apiKey';
    if (provider == AiProvider.openRouter) {
      httpReq.headers['HTTP-Referer'] = httpReferer;
      httpReq.headers['X-Title'] = appTitle;
    }
    httpReq.body = jsonEncode(body);
    return httpReq;
  }

  /// OpenAI: `/images/generations` · OpenRouter: unified `/images`
  http.Request buildImageHttpRequest({
    required AiProviderConfig config,
    required String apiKey,
    required AiImageRequest request,
  }) {
    final base = config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final model = (request.model?.trim().isNotEmpty == true)
        ? request.model!.trim()
        : provider.defaultImageModel;
    final Map<String, dynamic> body;
    final Uri uri;
    if (provider == AiProvider.openRouter) {
      // OpenRouter Image API (dall-e /images/generations desteklenmez)
      uri = Uri.parse('$base/images');
      body = <String, dynamic>{
        'model': model,
        'prompt': request.prompt,
        'n': 1,
        'aspect_ratio': mapAspectRatio(request.width, request.height),
        'output_format': 'png',
      };
      final refUrl = request.productImageUrl?.trim();
      if (refUrl != null && refUrl.isNotEmpty) {
        body['input_references'] = [
          {
            'type': 'image_url',
            'image_url': {'url': refUrl},
          },
        ];
      }
    } else {
      uri = Uri.parse('$base/images/generations');
      body = <String, dynamic>{
        'model': model,
        'prompt': request.prompt,
        'n': 1,
        'size': mapApiSize(request.width, request.height),
        'response_format': 'b64_json',
      };
    }
    final httpReq = http.Request('POST', uri);
    httpReq.headers['Content-Type'] = 'application/json';
    httpReq.headers['Authorization'] = 'Bearer $apiKey';
    if (provider == AiProvider.openRouter) {
      httpReq.headers['HTTP-Referer'] = httpReferer;
      httpReq.headers['X-Title'] = appTitle;
    }
    httpReq.body = jsonEncode(body);
    return httpReq;
  }

  /// DALL-E 3 uyumlu size eşlemesi
  static String mapApiSize(int width, int height) {
    final ratio = width / height;
    if (ratio > 1.2) return '1792x1024';
    if (ratio < 0.85) return '1024x1792';
    return '1024x1024';
  }

  /// OpenRouter Image API aspect_ratio
  static String mapAspectRatio(int width, int height) {
    final ratio = width / height;
    if (ratio > 1.2) return '16:9';
    if (ratio < 0.85) return '9:16';
    return '1:1';
  }

  /// OpenAI JSON yanıtından asistan metnini çıkarır
  static String? parseAssistantText(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final choices = map['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final message = first['message'];
      if (message is Map && message['content'] is String) {
        return (message['content'] as String).trim();
      }
      if (first['text'] is String) {
        return (first['text'] as String).trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// images/generations b64_json
  static Uint8List? parseImageB64(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final data = map['data'];
      if (data is! List || data.isEmpty) return null;
      final first = data.first;
      if (first is! Map) return null;
      final b64 = first['b64_json'] ?? first['b64'];
      if (b64 is! String || b64.isEmpty) return null;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AiCompletionResult> complete({
    required AiProviderConfig config,
    required String apiKey,
    required AiCompletionRequest request,
  }) async {
    final model = (request.model?.trim().isNotEmpty == true)
        ? request.model!.trim()
        : config.model;
    try {
      final built = buildHttpRequest(
        config: config,
        apiKey: apiKey,
        request: request,
      );
      final streamed = await _http.send(built);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AiCompletionResult.error(
          message: 'HTTP ${response.statusCode}',
          provider: provider,
        );
      }
      final text = parseAssistantText(response.body);
      if (text == null || text.isEmpty) {
        return AiCompletionResult.error(
          message: 'empty_response',
          provider: provider,
        );
      }
      return AiCompletionResult.ok(
        text: text,
        provider: provider,
        model: model,
      );
    } catch (e) {
      return AiCompletionResult.error(
        message: e.runtimeType.toString(),
        provider: provider,
      );
    }
  }

  @override
  Future<AiImageResult> generateImage({
    required AiProviderConfig config,
    required String apiKey,
    required AiImageRequest request,
  }) async {
    final model = (request.model?.trim().isNotEmpty == true)
        ? request.model!.trim()
        : provider.defaultImageModel;
    try {
      final built = buildImageHttpRequest(
        config: config,
        apiKey: apiKey,
        request: request,
      );
      final streamed = await _http.send(built);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AiImageResult.error(
          message: _httpErrorMessage(response.statusCode, response.body),
          provider: provider,
        );
      }
      final bytes = parseImageB64(response.body);
      if (bytes == null || bytes.isEmpty) {
        return AiImageResult.error(
          message: 'empty_image',
          provider: provider,
        );
      }
      return AiImageResult.ok(
        bytes: bytes,
        provider: provider,
        model: model,
      );
    } catch (e) {
      return AiImageResult.error(
        message: e.runtimeType.toString(),
        provider: provider,
      );
    }
  }

  /// HTTP hata gövdesinden kısa mesaj (key/token loglanmaz)
  static String _httpErrorMessage(int statusCode, String body) {
    final snippet = _extractApiError(body);
    if (snippet != null && snippet.isNotEmpty) {
      return 'HTTP $statusCode: $snippet';
    }
    return 'HTTP $statusCode';
  }

  static String? _extractApiError(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final err = map['error'];
      if (err is Map) {
        final msg = err['message'] ?? err['msg'];
        if (msg is String && msg.trim().isNotEmpty) {
          final t = msg.trim();
          return t.length > 180 ? '${t.substring(0, 180)}…' : t;
        }
      }
      if (map['message'] is String) {
        final t = (map['message'] as String).trim();
        if (t.isNotEmpty) {
          return t.length > 180 ? '${t.substring(0, 180)}…' : t;
        }
      }
    } catch (_) {}
    return null;
  }
}

/// OpenAI kısayol istemci
class OpenAiClient extends OpenAiCompatibleClient {
  /// {@macro openai_compatible_client}
  OpenAiClient({http.Client? httpClient})
      : super(provider: AiProvider.openAi, httpClient: httpClient);
}

/// OpenRouter kısayol istemci
class OpenRouterClient extends OpenAiCompatibleClient {
  /// {@macro openai_compatible_client}
  OpenRouterClient({http.Client? httpClient})
      : super(provider: AiProvider.openRouter, httpClient: httpClient);
}
