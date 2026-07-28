// Dosya Adı: ai_dynamic_report_store.dart
// Açıklama: AI dinamik rapor tanımları SQLite store (merkez yazma yok)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/ai/features/postgrest_query_spec.dart';
import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/ai_dynamic_report_definition.dart';

/// {@template ai_dynamic_report_store}
/// Yerel `ai_dynamic_reports` — sync kuyruğu opsiyonel (is_synced flag).
/// {@endtemplate}
class AiDynamicReportStore {
  static const String tableName = 'ai_dynamic_reports';

  final Uuid _uuid;

  /// {@macro ai_dynamic_report_store}
  AiDynamicReportStore({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<Database> _db() async {
    final svc = await DatabaseService.getInstance();
    final db = await svc.getDatabase();
    await db.execute(SqlQuerys.createAiDynamicReportsTable);
    return db;
  }

  /// Liste
  Future<List<AiDynamicReportDefinition>> listAll() async {
    final db = await _db();
    final rows = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'created_at DESC',
    );
    return rows.map(AiDynamicReportDefinition.fromMap).toList();
  }

  /// Kaydet (onay sonrası)
  Future<AiDynamicReportDefinition> saveProposal({
    required AiReportProposal proposal,
    String? createdBy,
    bool addFavoriteShortcut = false,
  }) async {
    final def = AiDynamicReportDefinition.fromProposal(
      id: _uuid.v4(),
      proposal: proposal,
      createdBy: createdBy,
      isFavoriteShortcut: addFavoriteShortcut,
    );
    final db = await _db();
    await db.insert(
      tableName,
      def.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return def;
  }

  /// Sil (soft)
  Future<void> softDelete(String id) async {
    final db = await _db();
    await db.update(
      tableName,
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
