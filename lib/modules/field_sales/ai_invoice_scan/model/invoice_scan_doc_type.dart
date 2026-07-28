// Dosya Adı: invoice_scan_doc_type.dart
// Açıklama: Resim→Fatura dens tip chip (Alış/Satış/Gider/Diğer)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template invoice_scan_doc_type}
/// OCR belge tipi — invoiceProvider invoiceType eşlemesi.
///
/// Kullanım örneği:
/// ```dart
/// InvoiceScanDocType.purchase.invoiceTypeKey;
/// ```
/// {@endtemplate}
enum InvoiceScanDocType {
  /// Alış faturası
  purchase,

  /// Satış (toptan)
  sales,

  /// Gider / masraf
  expense,

  /// Diğer / van
  other,
}

/// {@template invoice_scan_doc_type_x}
/// [InvoiceScanDocType] yardımcı uzantılar.
/// {@endtemplate}
extension InvoiceScanDocTypeX on InvoiceScanDocType {
  /// l10n: `field_sales.ai_invoice_scan.type_<name>`
  String get labelKey => 'field_sales.ai_invoice_scan.type_$name';

  /// AI prompt ipucu (kısa TR)
  String get promptHint {
    switch (this) {
      case InvoiceScanDocType.purchase:
        return 'alis';
      case InvoiceScanDocType.sales:
        return 'satis';
      case InvoiceScanDocType.expense:
        return 'gider';
      case InvoiceScanDocType.other:
        return 'diger';
    }
  }

  /// [invoiceProvider] tip anahtarı
  String get invoiceTypeKey {
    switch (this) {
      case InvoiceScanDocType.purchase:
        return 'purchase';
      case InvoiceScanDocType.sales:
        return 'field_sales.wholesale_invoice_8';
      case InvoiceScanDocType.expense:
        return 'expense';
      case InvoiceScanDocType.other:
        return 'field_sales.van_sales';
    }
  }

  /// Storage / JSON
  String get storageValue => name;

  /// Parse
  static InvoiceScanDocType tryParse(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    for (final t in InvoiceScanDocType.values) {
      if (t.name == v) return t;
    }
    return InvoiceScanDocType.other;
  }
}
