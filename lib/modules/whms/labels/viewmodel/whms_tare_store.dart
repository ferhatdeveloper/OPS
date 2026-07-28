// Dosya Adı: whms_tare_store.dart
// Açıklama: whms_tares SQLite CRUD (dens master)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/whms_tare.dart';

/// {@template whms_tare_store}
/// Dara master CRUD — offline-first.
///
/// Kullanım örneği:
/// ```dart
/// final s = WhmsTareStore();
/// await s.ensureReady();
/// await s.upsert(const WhmsTare(id: '', code: 'PALET', name: 'Palet', weight: 25));
/// ```
/// {@endtemplate}
class WhmsTareStore {
  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro whms_tare_store}
  const WhmsTareStore({this.openDb});

  static const String tableName = 'whms_tares';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tabloyu hazırlar.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsTaresTable);
  }

  /// Aktif daralar.
  Future<List<WhmsTare>> listActive() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0 '
          'AND COALESCE(is_active, 1) = 1',
      orderBy: 'code COLLATE NOCASE ASC',
    );
    return maps.map(WhmsTare.fromMap).toList(growable: false);
  }

  /// id boşsa insert; doluysa update. UNIQUE(code).
  Future<WhmsTare> upsert(WhmsTare row) async {
    final code = row.code.trim();
    final name = row.name.trim();
    if (code.isEmpty || name.isEmpty) {
      throw ArgumentError('code and name required');
    }
    if (row.weight < 0) {
      throw ArgumentError('weight must be >= 0');
    }
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final id = row.id.trim().isEmpty ? const Uuid().v4() : row.id.trim();
    final next = WhmsTare(
      id: id,
      code: code,
      name: name,
      weight: row.weight,
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
