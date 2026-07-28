// Dosya Adı: whms_package_type_store.dart
// Açıklama: whms_package_types SQLite CRUD (dens master)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/whms_package_type.dart';

/// {@template whms_package_type_store}
/// Paket tipi master CRUD — offline-first.
///
/// Kullanım örneği:
/// ```dart
/// final s = WhmsPackageTypeStore();
/// await s.ensureReady();
/// await s.upsert(const WhmsPackageType(id: '', code: 'KOLI', name: 'Koli'));
/// ```
/// {@endtemplate}
class WhmsPackageTypeStore {
  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro whms_package_type_store}
  const WhmsPackageTypeStore({this.openDb});

  static const String tableName = 'whms_package_types';

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tabloyu hazırlar.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsPackageTypesTable);
  }

  /// Aktif (silinmemiş) paket tipleri.
  Future<List<WhmsPackageType>> listActive() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0 '
          'AND COALESCE(is_active, 1) = 1',
      orderBy: 'code COLLATE NOCASE ASC',
    );
    return maps.map(WhmsPackageType.fromMap).toList(growable: false);
  }

  /// id boşsa insert; doluysa update. UNIQUE(code).
  Future<WhmsPackageType> upsert(WhmsPackageType row) async {
    final code = row.code.trim();
    final name = row.name.trim();
    if (code.isEmpty || name.isEmpty) {
      throw ArgumentError('code and name required');
    }
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final id = row.id.trim().isEmpty ? const Uuid().v4() : row.id.trim();
    final tare = row.tareRef?.trim();
    final next = WhmsPackageType(
      id: id,
      code: code,
      name: name,
      tareRef: (tare == null || tare.isEmpty) ? null : tare,
      afterSalesFlag: row.afterSalesFlag,
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
