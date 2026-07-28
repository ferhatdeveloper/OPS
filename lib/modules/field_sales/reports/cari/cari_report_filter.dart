// Dosya Adı: cari_report_filter.dart
// Açıklama: CARİ MBT rapor parametre filtresi (tarih/kod/GPS)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template cari_report_filter}
/// CARİ rapor sorgu filtresi — Parametreler snapshot’ı.
///
/// Kullanım örneği:
/// ```dart
/// const CariReportFilter(code: 'MBT-001', dateFrom: null);
/// ```
/// {@endtemplate}
class CariReportFilter {
  /// [dateFrom]: Başlangıç (dahil)
  final DateTime? dateFrom;

  /// [dateTo]: Bitiş (dahil)
  final DateTime? dateTo;

  /// [code]: Cari kod
  final String code;

  /// [name]: Cari ünvan
  final String name;

  /// [code2]: Kod aralık bitiş
  final String code2;

  /// [name2]: Ad aralık bitiş
  final String name2;

  /// [originLat]: Yakınımdaki / GPS orijin enlem
  final double? originLat;

  /// [originLng]: Yakınımdaki / GPS orijin boylam
  final double? originLng;

  /// [maxDistanceMeters]: Yakınlık üst sınırı (0 = sınırsız)
  final double maxDistanceMeters;

  /// {@macro cari_report_filter}
  const CariReportFilter({
    this.dateFrom,
    this.dateTo,
    this.code = '',
    this.name = '',
    this.code2 = '',
    this.name2 = '',
    this.originLat,
    this.originLng,
    this.maxDistanceMeters = 0,
  });
}
