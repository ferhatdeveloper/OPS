// Dosya Adı: report_layout_available_fields.dart
// Açıklama: Rapor veri kaynağı availableFields (query + DB alias) katalogu
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'report_layout.dart';
import 'report_layout_column.dart';

/// l10n öneki
const String _k = 'field_sales.mbt_reports';

/// {@template report_layout_available_fields}
/// Rapor id → veri kaynağındaki tüm kullanılabilir alanlar.
/// Varsayılan görünür küme [ReportLayoutDefaults] seed’idir; burada
/// ekstra alanlar (query map + ürün/cari DB alias) listelenir.
///
/// Kullanım örneği:
/// ```dart
/// final fields = ReportLayoutAvailableFields.forReportId('cari_extre');
/// final merged = ReportLayoutAvailableFields.mergeInto(layout);
/// ```
/// {@endtemplate}
class ReportLayoutAvailableFields {
  /// {@macro report_layout_available_fields}
  const ReportLayoutAvailableFields._();

  /// {@template report_layout_available_fields_for_report_id}
  /// Rapor için tüm available alan tanımları (görünürlük yok sayılır).
  ///
  /// Parametreler:
  /// - [reportId]: Katalog id
  ///
  /// Dönüş değeri:
  /// - [List]: Alan sütunları (varsayılan visible=false şablon)
  /// {@endtemplate}
  static List<ReportLayoutColumn> forReportId(String reportId) {
    switch (reportId) {
      case 'cari_extre':
        return _cols([
          'ref_no_date',
          'description',
          'debit',
          'credit',
          'balance',
          'code',
          'title',
          'voucher_type',
          'currency',
        ]);
      case 'detayli_cari_extre':
        return _cols([
          'ref_no_date',
          'voucher_type',
          'description',
          'currency',
          'debit',
          'credit',
          'balance',
          'code',
          'title',
        ]);
      case 'cari_hareket':
        return _cols([
          'date',
          'code',
          'title',
          'description',
          'debit',
          'credit',
          'balance',
          'voucher_type',
          'currency',
          'ref_no_date',
        ]);
      case 'tahsilat_listesi':
      case 'finans_transfer_edilen':
      case 'finans_transfer_edilmeyen':
      case 'ops_collection_report':
        return _cols([
          'code',
          'title',
          'txn_date',
          'due_date',
          'txn_type',
          'amount',
          'remaining',
          'day_diff',
          'doc_no',
          'status',
        ]);
      case 'stok_bakiye':
        return _cols([
          'stock_code',
          'stock_name',
          'balance',
          'barcode',
          'unit',
          'price',
          'vat_rate',
          'category',
          'description',
        ]);
      case 'borc_alacak':
      case 'cari_risk':
        return _cols([
          'code',
          'title',
          'debit',
          'credit',
          'balance',
          'phone',
          'tax_no',
          'address',
        ]);
      case 'yakinimdaki_cari_gps':
      case 'gps_konum':
      case 'plasiyer_gps':
        return _cols([
          'code',
          'title',
          'distance',
          'lat',
          'lng',
          'phone',
          'address',
          'date',
        ]);
      case 'satis_yapilmayan_cari':
        return _cols(['code', 'title', 'amount', 'phone', 'address']);
      case 'en_cok_satis_cari':
      case 'en_cok_alim_cari':
        return _cols([
          'code',
          'title',
          'amount',
          'quantity',
          'phone',
          'address',
        ]);
      case 'en_cok_urun_satis':
      case 'en_cok_urun_alis':
      case 'satisi_yapilmayan_urun':
      case 'en_cok_satilan_urun':
      case 'en_cok_alinan_urun':
        return _cols([
          'stock_code',
          'stock_name',
          'quantity',
          'amount',
          'barcode',
          'unit',
          'category',
        ]);
      case 'musteri_cek':
      case 'musteri_senet':
      case 'yonetici_cek':
      case 'yonetici_senet':
      case 'finans_portfoy_cek':
      case 'finans_firma_cek':
      case 'finans_portfoy_senet':
      case 'finans_firma_senet':
        return _cols([
          'code',
          'title',
          'doc_no',
          'due_date',
          'amount',
          'status',
          'date',
        ]);
      case 'stok_envanter':
      case 'urun_hangi_depo':
      case 'depoda_hangi_urun':
      case 'arac_stok':
      case 'ops_van_stock':
        return _cols([
          'stock_code',
          'stock_name',
          'warehouse',
          'balance',
          'barcode',
          'unit',
          'category',
        ]);
      case 'seri_lot':
        return _cols([
          'stock_code',
          'stock_name',
          'serial',
          'balance',
          'warehouse',
          'barcode',
        ]);
      case 'stok_hareket':
      case 'stok_sayim':
        return _cols([
          'date',
          'stock_code',
          'stock_name',
          'warehouse',
          'description',
          'quantity',
          'doc_no',
          'status',
          'code',
          'title',
          'amount',
        ]);
      case 'satis_siparisleri':
      case 'alis_siparisleri':
      case 'satis_faturalari':
      case 'alis_faturalari':
      case 'satis_irsaliyeleri':
      case 'alis_irsaliyeleri':
      case 'faturasiz_irsaliye_satis':
      case 'faturasiz_irsaliye_alis':
      case 'bekleyen_satis_siparis':
      case 'bekleyen_alis_siparis':
      case 'yonetici_fatura_satis':
      case 'yonetici_fatura_alis':
      case 'yonetici_siparis_satis':
      case 'yonetici_siparis_alis':
      case 'ops_sales_report':
        return _cols([
          'doc_no',
          'date',
          'code',
          'title',
          'amount',
          'status',
          'salesperson',
          'voucher_type',
        ]);
      case 'fatura_karlilik':
        return _cols([
          'doc_no',
          'date',
          'code',
          'title',
          'amount',
          'profit',
          'status',
        ]);
      case 'plasiyer_rota':
        return _cols([
          'visit_order',
          'weekday',
          'code',
          'title',
          'salesperson',
          'status',
          'distance',
          'lat',
          'lng',
          'date',
        ]);
      case 'plasiyer_gunluk':
      case 'plasiyer_satis_ozet':
      case 'plasiyer_tahsilat_ozet':
      case 'plasiyer_performans':
        return _cols([
          'date',
          'salesperson',
          'code',
          'title',
          'amount',
          'quantity',
          'status',
          'txn_type',
        ]);
      case 'yonetici_leaderboard':
        return _cols([
          'rank',
          'title',
          'period',
          'code',
          'points',
          'target',
          'achieved',
          'percent',
          'amount',
          'salesperson',
        ]);
      case 'yonetici_period_compare':
        return _cols([
          'code',
          'title',
          'period',
          'previous',
          'current',
          'growth',
          'amount',
        ]);
      case 'ops_target':
        return _cols([
          'title',
          'code',
          'period',
          'target',
          'achieved',
          'percent',
          'amount',
          'salesperson',
        ]);
      case 'ziyaret_listesi':
      case 'ziyaret_listesi_ozel':
      case 'plasiyer_ziyaret_ozet':
      case 'ops_visit_report':
        return _cols([
          'date',
          'visit_time',
          'code',
          'title',
          'salesperson',
          'status',
          'amount',
          'lat',
          'lng',
        ]);
      case 'kasa_hareket':
      case 'yonetici_kasa':
        return _cols([
          'date',
          'doc_no',
          'description',
          'debit',
          'credit',
          'balance',
          'amount',
        ]);
      case 'finans_kasa_bakiye':
        return _cols([
          'code',
          'title',
          'balance',
          'amount',
          'date',
          'status',
        ]);
      case 'yonetici_banka':
      case 'yonetici_firma_genel':
      case 'yonetici_kpi':
      case 'ops_performance':
      case 'ops_gun_sonu':
      case 'ops_advanced':
        return _cols([
          'code',
          'title',
          'date',
          'amount',
          'description',
          'quantity',
          'status',
        ]);
      default:
        return _cols(['code', 'title', 'date', 'amount', 'status', 'description']);
    }
  }

