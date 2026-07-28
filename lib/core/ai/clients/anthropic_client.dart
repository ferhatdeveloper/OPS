// Dosya Adı: anthropic_client.dart
// Açıklama: Anthropic Claude Messages API HTTP istemci
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../ai_chat_message.dart';
import '../ai_completion.dart';
import '../ai_image.dart';
import '../ai_provider.dart';
import '../ai_provider_client.dart';
import '../ai_provider_config.dart';

/// {@template anthropic_client}
/// Claude `/v1/messages` istemcisi.
/// {@endtemplate}
class AnthropicClient implements AiProviderClient {
  @override
  AiProvider get provider => AiProvider.anthropic;

  final http.Client _http;

  /// Anthropic API versiyon header
  static const String apiVersion = '2023-06-01';

  /// {@macro anthropic_client}
  AnthropicClient({http.Client? httpClient})
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
    final uri = Uri.parse('$base/v1/messages');
    final systemParts = <String>[];
    final messages = <Map<String, String>>[];
    for (final m in request.messages) {
      if (m.role == AiChatRole.system) {
        systemParts.add(m.content);
        continue;
      }
      messages.add({
        'role': m.role == AiChatRole.assistant ? 'assistant' : 'user',
        'content': m.content,
      });
    }
    final body = <String, dynamic>{
      'model': model,
      'max_tokens': request.maxTokens ?? 1024,
      'messages': messages,
    };
    if (systemParts.isNotEmpty) {
      body['system'] = systemParts.join('\n');
    }
    if (request.temperature != null) {
      body['temperature'] = request.temperature;
    }
    final httpReq = http.Request('POST', uri);
    httpReq.headers['Content-Type'] = 'application/json';
    httpReq.headers['x-api-key'] = apiKey;
    httpReq.headers['anthropic-version'] = apiVersion;
    httpReq.body = jsonEncode(body);
    return httpReq;
  }

  /// Yanıt metni
  static String? parseText(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final content = map['content'];
      if (content is! List || content.isEmpty) return null;
      final buf = StringBuffer();
      for (final part in content) {
        if (part is Map && part['type'] == 'text' && part['text'] is String) {
          buf.write(part['text']);
        }
      }
      final text = buf.toString().trim();
      return text.isEmpty ? null : text;
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
    return AiImageResult.unsupported(provider: provider);
  }
}
