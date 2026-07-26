// Dosya Adı: logo_job_store.dart
// Açıklama: Logo iş kuyruğu dens — sync_queue (job_queue) okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/logo_job_record.dart';

/// {@template logo_job_store}
/// `sync_queue` tablosunu oluşturur (yoksa) ve bekleyen Logo işlerini okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = LogoJobStore();
/// final rows = await store.loadAll();
/// ```
/// {@endtemplate}
class LogoJobStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro logo_job_store}
  const LogoJobStore({this.openDb});

  /// [tableName]: JobQueueService tablosu (`sync_queue`)
  static const String tableName = 'sync_queue';

  /// {@template logo_job_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template logo_job_store_ensure}
  /// sync_queue tablosunu oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createSyncQueueTable);
  }

  /// {@template logo_job_store_load_all}
  /// Bekleyen Logo job_queue satırlarını öncelik + tarihe göre döner.
  ///
  /// Dönüş değeri:
  /// - [List<LogoJobRecord>]: dens satırlar (seed yok — gerçek kuyruk)
  /// {@endtemplate}
  Future<List<LogoJobRecord>> loadAll() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      orderBy: 'priority DESC, created_at ASC',
    );
    return LogoJobRecord.fromMaps(
      maps.map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }
}
