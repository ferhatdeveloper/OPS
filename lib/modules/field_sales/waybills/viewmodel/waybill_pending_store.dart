// Dosya Adı: waybill_pending_store.dart
// Açıklama: Bekleyen irsaliyeler SQLite (approval_status=0) + dens seed
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/waybill_pending_seed.dart';

/// {@template waybill_pending_store}
/// `waybills` tablosundan onay bekleyen dens satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = WaybillPendingStore();
/// final rows = await store.loadPending();
/// ```
/// {@endtemplate}
class WaybillPendingStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'waybills';

  /// {@macro waybill_pending_store}
  const WaybillPendingStore({this.openDb});

  /// {@template waybill_pending_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template waybill_pending_store_ensure}
  /// Tabloyu oluşturur (yoksa) ve pending yoksa seed ekler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWaybillsTable);
    await seedPendingIfNone(db);
  }

  /// {@template waybill_pending_store_seed}
  /// `approval_status = 0` satır yoksa dens stub seed ekler.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite bağlantısı
  /// {@endtemplate}
  Future<void> seedPendingIfNone(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableName '
            'WHERE approval_status = 0',
          ),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();
    for (final row in WaybillPendingSeed.defaultMaps()) {
      batch.insert(
        tableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template waybill_pending_store_load}
  /// Onay bekleyen (`approval_status = 0`) irsaliyeleri yükler.
  ///
  /// Dönüş değeri:
  /// - [List<Map>]: SQLite dens satırlar (tarih DESC)
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> loadPending() async {
    await ensureReady();
    final db = await _db();
    return db.query(
      tableName,
      where: 'approval_status = ?',
      whereArgs: const [0],
      orderBy: 'waybill_date DESC',
    );
  }
}
