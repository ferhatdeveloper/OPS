// Dosya Adı: invoice_untransferred_store.dart
// Açıklama: Transfer edilmeyen faturalar — SQLite is_synced=0 + sync_queue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/invoice_untransferred_record.dart';
import 'invoice_untransferred_query.dart';

/// {@template invoice_untransferred_store}
/// `invoices` (is_synced=0) + `sync_queue` (entity=invoice) dens okuma.
///
/// Kullanım örneği:
/// ```dart
/// final store = InvoiceUntransferredStore();
/// final rows = await store.loadUnsynced();
/// ```
/// {@endtemplate}
class InvoiceUntransferredStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// [loader]: Test için sabit satır enjeksiyonu (DB atlanır)
  final Future<List<InvoiceUntransferredRecord>> Function()? loader;

  /// {@macro invoice_untransferred_store}
  const InvoiceUntransferredStore({
    this.openDb,
    this.loader,
  });

  /// {@template invoice_untransferred_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template invoice_untransferred_store_load}
  /// Transfer edilmeyen faturaları SQLite + kuyruktan birleştirir.
  ///
  /// Dönüş değeri:
  /// - [List]: Dens kayıtları (tarih DESC)
  /// {@endtemplate}
  Future<List<InvoiceUntransferredRecord>> loadUnsynced() async {
    if (loader != null) return loader!();
    final db = await _db();
    final invoiceMaps =
        await db.rawQuery(SqlQuerys.invoiceUntransferredDensRowsSql);
    final local =
        InvoiceUntransferredQuery.fromInvoiceSqliteMaps(invoiceMaps);
    List<Map<String, dynamic>> jobs = const [];
    try {
      jobs = await db.query(
        'sync_queue',
        where: 'LOWER(entity_type) = ?',
        whereArgs: const ['invoice'],
        orderBy: 'created_at DESC',
      );
    } catch (_) {
      jobs = const [];
    }
    final queued = InvoiceUntransferredQuery.fromSyncQueueJobs(jobs);
    return InvoiceUntransferredQuery.mergeLocalAndQueue(
      local: local,
      queued: queued,
    );
  }
}
