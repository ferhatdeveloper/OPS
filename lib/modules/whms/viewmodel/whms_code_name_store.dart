// Dosya Adı: whms_code_name_store.dart
// Açıklama: WHMS kod+ad SQLite store fabrikası (araç/lot/rezervasyon/iade)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../service/database_service.dart';
import '../view/whms_master_code_name_list_screen.dart';

/// {@template whms_code_name_store}
/// Tek tablo kod+ad CRUD — [createSql] ile tablo kurar.
///
/// Kullanım örneği:
/// ```dart
/// final s = WhmsCodeNameStore(
///   tableName: 'whms_vehicles',
///   createSql: SqlQuerys.createWhmsVehiclesTable,
/// );
/// await s.list();
/// ```
/// {@endtemplate}
class WhmsCodeNameStore implements WhmsMasterCodeNameStore {
  /// [tableName]: SQLite tablo
  final String tableName;

  /// [createSql]: CREATE TABLE IF NOT EXISTS
  final String createSql;

  /// [openDb]: Test DB
  final Future<Database> Function()? openDb;

  /// {@macro whms_code_name_store}
  const WhmsCodeNameStore({
    required this.tableName,
    required this.createSql,
    this.openDb,
  });

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// Tabloyu hazırlar.
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(createSql);
  }

  @override
  Future<List<WhmsMasterRow>> list() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'code COLLATE NOCASE ASC',
    );
    return maps
        .map(
          (m) => WhmsMasterRow(
            id: m['id']?.toString() ?? '',
            code: m['code']?.toString() ?? '',
            name: m['name']?.toString() ?? '',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<WhmsMasterRow> upsert({
    required String id,
    required String code,
    required String name,
  }) async {
    final c = code.trim();
    final n = name.trim();
    if (c.isEmpty || n.isEmpty) {
      throw ArgumentError('code and name required');
    }
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    final key = id.trim().isEmpty ? const Uuid().v4() : id.trim();
    await db.insert(
      tableName,
      <String, Object?>{
        'id': key,
        'code': c,
        'name': n,
        'is_active': 1,
        'ONAY': 0,
        'is_synced': 0,
        'is_deleted': 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return WhmsMasterRow(id: key, code: c, name: n);
  }

  @override
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
