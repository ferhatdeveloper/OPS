// Dosya Adı: einvoice_status_store.dart
// Açıklama: e-Fatura durum dens satırları SQLite okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/einvoice_status_record.dart';
import '../model/einvoice_status_seed.dart';

/// {@template einvoice_status_store}
/// `einvoice_status` tablosunu oluşturur (yoksa) ve aktif satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = EinvoiceStatusStore();
/// final rows = await store.loadAll();
/// ```
/// {@endtemplate}
class EinvoiceStatusStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro einvoice_status_store}
  const EinvoiceStatusStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = EinvoiceStatusSeed.tableName;

  /// {@template einvoice_status_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template einvoice_status_store_ensure}
  /// Tabloyu oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createEinvoiceStatusTable);
  }

  /// {@template einvoice_status_store_load_all}
  /// Soft-delete edilmemiş dens satırlarını tarihe göre (yeniden eskiye) döner.
  ///
  /// Dönüş değeri:
  /// - [List<EinvoiceStatusRecord>]: Aktif e-Fatura durum satırları
  /// {@endtemplate}
  Future<List<EinvoiceStatusRecord>> loadAll() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: 'COALESCE(is_deleted, 0) = 0',
      orderBy: 'COALESCE(document_date, created_at, updated_at) DESC, '
          'id ASC',
    );
    return maps
        .map(EinvoiceStatusRecord.fromMap)
        .toList(growable: false);
  }
}
