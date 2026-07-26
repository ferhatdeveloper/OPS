// Dosya Adı: day_sales_gate.dart
// Açıklama: Mesai kapalıyken satış/tahsilat girişlerini sınıflandırır
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template day_sales_gate}
/// Dashboard satış gate: sipariş / fatura / irsaliye / tahsilat
/// mesai (DayStatusStore.isDayOpen) gerektirir.
///
/// Kullanım örneği:
/// ```dart
/// if (DaySalesGate.requiresOpenDay(moduleName: 'Sipariş Girişi')) {
///   // SnackBar + day_open
/// }
/// ```
/// {@endtemplate}
class DaySalesGate {
  /// [gatedModules]: Title-switch ile açılan satış girişleri
  static const Set<String> gatedModules = {
    'Sipariş Girişi',
    'Satış',
    'Alış',
    'Sipariş Satış',
    'Sipariş Alış',
    'Satış Faturası',
    'Toptan Satış',
    'Toptan Satış İade',
    'Tahsilat Girişi',
    'Yeni Hareket',
    'Nakit/KK Ödeme',
    'Nakit Ödeme',
    'Kredi Kartı ile Ödeme',
    'Virman Fişi',
    'Virman Fişleri',
    'Havale/EFT',
    'Havale/EFT İşlemleri',
  };

  /// [gatedRoutes]: Seed named route satış girişleri
  static const Set<String> gatedRoutes = {
    '/field-sales/orders',
    '/field-sales/orders-sales',
    '/field-sales/orders-purchase',
    '/sales-order',
    '/field-sales/collections',
    '/field-sales/collection',
    '/field-sales/payment-entry',
    '/field-sales/virman',
    '/field-sales/wire-transfer',
    '/field-sales/invoices/new',
    '/field-sales/wholesale',
    '/field-sales/wholesale-return',
    '/field-sales/invoice-wholesale',
    '/field-sales/invoice-return',
    '/field-sales/invoice-purchase',
    '/field-sales/waybill-wholesale',
    '/field-sales/waybill-purchase',
    '/field-sales/waybills',
  };

  /// {@macro day_sales_gate}
  const DaySalesGate();

  /// {@template day_sales_gate_requires_open_day}
  /// Modül veya route mesai gerektirir mi?
  ///
  /// Parametreler:
  /// - [moduleName]: Dashboard menü başlığı
  /// - [route]: Seed named route (opsiyonel)
  ///
  /// Dönüş değeri:
  /// - [bool]: true ise DayStatusStore.isDayOpen kontrol edilmeli
  /// {@endtemplate}
  static bool requiresOpenDay({
    String? moduleName,
    String? route,
  }) {
    final r = (route ?? '').trim();
    if (r.isNotEmpty && gatedRoutes.contains(r)) return true;
    final m = (moduleName ?? '').trim();
    return m.isNotEmpty && gatedModules.contains(m);
  }
}
