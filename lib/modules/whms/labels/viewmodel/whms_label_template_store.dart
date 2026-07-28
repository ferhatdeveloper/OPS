// Dosya Adı: whms_label_template_store.dart
// Açıklama: whms_label_templates SQLite CRUD (etiket şablon stub)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/whms_label_template.dart';

/// {@template whms_label_template_store}
/// Etiket şablon stub CRUD — offline-first.
///
/// Kullanım örneği:
/// ```dart
/// final s = WhmsLabelTemplateStore();
/// await s.ensureReady();
/// await s.seedDefaultsIfEmpty();
/// ```
/// {@endtemplate}
class WhmsLabelTemplateStore {
  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro whms_label_template_store}
  const WhmsLabelTemplateStore({this.openDb});

  static const String tableName = 'whms_label_templates';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tabloyu hazırlar.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsLabelTemplatesTable);
  }

  /// Aktif şablonlar.
  Future<List<WhmsLabelTemplate>> listActive() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0 '
          'AND COALESCE(is_active, 1) = 1',
      orderBy: 'code COLLATE NOCASE ASC',
    );
    return maps.map(WhmsLabelTemplate.fromMap).toList(growable: false);
  }

  /// Boşsa ürün + raf örnek şablonlarını yazar.
  Future<void> seedDefaultsIfEmpty() async {
    await ensureReady();
    final existing = await listActive();
    if (existing.isNotEmpty) return;
    await upsert(
      const WhmsLabelTemplate(
        id: '',
        code: 'URUN50',
        name: 'Ürün 50x30',
        labelType: WhmsLabelTemplate.typeProductSmall,
        sampleProductName: 'ÖRNEK ÜRÜN',
        sampleProductCode: 'BRC-10023',
        samplePrice: '1.250,00',
      ),
    );
    await upsert(
      const WhmsLabelTemplate(
        id: '',
        code: 'RAF80',
        name: 'Raf 80x40',
        labelType: WhmsLabelTemplate.typeShelfLarge,
        sampleProductName: 'ÖRNEK RAF',
        sampleProductCode: 'SHF-20001',
        samplePrice: '99,90',
      ),
    );
  }

  /// id boşsa insert; doluysa update.
  Future<WhmsLabelTemplate> upsert(WhmsLabelTemplate row) async {
    final code = row.code.trim();
    final name = row.name.trim();
    if (code.isEmpty || name.isEmpty) {
      throw ArgumentError('code and name required');
    }
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final id = row.id.trim().isEmpty ? const Uuid().v4() : row.id.trim();
    final next = WhmsLabelTemplate(
      id: id,
      code: code,
      name: name,
      labelType: row.labelType == WhmsLabelTemplate.typeShelfLarge
          ? WhmsLabelTemplate.typeShelfLarge
          : WhmsLabelTemplate.typeProductSmall,
      sampleProductName: row.sampleProductName?.trim(),
      sampleProductCode: row.sampleProductCode?.trim(),
      samplePrice: row.samplePrice?.trim(),
      isActive: row.isActive,
      createdAt: row.createdAt?.trim().isNotEmpty == true
          ? row.createdAt
          : now,
      updatedAt: now,
    );
    await db.insert(
      tableName,
      next.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return next;
  }

  /// Soft delete.
  Future<void> softDelete(String id) async {
    final key = id.trim();
    if (key.isEmpty) return;
    await ensureReady();
    final db = await _db();
    await db.update(
      tableName,
      <String, Object?>{
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[key],
    );
  }
}