  /// {@template report_layout_available_fields_merge_into}
  /// Kayıtlı / seed layout’a eksik available alanları `visible: false` ekler.
  /// Mevcut sıra ve görünürlük korunur.
  ///
  /// Parametreler:
  /// - [layout]: Mevcut layout
  ///
  /// Dönüş değeri:
  /// - [ReportLayout]: Genişletilmiş layout
  /// {@endtemplate}
  static ReportLayout mergeInto(ReportLayout layout) {
    final available = forReportId(layout.reportId);
    if (available.isEmpty) return layout;
    final have = layout.columns.map((c) => c.id).toSet();
    final extras = <ReportLayoutColumn>[];
    for (final a in available) {
      if (have.contains(a.id)) continue;
      extras.add(a.copyWith(visible: false));
    }
    if (extras.isEmpty) return layout;
    return layout.copyWith(
      columns: [...layout.columns, ...extras],
    );
  }

  static List<ReportLayoutColumn> _cols(List<String> ids) {
    return [
      for (final id in ids) _field(id),
    ];
  }

  static ReportLayoutColumn _field(String id) {
    final meta = _meta[id] ?? _FieldMeta(titleSuffix: 'col_$id');
    return ReportLayoutColumn(
      id: id,
      titleKey: '$_k.${meta.titleSuffix}',
      visible: false,
      flex: meta.flex,
      align: meta.align,
      includeInTotals: meta.includeInTotals,
    );
  }

