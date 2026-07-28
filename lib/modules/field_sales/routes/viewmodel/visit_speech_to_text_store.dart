// Dosya Adı: visit_speech_to_text_store.dart
// Açıklama: Ziyaret formu cihaz ASR (speech_to_text) oturum store
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../model/visit_speech_notes.dart';
import '../model/visit_speech_audio_helper.dart';

/// {@template visit_speech_status}
/// Ziyaret STT oturum durumu.
/// {@endtemplate}
enum VisitSpeechStatus {
  /// [idle]: Hazır / dinlemiyor
  idle,

  /// [initializing]: İzin + initialize
  initializing,

  /// [listening]: Mikrofon açık, tanıma aktif
  listening,

  /// [unavailable]: Cihazda STT yok
  unavailable,

  /// [denied]: Mikrofon / konuşma izni reddedildi
  denied,

  /// [error]: Geçici hata
  error,
}

/// {@template visit_speech_state}
/// STT store durumu (dens kayıt çubuğu için).
/// {@endtemplate}
class VisitSpeechState {
  /// [status]: Oturum durumu
  final VisitSpeechStatus status;

  /// [partialText]: Anlık (partial) tanıma
  final String partialText;

  /// [errorKey]: l10n hata anahtarı
  final String? errorKey;

  /// [localeId]: Seçilen ASR locale
  final String? localeId;

  /// [onDevice]: on-device tercih edildi mi
  final bool onDevice;

  /// [audioRecordingPath]: Planlanan / kaydedilen ses dosyası yolu
  final String? audioRecordingPath;

  /// {@macro visit_speech_state}
  const VisitSpeechState({
    this.status = VisitSpeechStatus.idle,
    this.partialText = '',
    this.errorKey,
    this.localeId,
    this.onDevice = true,
    this.audioRecordingPath,
  });

  /// {@template visit_speech_state_copy_with}
  /// Durum kopyası.
  /// {@endtemplate}
  VisitSpeechState copyWith({
    VisitSpeechStatus? status,
    String? partialText,
    String? errorKey,
    String? localeId,
    bool? onDevice,
    String? audioRecordingPath,
    bool clearError = false,
    bool clearAudioPath = false,
  }) {
    return VisitSpeechState(
      status: status ?? this.status,
      partialText: partialText ?? this.partialText,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      localeId: localeId ?? this.localeId,
      onDevice: onDevice ?? this.onDevice,
      audioRecordingPath: clearAudioPath
          ? null
          : (audioRecordingPath ?? this.audioRecordingPath),
    );
  }

  /// [isListening]: Aktif kayıt
  bool get isListening => status == VisitSpeechStatus.listening;
}

/// {@template visit_speech_to_text_store}
/// Cihaz ASR oturumu — offline-first (`onDevice: true` tercih).
///
/// Kullanım örneği:
/// ```dart
/// await ref.read(visitSpeechProvider.notifier).startListening(
///   languageCode: 'tr',
///   onFinalText: (t) {},
/// );
/// ```
/// {@endtemplate}
class VisitSpeechToTextStore extends StateNotifier<VisitSpeechState> {
  /// [_speech]: Platform speech_to_text örneği
  final SpeechToText _speech;

  /// [_requestMic]: Mikrofon izni (test enjeksiyonu)
  final Future<PermissionStatus> Function() _requestMic;

  /// [_initialized]: initialize tamamlandı mı
  bool _initialized = false;

  /// [_onFinalText]: Nihai metin geri çağrısı
  void Function(String text)? _onFinalText;

  /// [_onAudioPathReady]: Ses yolu hazır olduğunda (STT durunca)
  void Function(String path)? _onAudioPathReady;

  /// [_pendingVisitId]: Aktif ziyaret id (ses yolu için)
  String? _pendingVisitId;

  /// {@macro visit_speech_to_text_store}
  VisitSpeechToTextStore({
    SpeechToText? speech,
    Future<PermissionStatus> Function()? requestMic,
  })  : _speech = speech ?? SpeechToText(),
        _requestMic = requestMic ?? (() => Permission.microphone.request()),
        super(const VisitSpeechState());

  /// {@template visit_speech_ensure_ready}
  /// İzin + SpeechToText.initialize.
  ///
  /// Dönüş değeri:
  /// - [bool]: Dinlemeye hazır mı
  /// {@endtemplate}
  Future<bool> ensureReady() async {
    if (_initialized && _speech.isAvailable) return true;

    state = state.copyWith(
      status: VisitSpeechStatus.initializing,
      clearError: true,
    );

    final mic = await _requestMic();
    if (!mic.isGranted) {
      state = state.copyWith(
        status: VisitSpeechStatus.denied,
        errorKey: 'field_sales.visit_speech_mic_denied',
      );
      return false;
    }

    final ok = await _speech.initialize(
      onError: (error) {
        debugPrint('VisitSpeechToTextStore error: ${error.errorMsg}');
        if (!mounted) return;
        state = state.copyWith(
          status: VisitSpeechStatus.error,
          errorKey: 'field_sales.visit_speech_error',
          partialText: '',
        );
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          if (state.status == VisitSpeechStatus.listening) {
            state = state.copyWith(
              status: VisitSpeechStatus.idle,
              partialText: '',
            );
          }
        }
      },
    );

    _initialized = ok;
    if (!ok) {
      state = state.copyWith(
        status: VisitSpeechStatus.unavailable,
        errorKey: 'field_sales.visit_speech_unavailable',
      );
      return false;
    }

