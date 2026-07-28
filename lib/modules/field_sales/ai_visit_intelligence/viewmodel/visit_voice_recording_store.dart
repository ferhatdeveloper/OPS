// Dosya Adı: visit_voice_recording_store.dart
// Açıklama: Ziyaret arka plan / oturum ses kaydı (izin + KVKK onay)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../../service/database_service.dart';
import '../../routes/model/visit_speech_audio_helper.dart';
import '../model/visit_audio_segment.dart';

/// {@template visit_voice_recording_state}
/// Kayıt oturumu durumu.
/// {@endtemplate}
class VisitVoiceRecordingState {
  /// [isRecording]
  final bool isRecording;

  /// [hasConsent]
  final bool hasConsent;

  /// [visitId]
  final String? visitId;

  /// [filePath]
  final String? filePath;

  /// [segmentId]
  final String? segmentId;

  /// [errorKey]: l10n
  final String? errorKey;

  /// [startedAtMs]
  final int? startedAtMs;

  /// {@macro visit_voice_recording_state}
  const VisitVoiceRecordingState({
    this.isRecording = false,
    this.hasConsent = false,
    this.visitId,
    this.filePath,
    this.segmentId,
    this.errorKey,
    this.startedAtMs,
  });

  VisitVoiceRecordingState copyWith({
    bool? isRecording,
    bool? hasConsent,
    String? visitId,
    String? filePath,
    String? segmentId,
    String? errorKey,
    int? startedAtMs,
    bool clearError = false,
  }) {
    return VisitVoiceRecordingState(
      isRecording: isRecording ?? this.isRecording,
      hasConsent: hasConsent ?? this.hasConsent,
      visitId: visitId ?? this.visitId,
      filePath: filePath ?? this.filePath,
      segmentId: segmentId ?? this.segmentId,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      startedAtMs: startedAtMs ?? this.startedAtMs,
    );
  }
}

