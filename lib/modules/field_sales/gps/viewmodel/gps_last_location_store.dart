// Dosya Adı: gps_last_location_store.dart
// Açıklama: GPS dens son konum listesi SQLite erişim + seed
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/gps_last_location_record.dart';
import '../model/gps_last_location_seed.dart';

/// {@template gps_last_location_store}
/// `gps_logs` tablosunu oluşturur, boşsa seedler, son konumları sorgular.
///
/// Kullanım örneği:
/// ```dart
/// final store = GpsLastLocationStore();
/// final rows = await store.loadLastLocations();
/// ```
/// {@endtemplate}
class GpsLastLocationStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro gps_last_location_store}
  const GpsLastLocationStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = GpsLastLocationSeed.tableName;

  /// {@template gps_last_location_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template gps_last_location_store_ensure}
  /// Tabloyu oluşturur, dens kolonlarını ekler, boşsa seedler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createGpsLogsTable);
    await _ensureColumns(db);
    await seedIfEmpty(db);
  }

  /// {@template gps_last_location_store_ensure_columns}
  /// Eski şemaya dens kolonlarını ekler (yoksa).
  /// {@endtemplate}
  Future<void> _ensureColumns(Database db) async {
    const alters = <String>[
      SqlQuerys.addGpsLogsSalespersonCodeColumn,
      SqlQuerys.addGpsLogsLabelColumn,
      SqlQuerys.addGpsLogsAccuracyColumn,
      SqlQuerys.addGpsLogsIsDeletedColumn,
      SqlQuerys.addGpsLogsCreatedAtColumn,
      SqlQuerys.addGpsLogsUpdatedAtColumn,
    ];
    for (final sql in alters) {
      try {
        await db.execute(sql);
      } catch (_) {
        // Kolon zaten var
      }
    }
  }

  /// {@template gps_last_location_store_seed_if_empty}
  /// Tablo boşsa MBT dens örnek son konumları ekler.
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
    for (final row in GpsLastLocationSeed.defaultRows) {
      batch.insert(
        tableName,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template gps_last_location_store_load_last}
  /// Plasiyer koduna göre en son konumları döner (yeniden eskiye).
  ///
  /// Parametreler:
  /// - [limit]: Maksimum satır (varsayılan 100)
  ///
  /// Dönüş değeri:
  /// - [List]: Son konum dens satırları
  /// {@endtemplate}
  Future<List<GpsLastLocationRecord>> loadLastLocations({
    int limit = 100,
  }) async {
    await ensureReady();
    final db = await _db();

    // Plasiyer kodu doluysa grup sonu; boş kodlu ham loglar da dahil.
    final rows = await db.rawQuery(
      '''
      SELECT g.*
      FROM $tableName g
      INNER JOIN (
        SELECT
          COALESCE(salesperson_code, '') AS sc,
          MAX(timestamp) AS max_ts
        FROM $tableName
        WHERE COALESCE(is_deleted, 0) = 0
        GROUP BY COALESCE(salesperson_code, '')
      ) latest
        ON COALESCE(g.salesperson_code, '') = latest.sc
       AND g.timestamp = latest.max_ts
      WHERE COALESCE(g.is_deleted, 0) = 0
      ORDER BY g.timestamp DESC
      LIMIT ?
      ''',
      [limit],
    );

    return rows.map(GpsLastLocationRecord.fromMap).toList(growable: false);
  }
}
