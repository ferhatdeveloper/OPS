// Dosya Adı: invoice_untransferred_seed.dart
// Açıklama: Transfer edilmeyen fatura dens stub seed (is_synced=0)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

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

  /// Yer tutucu dens satırlar (yalnızca is_synced=0).
  static final List<InvoiceUntransferredRecord> defaultRows = [
    InvoiceUntransferredRecord(
      id: 'inv_untr_sales_001',
      documentNo: 'FT20260011',
      invoiceType: 'field_sales.wholesale_invoice_8',
      docSide: InvoiceUntransferredDocSide.sales,
      customerCode: 'C0001',
      customerName: 'Demo Cari A.Ş.',
      documentDate: DateTime(2026, 7, 26),
      amount: 2450.00,
      status: 'Completed',
      approvalStatus: 1,
      isSynced: 0,
      queueJobId: 'job_inv_stub_001',
      createdAt: DateTime(2026, 7, 26, 9, 15),
      updatedAt: DateTime(2026, 7, 26, 9, 15),
    ),
    InvoiceUntransferredRecord(
      id: 'inv_untr_sales_002',
      documentNo: 'FT20260012',
      invoiceType: 'field_sales.van_sales',
      docSide: InvoiceUntransferredDocSide.sales,
      customerCode: 'C0002',
      customerName: 'Örnek Ticaret Ltd.',
      documentDate: DateTime(2026, 7, 25),
      amount: 780.25,
      status: 'Completed',
      approvalStatus: 1,
      isSynced: 0,
      createdAt: DateTime(2026, 7, 25, 16, 0),
      updatedAt: DateTime(2026, 7, 25, 16, 5),
    ),
    InvoiceUntransferredRecord(
      id: 'inv_untr_purchase_001',
      documentNo: 'AF20260005',
      invoiceType: 'field_sales.purchase_invoice',
      docSide: InvoiceUntransferredDocSide.purchase,
      customerCode: 'S0001',
      customerName: 'Tedarikçi XYZ',
      documentDate: DateTime(2026, 7, 22),
      amount: 9100.00,
      status: 'Completed',
      approvalStatus: 1,
      isSynced: 0,
      createdAt: DateTime(2026, 7, 22, 11, 30),
      updatedAt: DateTime(2026, 7, 22, 11, 30),
    ),
  ];

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
