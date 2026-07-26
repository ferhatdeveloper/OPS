// Dosya Adı: sales_target_store.dart
// Açıklama: Satış hedefleri dens satırları SQLite + seed katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/sales_target_record.dart';
import '../model/sales_target_seed.dart';

/// {@template sales_target_store}
/// `targets` tablosunu oluşturur, boşsa seedler, dens satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = SalesTargetStore();
/// final rows = await store.loadAll();
/// ```
/// {@endtemplate}
class SalesTargetStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro sales_target_store}
  const SalesTargetStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = SalesTargetSeed.tableName;

  /// {@template sales_target_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template sales_target_store_ensure}
  /// Tabloyu oluşturur (yoksa) ve boşsa seed ekler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createTargetsTable);
    await seedIfEmpty(db);
  }

  /// {@template sales_target_store_seed_if_empty}
  /// Tablo boşsa MBT dens örnek hedefleri ekler.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite bağlantısı
  /// {@endtemplate}
  Future<void> seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
        ) ??
        0;
    if (count > 0) return;

    final batch = db.batch();
    for (final map in SalesTargetSeed.defaultMaps) {
      batch.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template sales_target_store_load_all}
  /// Dens satırlarını dönem / oluşum tarihine göre (yeniden eskiye) döner.
  ///
  /// Dönüş değeri:
  /// - [List<SalesTargetRecord>]: Aktif satış hedefi satırları
  /// {@endtemplate}
  Future<List<SalesTargetRecord>> loadAll() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      orderBy: 'period DESC, type ASC, user_id ASC',
    );
    return maps.map(SalesTargetRecord.fromMap).toList(growable: false);
  }

  /// {@template sales_target_store_load_by_type}
  /// Tür filtresiyle dens satırlarını döner.
  ///
  /// Parametreler:
  /// - [type]: `Sales` | `Collection` | `Visit` (boş → tümü)
  ///
  /// Dönüş değeri:
  /// - [List<SalesTargetRecord>]: Filtrelenmiş satırlar
  /// {@endtemplate}
  Future<List<SalesTargetRecord>> loadByType(String type) async {
    final all = await loadAll();
    final t = type.trim();
    if (t.isEmpty) return all;
    return all
        .where((r) => r.type.toLowerCase() == t.toLowerCase())
        .toList(growable: false);
  }
}
