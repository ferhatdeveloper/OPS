// Dosya Adı: cash_card_store.dart
// Açıklama: cash_cards SQLite seed / sync erişim katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/cash_card_seed.dart';

/// {@template cash_card_store}
/// `cash_cards` tablosunu oluşturur, master seed yazar, sync durumunu yönetir.
///
/// Kullanım örneği:
/// ```dart
/// final store = CashCardStore();
/// await store.ensureReady();
/// final rows = await store.listActive();
/// ```
/// {@endtemplate}
class CashCardStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro cash_card_store}
  const CashCardStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = CashCardSeed.tableName;

  /// {@template cash_card_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template cash_card_store_ensure}
  /// Tabloyu oluşturur (yoksa) ve boşsa CashCardMaster seed ekler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createCashCardsTable);
    await seedIfEmpty(db);
  }

  /// {@template cash_card_store_seed_if_empty}
  /// Tablo boşsa master seed satırlarını yazar.
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
    for (final map in CashCardSeed.defaultMaps) {
      batch.insert(
        tableName,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// {@template cash_card_store_sync_from_master}
  /// CashCardMaster satırlarını upsert eder (eksik kodları tamamlar).
  ///
  /// Dönüş değeri:
  /// - [int]: Yazılan / güncellenen satır sayısı
  /// {@endtemplate}
  Future<int> syncFromMaster() async {
    final db = await _db();
    await db.execute(SqlQuerys.createCashCardsTable);
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    var n = 0;
    for (final map in CashCardSeed.defaultMaps) {
      final row = Map<String, dynamic>.from(map);
      row['updated_at'] = now;
      row['is_synced'] = 0;
      batch.insert(
        tableName,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      n++;
    }
    await batch.commit(noResult: true);
    return n;
  }

  /// {@template cash_card_store_list_active}
  /// Aktif kasa kartlarını kod sırasıyla döner.
  ///
  /// Dönüş değeri:
  /// - [List]: Aktif [CashCardRecord] listesi
  /// {@endtemplate}
  Future<List<CashCardRecord>> listActive() async {
    final db = await _db();
    await db.execute(SqlQuerys.createCashCardsTable);
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_active, 1) = 1',
      orderBy: 'code ASC',
    );
    return maps.map(CashCardRecord.fromMap).toList(growable: false);
  }

  /// {@template cash_card_store_count}
  /// Toplam satır sayısı.
  ///
  /// Dönüş değeri:
  /// - [int]: Kayıt adedi
  /// {@endtemplate}
  Future<int> count() async {
    final db = await _db();
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
        ) ??
        0;
  }

  /// {@template cash_card_store_pending_sync}
  /// Henüz sync edilmemiş (`is_synced=0`) satır sayısı.
  ///
  /// Dönüş değeri:
  /// - [int]: Bekleyen adet
  /// {@endtemplate}
  Future<int> pendingSyncCount() async {
    final db = await _db();
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $tableName '
            'WHERE COALESCE(is_synced, 0) = 0',
          ),
        ) ??
        0;
  }

  /// {@template cash_card_store_mark_all_synced}
  /// Tüm satırları sync edilmiş işaretler.
  /// {@endtemplate}
  Future<void> markAllSynced() async {
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.update(
      tableName,
      {'is_synced': 1, 'updated_at': now},
    );
  }
}
