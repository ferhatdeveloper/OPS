// Dosya Adı: other_report_scope.dart
// Açıklama: DİĞER + yönetici/finans/plasiyer ekstra rapor id kapsamı
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template other_report_scope}
/// `reports/other/` modülünün sahip olduğu katalog id’leri.
///
/// Kullanım örneği:
/// ```dart
/// OtherReportScope.owns('plasiyer_gps'); // true
/// ```
/// {@endtemplate}
class OtherReportScope {
  /// {@macro other_report_scope}
  const OtherReportScope._();

  /// MBT DİĞER (6) — orijinal RAPORLAR sheet
  static const List<String> digerCore = [
    'plasiyer_gps',
    'plasiyer_rota',
    'plasiyer_gunluk',
    'ziyaret_listesi',
    'ziyaret_listesi_ozel',
    'kasa_hareket',
  ];

  /// Plasiyer ek raporları (40 ötesi)
  static const List<String> plasiyerExtras = [
    'plasiyer_satis_ozet',
    'plasiyer_tahsilat_ozet',
    'plasiyer_ziyaret_ozet',
    'plasiyer_performans',
  ];

  /// Yönetici hub (MBT YÖNETİCİ ekranı + OPS KPI)
  static const List<String> yoneticiExtras = [
    'yonetici_kasa',
    'yonetici_banka',
    'yonetici_cek',
    'yonetici_senet',
    'yonetici_firma_genel',
    'yonetici_fatura_satis',
    'yonetici_fatura_alis',
    'yonetici_siparis_satis',
    'yonetici_siparis_alis',
    'yonetici_kpi',
    'yonetici_leaderboard',
    'yonetici_period_compare',
  ];

  /// Finans sheet ekleri (40 ötesi)
  static const List<String> finansExtras = [
    'finans_transfer_edilen',
    'finans_transfer_edilmeyen',
    'finans_portfoy_cek',
    'finans_firma_cek',
    'finans_portfoy_senet',
    'finans_firma_senet',
    'finans_kasa_bakiye',
  ];

  /// Tüm other-owned id’ler
  static Set<String> get allIds => {
        ...digerCore,
        ...plasiyerExtras,
        ...yoneticiExtras,
        ...finansExtras,
      };

  /// Bu ajanın kataloğa eklediği 40-ötesi adet
  /// (yonetici 12 + finans 7 + plasiyer 4 = 23; OPS ayrı)
  static int get extrasBeyond40Owned =>
      yoneticiExtras.length +
      finansExtras.length +
      plasiyerExtras.length;

  /// {@template other_report_scope_owns}
  /// Bu id other modülüne mi ait?
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  ///
  /// Dönüş değeri:
  /// - [bool]: Sahiplik
  /// {@endtemplate}
  static bool owns(String? reportId) {
    if (reportId == null || reportId.isEmpty) return false;
    return allIds.contains(reportId);
  }
}
