// Dosya Adı: cari_report_ids.dart
// Açıklama: CARİ MBT rapor id sabitleri (katalog 14 + OPS ekstra)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template cari_report_ids}
/// CARİ kategori rapor id’leri — query / result yönlendirmesi.
///
/// Kullanım örneği:
/// ```dart
/// CariReportIds.handles('cari_extre'); // true
/// ```
/// {@endtemplate}
class CariReportIds {
  /// {@macro cari_report_ids}
  const CariReportIds._();

  /// Katalog CARİ (14)
  static const String cariExtre = 'cari_extre';
  static const String tahsilatListesi = 'tahsilat_listesi';
  static const String detayliCariExtre = 'detayli_cari_extre';
  static const String yakinimdakiCariGps = 'yakinimdaki_cari_gps';
  static const String borcAlacak = 'borc_alacak';
  static const String cariHareket = 'cari_hareket';
  static const String satisYapilmayanCari = 'satis_yapilmayan_cari';
  static const String enCokSatisCari = 'en_cok_satis_cari';
  static const String enCokAlimCari = 'en_cok_alim_cari';
  static const String enCokUrunSatis = 'en_cok_urun_satis';
  static const String enCokUrunAlis = 'en_cok_urun_alis';
  static const String gpsKonum = 'gps_konum';
  static const String musteriCek = 'musteri_cek';
  static const String musteriSenet = 'musteri_senet';

  /// OPS ekstra (MBT risk / açık hesap)
  static const String cariRisk = 'cari_risk';

  /// Desteklenen tüm id’ler
  static const Set<String> all = {
    cariExtre,
    tahsilatListesi,
    detayliCariExtre,
    yakinimdakiCariGps,
    borcAlacak,
    cariHareket,
    satisYapilmayanCari,
    enCokSatisCari,
    enCokAlimCari,
    enCokUrunSatis,
    enCokUrunAlis,
    gpsKonum,
    musteriCek,
    musteriSenet,
    cariRisk,
  };

  /// {@template cari_report_ids_handles}
  /// Bu id CARİ query service kapsamında mı?
  /// {@endtemplate}
  static bool handles(String reportId) => all.contains(reportId);
}
