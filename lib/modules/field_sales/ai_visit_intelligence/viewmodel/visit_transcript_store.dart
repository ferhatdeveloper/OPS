// Dosya Adı: visit_transcript_store.dart
// Açıklama: visit_transcripts SQLite + AI analiz kuyruğu
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:uuid/uuid.dart';

import '../../../../core/ai/features/visit_transcript_analyze_service.dart';
import '../../../../service/database_service.dart';
import '../model/visit_emotion.dart';
import '../model/visit_transcript.dart';

/// {@template visit_transcript_store}
/// Transcript CRUD + offline AI kuyruk (pending → done).
/// Silent write yalnız ONAY=0 draft.
/// {@endtemplate}
class VisitTranscriptStore {
  final VisitTranscriptAnalyzeService _analyzer;

  /// {@macro visit_transcript_store}
  VisitTranscriptStore({VisitTranscriptAnalyzeService? analyzer})
      : _analyzer = analyzer ?? VisitTranscriptAnalyzeService();

  /// Draft satır ekle (kullanıcı onayı yok)
  Future<VisitTranscript> insertDraft(VisitTranscript row) async {
    final db = await DatabaseService.getInstance();
    await db.ensureVisitVoiceIntelligenceSchema();
    final sqlite = await db.getDatabase();
    final draft = row.copyWith(queueStatus: 'pending', onay: 0);
    await sqlite.insert('visit_transcripts', draft.toMap());
    return draft;
  }

  /// STT metninden tek draft satır
  Future<VisitTranscript> addSttDraft({
    required String visitId,
    required String text,
    String speakerLabel = 'Speaker 1',
    String? lang,
    String? segmentId,
    int startMs = 0,
    int endMs = 0,
  }) async {
    final now = DateTime.now().toIso8601String();
    final row = VisitTranscript(
      id: const Uuid().v4(),
      visitId: visitId,
      segmentId: segmentId,
      speakerLabel: speakerLabel,
      startMs: startMs,
      endMs: endMs,
      text: text.trim(),
      lang: lang,
      queueStatus: 'pending',
      onay: 0,
      createdAt: now,
      updatedAt: now,
    );
    return insertDraft(row);
  }

  /// Bekleyen satırları AI ile işle (net yoksa pending kalır)
  Future<VisitTranscriptAnalyzeResult?> processQueue(String visitId) async {
    final db = await DatabaseService.getInstance();
    await db.ensureVisitVoiceIntelligenceSchema();
    final sqlite = await db.getDatabase();
    final rows = await sqlite.query(
      'visit_transcripts',
      where: "visit_id = ? AND queue_status = 'pending' AND is_deleted = 0",
      whereArgs: [visitId],
      orderBy: 'start_ms ASC, created_at ASC',
    );
    if (rows.isEmpty) return null;

    final texts = rows
        .map((r) => VisitTranscript.fromMap(r))
        .map((t) => '${t.speakerLabel}: ${t.text}')
        .join('\n');

    final result = await _analyzer.analyze(
      visitId: visitId,
      transcriptText: texts,
    );

    if (!result.isOk) {
      // Net/key yok — pending bırak
      return result;
    }

    final now = DateTime.now().toIso8601String();
    for (final r in rows) {
      await sqlite.update(
        'visit_transcripts',
        {
          'queue_status': 'done',
          'emotion': result.emotion.storageKey,
          'lang': result.lang,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }

    // Silent draft write — visits.ai_status_draft / emotion_summary
    await sqlite.update(
      'visits',
      {
        'emotion_summary': result.emotion.storageKey,
        'ai_status_draft': result.statusSuggestion ?? result.summary,
      },
      where: 'id = ?',
      whereArgs: [visitId],
    );

    // Diarize hint (best-effort)
    try {
      final diarized = await _analyzer.diarizeHint(
        visitId: visitId,
        segmentsText: texts,
      );
      for (final d in diarized) {
        await sqlite.insert('visit_transcripts', d.toMap());
      }
    } catch (_) {}

    return result;
  }

  /// Kullanıcı onaylı: draft notu visits.notes’a yaz + ONAY=1
  Future<void> approveStatusSuggestion({
    required String visitId,
    required String notesAppend,
  }) async {
    final db = await DatabaseService.getInstance();
    final sqlite = await db.getDatabase();
    final visitRows = await sqlite.query(
      'visits',
      columns: ['notes', 'ai_status_draft'],
      where: 'id = ?',
      whereArgs: [visitId],
      limit: 1,
    );
    if (visitRows.isEmpty) return;
    final existing = (visitRows.first['notes']?.toString() ?? '').trim();
    final draft = notesAppend.trim().isNotEmpty
        ? notesAppend.trim()
        : (visitRows.first['ai_status_draft']?.toString() ?? '').trim();
    if (draft.isEmpty) return;
    final merged = existing.isEmpty ? draft : '$existing\n$draft';
    await sqlite.update(
      'visits',
      {'notes': merged, 'ai_status_draft': null},
      where: 'id = ?',
      whereArgs: [visitId],
    );
    await sqlite.update(
      'visit_transcripts',
      {
        'ONAY': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'visit_id = ? AND ONAY = 0',
      whereArgs: [visitId],
    );
  }

  /// Ziyaret transcriptleri
  Future<List<VisitTranscript>> listForVisit(String visitId) async {
    final db = await DatabaseService.getInstance();
    await db.ensureVisitVoiceIntelligenceSchema();
    final sqlite = await db.getDatabase();
    final rows = await sqlite.query(
      'visit_transcripts',
      where: 'visit_id = ? AND is_deleted = 0',
      whereArgs: [visitId],
      orderBy: 'start_ms ASC, created_at ASC',
    );
    return rows.map(VisitTranscript.fromMap).toList(growable: false);
  }
}
