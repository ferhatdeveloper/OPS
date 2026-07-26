// Dosya Adı: invoice_pending_store.dart
// Açıklama: Bekleyen faturalar dens SQLite okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/invoice_pending_record.dart';
import '../model/invoice_pending_seed.dart';

/// {@template invoice_pending_store}
/// `invoices` tablosundan onay/status bekleyen dens satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = InvoicePendingStore();
/// final rows = await store.loadPending();
/// ```
/// {@endtemplate}
class InvoicePendingStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro invoice_pending_store}
  const InvoicePendingStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = InvoicePendingSeed.tableName;

  /// {@template invoice_pending_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template invoice_pending_store_ensure}
  /// `invoices` tablosunu oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createInvoicesTable);
  }

  /// {@template invoice_pending_store_load_pending}
  /// Bekleyen faturaları tarihe göre (yeniden eskiye) döner.
  /// Kriter: `approval_status = 0` veya `status = Pending`.
  ///
  /// Dönüş değeri:
  /// - [List<InvoicePendingRecord>]: Bekleyen dens satırlar
  /// {@endtemplate}
  Future<List<InvoicePendingRecord>> loadPending() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      tableName,
      where: "COALESCE(approval_status, 0) = 0 "
          "OR LOWER(COALESCE(status, '')) = 'pending'",
      orderBy: 'invoice_date DESC, id ASC',
    );
    return maps
        .where(InvoicePendingRecord.isPendingMap)
        .map(InvoicePendingRecord.fromMap)
        .toList(growable: false);
  }
}
