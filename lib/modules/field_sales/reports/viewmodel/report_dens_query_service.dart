// Dosya Adı: report_dens_query_service.dart
// Açıklama: Satış/tahsilat/ziyaret rapor dens satırlarını SQLite’tan okur
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../view/report_dens_form.dart';

/// {@template report_dens_kind}
/// Rapor dens türü (satış / tahsilat / ziyaret).
///
/// Kullanım örneği:
/// ```dart
/// ReportDensKind.sales
/// ```
/// {@endtemplate}
enum ReportDensKind {
  /// Satış (faturalar)
  sales,

  /// Tahsilat
  collection,

  /// Ziyaret
  visit,
}

/// {@template report_dens_query_service}
/// Rapor dens satırlarını yerel SQLite sorgularıyla üretir.
///
/// Kullanım örneği:
/// ```dart
/// final rows = await ReportDensQueryService.fetchRows(
///   db: db,
///   kind: ReportDensKind.sales,
///   dateFrom: DateTime(2026, 7, 1),
///   dateTo: DateTime(2026, 7, 26),
/// );
/// ```
/// {@endtemplate}
class ReportDensQueryService {
  /// {@template report_dens_query_service_fetch_rows}
  /// Tarih aralığına göre dens satır listesini döner.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite veritabanı
  /// - [kind]: Rapor türü
  /// - [dateFrom]: Başlangıç (dahil)
  /// - [dateTo]: Bitiş (dahil)
  ///
  /// Dönüş değeri:
  /// - [List<ReportDensRowPlaceholder>]: Dens satırları
  /// {@endtemplate}
  static Future<List<ReportDensRowPlaceholder>> fetchRows({
    required Database db,
    required ReportDensKind kind,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final from = _toDateOnly(dateFrom);
    final to = _toDateOnly(dateTo);
    final sql = _sqlFor(kind);
    final maps = await db.rawQuery(sql, [from, to]);
    return maps.map((row) => _mapRow(kind, row)).toList();
  }

  /// {@template report_dens_query_service_sql_for}
  /// Tür için SQL sabitini seçer.
  /// {@endtemplate}
  static String _sqlFor(ReportDensKind kind) {
    switch (kind) {
      case ReportDensKind.sales:
        return SqlQuerys.reportDensSalesRowsSql;
      case ReportDensKind.collection:
        return SqlQuerys.reportDensCollectionRowsSql;
      case ReportDensKind.visit:
        return SqlQuerys.reportDensVisitRowsSql;
    }
  }

  /// {@template report_dens_query_service_map_row}
  /// SQLite satırını dens satırına dönüştürür.
  /// {@endtemplate}
  static ReportDensRowPlaceholder _mapRow(
    ReportDensKind kind,
    Map<String, dynamic> row,
  ) {
    final title = (row['customer_name'] ?? '').toString();
    final eventDate = _formatDate(row['event_date']?.toString());
    final detail = (row['detail'] ?? row['status'] ?? '').toString();
    final subtitle = detail.isEmpty ? eventDate : '$eventDate · $detail';

    return ReportDensRowPlaceholder(
      title: title.isEmpty ? '—' : title,
      subtitle: subtitle,
      value: _formatValue(kind, row['amount']),
    );
  }

  /// {@template report_dens_query_service_format_value}
  /// Tutar veya süre değerini satır metnine çevirir.
  /// {@endtemplate}
  static String _formatValue(ReportDensKind kind, Object? raw) {
    if (kind == ReportDensKind.visit) {
      final minutes = (raw as num?)?.toInt();
      if (minutes == null) return '—';
      return '$minutes dk';
    }
    final amount = (raw as num?)?.toDouble() ?? 0;
    return '${amount.toStringAsFixed(2)} ₺';
  }

  /// {@template report_dens_query_service_format_date}
  /// ISO tarih metnini dd.MM.yyyy yapar.
  /// {@endtemplate}
  static String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  /// {@template report_dens_query_service_to_date_only}
  /// SQLite date() için yyyy-MM-dd üretir.
  /// {@endtemplate}
  static String _toDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
