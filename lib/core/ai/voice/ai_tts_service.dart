// Dosya Adı: ai_tts_service.dart
// Açıklama: AI cevap TTS — OpenAI bulut + cihaz neural fallback
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../features/ai_chat_reply_sanitizer.dart';
import 'ai_openai_tts_voice.dart';
import 'ai_speech_language_detector.dart';
import 'ai_tts_voice.dart';

/// {@template ai_tts_engine}
/// Test inject için TTS motor arayüzü.
/// {@endtemplate}
abstract class AiTtsEngine {
  /// Metni seslendir; false = motor reddetti / sessiz
  Future<bool> speak(String text);

  /// Etkili dil koduna göre locale + neural ses ayarla
  Future<void> setLanguageCode(String langCode);

  /// Konuşmacı stili (natural / warm_f / …)
  set voicePersona(AiTtsVoicePersona persona);

  /// Konuşmayı kes
  Future<void> stop();

  /// Tamamlanma callback
  void setOnComplete(VoidCallback? callback);

  /// Hata / iptal callback
  void setOnCancel(VoidCallback? callback);

  /// Kaynakları bırak
  Future<void> dispose();
}

/// {@template flutter_ai_tts_engine}
/// `flutter_tts` — dil + cihazdaki en iyi neural konuşmacı.
/// {@endtemplate}
class FlutterAiTtsEngine implements AiTtsEngine {
  /// [_tts]: Platform TTS
  final FlutterTts _tts = FlutterTts();

  /// [_ready]
  bool _ready = false;

  /// [_onComplete]
  VoidCallback? _onComplete;

  /// [_onCancel]
  VoidCallback? _onCancel;

  /// [_activeLang]: Son ayarlanan kısa dil kodu
  String? _activeLang;

  /// [_activeVoiceKey]: name|locale — gereksiz setVoice önleme
  String? _activeVoiceKey;

  /// [_persona]
  AiTtsVoicePersona _persona = AiTtsVoicePersona.natural;

  /// [_voicesCache]
  List<AiTtsVoiceInfo>? _voicesCache;

  /// Son hata mesajı (debug)
  String? lastError;

  /// Son seçilen ses adı (UI / debug)
  String? lastVoiceName;

  /// {@macro flutter_ai_tts_engine}
  FlutterAiTtsEngine();

  @override
  set voicePersona(AiTtsVoicePersona persona) {
    if (_persona == persona) return;
    _persona = persona;
    _activeLang = null;
    _activeVoiceKey = null;
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await _preferGoogleEngine();
      }
      if (!kIsWeb && Platform.isIOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }
      await _tts.awaitSpeakCompletion(false);
      await _pickLanguageAndVoice('tr');
      // Daha doğal tempo (çok hızlı = robotik)
      await _tts.setSpeechRate(Platform.isAndroid ? 0.42 : 0.46);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.02);
    } catch (e) {
      lastError = e.toString();
    }
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {
      _onComplete?.call();
    });
    _tts.setCancelHandler(() {
      _onCancel?.call();
    });
    _tts.setErrorHandler((msg) {
      lastError = msg?.toString();
      _onCancel?.call();
    });
    _ready = true;
  }

  /// Android: Google TTS motoru (neural TR/EN sesleri)
  Future<void> _preferGoogleEngine() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is! List) return;
      final names = engines.map((e) => e.toString()).toList();
      const preferred = [
        'com.google.android.tts',
        'com.google.android.tts.services',
      ];
      for (final id in preferred) {
        if (names.contains(id)) {
          await _tts.setEngine(id);
          return;
        }
      }
      for (final n in names) {
        if (n.toLowerCase().contains('google')) {
          await _tts.setEngine(n);
          return;
        }
      }
    } catch (e) {
      lastError = e.toString();
    }
  }

  Future<List<AiTtsVoiceInfo>> _loadVoices() async {
    final cached = _voicesCache;
    if (cached != null) return cached;
    try {
      final raw = await _tts.getVoices;
      final list = AiTtsVoiceSelector.parseVoices(raw);
      _voicesCache = list;
      return list;
    } catch (e) {
      lastError = e.toString();
      _voicesCache = const [];
      return const [];
    }
  }

  Future<void> _pickLanguageAndVoice(String langCode) async {
    final code =
        AiSpeechLanguageDetector.normalize(langCode) ?? 'tr';
    final voiceKeyWanted = '${_persona.storageKey}|$code';
    if (_activeLang == code && _activeVoiceKey == voiceKeyWanted) {
      return;
    }

    final preferred = AiSpeechLanguageDetector.ttsCandidates(code);
    try {
      for (final lang in preferred) {
        final avail = await _tts.isLanguageAvailable(lang);
        if (avail == true || avail == 1) {
          await _tts.setLanguage(lang);
          break;
        }
      }
    } catch (e) {
      lastError = e.toString();
      try {
        await _tts.setLanguage(AiSpeechLanguageDetector.ttsLocale(code));
      } catch (_) {
        try {
          await _tts.setLanguage('en-US');
        } catch (_) {}
      }
    }

    await _applyBestVoice(code);
    _activeLang = code;
    _activeVoiceKey = voiceKeyWanted;
  }

  Future<void> _applyBestVoice(String langCode) async {
    if (_persona == AiTtsVoicePersona.device) {
      try {
        await _tts.clearVoice();
      } catch (_) {}
      lastVoiceName = null;
      return;
    }
    final voices = await _loadVoices();
    final best = AiTtsVoiceSelector.pickBest(
      voices: voices,
      langCode: langCode,
      persona: _persona,
    );
    if (best == null) {
      lastVoiceName = null;
      return;
    }
    try {
      await _tts.setVoice(best.toSetVoiceMap());
      lastVoiceName = best.name;
      // Neural seçildikten sonra hafif doğal tempo
      await _tts.setSpeechRate(Platform.isAndroid ? 0.42 : 0.46);
      await _tts.setPitch(
        _persona == AiTtsVoicePersona.calmM ? 0.98 : 1.03,
      );
    } catch (e) {
      lastError = e.toString();
      lastVoiceName = null;
    }
  }

  /// Markdown / emoji / klon ID temizliği — TTS daha doğal
  static String sanitizeForSpeech(String text) {
    return AiChatReplySanitizer.forSpeech(text);
  }

  @override
  Future<void> setLanguageCode(String langCode) async {
    await _ensureReady();
    await _pickLanguageAndVoice(langCode);
  }

  @override
  void setOnComplete(VoidCallback? callback) {
    _onComplete = callback;
  }

  @override
  void setOnCancel(VoidCallback? callback) {
    _onCancel = callback;
  }

  @override
  Future<bool> speak(String text) async {
    final t = sanitizeForSpeech(text);
    if (t.isEmpty) return false;
    await _ensureReady();
    try {
      await _tts.stop();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final result = await _tts.speak(t);
      if (result == 0 || result == false) {
        lastError = 'speak_rejected';
        return false;
      }
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await stop();
    _onComplete = null;
    _onCancel = null;
  }
}

