// Dosya Adı: gemini_client.dart
// Açıklama: Google Gemini generateContent + Imagen görsel HTTP istemci
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../ai_chat_message.dart';
import '../ai_completion.dart';
import '../ai_image.dart';
import '../ai_provider.dart';
import '../ai_provider_client.dart';
import '../ai_provider_config.dart';

/// {@template gemini_client}
/// Gemini `models/{model}:generateContent` istemcisi.
/// Key query veya `x-goog-api-key` header ile gider (loglanmaz).
/// {@endtemplate}
class GeminiClient implements AiProviderClient {
  @override
  AiProvider get provider => AiProvider.gemini;

  final http.Client _http;

  /// {@macro gemini_client}
  GeminiClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  /// HTTP isteği builder (test)
  http.Request buildHttpRequest({
    required AiProviderConfig config,
    required String apiKey,
    required AiCompletionRequest request,
  }) {
    final model = (request.model?.trim().isNotEmpty == true)
        ? request.model!.trim()
        : config.model;
    final base = config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/models/$model:generateContent');
    final systemParts = <String>[];
    final contents = <Map<String, dynamic>>[];
    for (final m in request.messages) {
      if (m.role == AiChatRole.system) {
        systemParts.add(m.content);
        continue;
      }
      final role = m.role == AiChatRole.assistant ? 'model' : 'user';
      final parts = <Map<String, dynamic>>[
        {'text': m.content},
      ];
      if (m.hasImage) {
        final mime = (m.imageMimeType ?? 'image/jpeg').trim();
        parts.add({
          'inline_data': {
            'mime_type': mime,
            'data': m.imageBase64!.trim(),
          },
        });
      }
      contents.add({
        'role': role,
        'parts': parts,
      });
    }
    final body = <String, dynamic>{
      'contents': contents,
    };
    if (systemParts.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemParts.join('\n')},
        ],
      };
    }
    if (request.temperature != null || request.maxTokens != null) {
      body['generationConfig'] = {
        if (request.temperature != null) 'temperature': request.temperature,
        if (request.maxTokens != null) 'maxOutputTokens': request.maxTokens,
      };
    }
    final httpReq = http.Request('POST', uri);
    httpReq.headers['Content-Type'] = 'application/json';
    httpReq.headers['x-goog-api-key'] = apiKey;
    httpReq.body = jsonEncode(body);
    return httpReq;
  }

  /// Imagen `:predict` isteği
  http.Request buildImageHttpRequest({
    required AiProviderConfig config,
    required String apiKey,
    required AiImageRequest request,
  }) {
    final model = (request.model?.trim().isNotEmpty == true)
        ? request.model!.trim()
        : provider.defaultImageModel;
    final base = config.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/models/$model:predict');
    final body = <String, dynamic>{
      'instances': [
        {'prompt': request.prompt},
      ],
      'parameters': {
        'sampleCount': 1,
        'aspectRatio': mapAspectRatio(request.width, request.height),
      },
    };
    final httpReq = http.Request('POST', uri);
    httpReq.headers['Content-Type'] = 'application/json';
    httpReq.headers['x-goog-api-key'] = apiKey;
    httpReq.body = jsonEncode(body);
    return httpReq;
  }

  /// Imagen aspectRatio
  static String mapAspectRatio(int width, int height) {
    final ratio = width / height;
    if (ratio > 1.2) return '16:9';
    if (ratio < 0.85) return '9:16';
    return '1:1';
  }

  /// Yanıt metni
  static String? parseText(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final candidates = map['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;
      final content = (candidates.first as Map)['content'];
      if (content is! Map) return null;
      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) return null;
      final text = (parts.first as Map)['text'];
      if (text is String) return text.trim();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Imagen predict bytes
  static Uint8List? parseImageBytes(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final predictions = map['predictions'];
      if (predictions is! List || predictions.isEmpty) return null;
      final first = predictions.first;
      if (first is! Map) return null;
      final b64 = first['bytesBase64Encoded'] ?? first['bytes'];
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
      final text = parseText(response.body);
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
      final bytes = parseImageBytes(response.body);
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

  static String _httpErrorMessage(int statusCode, String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final err = map['error'];
      if (err is Map && err['message'] is String) {
        final t = (err['message'] as String).trim();
        if (t.isNotEmpty) {
          final short = t.length > 180 ? '${t.substring(0, 180)}…' : t;
          return 'HTTP $statusCode: $short';
        }
      }
    } catch (_) {}
    return 'HTTP $statusCode';
  }
}
