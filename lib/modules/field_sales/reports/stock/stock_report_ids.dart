// Dosya Adı: stock_report_ids.dart
// Açıklama: STOK MBT rapor id sabitleri (katalog parity + ekstra)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template stock_report_ids}
/// STOK kategorisi rapor id’leri — query service yönlendirmesi.
///
/// Kullanım örneği:
/// ```dart
/// StockReportIds.handles('stok_bakiye'); // true
/// ```
/// {@endtemplate}
class StockReportIds {
  /// {@macro stock_report_ids}
  const StockReportIds._();

  /// Katalog STOK (9)
  static const String stokBakiye = 'stok_bakiye';
  static const String stokEnvanter = 'stok_envanter';
  static const String stokHareket = 'stok_hareket';
  static const String seriLot = 'seri_lot';
  static const String urunHangiDepo = 'urun_hangi_depo';
  static const String depodaHangiUrun = 'depoda_hangi_urun';
  static const String satisiYapilmayanUrun = 'satisi_yapilmayan_urun';
  static const String enCokSatilanUrun = 'en_cok_satilan_urun';
  static const String enCokAlinanUrun = 'en_cok_alinan_urun';

  /// OPS ekstra (9+)
  static const String aracStok = 'arac_stok';
  static const String opsVanStock = 'ops_van_stock';
  static const String stokSayim = 'stok_sayim';

  /// Desteklenen tüm id’ler
  static const Set<String> all = {
    stokBakiye,
    stokEnvanter,
    stokHareket,
    seriLot,
    urunHangiDepo,
    depodaHangiUrun,
    satisiYapilmayanUrun,
    enCokSatilanUrun,
    enCokAlinanUrun,
    aracStok,
    opsVanStock,
    stokSayim,
  };

  /// {@template stock_report_ids_handles}
  /// Bu id STOK query service kapsamında mı?
  /// {@endtemplate}
  static bool handles(String reportId) => all.contains(reportId);
}
