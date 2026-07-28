// Dosya Adı: document_report_filter.dart
// Açıklama: Belge (sipariş/fatura/irsaliye) rapor parametre filtresi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import '../engine/mbt_report_action_service.dart';

/// {@template document_report_filter}
/// Belge rapor sorgu filtresi — Parametreler snapshot’ı.
///
/// Kullanım örneği:
/// ```dart
/// DocumentReportFilter.fromSnapshot(snapshot, stockCode: 'STK-1');
/// ```
/// {@endtemplate}
class DocumentReportFilter {
  /// [dateFrom]: Başlangıç (dahil)
  final DateTime? dateFrom;

  /// [dateTo]: Bitiş (dahil)
  final DateTime? dateTo;

  /// [code]: Cari / belge kod arama
  final String code;

  /// [name]: Cari ünvan arama
  final String name;

  /// [cariCode]: CARİKODU filtresi
  final String cariCode;

  /// [cariName]: Cari ad (CARİKODU satırı)
  final String cariName;

  /// [stockCode]: STK.KOD (bekleyen sipariş)
  final String stockCode;

  /// [stockName]: STK.AD
  final String stockName;

  /// [warehouse]: Ambar filtresi (metin; şimdilik bilgilendirme)
  final String warehouse;

  /// {@macro document_report_filter}
  const DocumentReportFilter({
    this.dateFrom,
    this.dateTo,
    this.code = '',
    this.name = '',
    this.cariCode = '',
    this.cariName = '',
    this.stockCode = '',
    this.stockName = '',
    this.warehouse = '',
  });

  /// {@template document_report_filter_from_snapshot}
  /// [MbtReportParamSnapshot] + opsiyonel stok/cari alanları.
  /// {@endtemplate}
  factory DocumentReportFilter.fromSnapshot(
    MbtReportParamSnapshot snapshot, {
    String cariCode = '',
    String cariName = '',
    String stockCode = '',
    String stockName = '',
    String warehouse = '',
  }) {
    return DocumentReportFilter(
      dateFrom: snapshot.dateFrom,
      dateTo: snapshot.dateTo,
      code: snapshot.code,
      name: snapshot.name,
      cariCode: cariCode,
      cariName: cariName,
      stockCode: stockCode,
      stockName: stockName,
      warehouse: warehouse,
    );
  }
}
