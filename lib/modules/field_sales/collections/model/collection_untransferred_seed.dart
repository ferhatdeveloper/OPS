// Dosya Adı: collection_untransferred_seed.dart
// Açıklama: Transfer edilmeyen tahsilat dens stub seed satırları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'collection_untransferred_record.dart';

/// {@template collection_untransferred_seed}
/// MBT Transfer Edilmeyen Tahsilatlar dens stub seed (SQLite boşken).
///
/// Kullanım örneği:
/// ```dart
/// final rows = CollectionUntransferredSeed.defaultRows;
/// ```
/// {@endtemplate}
class CollectionUntransferredSeed {
  CollectionUntransferredSeed._();

  /// [route]: Named route — menü seed ile aynı
  static const String route = '/field-sales/finance-untransferred';

  /// [submenuTitle]: Menü seed alt başlık
  static const String submenuTitle = 'Transfer Edilmeyen Tahsilatlar';

  /// [tableName]: SQLite tablo adı (kalıcılık sonraki faz)
  static const String tableName = 'collections';

  /// Yer tutucu dens satırlar (hepsi isSynced=false).
  static List<CollectionUntransferredRecord> get defaultRows {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    return [
      CollectionUntransferredRecord(
        id: 'cu_stub_cash_sales',
        documentNo: 'TH20260001',
        customerCode: 'C0001',
        customerName: 'Demo Cari A.Ş.',
        amount: 1250.50,
        paymentType: 'Cash',
        collectionDate: today,
        docSide: CollectionUntransferredDocSide.sales,
        cashCode: '01',
        currencyCode: 'TRY',
        notes: 'Nakit tahsilat stub',
      ),
      CollectionUntransferredRecord(
        id: 'cu_stub_check_sales',
        documentNo: 'TH20260002',
        customerCode: 'C0002',
        customerName: 'Örnek Ticaret Ltd.',
        amount: 890.00,
        paymentType: 'Check',
        collectionDate: yesterday,
        docSide: CollectionUntransferredDocSide.sales,
        cashCode: '01',
        currencyCode: 'TRY',
        notes: 'Çek tahsilat stub',
      ),
      CollectionUntransferredRecord(
        id: 'cu_stub_card_sales',
        documentNo: 'TH20260003',
        customerCode: 'C0003',
        customerName: 'Perakende Müşteri',
        amount: 320.75,
        paymentType: 'CreditCard',
        collectionDate: today,
        docSide: CollectionUntransferredDocSide.sales,
        cashCode: 'KK01',
        currencyCode: 'TRY',
      ),
      CollectionUntransferredRecord(
        id: 'cu_stub_cashout_purchase',
        documentNo: 'OD20260001',
        customerCode: 'C0001',
        customerName: 'Demo Cari A.Ş.',
        amount: 150.00,
        paymentType: 'CashOut',
        collectionDate: today,
        docSide: CollectionUntransferredDocSide.purchase,
        cashCode: '01',
        currencyCode: 'TRY',
        notes: 'Nakit ödeme stub',
      ),
      CollectionUntransferredRecord(
        id: 'cu_stub_note_sales',
        documentNo: 'TH20260004',
        customerCode: 'C0004',
        customerName: 'Senetli Cari',
        amount: 2400.00,
        paymentType: 'Note',
        collectionDate: yesterday,
        docSide: CollectionUntransferredDocSide.sales,
        cashCode: '01',
        currencyCode: 'TRY',
      ),
    ];
  }

  /// {@template collection_untransferred_seed_sales_rows}
  /// Satış dens stub satırları.
  /// {@endtemplate}
  static List<CollectionUntransferredRecord> get salesRows => defaultRows
      .where((r) => r.docSide == CollectionUntransferredDocSide.sales)
      .toList(growable: false);

  /// {@template collection_untransferred_seed_purchase_rows}
  /// Alış / ödeme dens stub satırları.
  /// {@endtemplate}
  static List<CollectionUntransferredRecord> get purchaseRows => defaultRows
      .where((r) => r.docSide == CollectionUntransferredDocSide.purchase)
      .toList(growable: false);

  /// {@template collection_untransferred_seed_maps}
  /// SQLite insert için map listesi.
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps =>
      defaultRows.map((r) => r.toMap()).toList(growable: false);
}