    state = state.copyWith(
      status: VisitSpeechStatus.idle,
      clearError: true,
    );
    return true;
  }

  /// {@template visit_speech_start_listening}
  /// Dinlemeyi başlatır; nihai sonuçlar [onFinalText] ile iletilir.
  ///
  /// Parametreler:
  /// - [languageCode]: App dil kodu (tr/ar/ku…)
  /// - [onFinalText]: Nihai transcript
  /// - [preferOnDevice]: true → önce on-device dene
  /// - [autoRestart]: Platform timeout sonrası yeniden dinle
  ///
  /// Dönüş değeri:
  /// - [bool]: Başladı mı
  /// {@endtemplate}
  Future<bool> startListening({
    required String languageCode,
    required void Function(String text) onFinalText,
    String? visitId,
    void Function(String path)? onAudioPathReady,
    bool preferOnDevice = true,
    bool autoRestart = true,
  }) async {
    _onFinalText = onFinalText;
    _onAudioPathReady = onAudioPathReady;
    _pendingVisitId = visitId?.trim().isNotEmpty == true ? visitId!.trim() : null;
    final ready = await ensureReady();
    if (!ready) return false;

    String? audioPath;
    if (_pendingVisitId != null) {
      audioPath = await VisitSpeechAudioHelper.plannedRecordingPath(
        visitId: _pendingVisitId!,
      );
    }

    final locales = await _speech.locales();
    final localeIds = locales.map((l) => l.localeId).toList(growable: false);
    final localeId = VisitSpeechNotes.resolveLocaleId(
      languageCode,
      localeIds,
    );

    var usedOnDevice = preferOnDevice;
    try {
      await _listen(
        localeId: localeId,
        onDevice: preferOnDevice,
        autoRestart: autoRestart,
      );
    } catch (e) {
      debugPrint('VisitSpeech onDevice listen failed: $e');
      if (preferOnDevice) {
        usedOnDevice = false;
        try {
          await _listen(
            localeId: localeId,
            onDevice: false,
            autoRestart: autoRestart,
          );
        } catch (e2) {
          debugPrint('VisitSpeech network listen failed: $e2');
          state = state.copyWith(
            status: VisitSpeechStatus.error,
            errorKey: 'field_sales.visit_speech_error',
          );
          return false;
        }
      } else {
        state = state.copyWith(
          status: VisitSpeechStatus.error,
          errorKey: 'field_sales.visit_speech_error',
        );
        return false;
      }
    }

    state = state.copyWith(
      status: VisitSpeechStatus.listening,
      localeId: localeId,
      onDevice: usedOnDevice,
      partialText: '',
      audioRecordingPath: audioPath,
      clearError: true,
    );
    if (audioPath != null && audioPath.trim().isNotEmpty) {
      _onAudioPathReady?.call(audioPath.trim());
    }
    return true;
  }

  /// {@template visit_speech_listen_internal}
  /// Platform listen çağrısı.
  /// {@endtemplate}
  Future<void> _listen({
    required String? localeId,
    required bool onDevice,
    required bool autoRestart,
  }) async {
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final words = result.recognizedWords.trim();
        if (result.finalResult) {
          if (words.isNotEmpty) {
            _onFinalText?.call(words);
          }
          state = state.copyWith(partialText: '');
          if (autoRestart && state.status == VisitSpeechStatus.listening) {
            // Kısa sessizlik sonrası platform oturumu kapanır; yeniden aç.
            Future<void>.delayed(const Duration(milliseconds: 350), () async {
              if (!mounted) return;
              if (state.status != VisitSpeechStatus.listening) return;
              if (_speech.isListening) return;
              try {
                await _listen(
                  localeId: localeId,
                  onDevice: onDevice,
                  autoRestart: autoRestart,
                );
              } catch (_) {}
            });
          }
        } else {
          state = state.copyWith(partialText: words);
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        onDevice: onDevice,
        listenMode: ListenMode.dictation,
        localeId: localeId,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  /// {@template visit_speech_stop_listening}
  /// Dinlemeyi durdurur.
  /// {@endtemplate}
  Future<void> stopListening() async {
    final path = state.audioRecordingPath;
    _onFinalText = null;
    _pendingVisitId = null;
    try {
      await _speech.stop();
    } catch (_) {}
    if (path != null && path.trim().isNotEmpty) {
      _onAudioPathReady?.call(path.trim());
    }
    _onAudioPathReady = null;
    if (!mounted) return;
    state = state.copyWith(
      status: VisitSpeechStatus.idle,
      partialText: '',
      clearError: true,
    );
  }

  /// {@template visit_speech_toggle}
  /// Dinleme açık/kapalı.
  /// {@endtemplate}
  Future<bool> toggleListening({
    required String languageCode,
    required void Function(String text) onFinalText,
    String? visitId,
    void Function(String path)? onAudioPathReady,
  }) async {
    if (state.isListening) {
      await stopListening();
      return false;
    }
    return startListening(
      languageCode: languageCode,
      onFinalText: onFinalText,
      visitId: visitId,
      onAudioPathReady: onAudioPathReady,
    );
  }

  /// {@template visit_speech_dispose_speech}
  /// Kaynakları serbest bırakır.
  /// {@endtemplate}
  Future<void> disposeSpeech() async {
    await stopListening();
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    disposeSpeech();
    super.dispose();
  }
}

/// Form kapsamlı autoDispose STT store.
final visitSpeechProvider =
    StateNotifierProvider.autoDispose<VisitSpeechToTextStore, VisitSpeechState>(
  (ref) {
    final store = VisitSpeechToTextStore();
    ref.onDispose(() {
      // ignore: discarded_futures
      store.disposeSpeech();
    });
    return store;
  },
);
