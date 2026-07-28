// Dosya Adı: mbt_report_catalog.dart
// Açıklama: MBT RAPORLAR + Yönetici/Finans/OPS genişletilmiş katalog (74)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'mbt_report_category.dart';
import 'mbt_report_definition.dart';
import 'mbt_report_param_field.dart';

/// {@template mbt_report_catalog}
/// Cihaz + screenshot envanterine dayalı MBT rapor kataloğu (40)
/// + Yönetici/Finans/OPS/Diğer genişletme = **74** (benzersiz id).
///
/// Kullanım örneği:
/// ```dart
/// MbtReportCatalog.byCategory(MbtReportCategory.cari);
/// ```
/// {@endtemplate}
class MbtReportCatalog {
  /// Tüm rapor tanımları (sıra MBT grid + OPS genişletme)
  static const List<MbtReportDefinition> all = [
    // —— CARİ (15) ——
    MbtReportDefinition(
      id: 'cari_extre',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.cari_extre',
      designFile: 'CariExtre.repx',
      fields: MbtReportParamProfiles.cariExtre,
    ),
    MbtReportDefinition(
      id: 'tahsilat_listesi',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.tahsilat_listesi',
      designFile: 'TahsilatListesi.repx',
      fields: MbtReportParamProfiles.tahsilat,
    ),
    MbtReportDefinition(
      id: 'detayli_cari_extre',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.detayli_cari_extre',
      designFile: 'StokluCariExtre.repx',
      fields: MbtReportParamProfiles.cariExtre,
    ),
    MbtReportDefinition(
      id: 'yakinimdaki_cari_gps',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.yakinimdaki_cari_gps',
      designFile: '',
      fields: MbtReportParamProfiles.cariGps,
    ),
    MbtReportDefinition(
      id: 'borc_alacak',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.borc_alacak',
      designFile: 'CariBakiyeListe.repx',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),
    MbtReportDefinition(
      id: 'cari_hareket',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.cari_hareket',
      designFile: 'CariHareketListe.repx',
      fields: MbtReportParamProfiles.cariExtre,
    ),
    MbtReportDefinition(
      id: 'satis_yapilmayan_cari',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.satis_yapilmayan_cari',
      designFile: 'HareketGormeyenCariler.repx',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),
    MbtReportDefinition(
      id: 'en_cok_satis_cari',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.en_cok_satis_cari',
      designFile: 'EncokSatisYapilanCari.repx',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),
    MbtReportDefinition(
      id: 'en_cok_alim_cari',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.en_cok_alim_cari',
      designFile: 'EncokAlimYapilanCari.repx',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),
    MbtReportDefinition(
      id: 'en_cok_urun_satis',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.en_cok_urun_satis',
      designFile: 'CariStokTercih.repx',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),
    MbtReportDefinition(
      id: 'en_cok_urun_alis',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.en_cok_urun_alis',
      designFile: 'CariStokTercih.repx',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),
    MbtReportDefinition(
      id: 'gps_konum',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.gps_konum',
      designFile: '',
      fields: MbtReportParamProfiles.cariGps,
    ),
    MbtReportDefinition(
      id: 'musteri_cek',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.musteri_cek',
      designFile: 'MusteriCekSenetListe.repx',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),
    MbtReportDefinition(
      id: 'musteri_senet',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.musteri_senet',
      designFile: 'MusteriCekSenetListe.repx',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),
    MbtReportDefinition(
      id: 'cari_risk',
      category: MbtReportCategory.cari,
      titleKey: 'field_sales.mbt_reports.cari_risk',
      designFile: '',
      fields: MbtReportParamProfiles.cariSimpleDate,
    ),

    // —— STOK (11) ——
    MbtReportDefinition(
      id: 'stok_bakiye',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.stok_bakiye',
      designFile: 'StokBakiye.repx',
      fields: MbtReportParamProfiles.stokBakiye,
    ),
    MbtReportDefinition(
      id: 'stok_envanter',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.stok_envanter',
      designFile: 'StokEnvanter.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'stok_hareket',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.stok_hareket',
      designFile: 'StokHareketListe.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'seri_lot',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.seri_lot',
      designFile: '',
      fields: MbtReportParamProfiles.stokBakiye,
    ),
    MbtReportDefinition(
      id: 'urun_hangi_depo',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.urun_hangi_depo',
      designFile: 'UrunHangiDepolarda.repx',
      fields: MbtReportParamProfiles.stokBakiye,
    ),
    MbtReportDefinition(
      id: 'depoda_hangi_urun',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.depoda_hangi_urun',
      designFile: 'DepodakiUrunler.repx',
      fields: MbtReportParamProfiles.stokBakiye,
    ),
    MbtReportDefinition(
      id: 'satisi_yapilmayan_urun',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.satisi_yapilmayan_urun',
      designFile: 'HareketGormeyenStoklar.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'en_cok_satilan_urun',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.en_cok_satilan_urun',
      designFile: 'EncokSatilanStok.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'en_cok_alinan_urun',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.en_cok_alinan_urun',
      designFile: 'EncokAlinanStok.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'stok_sayim',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.stok_sayim',
      designFile: 'StokSayim.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'arac_stok',
      category: MbtReportCategory.stok,
      titleKey: 'field_sales.mbt_reports.arac_stok',
      designFile: 'AracStok.repx',
      fields: MbtReportParamProfiles.stokBakiye,
    ),

    // —— SİPARİŞ (4) ——
    MbtReportDefinition(
      id: 'satis_siparisleri',
      category: MbtReportCategory.siparis,
      titleKey: 'field_sales.mbt_reports.satis_siparisleri',
      designFile: 'SiparisListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'alis_siparisleri',
      category: MbtReportCategory.siparis,
      titleKey: 'field_sales.mbt_reports.alis_siparisleri',
      designFile: 'SiparisListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'bekleyen_satis_siparis',
      category: MbtReportCategory.siparis,
      titleKey: 'field_sales.mbt_reports.bekleyen_satis_siparis',
      designFile: 'BekleyenSatisSiparisler.repx',
      fields: MbtReportParamProfiles.belgeStokKod,
    ),
    MbtReportDefinition(
      id: 'bekleyen_alis_siparis',
      category: MbtReportCategory.siparis,
      titleKey: 'field_sales.mbt_reports.bekleyen_alis_siparis',
      designFile: 'BekleyenAlisSiparisler.repx',
      fields: MbtReportParamProfiles.belgeStokKod,
    ),

    // —— FATURA (3) ——
    MbtReportDefinition(
      id: 'satis_faturalari',
      category: MbtReportCategory.fatura,
      titleKey: 'field_sales.mbt_reports.satis_faturalari',
      designFile: 'SatisFaturaListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'alis_faturalari',
      category: MbtReportCategory.fatura,
      titleKey: 'field_sales.mbt_reports.alis_faturalari',
      designFile: 'AlisFaturaListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'fatura_karlilik',
      category: MbtReportCategory.fatura,
      titleKey: 'field_sales.mbt_reports.fatura_karlilik',
      designFile: 'FisMaliyet.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),

    // —— İRSALİYE (4) ——
    MbtReportDefinition(
      id: 'satis_irsaliyeleri',
      category: MbtReportCategory.irsaliye,
      titleKey: 'field_sales.mbt_reports.satis_irsaliyeleri',
      designFile: 'SatisIrsaliyeleri.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'alis_irsaliyeleri',
      category: MbtReportCategory.irsaliye,
      titleKey: 'field_sales.mbt_reports.alis_irsaliyeleri',
      designFile: 'AlisIrsaliyeleri.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'faturasiz_irsaliye_satis',
      category: MbtReportCategory.irsaliye,
      titleKey: 'field_sales.mbt_reports.faturasiz_irsaliye_satis',
      designFile: 'FaturasizIrsaliyeSatis.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'faturasiz_irsaliye_alis',
      category: MbtReportCategory.irsaliye,
      titleKey: 'field_sales.mbt_reports.faturasiz_irsaliye_alis',
      designFile: 'FaturasizIrsaliyeAlis.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),

    // —— DİĞER (10) ——
    MbtReportDefinition(
      id: 'plasiyer_gps',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.plasiyer_gps',
      designFile: '',
      fields: MbtReportParamProfiles.gps,
    ),
    MbtReportDefinition(
      id: 'plasiyer_rota',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.plasiyer_rota',
      designFile: 'SaticiRotaRapor.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'plasiyer_gunluk',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.plasiyer_gunluk',
      designFile: 'SaticiGunlukRapor.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'ziyaret_listesi',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.ziyaret_listesi',
      designFile: 'ZiyaretListesi.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'ziyaret_listesi_ozel',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.ziyaret_listesi_ozel',
      designFile: 'GelismisZiyaretListesi.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'kasa_hareket',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.kasa_hareket',
      designFile: 'KasaHareketRapor.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'plasiyer_satis_ozet',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.plasiyer_satis_ozet',
      designFile: 'SaticiGunlukRapor.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'plasiyer_tahsilat_ozet',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.plasiyer_tahsilat_ozet',
      designFile: 'TahsilatListesi.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'plasiyer_ziyaret_ozet',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.plasiyer_ziyaret_ozet',
      designFile: 'ZiyaretListesi.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'plasiyer_performans',
      category: MbtReportCategory.diger,
      titleKey: 'field_sales.mbt_reports.plasiyer_performans',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),

    // —— YÖNETİCİ (12) ——
    MbtReportDefinition(
      id: 'yonetici_kasa',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_kasa',
      designFile: 'KasaHareketRapor.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'yonetici_banka',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_banka',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'yonetici_cek',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_cek',
      designFile: 'MusteriCekSenetListe.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'yonetici_senet',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_senet',
      designFile: 'MusteriCekSenetListe.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'yonetici_firma_genel',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_firma_genel',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'yonetici_fatura_satis',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_fatura_satis',
      designFile: 'SatisFaturaListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'yonetici_fatura_alis',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_fatura_alis',
      designFile: 'AlisFaturaListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'yonetici_siparis_satis',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_siparis_satis',
      designFile: 'SiparisListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'yonetici_siparis_alis',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_siparis_alis',
      designFile: 'SiparisListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'yonetici_kpi',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_kpi',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'yonetici_leaderboard',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_leaderboard',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'yonetici_period_compare',
      category: MbtReportCategory.yonetici,
      titleKey: 'field_sales.mbt_reports.yonetici_period_compare',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),

    // —— FİNANS (7) ——
    MbtReportDefinition(
      id: 'finans_transfer_edilen',
      category: MbtReportCategory.finans,
      titleKey: 'field_sales.mbt_reports.finans_transfer_edilen',
      designFile: 'TahsilatListesi.repx',
      fields: MbtReportParamProfiles.tahsilat,
    ),
    MbtReportDefinition(
      id: 'finans_transfer_edilmeyen',
      category: MbtReportCategory.finans,
      titleKey: 'field_sales.mbt_reports.finans_transfer_edilmeyen',
      designFile: 'TahsilatListesi.repx',
      fields: MbtReportParamProfiles.tahsilat,
    ),
    MbtReportDefinition(
      id: 'finans_portfoy_cek',
      category: MbtReportCategory.finans,
      titleKey: 'field_sales.mbt_reports.finans_portfoy_cek',
      designFile: 'MusteriCekSenetListe.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'finans_firma_cek',
      category: MbtReportCategory.finans,
      titleKey: 'field_sales.mbt_reports.finans_firma_cek',
      designFile: 'MusteriCekSenetListe.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'finans_portfoy_senet',
      category: MbtReportCategory.finans,
      titleKey: 'field_sales.mbt_reports.finans_portfoy_senet',
      designFile: 'MusteriCekSenetListe.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'finans_firma_senet',
      category: MbtReportCategory.finans,
      titleKey: 'field_sales.mbt_reports.finans_firma_senet',
      designFile: 'MusteriCekSenetListe.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'finans_kasa_bakiye',
      category: MbtReportCategory.finans,
      titleKey: 'field_sales.mbt_reports.finans_kasa_bakiye',
      designFile: 'KasaHareketRapor.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),

    // —— OPS (8) ——
    MbtReportDefinition(
      id: 'ops_sales_report',
      category: MbtReportCategory.ops,
      titleKey: 'field_sales.mbt_reports.ops_sales_report',
      designFile: 'SatisFaturaListesi.repx',
      fields: MbtReportParamProfiles.belgeListesi,
    ),
    MbtReportDefinition(
      id: 'ops_collection_report',
      category: MbtReportCategory.ops,
      titleKey: 'field_sales.mbt_reports.ops_collection_report',
      designFile: 'TahsilatListesi.repx',
      fields: MbtReportParamProfiles.tahsilat,
    ),
    MbtReportDefinition(
      id: 'ops_visit_report',
      category: MbtReportCategory.ops,
      titleKey: 'field_sales.mbt_reports.ops_visit_report',
      designFile: 'ZiyaretListesi.repx',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'ops_performance',
      category: MbtReportCategory.ops,
      titleKey: 'field_sales.mbt_reports.ops_performance',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'ops_gun_sonu',
      category: MbtReportCategory.ops,
      titleKey: 'field_sales.mbt_reports.ops_gun_sonu',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'ops_advanced',
      category: MbtReportCategory.ops,
      titleKey: 'field_sales.mbt_reports.ops_advanced',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),
    MbtReportDefinition(
      id: 'ops_van_stock',
      category: MbtReportCategory.ops,
      titleKey: 'field_sales.mbt_reports.ops_van_stock',
      designFile: 'StokBakiye.repx',
      fields: MbtReportParamProfiles.stokBakiye,
    ),
    MbtReportDefinition(
      id: 'ops_target',
      category: MbtReportCategory.ops,
      titleKey: 'field_sales.mbt_reports.ops_target',
      designFile: '',
      fields: MbtReportParamProfiles.simpleDate,
    ),
  ];

  /// {@template mbt_report_catalog_by_category}
  /// Kategoriye göre rapor listesi.
  ///
  /// Parametreler:
  /// - [category]: Hub kategori
  ///
  /// Dönüş değeri:
  /// - [List<MbtReportDefinition>]: Raporlar
  /// {@endtemplate}
  static List<MbtReportDefinition> byCategory(MbtReportCategory category) {
    return all.where((r) => r.category == category).toList(growable: false);
  }

  /// {@template mbt_report_catalog_by_id}
  /// Id ile rapor bulur.
  ///
  /// Parametreler:
  /// - [id]: Stabil kimlik
  ///
  /// Dönüş değeri:
  /// - [MbtReportDefinition?]: Tanım veya null
  /// {@endtemplate}
  static MbtReportDefinition? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }
}