/// {@template visit_voice_recording_store}
/// Check-in açıkken sürekli ses kaydı (kullanıcı onayı şart).
/// Offline-first: segment SQLite; AI kuyruk ayrı.
/// {@endtemplate}
class VisitVoiceRecordingStore
    extends StateNotifier<VisitVoiceRecordingState> {
  final AudioRecorder _recorder;
  final Future<PermissionStatus> Function() _requestMic;
  final Future<void> Function()? _ensureFgNotification;

  /// {@macro visit_voice_recording_store}
  VisitVoiceRecordingStore({
    AudioRecorder? recorder,
    Future<PermissionStatus> Function()? requestMic,
    Future<void> Function()? ensureFgNotification,
  })  : _recorder = recorder ?? AudioRecorder(),
        _requestMic = requestMic ?? (() => Permission.microphone.request()),
        _ensureFgNotification = ensureFgNotification,
        super(const VisitVoiceRecordingState());

  /// KVKK / kullanıcı onayı işaretle
  Future<void> setConsent({
    required String visitId,
    required bool accepted,
  }) async {
    if (!accepted) {
      state = state.copyWith(
        hasConsent: false,
        visitId: visitId,
        errorKey: 'field_sales.visit_voice.consent_required',
      );
      return;
    }
    final now = DateTime.now().toIso8601String();
    try {
      final db = await DatabaseService.getInstance();
      await db.ensureVisitVoiceIntelligenceSchema();
      final sqlite = await db.getDatabase();
      await sqlite.update(
        'visits',
        {'voice_consent_at': now},
        where: 'id = ?',
        whereArgs: [visitId],
      );
    } catch (_) {}
    state = state.copyWith(
      hasConsent: true,
      visitId: visitId,
      clearError: true,
    );
  }

  /// {@template visit_voice_recording_start}
  /// Kaydı başlat (izin + onay).
  /// {@endtemplate}
  Future<bool> start({required String visitId}) async {
    if (state.isRecording) return true;
    if (!state.hasConsent && state.visitId != visitId) {
      state = state.copyWith(
        errorKey: 'field_sales.visit_voice.consent_required',
      );
      return false;
    }
    if (!state.hasConsent) {
      state = state.copyWith(
        errorKey: 'field_sales.visit_voice.consent_required',
      );
      return false;
    }

    if (kIsWeb) {
      state = state.copyWith(
        errorKey: 'field_sales.visit_voice.unsupported_platform',
      );
      return false;
    }

    final mic = await _requestMic();
    if (!mic.isGranted) {
      state = state.copyWith(
        errorKey: 'field_sales.visit_speech_mic_denied',
      );
      return false;
    }

    final path = await VisitSpeechAudioHelper.plannedRecordingPath(
      visitId: visitId,
    );
    if (path == null) {
      state = state.copyWith(
        errorKey: 'field_sales.visit_voice.err_path',
      );
      return false;
    }

    try {
      await _ensureFgNotification?.call();
      await _wakeBackgroundService();
      final can = await _recorder.hasPermission();
      if (!can) {
        state = state.copyWith(
          errorKey: 'field_sales.visit_speech_mic_denied',
        );
        return false;
      }
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      final segmentId = const Uuid().v4();
      final now = DateTime.now();
      final iso = now.toIso8601String();
      final segment = VisitAudioSegment(
        id: segmentId,
        visitId: visitId,
        filePath: path,
        startMs: 0,
        createdAt: iso,
        updatedAt: iso,
      );
      await _insertSegment(segment);
      await _patchVisitAudioPath(visitId, path);

      state = state.copyWith(
        isRecording: true,
        visitId: visitId,
        filePath: path,
        segmentId: segmentId,
        startedAtMs: now.millisecondsSinceEpoch,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        errorKey: 'field_sales.visit_voice.err_record',
      );
      return false;
    }
  }

  /// {@template visit_voice_recording_stop}
  /// Kaydı durdur; segment end_ms güncelle.
  /// {@endtemplate}
  Future<String?> stop() async {
    if (!state.isRecording) return state.filePath;
    try {
      final path = await _recorder.stop();
      final endMs = state.startedAtMs == null
          ? 0
          : DateTime.now().millisecondsSinceEpoch - state.startedAtMs!;
      final segmentId = state.segmentId;
      if (segmentId != null) {
        await _closeSegment(segmentId, endMs, path ?? state.filePath);
      }
      if (state.visitId != null && (path ?? state.filePath) != null) {
        await _patchVisitAudioPath(
          state.visitId!,
          path ?? state.filePath!,
        );
      }
      state = state.copyWith(
        isRecording: false,
        filePath: path ?? state.filePath,
      );
      return path ?? state.filePath;
    } catch (_) {
      state = state.copyWith(
        isRecording: false,
        errorKey: 'field_sales.visit_voice.err_record',
      );
      return null;
    }
  }

  Future<void> _insertSegment(VisitAudioSegment segment) async {
    try {
      final db = await DatabaseService.getInstance();
      await db.ensureVisitVoiceIntelligenceSchema();
      final sqlite = await db.getDatabase();
      await sqlite.insert('visit_audio_segments', segment.toMap());
    } catch (_) {}
  }

  Future<void> _closeSegment(
    String segmentId,
    int endMs,
    String? path,
  ) async {
    try {
      final db = await DatabaseService.getInstance();
      final sqlite = await db.getDatabase();
      final patch = <String, Object?>{
        'end_ms': endMs,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (path != null && path.isNotEmpty) {
        patch['file_path'] = path;
      }
      await sqlite.update(
        'visit_audio_segments',
        patch,
        where: 'id = ?',
        whereArgs: [segmentId],
      );
    } catch (_) {}
  }

  Future<void> _patchVisitAudioPath(String visitId, String path) async {
    try {
      final db = await DatabaseService.getInstance();
      final sqlite = await db.getDatabase();
      await sqlite.update(
        'visits',
        {'audio_recording_path': path},
        where: 'id = ?',
        whereArgs: [visitId],
      );
    } catch (_) {}
  }

  Future<void> _wakeBackgroundService() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final service = FlutterBackgroundService();
      final running = await service.isRunning();
      if (!running) {
        await service.startService();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (state.isRecording) {
      _recorder.stop();
    }
    _recorder.dispose();
    super.dispose();
  }
}

/// Riverpod provider
final visitVoiceRecordingProvider = StateNotifierProvider<
    VisitVoiceRecordingStore, VisitVoiceRecordingState>((ref) {
  return VisitVoiceRecordingStore();
});