  static const Map<String, _FieldMeta> _meta = {
    'ref_no_date': _FieldMeta(titleSuffix: 'col_ref_no_date', flex: 2),
    'description': _FieldMeta(titleSuffix: 'col_description', flex: 3),
    'debit': _FieldMeta(
      titleSuffix: 'col_debit',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'credit': _FieldMeta(
      titleSuffix: 'col_credit',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'balance': _FieldMeta(
      titleSuffix: 'col_balance',
      align: ReportLayoutColumnAlign.right,
    ),
    'code': _FieldMeta(titleSuffix: 'col_code', flex: 2),
    'title': _FieldMeta(titleSuffix: 'col_title', flex: 3),
    'voucher_type': _FieldMeta(titleSuffix: 'col_voucher_type', flex: 2),
    'currency': _FieldMeta(titleSuffix: 'col_currency'),
    'txn_date': _FieldMeta(titleSuffix: 'col_txn_date'),
    'due_date': _FieldMeta(titleSuffix: 'col_due_date'),
    'txn_type': _FieldMeta(titleSuffix: 'col_txn_type', flex: 2),
    'amount': _FieldMeta(
      titleSuffix: 'col_amount',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'remaining': _FieldMeta(
      titleSuffix: 'col_remaining',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'day_diff': _FieldMeta(
      titleSuffix: 'col_day_diff',
      align: ReportLayoutColumnAlign.right,
    ),
    'stock_code': _FieldMeta(titleSuffix: 'col_stock_code', flex: 2),
    'stock_name': _FieldMeta(titleSuffix: 'col_stock_name', flex: 3),
    'barcode': _FieldMeta(titleSuffix: 'col_barcode', flex: 2),
    'unit': _FieldMeta(titleSuffix: 'col_unit'),
    'price': _FieldMeta(
      titleSuffix: 'col_price',
      align: ReportLayoutColumnAlign.right,
    ),
    'vat_rate': _FieldMeta(
      titleSuffix: 'col_vat_rate',
      align: ReportLayoutColumnAlign.right,
    ),
    'category': _FieldMeta(titleSuffix: 'col_category', flex: 2),
    'warehouse': _FieldMeta(titleSuffix: 'col_warehouse', flex: 2),
    'serial': _FieldMeta(titleSuffix: 'col_serial', flex: 2),
    'date': _FieldMeta(titleSuffix: 'col_date'),
    'doc_no': _FieldMeta(titleSuffix: 'col_doc_no', flex: 2),
    'status': _FieldMeta(titleSuffix: 'col_status'),
    'quantity': _FieldMeta(
      titleSuffix: 'col_quantity',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'distance': _FieldMeta(
      titleSuffix: 'col_distance',
      align: ReportLayoutColumnAlign.right,
    ),
    'lat': _FieldMeta(titleSuffix: 'col_lat'),
    'lng': _FieldMeta(titleSuffix: 'col_lng'),
    'profit': _FieldMeta(
      titleSuffix: 'col_profit',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'visit_time': _FieldMeta(titleSuffix: 'col_visit_time'),
    'salesperson': _FieldMeta(titleSuffix: 'col_salesperson', flex: 2),
    'phone': _FieldMeta(titleSuffix: 'col_phone', flex: 2),
    'tax_no': _FieldMeta(titleSuffix: 'col_tax_no', flex: 2),
    'address': _FieldMeta(titleSuffix: 'col_address', flex: 3),
    'visit_order': _FieldMeta(
      titleSuffix: 'col_visit_order',
      align: ReportLayoutColumnAlign.right,
    ),
    'weekday': _FieldMeta(titleSuffix: 'col_weekday'),
    'rank': _FieldMeta(
      titleSuffix: 'col_rank',
      align: ReportLayoutColumnAlign.right,
    ),
    'period': _FieldMeta(titleSuffix: 'col_period'),
    'points': _FieldMeta(
      titleSuffix: 'col_points',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'target': _FieldMeta(
      titleSuffix: 'col_target',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'achieved': _FieldMeta(
      titleSuffix: 'col_achieved',
      align: ReportLayoutColumnAlign.right,
      includeInTotals: true,
    ),
    'percent': _FieldMeta(
      titleSuffix: 'col_percent',
      align: ReportLayoutColumnAlign.right,
    ),
    'previous': _FieldMeta(
      titleSuffix: 'col_previous',
      align: ReportLayoutColumnAlign.right,
    ),
    'current': _FieldMeta(
      titleSuffix: 'col_current',
      align: ReportLayoutColumnAlign.right,
    ),
    'growth': _FieldMeta(
      titleSuffix: 'col_growth',
      align: ReportLayoutColumnAlign.right,
    ),
  };
}

/// Alan meta (l10n + hizalama)
class _FieldMeta {
  final String titleSuffix;
  final int flex;
  final ReportLayoutColumnAlign align;
  final bool includeInTotals;

  const _FieldMeta({
    required this.titleSuffix,
    this.flex = 1,
    this.align = ReportLayoutColumnAlign.left,
    this.includeInTotals = false,
  });
}
