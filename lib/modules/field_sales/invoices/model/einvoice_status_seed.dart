// Dosya Adı: einvoice_status_seed.dart
// Açıklama: e-Fatura durum dens stub seed satırları (ETTN + GİB)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'einvoice_gib_status.dart';
import 'einvoice_status_record.dart';

/// {@template einvoice_status_seed}
/// MBT e-Fatura Durum dens stub seed (SQLite boşken).
///
/// Kullanım örneği:
/// ```dart
/// final rows = EinvoiceStatusSeed.defaultRows;
/// ```
/// {@endtemplate}
class EinvoiceStatusSeed {
  EinvoiceStatusSeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/einvoice-status';

  /// [submenuTitle]: Menü seed alt başlık
  static const String submenuTitle = 'e-Fatura Durum';

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'einvoice_status';

  /// Yer tutucu dens satırlar (ETTN + GİB durum).
  static final List<EinvoiceStatusRecord> defaultRows = [
    EinvoiceStatusRecord(
      id: 'eis_stub_sales_sent',
      invoiceId: 'inv_stub_001',
      documentNo: 'EF20260001',
      ettn: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      gibStatus: EinvoiceGibStatus.sent,
      docSide: EinvoiceDocSide.sales,
      profile: 'e_fatura',
      customerCode: 'C0001',
      customerName: 'Demo Cari A.Ş.',
      documentDate: DateTime(2026, 7, 26),
      amount: 1250.50,
      statusMessage: 'GİB iletildi',
      createdAt: DateTime(2026, 7, 26, 9, 0),
      updatedAt: DateTime(2026, 7, 26, 9, 5),
    ),
    EinvoiceStatusRecord(
      id: 'eis_stub_sales_accepted',
      invoiceId: 'inv_stub_002',
      documentNo: 'EF20260002',
      ettn: 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
      gibStatus: EinvoiceGibStatus.accepted,
      docSide: EinvoiceDocSide.sales,
      profile: 'e_fatura',
      customerCode: 'C0002',
      customerName: 'Örnek Ticaret Ltd.',
      documentDate: DateTime(2026, 7, 25),
      amount: 890.00,
      statusMessage: 'Alıcı kabul',
      approvalStatus: 1,
      isSynced: 1,
      createdAt: DateTime(2026, 7, 25, 14, 0),
      updatedAt: DateTime(2026, 7, 25, 16, 30),
    ),
    EinvoiceStatusRecord(
      id: 'eis_stub_sales_waiting',
      documentNo: 'EA20260003',
      ettn: 'c3d4e5f6-a7b8-9012-cdef-123456789012',
      gibStatus: EinvoiceGibStatus.waiting,
      docSide: EinvoiceDocSide.sales,
      profile: 'e_arsiv',
      customerCode: 'C0003',
      customerName: 'Perakende Müşteri',
      documentDate: DateTime(2026, 7, 24),
      amount: 320.75,
      statusMessage: 'e-Arşiv rapor bekliyor',
      createdAt: DateTime(2026, 7, 24, 11, 0),
      updatedAt: DateTime(2026, 7, 24, 11, 10),
    ),
    EinvoiceStatusRecord(
      id: 'eis_stub_purchase_rejected',
      documentNo: 'AF20260001',
      ettn: 'd4e5f6a7-b8c9-0123-def0-234567890123',
      gibStatus: EinvoiceGibStatus.rejected,
      docSide: EinvoiceDocSide.purchase,
      profile: 'e_fatura',
      customerCode: 'S0001',
      customerName: 'Tedarikçi XYZ',
      documentDate: DateTime(2026, 7, 20),
      amount: 5400.00,
      statusMessage: 'Şema hatası',
      createdAt: DateTime(2026, 7, 20, 8, 0),
      updatedAt: DateTime(2026, 7, 20, 8, 45),
    ),
    EinvoiceStatusRecord(
      id: 'eis_stub_sales_queued',
      documentNo: 'EF20260004',
      ettn: 'e5f6a7b8-c9d0-1234-ef01-345678901234',
      gibStatus: EinvoiceGibStatus.queued,
      docSide: EinvoiceDocSide.sales,
      profile: 'e_fatura',
      customerCode: 'C0001',
      customerName: 'Demo Cari A.Ş.',
      documentDate: DateTime(2026, 7, 26),
      amount: 99.90,
      statusMessage: 'Kuyrukta',
      createdAt: DateTime(2026, 7, 26, 10, 0),
      updatedAt: DateTime(2026, 7, 26, 10, 0),
    ),
  ];

  /// {@template einvoice_status_seed_sales_rows}
  /// Satış dens stub satırları.
  /// {@endtemplate}
  static List<EinvoiceStatusRecord> get salesRows => defaultRows
      .where((r) => r.docSide == EinvoiceDocSide.sales)
      .toList(growable: false);

  /// {@template einvoice_status_seed_purchase_rows}
  /// Alış dens stub satırları.
  /// {@endtemplate}
  static List<EinvoiceStatusRecord> get purchaseRows => defaultRows
      .where((r) => r.docSide == EinvoiceDocSide.purchase)
      .toList(growable: false);

  /// {@template einvoice_status_seed_maps}
  /// SQLite insert için map listesi.
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);
}
