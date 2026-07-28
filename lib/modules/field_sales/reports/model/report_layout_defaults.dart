// Dosya Adı: report_layout_defaults.dart
// Açıklama: 60 MBT rapor için varsayılan in-app dizayn şemaları
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'mbt_report_catalog.dart';
import 'report_layout.dart';
import 'report_layout_available_fields.dart';
import 'report_layout_column.dart';

/// l10n öneki
const String _k = 'field_sales.mbt_reports';

/// {@template report_layout_defaults}
/// Katalog id → varsayılan [ReportLayout]. Bilinen PDF sütunları
/// (Cari Extre / Tahsilat / Stok Bakiye) doğrulanmış; diğerleri
/// rapor tipine göre makul varsayılan.
/// Seed görünür küme + [ReportLayoutAvailableFields] (gizli extras).
///
/// Kullanım örneği:
/// ```dart
/// final layout = ReportLayoutDefaults.forReportId('cari_extre');
/// ```
/// {@endtemplate}
class ReportLayoutDefaults {
  /// {@macro report_layout_defaults}
  const ReportLayoutDefaults._();

  /// {@template report_layout_defaults_for_report_id}
  /// Rapor id için varsayılan dizayn (tüm available alanlar; seed görünür).
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  ///
  /// Dönüş değeri:
  /// - [ReportLayout]: Varsayılan layout
  /// {@endtemplate}
  static ReportLayout forReportId(String reportId) {
    return ReportLayoutAvailableFields.mergeInto(_seeded(reportId));
  }

  /// {@template report_layout_defaults_seeded_visible_ids}
  /// Seed görünür sütun id’leri (available extras hariç).
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  ///
  /// Dönüş değeri:
  /// - [List]: Görünür id listesi
  /// {@endtemplate}
  static List<String> seededVisibleIds(String reportId) {
    return _seeded(reportId)
        .columns
        .where((c) => c.visible)
        .map((c) => c.id)
        .toList(growable: false);
  }

  /// Seed layout (yalnızca varsayılan görünür/gizli set; available merge yok)
  static ReportLayout _seeded(String reportId) {
    final def = MbtReportCatalog.byId(reportId);
    final titleKey = def?.titleKey ?? '$_k.$reportId';
    switch (reportId) {
      case 'cari_extre':
        return _cariExtre(titleKey);
      case 'detayli_cari_extre':
        return _detayliCariExtre(titleKey);
      case 'tahsilat_listesi':
        return _tahsilat('tahsilat_listesi', titleKey);
      case 'stok_bakiye':
        return _stokBakiye('stok_bakiye', titleKey);
      case 'cari_hareket':
        return _cariHareket(titleKey);
      case 'borc_alacak':
      case 'cari_risk':
        return _borcAlacak(titleKey, reportId);
      case 'yakinimdaki_cari_gps':
      case 'gps_konum':
      case 'plasiyer_gps':
        return _gps(reportId, titleKey);
      case 'satis_yapilmayan_cari':
      case 'en_cok_satis_cari':
      case 'en_cok_alim_cari':
        return _cariRanking(reportId, titleKey);
      case 'en_cok_urun_satis':
      case 'en_cok_urun_alis':
      case 'satisi_yapilmayan_urun':
      case 'en_cok_satilan_urun':
      case 'en_cok_alinan_urun':
        return _urunRanking(reportId, titleKey);
      case 'musteri_cek':
      case 'musteri_senet':
        return _cekSenet(reportId, titleKey);
      case 'stok_envanter':
      case 'seri_lot':
      case 'urun_hangi_depo':
      case 'depoda_hangi_urun':
        return _stokMaster(reportId, titleKey);
      case 'stok_hareket':
        return _stokHareket(titleKey);
      case 'stok_sayim':
        return _stokHareket(titleKey, reportId: 'stok_sayim');
      case 'satis_siparisleri':
      case 'alis_siparisleri':
      case 'satis_faturalari':
      case 'alis_faturalari':
      case 'satis_irsaliyeleri':
      case 'alis_irsaliyeleri':
      case 'faturasiz_irsaliye_satis':
      case 'faturasiz_irsaliye_alis':
        return _belgeListesi(reportId, titleKey);
      case 'bekleyen_satis_siparis':
      case 'bekleyen_alis_siparis':
        return _bekleyenSiparis(reportId, titleKey);
      case 'fatura_karlilik':
        return _faturaKarlilik(titleKey);
      case 'plasiyer_rota':
        return _rota(titleKey);
      case 'plasiyer_gunluk':
      case 'plasiyer_satis_ozet':
      case 'plasiyer_tahsilat_ozet':
      case 'plasiyer_performans':
        return _plasiyer(reportId, titleKey);
      case 'ziyaret_listesi':
      case 'ziyaret_listesi_ozel':
      case 'plasiyer_ziyaret_ozet':
        return _ziyaret(reportId, titleKey);
      case 'kasa_hareket':
        return _kasaHareket('kasa_hareket', titleKey);
      case 'yonetici_kasa':
        return _kasaHareket('yonetici_kasa', titleKey);
      case 'yonetici_banka':
      case 'yonetici_firma_genel':
      case 'yonetici_kpi':
      case 'ops_performance':
      case 'ops_gun_sonu':
      case 'ops_advanced':
        return _generic(reportId, titleKey);
      case 'yonetici_leaderboard':
        return _leaderboard(titleKey);
      case 'yonetici_period_compare':
        return _periodCompare(titleKey);
      case 'ops_target':
        return _hedef(titleKey);
      case 'yonetici_cek':
      case 'yonetici_senet':
      case 'finans_portfoy_cek':
      case 'finans_firma_cek':
      case 'finans_portfoy_senet':
      case 'finans_firma_senet':
        return _cekSenet(reportId, titleKey);
      case 'finans_transfer_edilen':
      case 'finans_transfer_edilmeyen':
        return _tahsilat(reportId, titleKey);
      case 'finans_kasa_bakiye':
        // Query: code · title · balance · status (hareket değil kart bakiyesi)
        return _kasaBakiye(titleKey);
      case 'yonetici_fatura_satis':
      case 'yonetici_fatura_alis':
      case 'yonetici_siparis_satis':
      case 'yonetici_siparis_alis':
      case 'ops_sales_report':
        return _belgeListesi(reportId, titleKey);
      case 'ops_collection_report':
        return _tahsilat('ops_collection_report', titleKey);
      case 'ops_visit_report':
        return _ziyaret(reportId, titleKey);
      case 'ops_van_stock':
      case 'arac_stok':
        return _stokMaster(reportId, titleKey);
      default:
        return _generic(reportId, titleKey);
    }
  }

