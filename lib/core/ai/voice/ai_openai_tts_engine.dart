// Dosya Adı: ai_openai_tts_engine.dart
// Açıklama: OpenAI audio/speech → MP3 geçici dosya + audioplayers oynatma
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../features/ai_chat_reply_sanitizer.dart';
import 'ai_openai_tts_voice.dart';
import 'ai_tts_service.dart';
import 'ai_tts_voice.dart';

/// {@template openai_ai_tts_engine}
/// OpenAI `POST /v1/audio/speech` bulut TTS motoru.
///
/// Key yok / HTTP hata / offline → [speak] false (cihaz fallback üst katmanda).
/// API key asla loglanmaz.
///
/// Kullanım örneği:
/// ```dart
/// final eng = OpenAiTtsEngine(
///   apiKeyResolver: () => store.readApiKey(AiProvider.openAi),
/// );
/// await eng.speak('Merhaba');
/// ```
/// {@endtemplate}
class OpenAiTtsEngine implements AiTtsEngine {
  /// [_http]: Test inject
  final http.Client _http;

  /// [_apiKeyResolver]: OpenAI düz key (kısa ömürlü)
  final Future<String?> Function() _apiKeyResolver;

  /// [_playerFactory]: Test inject
  final AudioPlayer Function() _playerFactory;

  /// [_tempDirFactory]: Test inject
  final Future<Directory> Function()? _tempDirFactory;

  /// [baseUrl]: OpenAI API tabanı
  final String baseUrl;

  /// [model]: gpt-4o-mini-tts (tercih) / tts-1
  final String model;

  /// [_persona]
  AiTtsVoicePersona _persona = AiTtsVoicePersona.natural;

  /// [_player]
  AudioPlayer? _player;

  /// [_onComplete]
  VoidCallback? _onComplete;

  /// [_onCancel]
  VoidCallback? _onCancel;

  /// [_completeSub]
  StreamSubscription<void>? _completeSub;

  /// [_tempFile]: Son yazılan MP3
  File? _tempFile;

  /// [_speaking]: Oynatma sürüyor
  bool _speaking = false;

  /// [_disposed]
  bool _disposed = false;

  /// Son hata (debug; key içermez)
  String? lastError;

  /// Son kullanılan OpenAI voice id
  String? lastVoiceId;

  /// OpenAI input üst sınırı
  static const int maxInputChars = 4096;

  /// {@macro openai_ai_tts_engine}
  OpenAiTtsEngine({
    required Future<String?> Function() apiKeyResolver,
    http.Client? httpClient,
    AudioPlayer Function()? playerFactory,
    Future<Directory> Function()? tempDirFactory,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = AiOpenAiTtsVoiceMapper.defaultModel,
  })  : _apiKeyResolver = apiKeyResolver,
        _http = httpClient ?? http.Client(),
        _playerFactory = playerFactory ?? AudioPlayer.new,
        _tempDirFactory = tempDirFactory;

  @override
  set voicePersona(AiTtsVoicePersona persona) {
    _persona = persona;
  }

  @override
  Future<void> setLanguageCode(String langCode) async {
    // OpenAI TTS girdiden dil algılar; locale ayarı yok.
  }

  @override
  void setOnComplete(VoidCallback? callback) {
    _onComplete = callback;
  }

  @override
  void setOnCancel(VoidCallback? callback) {
    _onCancel = callback;
  }

  Future<Directory> _tempDir() async {
    final factory = _tempDirFactory;
    if (factory != null) return factory();
    return getTemporaryDirectory();
  }

  Future<AudioPlayer> _ensurePlayer() async {
    final existing = _player;
    if (existing != null) return existing;
    final p = _playerFactory();
    await _completeSub?.cancel();
    _completeSub = p.onPlayerComplete.listen((_) {
      _speaking = false;
      _cleanupTemp();
      _onComplete?.call();
    });
    _player = p;
    return p;
  }

  void _cleanupTemp() {
    final f = _tempFile;
    _tempFile = null;
    if (f == null) return;
    try {
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  /// Markdown / emoji temizliği
  static String sanitizeForSpeech(String text) {
    return AiChatReplySanitizer.forSpeech(text);
  }

  @override
  Future<bool> speak(String text) async {
    if (_disposed) return false;
    final voice = AiOpenAiTtsVoiceMapper.voiceId(_persona);
    if (voice == null) {
      lastError = 'persona_device';
      return false;
    }
    final t = sanitizeForSpeech(text);
    if (t.isEmpty) return false;
    final clipped = t.length > maxInputChars
        ? t.substring(0, maxInputChars)
        : t;

    final key = (await _apiKeyResolver())?.trim();
    if (key == null || key.isEmpty) {
      lastError = 'no_openai_key';
      return false;
    }

    lastVoiceId = voice;
    try {
      await stop(notifyCancel: false);
      final bytes = await _fetchSpeech(
        apiKey: key,
        voice: voice,
        input: clipped,
      );
      if (bytes == null || bytes.isEmpty) return false;

      final dir = await _tempDir();
      final file = File(
        '${dir.path}/ai_openai_tts_'
        '${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      await file.writeAsBytes(bytes, flush: true);
      _tempFile = file;

      final player = await _ensurePlayer();
      _speaking = true;
      await player.play(DeviceFileSource(file.path));
      return true;
    } on SocketException catch (e) {
      lastError = 'offline:${e.osError?.errorCode ?? 0}';
      _speaking = false;
      return false;
    } on TimeoutException {
      lastError = 'timeout';
      _speaking = false;
      return false;
    } catch (e) {
      lastError = e.runtimeType.toString();
      _speaking = false;
      return false;
    }
  }

  Future<List<int>?> _fetchSpeech({
    required String apiKey,
    required String voice,
    required String input,
  }) async {
    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/audio/speech',
    );
    final body = <String, dynamic>{
      'model': model,
      'voice': voice,
      'input': input,
      'response_format': 'mp3',
    };
    final instr = AiOpenAiTtsVoiceMapper.instructions(_persona);
    if (instr != null && model.contains('gpt-4o-mini-tts')) {
      body['instructions'] = instr;
    }

    final response = await _http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Body / key loglanmaz
      lastError = 'http_${response.statusCode}';
      return null;
    }
    return response.bodyBytes;
  }

  /// [notifyCancel]: Interrupt’ta callback; speak öncesi sessiz stop’ta false
  @override
  Future<void> stop({bool notifyCancel = true}) async {
    final wasSpeaking = _speaking;
    _speaking = false;
    try {
      await _player?.stop();
    } catch (_) {}
    _cleanupTemp();
    if (notifyCancel && wasSpeaking) {
      _onCancel?.call();
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop(notifyCancel: false);
    await _completeSub?.cancel();
    _completeSub = null;
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _onComplete = null;
    _onCancel = null;
  }
}
