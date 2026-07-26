// Dosya Adı: invoice_list_dens_store.dart
// Açıklama: Fatura listesi dens — SQLite invoices okuma katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/invoice_list_dens_record.dart';

/// {@template invoice_list_dens_store}
/// `invoices` tablosundan fatura listesi dens satırlarını okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = InvoiceListDensStore();
/// final rows = await store.loadAll();
/// ```
/// {@endtemplate}
class InvoiceListDensStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro invoice_list_dens_store}
  const InvoiceListDensStore({this.openDb});

  /// {@template invoice_list_dens_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template invoice_list_dens_store_load_all}
  /// Tüm faturaları dens kaydı olarak (tarih DESC) yükler.
  ///
  /// Dönüş değeri:
  /// - [List<InvoiceListDensRecord>]: Dens satırları
  /// {@endtemplate}
  Future<List<InvoiceListDensRecord>> loadAll() async {
    final db = await _db();
    final maps = await db.rawQuery(SqlQuerys.invoiceListDensRowsSql);
    return maps
        .map(InvoiceListDensRecord.fromMap)
        .toList(growable: false);
  }
}
