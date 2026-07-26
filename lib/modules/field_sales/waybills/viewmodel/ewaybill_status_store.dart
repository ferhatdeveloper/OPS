// Dosya Adı: ewaybill_status_store.dart
// Açıklama: e-İrsaliye durum dens SQLite okuma / seed katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/ewaybill_status_record.dart';
import '../model/ewaybill_status_seed.dart';

/// {@template ewaybill_status_store}
/// `ewaybill_status` tablosunu oluşturur, boşsa seedler, dens satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = EwaybillStatusStore();
/// final rows = await store.loadAll();
/// ```
/// {@endtemplate}
class EwaybillStatusStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro ewaybill_status_store}
  const EwaybillStatusStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = EwaybillStatusSeed.tableName;

  /// {@template ewaybill_status_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template ewaybill_status_store_ensure}
  /// Tabloyu oluşturur (yoksa) ve boşsa stub seed ekler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createEwaybillStatusTable);
    await seedIfEmpty(db);
  }

  /// {@template ewaybill_status_store_seed_if_empty}
  /// Tablo boşsa MBT dens stub satırlarını yazar.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite bağlantısı
  /// {@endtemplate}
  Future<void> seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableName '
            'WHERE COALESCE(is_deleted, 0) = 0',
          ),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();
    for (final map in EwaybillStatusSeed.defaultMaps) {
      batch.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template ewaybill_status_store_load_all}
  /// Aktif dens satırlarını SQLite’tan yükler (yeniden eskiye).
  ///
  /// Dönüş değeri:
  /// - [List]: `is_deleted = 0` kayıtlar
  /// {@endtemplate}
  Future<List<EwaybillStatusRecord>> loadAll() async {
    await ensureReady();
    final db = await _db();
    final rows = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'document_date DESC, updated_at DESC, document_no ASC',
    );
    return rows.map(EwaybillStatusRecord.fromMap).toList(growable: false);
  }
}
