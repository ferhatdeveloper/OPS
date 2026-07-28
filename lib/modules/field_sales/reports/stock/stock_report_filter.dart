// Dosya Adı: stock_report_filter.dart
// Açıklama: STOK MBT rapor parametre filtresi (kod/ambar/bakiye/tarih)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import '../engine/mbt_report_action_service.dart';

/// {@template stock_report_filter}
/// STOK rapor sorgu filtresi — Parametreler ekranı snapshot’ı.
///
/// Kullanım örneği:
/// ```dart
/// const StockReportFilter(code: 'STK-001', gtZero: true);
/// ```
/// {@endtemplate}
class StockReportFilter {
  /// [dateFrom]: Başlangıç (dahil)
  final DateTime? dateFrom;

  /// [dateTo]: Bitiş (dahil)
  final DateTime? dateTo;

  /// [code]: Stok kod başlangıç / arama
  final String code;

  /// [name]: Stok ad başlangıç / arama
  final String name;

  /// [code2]: Stok kod bitiş
  final String code2;

  /// [name2]: Stok ad bitiş
  final String name2;

  /// [warehouse]: Ambar kod/ad filtresi
  final String warehouse;

  /// [gtZero]: Bakiye > 0
  final bool gtZero;

  /// [ltZero]: Bakiye < 0
  final bool ltZero;

  /// [eqZero]: Bakiye = 0
  final bool eqZero;

  /// {@macro stock_report_filter}
  const StockReportFilter({
    this.dateFrom,
    this.dateTo,
    this.code = '',
    this.name = '',
    this.code2 = '',
    this.name2 = '',
    this.warehouse = '',
    this.gtZero = false,
    this.ltZero = false,
    this.eqZero = false,
  });

  /// {@template stock_report_filter_from_snapshot}
  /// [MbtReportParamSnapshot] → stok filtresi.
  /// {@endtemplate}
  factory StockReportFilter.fromSnapshot(MbtReportParamSnapshot s) {
    return StockReportFilter(
      dateFrom: s.dateFrom,
      dateTo: s.dateTo,
      code: s.code,
      name: s.name,
      code2: s.code2,
      name2: s.name2,
      warehouse: s.warehouse,
      gtZero: s.gtZero,
      ltZero: s.ltZero,
      eqZero: s.eqZero,
    );
  }
}
