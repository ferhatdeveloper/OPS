// Dosya Adı: document_report_ids.dart
// Açıklama: SİPARİŞ + FATURA + İRSALİYE MBT rapor id sabitleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template document_report_ids}
/// Belge raporları (sipariş / fatura / irsaliye) — query yönlendirme.
///
/// Kullanım örneği:
/// ```dart
/// DocumentReportIds.handles('satis_siparisleri'); // true
/// ```
/// {@endtemplate}
class DocumentReportIds {
  /// {@macro document_report_ids}
  const DocumentReportIds._();

  /// SİPARİŞ (4)
  static const String satisSiparisleri = 'satis_siparisleri';
  static const String alisSiparisleri = 'alis_siparisleri';
  static const String bekleyenSatisSiparis = 'bekleyen_satis_siparis';
  static const String bekleyenAlisSiparis = 'bekleyen_alis_siparis';

  /// FATURA (3)
  static const String satisFaturalari = 'satis_faturalari';
  static const String alisFaturalari = 'alis_faturalari';
  static const String faturaKarlilik = 'fatura_karlilik';

  /// İRSALİYE (4)
  static const String satisIrsaliyeleri = 'satis_irsaliyeleri';
  static const String alisIrsaliyeleri = 'alis_irsaliyeleri';
  static const String faturasizIrsaliyeSatis = 'faturasiz_irsaliye_satis';
  static const String faturasizIrsaliyeAlis = 'faturasiz_irsaliye_alis';

  /// Desteklenen tüm id’ler (11)
  static const Set<String> all = {
    satisSiparisleri,
    alisSiparisleri,
    bekleyenSatisSiparis,
    bekleyenAlisSiparis,
    satisFaturalari,
    alisFaturalari,
    faturaKarlilik,
    satisIrsaliyeleri,
    alisIrsaliyeleri,
    faturasizIrsaliyeSatis,
    faturasizIrsaliyeAlis,
  };

  /// {@template document_report_ids_handles}
  /// Bu id belge query service kapsamında mı?
  /// {@endtemplate}
  static bool handles(String reportId) => all.contains(reportId);

  /// Satış yönü mü?
  static bool isSalesSide(String reportId) {
    return reportId.contains('satis') || reportId == faturaKarlilik;
  }

  /// Bekleyen sipariş mi?
  static bool isPendingOrder(String reportId) {
    return reportId.startsWith('bekleyen_');
  }

  /// Faturasız irsaliye mi?
  static bool isUninvoicedWaybill(String reportId) {
    return reportId.startsWith('faturasiz_irsaliye');
  }
}
