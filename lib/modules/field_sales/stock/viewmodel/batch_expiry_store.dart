// Dosya Adı: batch_expiry_store.dart
// Açıklama: Parti / SKT dens satırları SQLite okuma + seed fallback
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/batch_expiry_record.dart';
import '../model/batch_expiry_seed.dart';

/// {@template batch_expiry_store}
/// `batch_expiry` tablosunu oluşturur (yoksa) ve aktif satırları okur.
/// Boşsa [BatchExpirySeed] fallback döner.
///
/// Kullanım örneği:
/// ```dart
/// final store = BatchExpiryStore();
/// final rows = await store.loadAllOrSeed();
/// ```
/// {@endtemplate}
class BatchExpiryStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro batch_expiry_store}
  const BatchExpiryStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = BatchExpirySeed.tableName;

  /// {@template batch_expiry_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template batch_expiry_store_ensure}
  /// Tabloyu oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createBatchExpiryTable);
  }

  /// {@template batch_expiry_store_load_all}
  /// Soft-delete edilmemiş dens satırlarını SKT’ye göre (yakından uzağa) döner.
  /// Tablo boşsa boş liste.
  ///
  /// Dönüş değeri:
  /// - [List<BatchExpiryRecord>]: Aktif parti / SKT satırları
  /// {@endtemplate}
  Future<List<BatchExpiryRecord>> loadAll() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'expiry_date ASC, product_code ASC, id ASC',
    );
    return maps
        .map(BatchExpiryRecord.fromMap)
        .toList(growable: false);
  }

  /// {@template batch_expiry_store_load_all_or_seed}
  /// SQLite satırlarını okur; boşsa stub seed listesini döner.
  ///
  /// Dönüş değeri:
  /// - [List<BatchExpiryRecord>]: SQLite veya seed satırları
  /// {@endtemplate}
  Future<List<BatchExpiryRecord>> loadAllOrSeed() async {
    try {
      final rows = await loadAll();
      if (rows.isEmpty) {
        return List<BatchExpiryRecord>.from(BatchExpirySeed.defaultRows);
      }
      return rows;
    } catch (_) {
      return List<BatchExpiryRecord>.from(BatchExpirySeed.defaultRows);
    }
  }
}
