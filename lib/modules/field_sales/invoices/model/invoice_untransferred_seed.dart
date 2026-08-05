// Dosya Adı: invoice_untransferred_seed.dart
// Açıklama: Transfer edilmeyen fatura dens stub seed (is_synced=0)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'invoice_untransferred_record.dart';

/// {@template invoice_untransferred_seed}
/// MBT Transfer Edilmeyen Faturalar dens stub seed (SQLite boşken).
///
/// Kullanım örneği:
/// ```dart
/// final rows = InvoiceUntransferredSeed.defaultRows;
/// ```
/// {@endtemplate}
class InvoiceUntransferredSeed {
  InvoiceUntransferredSeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/invoices-untransferred';

  /// [submenuTitle]: Menü seed alt başlık
  static const String submenuTitle = 'Transfer Edilmeyen Faturalar';

  /// [tableName]: SQLite kaynak tablo
  static const String tableName = 'invoices';

  /// [entityType]: sync_queue entity_type
  static const String entityType = 'invoice';

  /// Dens dönem filtresi (Bu Ay) ile uyumlu stub gün.
  static DateTime get _stubDay {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day == 1 ? 1 : now.day - 1);
  }

  /// Yer tutucu dens satırlar (yalnızca is_synced=0).
  static List<InvoiceUntransferredRecord> get defaultRows {
    final day = _stubDay;
    return [
      InvoiceUntransferredRecord(
        id: 'inv_untr_sales_001',
        documentNo: 'FT20260011',
        invoiceType: 'field_sales.wholesale_invoice_8',
        docSide: InvoiceUntransferredDocSide.sales,
        customerCode: 'C0001',
        customerName: 'Demo Cari A.Ş.',
        documentDate: day,
        amount: 2450.00,
        status: 'Completed',
        approvalStatus: 1,
        isSynced: 0,
        queueJobId: 'job_inv_stub_001',
        createdAt: day.add(const Duration(hours: 9, minutes: 15)),
        updatedAt: day.add(const Duration(hours: 9, minutes: 15)),
      ),
      InvoiceUntransferredRecord(
        id: 'inv_untr_sales_002',
        documentNo: 'FT20260012',
        invoiceType: 'field_sales.van_sales',
        docSide: InvoiceUntransferredDocSide.sales,
        customerCode: 'C0002',
        customerName: 'Örnek Ticaret Ltd.',
        documentDate: day,
        amount: 780.25,
        status: 'Completed',
        approvalStatus: 1,
        isSynced: 0,
        createdAt: day.add(const Duration(hours: 16)),
        updatedAt: day.add(const Duration(hours: 16, minutes: 5)),
      ),
      InvoiceUntransferredRecord(
        id: 'inv_untr_purchase_001',
        documentNo: 'AF20260005',
        invoiceType: 'field_sales.purchase_invoice',
        docSide: InvoiceUntransferredDocSide.purchase,
        customerCode: 'S0001',
        customerName: 'Tedarikçi XYZ',
        documentDate: day,
        amount: 9100.00,
        status: 'Completed',
        approvalStatus: 1,
        isSynced: 0,
        createdAt: day.add(const Duration(hours: 11, minutes: 30)),
        updatedAt: day.add(const Duration(hours: 11, minutes: 30)),
      ),
    ];
  }
  /// {@template invoice_untransferred_seed_sales_rows}
  /// Satış dens stub satırları.
  /// {@endtemplate}
  static List<InvoiceUntransferredRecord> get salesRows => defaultRows
      .where((r) => r.docSide == InvoiceUntransferredDocSide.sales)
      .toList(growable: false);

  /// {@template invoice_untransferred_seed_purchase_rows}
  /// Alış dens stub satırları.
  /// {@endtemplate}
  static List<InvoiceUntransferredRecord> get purchaseRows => defaultRows
      .where((r) => r.docSide == InvoiceUntransferredDocSide.purchase)
      .toList(growable: false);

  /// {@template invoice_untransferred_seed_maps}
  /// SQLite / seed insert map listesi.
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);
}