/// {@template ai_tts_service}
/// AI sesli cevap okuyucu. Önce OpenAI bulut, sonra cihaz TTS.
/// {@endtemplate}
class AiTtsService {
  /// [engine]: Cihaz flutter_tts (fallback)
  final AiTtsEngine engine;

  /// [cloudEngine]: OpenAI audio/speech (yoksa yalnızca cihaz)
  final AiTtsEngine? cloudEngine;

  /// [_hasOpenAiKey]: Bulut politika — key var mı (değer okunmaz burada)
  final Future<bool> Function() _hasOpenAiKey;

  /// [enabled]: Ayarlardan TTS (varsayılan açık)
  bool enabled;

  /// [cloudTtsEnabled]: OpenAI bulut ses (varsayılan açık)
  bool cloudTtsEnabled;

  /// [speechLanguagePreference]: auto | tr | en | …
  String speechLanguagePreference;

  /// [fallbackLang]: Auto’da belirsiz metin / app dili
  String fallbackLang;

  /// [_persona]
  AiTtsVoicePersona _persona;

  /// Son konuşmada kullanılan etkili dil kodu
  String? lastSpokenLang;

  /// Son denemede bulut kullanıldı mı (debug / test)
  bool lastUsedCloud = false;

  /// {@macro ai_tts_service}
  AiTtsService({
    AiTtsEngine? engine,
    this.cloudEngine,
    Future<bool> Function()? hasOpenAiKey,
    this.enabled = true,
    this.cloudTtsEnabled = true,
    this.speechLanguagePreference = AiSpeechLanguageDetector.auto,
    this.fallbackLang = 'tr',
    AiTtsVoicePersona voicePersona = AiTtsVoicePersona.natural,
  })  : engine = engine ?? FlutterAiTtsEngine(),
        _hasOpenAiKey = hasOpenAiKey ?? (() async => false),
        _persona = voicePersona {
    this.engine.voicePersona = voicePersona;
    cloudEngine?.voicePersona = voicePersona;
  }

  /// Konuşmacı stilini güncelle
  set voicePersona(AiTtsVoicePersona persona) {
    _persona = persona;
    engine.voicePersona = persona;
    cloudEngine?.voicePersona = persona;
  }

  AiTtsVoicePersona get voicePersona => _persona;

  void bindHandlers({
    VoidCallback? onComplete,
    VoidCallback? onCancel,
  }) {
    engine.setOnComplete(onComplete);
    engine.setOnCancel(onCancel);
    cloudEngine?.setOnComplete(onComplete);
    cloudEngine?.setOnCancel(onCancel);
  }

  /// TTS açıksa konuş; bulut dener, başarısızsa cihaz.
  Future<bool> speakIfEnabled(String text) async {
    if (!enabled) return false;
    final t = text.trim();
    if (t.isEmpty) return false;
    final code = AiSpeechLanguageDetector.resolve(
      preference: speechLanguagePreference,
      text: t,
      fallback: fallbackLang,
    );
    lastSpokenLang = code;
    lastUsedCloud = false;

    final cloud = cloudEngine;
    final hasKey = await _hasOpenAiKey();
    final tryCloud = cloud != null &&
        AiTtsCloudPolicy.shouldAttemptCloud(
          ttsEnabled: enabled,
          cloudTtsEnabled: cloudTtsEnabled,
          persona: _persona,
          hasOpenAiKey: hasKey,
        );

    if (tryCloud) {
      cloud.voicePersona = _persona;
      try {
        await engine.stop();
        await cloud.setLanguageCode(code);
        final ok = await cloud.speak(t);
        if (ok) {
          lastUsedCloud = true;
          return true;
        }
      } catch (_) {}
    }

    try {
      await cloud?.stop();
    } catch (_) {}
    try {
      await engine.setLanguageCode(code);
    } catch (_) {}
    engine.voicePersona = _persona;
    return engine.speak(t);
  }

  /// Hem bulut player hem cihaz TTS kesilir
  Future<void> stop() async {
    try {
      await cloudEngine?.stop();
    } catch (_) {}
    await engine.stop();
  }

  Future<void> dispose() async {
    try {
      await cloudEngine?.dispose();
    } catch (_) {}
    await engine.dispose();
  }
}
