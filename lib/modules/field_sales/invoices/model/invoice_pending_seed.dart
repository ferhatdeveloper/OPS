// Dosya Adı: invoice_pending_seed.dart
// Açıklama: Bekleyen fatura dens stub seed satırları (SQLite boş / test)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'invoice_pending_record.dart';

/// {@template invoice_pending_seed}
/// MBT Bekleyen Faturalar dens stub seed (test / boş DB).
///
/// Kullanım örneği:
/// ```dart
/// final rows = InvoicePendingSeed.defaultRows;
/// ```
/// {@endtemplate}
class InvoicePendingSeed {
  InvoicePendingSeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/invoices-pending';

  /// [submenuTitle]: Menü seed alt başlık
  static const String submenuTitle = 'Bekleyen Faturalar';

  /// [tableName]: SQLite kaynak tablo
  static const String tableName = 'invoices';

  /// Yer tutucu dens satırlar (onay bekleyen).
  static final List<InvoicePendingRecord> defaultRows = [
    InvoicePendingRecord(
      id: 'inv_pending_sales_001',
      customerId: 'c_stub_001',
      customerCode: 'C0001',
      customerName: 'Demo Cari A.Ş.',
      invoiceDate: DateTime(2026, 7, 26),
      totalAmount: 1250.50,
      status: 'Pending',
      invoiceType: 'field_sales.wholesale_invoice',
      approvalStatus: 0,
      isSynced: 0,
      notes: 'Toptan satış — onay bekliyor',
    ),
    InvoicePendingRecord(
      id: 'inv_pending_sales_002',
      customerId: 'c_stub_002',
      customerCode: 'C0002',
      customerName: 'Örnek Ticaret Ltd.',
      invoiceDate: DateTime(2026, 7, 25),
      totalAmount: 890.00,
      status: 'Pending',
      invoiceType: 'field_sales.van_sales',
      approvalStatus: 0,
      isSynced: 0,
    ),
    InvoicePendingRecord(
      id: 'inv_pending_purchase_001',
      customerId: 'c_stub_sup_001',
      customerCode: 'TED-001',
      customerName: 'Tedarikçi A.Ş.',
      invoiceDate: DateTime(2026, 7, 24),
      totalAmount: 3200.75,
      status: 'Pending',
      invoiceType: 'field_sales.purchase_invoice',
      approvalStatus: 0,
      isSynced: 0,
      notes: 'Satın alma — onay bekliyor',
    ),
  ];

  /// Satış dens stub satırları.
  static List<InvoicePendingRecord> get salesRows => defaultRows
      .where((r) => r.docSide == InvoicePendingDocSide.sales)
      .toList(growable: false);

  /// Alış dens stub satırları.
  static List<InvoicePendingRecord> get purchaseRows => defaultRows
      .where((r) => r.docSide == InvoicePendingDocSide.purchase)
      .toList(growable: false);

  /// SQLite insert map listesi.
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);
}