  /// {@template report_layout_defaults_all}
  /// 71 rapor için varsayılan map.
  ///
  /// Dönüş değeri:
  /// - [Map]: reportId → layout
  /// {@endtemplate}
  static Map<String, ReportLayout> all() {
    final map = <String, ReportLayout>{};
    for (final r in MbtReportCatalog.all) {
      map[r.id] = forReportId(r.id);
    }
    return map;
  }

  static ReportLayoutColumn _col(
    String id, {
    required String titleSuffix,
    bool visible = true,
    int flex = 1,
    ReportLayoutColumnAlign align = ReportLayoutColumnAlign.left,
    bool includeInTotals = false,
  }) {
    return ReportLayoutColumn(
      id: id,
      titleKey: '$_k.$titleSuffix',
      visible: visible,
      flex: flex,
      align: align,
      includeInTotals: includeInTotals,
    );
  }

  /// Cari Extre — kanıtlı sütunlar
  static ReportLayout _cariExtre(String titleKey) {
    return ReportLayout(
      reportId: 'cari_extre',
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('ref_no_date', titleSuffix: 'col_ref_no_date', flex: 2),
        _col('description', titleSuffix: 'col_description', flex: 3),
        _col(
          'debit',
          titleSuffix: 'col_debit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'credit',
          titleSuffix: 'col_credit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'balance',
          titleSuffix: 'col_balance',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  static ReportLayout _detayliCariExtre(String titleKey) {
    return ReportLayout(
      reportId: 'detayli_cari_extre',
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('ref_no_date', titleSuffix: 'col_ref_no_date', flex: 2),
        _col('voucher_type', titleSuffix: 'col_voucher_type', flex: 2),
        _col('description', titleSuffix: 'col_description', flex: 3),
        _col('currency', titleSuffix: 'col_currency'),
        _col(
          'debit',
          titleSuffix: 'col_debit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'credit',
          titleSuffix: 'col_credit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'balance',
          titleSuffix: 'col_balance',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  /// Tahsilat — kanıtlı sütunlar
  static ReportLayout _tahsilat(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 3),
        _col('txn_date', titleSuffix: 'col_txn_date'),
        _col('due_date', titleSuffix: 'col_due_date'),
        _col('txn_type', titleSuffix: 'col_txn_type', flex: 2),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'remaining',
          titleSuffix: 'col_remaining',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'day_diff',
          titleSuffix: 'col_day_diff',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  /// Stok Bakiye — kanıtlı sütunlar
  static ReportLayout _stokBakiye(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('stock_code', titleSuffix: 'col_stock_code', flex: 2),
        _col('stock_name', titleSuffix: 'col_stock_name', flex: 3),
        _col(
          'balance',
          titleSuffix: 'col_balance',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
      ],
    );
  }

  static ReportLayout _cariHareket(String titleKey) {
    return ReportLayout(
      reportId: 'cari_hareket',
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('date', titleSuffix: 'col_date'),
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 2),
        _col('description', titleSuffix: 'col_description', flex: 2),
        _col(
          'debit',
          titleSuffix: 'col_debit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'credit',
          titleSuffix: 'col_credit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
      ],
    );
  }

  static ReportLayout _borcAlacak(String titleKey, [String reportId = 'borc_alacak']) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 3),
        _col(
          'debit',
          titleSuffix: 'col_debit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'credit',
          titleSuffix: 'col_credit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'balance',
          titleSuffix: 'col_balance',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  static ReportLayout _gps(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      columns: [
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 3),
        _col(
          'distance',
          titleSuffix: 'col_distance',
          align: ReportLayoutColumnAlign.right,
        ),
        _col('lat', titleSuffix: 'col_lat'),
        _col('lng', titleSuffix: 'col_lng'),
      ],
    );
  }

  static ReportLayout _cariRanking(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 3),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'quantity',
          titleSuffix: 'col_quantity',
          align: ReportLayoutColumnAlign.right,
          visible: reportId != 'satis_yapilmayan_cari',
        ),
      ],
    );
  }

  static ReportLayout _urunRanking(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('stock_code', titleSuffix: 'col_stock_code', flex: 2),
        _col('stock_name', titleSuffix: 'col_stock_name', flex: 3),
        _col(
          'quantity',
          titleSuffix: 'col_quantity',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
      ],
    );
  }

  static ReportLayout _cekSenet(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 2),
        _col('doc_no', titleSuffix: 'col_doc_no'),
        _col('due_date', titleSuffix: 'col_due_date'),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col('status', titleSuffix: 'col_status'),
      ],
    );
  }

  static ReportLayout _stokMaster(String reportId, String titleKey) {
    final withSerial = reportId == 'seri_lot';
    final withWh = reportId == 'urun_hangi_depo' ||
        reportId == 'depoda_hangi_urun' ||
        reportId == 'stok_envanter' ||
        reportId == 'arac_stok' ||
        reportId == 'ops_van_stock';
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: reportId == 'stok_envanter' ||
          reportId == 'arac_stok' ||
          reportId == 'ops_van_stock',
      columns: [
        _col('stock_code', titleSuffix: 'col_stock_code', flex: 2),
        _col('stock_name', titleSuffix: 'col_stock_name', flex: 3),
        if (withWh) _col('warehouse', titleSuffix: 'col_warehouse', flex: 2),
        if (withSerial) _col('serial', titleSuffix: 'col_serial', flex: 2),
        _col(
          'balance',
          titleSuffix: 'col_balance',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
      ],
    );
  }

  static ReportLayout _stokHareket(String titleKey, {String reportId = 'stok_hareket'}) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('date', titleSuffix: 'col_date'),
        _col('stock_code', titleSuffix: 'col_stock_code', flex: 2),
        _col('stock_name', titleSuffix: 'col_stock_name', flex: 2),
        _col('warehouse', titleSuffix: 'col_warehouse'),
        _col('description', titleSuffix: 'col_description', flex: 2),
        _col(
          'quantity',
          titleSuffix: 'col_quantity',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
      ],
    );
  }

  static ReportLayout _belgeListesi(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('doc_no', titleSuffix: 'col_doc_no', flex: 2),
        _col('date', titleSuffix: 'col_date'),
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 2),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col('status', titleSuffix: 'col_status'),
      ],
    );
  }

  static ReportLayout _bekleyenSiparis(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      dense: true,
      columns: [
        _col('doc_no', titleSuffix: 'col_doc_no', flex: 2),
        _col('date', titleSuffix: 'col_date'),
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 2),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col('status', titleSuffix: 'col_status'),
      ],
    );
  }

  static ReportLayout _faturaKarlilik(String titleKey) {
    return ReportLayout(
      reportId: 'fatura_karlilik',
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('doc_no', titleSuffix: 'col_doc_no', flex: 2),
        _col('date', titleSuffix: 'col_date'),
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 2),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'profit',
          titleSuffix: 'col_profit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
      ],
    );
  }

  static ReportLayout _plasiyer(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('date', titleSuffix: 'col_date'),
        _col('salesperson', titleSuffix: 'col_salesperson', flex: 2),
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 2),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
      ],
    );
  }

  /// Plasiyer rota — durak sırası / gün / cari (visits değil).
  static ReportLayout _rota(String titleKey) {
    return ReportLayout(
      reportId: 'plasiyer_rota',
      titleKey: titleKey,
      dense: true,
      columns: [
        _col(
          'visit_order',
          titleSuffix: 'col_visit_order',
          align: ReportLayoutColumnAlign.right,
        ),
        _col('weekday', titleSuffix: 'col_weekday'),
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 3),
        _col('salesperson', titleSuffix: 'col_salesperson', flex: 2),
        _col('status', titleSuffix: 'col_status'),
        _col(
          'distance',
          titleSuffix: 'col_distance',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  /// Hedef sıralaması — sıra / plasiyer / puan veya gerçekleşme.
  static ReportLayout _leaderboard(String titleKey) {
    return ReportLayout(
      reportId: 'yonetici_leaderboard',
      titleKey: titleKey,
      dense: true,
      showTotals: true,
      columns: [
        _col(
          'rank',
          titleSuffix: 'col_rank',
          align: ReportLayoutColumnAlign.right,
        ),
        _col('title', titleSuffix: 'col_salesperson', flex: 3),
        _col('period', titleSuffix: 'col_period'),
        _col('code', titleSuffix: 'col_txn_type'),
        _col(
          'points',
          titleSuffix: 'col_points',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'target',
          titleSuffix: 'col_target',
          align: ReportLayoutColumnAlign.right,
        ),
        _col(
          'achieved',
          titleSuffix: 'col_achieved',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'percent',
          titleSuffix: 'col_percent',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  /// Dönem A/B karşılaştırma satırları.
  static ReportLayout _periodCompare(String titleKey) {
    return ReportLayout(
      reportId: 'yonetici_period_compare',
      titleKey: titleKey,
      dense: true,
      columns: [
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 2),
        _col('period', titleSuffix: 'col_period', flex: 2),
        _col(
          'previous',
          titleSuffix: 'col_previous',
          align: ReportLayoutColumnAlign.right,
        ),
        _col(
          'current',
          titleSuffix: 'col_current',
          align: ReportLayoutColumnAlign.right,
        ),
        _col(
          'growth',
          titleSuffix: 'col_growth',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  /// Hedef özeti — plasiyer / dönem / hedef / gerçekleşen / %.
  static ReportLayout _hedef(String titleKey) {
    return ReportLayout(
      reportId: 'ops_target',
      titleKey: titleKey,
      dense: true,
      showTotals: true,
      columns: [
        _col('title', titleSuffix: 'col_salesperson', flex: 3),
        _col('code', titleSuffix: 'col_txn_type'),
        _col('period', titleSuffix: 'col_period'),
        _col(
          'target',
          titleSuffix: 'col_target',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'achieved',
          titleSuffix: 'col_achieved',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'percent',
          titleSuffix: 'col_percent',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  static ReportLayout _ziyaret(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      columns: [
        _col('date', titleSuffix: 'col_date'),
        _col('visit_time', titleSuffix: 'col_visit_time'),
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 3),
        _col('salesperson', titleSuffix: 'col_salesperson', flex: 2),
        _col('status', titleSuffix: 'col_status'),
      ],
    );
  }

  static ReportLayout _kasaHareket(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      showTotals: true,
      columns: [
        _col('date', titleSuffix: 'col_date'),
        _col('doc_no', titleSuffix: 'col_doc_no'),
        _col('description', titleSuffix: 'col_description', flex: 3),
        _col(
          'debit',
          titleSuffix: 'col_debit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'credit',
          titleSuffix: 'col_credit',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col(
          'balance',
          titleSuffix: 'col_balance',
          align: ReportLayoutColumnAlign.right,
        ),
      ],
    );
  }

  static ReportLayout _generic(String reportId, String titleKey) {
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      columns: [
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 3),
        _col('date', titleSuffix: 'col_date'),
        _col(
          'amount',
          titleSuffix: 'col_amount',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
      ],
    );
  }

  /// Kasa bakiyesi — kart kodu / ünvan / bakiye.
  static ReportLayout _kasaBakiye(String titleKey) {
    return ReportLayout(
      reportId: 'finans_kasa_bakiye',
      titleKey: titleKey,
      showTotals: true,
      dense: true,
      columns: [
        _col('code', titleSuffix: 'col_code', flex: 2),
        _col('title', titleSuffix: 'col_title', flex: 3),
        _col(
          'balance',
          titleSuffix: 'col_balance',
          align: ReportLayoutColumnAlign.right,
          includeInTotals: true,
        ),
        _col('status', titleSuffix: 'col_status'),
      ],
    );
  }
}
