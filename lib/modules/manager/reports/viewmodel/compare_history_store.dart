// Dosya Adı: compare_history_store.dart
// Açıklama: Dönem karşılaştırma geçmişi SQLite CRUD
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/compare_history_entry.dart';
import '../model/compare_matrix_models.dart';

/// {@template compare_history_store}
/// `period_compare_history` tablosunda kayıtlı karşılaştırmalar.
///
/// Kullanım örneği:
/// ```dart
/// final store = CompareHistoryStore();
/// final list = await store.list();
/// ```
/// {@endtemplate}
class CompareHistoryStore {
  /// [openDb]: Test enjeksiyonu
  final Future<Database> Function()? openDb;

  /// {@macro compare_history_store}
  const CompareHistoryStore({this.openDb});

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tabloyu oluşturur.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createPeriodCompareHistoryTable);
  }

  /// {@template compare_history_store_list}
  /// Silinmemiş kayıtlar (yeniden eskiye).
  ///
  /// Dönüş değeri:
  /// - [List<CompareHistoryEntry>]
  /// {@endtemplate}
  Future<List<CompareHistoryEntry>> list({int limit = 50}) async {
    await ensureReady();
    final db = await _db();
    final rows = await db.query(
      'period_compare_history',
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    final out = <CompareHistoryEntry>[];
    for (final row in rows) {
      final entry = _fromRow(row);
      if (entry != null) out.add(entry);
    }
    return out;
  }

  /// {@template compare_history_store_save}
  /// Yeni kayıt veya aynı isimde güncelleme.
  ///
  /// Parametreler:
  /// - [name]: Etiket
  /// - [query]: Sihirbaz
  /// - [result]: Snapshot (opsiyonel)
  /// - [replaceSameName]: Aynı isim varsa üzerine yaz
  ///
  /// Dönüş değeri:
  /// - [CompareHistoryEntry]
  /// {@endtemplate}
  Future<CompareHistoryEntry> save({
    required String name,
    required ComparisonWizardState query,
    CompareMatrixResult? result,
    bool replaceSameName = true,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('name required');
    }
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();

    String? existingId;
    if (replaceSameName) {
      final found = await db.query(
        'period_compare_history',
        columns: ['id'],
        where: 'name = ? AND COALESCE(is_deleted, 0) = 0',
        whereArgs: [trimmed],
        limit: 1,
      );
      if (found.isNotEmpty) {
        existingId = found.first['id']?.toString();
      }
    }

    final id = existingId ?? const Uuid().v4();
    final map = <String, Object?>{
      'id': id,
      'name': trimmed,
      'template': query.template.name,
      'query_json': jsonEncode(query.toJson()),
      'result_json':
          result == null ? null : jsonEncode(result.toJson()),
      'created_at': existingId == null
          ? now
          : (await _createdAt(db, id)) ?? now,
      'updated_at': now,
      'is_deleted': 0,
    };
    await db.insert(
      'period_compare_history',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return CompareHistoryEntry(
      id: id,
      name: trimmed,
      template: query.template,
      query: query,
      result: result,
      createdAt: map['created_at']!.toString(),
      updatedAt: now,
    );
  }

  /// Soft delete.
  Future<void> delete(String id) async {
    await ensureReady();
    final db = await _db();
    await db.update(
      'period_compare_history',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Id ile getir.
  Future<CompareHistoryEntry?> getById(String id) async {
    await ensureReady();
    final db = await _db();
    final rows = await db.query(
      'period_compare_history',
      where: 'id = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<String?> _createdAt(Database db, String id) async {
    final rows = await db.query(
      'period_compare_history',
      columns: ['created_at'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['created_at']?.toString();
  }

  CompareHistoryEntry? _fromRow(Map<String, Object?> row) {
    final id = row['id']?.toString() ?? '';
    final name = row['name']?.toString() ?? '';
    if (id.isEmpty || name.isEmpty) return null;

    Map<String, dynamic>? queryMap;
    try {
      final decoded = jsonDecode(row['query_json']?.toString() ?? '{}');
      if (decoded is Map) {
        queryMap = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    final query = ComparisonWizardState.fromJson(queryMap);
    if (query == null) return null;

    CompareTemplate template;
    try {
      template = CompareTemplate.values.byName(
        row['template']?.toString() ?? query.template.name,
      );
    } catch (_) {
      template = query.template;
    }

    CompareMatrixResult? result;
    final rawResult = row['result_json']?.toString();
    if (rawResult != null && rawResult.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawResult);
        if (decoded is Map) {
          result = CompareMatrixResult.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    return CompareHistoryEntry(
      id: id,
      name: name,
      template: template,
      query: query,
      result: result,
      createdAt: row['created_at']?.toString() ?? '',
      updatedAt: row['updated_at']?.toString() ?? '',
    );
  }
}
