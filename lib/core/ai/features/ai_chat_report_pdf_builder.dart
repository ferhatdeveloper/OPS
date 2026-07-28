// Dosya Adı: ai_chat_report_pdf_builder.dart
// Açıklama: AI chat / dinamik rapor satırlarından dens PDF (report_pdf_*)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:typed_data';

import '../../../modules/field_sales/reports/engine/mbt_report_action_service.dart';
import '../../../modules/field_sales/reports/model/mbt_report_category.dart';
import '../../../modules/field_sales/reports/model/mbt_report_definition.dart';
import '../../../modules/field_sales/reports/model/report_layout.dart';
import '../../../modules/field_sales/reports/model/report_layout_column.dart';
import 'postgrest_query_spec.dart';

/// {@template ai_chat_report_pdf_payload}
/// Chat PDF eki (API’ye gönderilmez).
/// {@endtemplate}
class AiChatReportPdfPayload {
  /// [title]: Viewer / dosya başlığı
  final String title;

  /// [bytes]: PDF içeriği
  final Uint8List bytes;

  /// [rowCount]: Özet satır sayısı
  final int rowCount;

  /// {@macro ai_chat_report_pdf_payload}
  const AiChatReportPdfPayload({
    required this.title,
    required this.bytes,
    required this.rowCount,
  });
}

/// {@template ai_chat_report_pdf_builder}
/// Dinamik rapor satırlarını mevcut MBT dens PDF motoruna bağlar.
///
/// Kullanım örneği:
/// ```dart
/// final pdf = await AiChatReportPdfBuilder().build(
///   title: 'Cari',
///   columns: cols,
///   rows: maps,
/// );
/// ```
/// {@endtemplate}
class AiChatReportPdfBuilder {
  /// [actions]: PDF motoru (test inject)
  final MbtReportActionService actions;

  /// {@macro ai_chat_report_pdf_builder}
  AiChatReportPdfBuilder({MbtReportActionService? actions})
      : actions = actions ?? MbtReportActionService();

  /// Sentetik katalog tanımı (PDF motoru için)
  static const MbtReportDefinition syntheticReport = MbtReportDefinition(
    id: 'ai_chat_dynamic',
    category: MbtReportCategory.diger,
    titleKey: 'field_sales.ai_reports.title',
    designFile: 'AiChat.repx',
    fields: [],
  );

  /// {@template ai_chat_report_pdf_builder_string_rows}
  /// Dinamik satırları PDF string map’e çevirir.
  ///
  /// Parametreler:
  /// - [rows]: Ham satırlar
  /// - [columnIds]: Sütun sırası
  ///
  /// Dönüş değeri:
  /// - [List<Map<String, String>>]
  /// {@endtemplate}
  static List<Map<String, String>> toStringRows({
    required List<Map<String, dynamic>> rows,
    required List<String> columnIds,
  }) {
    final ids = columnIds.where((e) => e.trim().isNotEmpty).toList();
    return rows.map((row) {
      final out = <String, String>{};
      for (final id in ids) {
        final v = row[id];
        out[id] = v == null ? '' : '$v';
      }
      return out;
    }).toList(growable: false);
  }

  /// {@template ai_chat_report_pdf_builder_layout}
  /// Sütun listesinden dens layout.
  /// {@endtemplate}
  static ReportLayout layoutFromColumns({
    required String reportId,
    required String titleKey,
    required List<AiReportLayoutColumn> columns,
  }) {
    final cols = columns
        .where((c) => c.id.trim().isNotEmpty)
        .map(
          (c) => ReportLayoutColumn(
            id: c.id.trim(),
            titleKey: c.labelKey.trim().isEmpty ? c.id : c.labelKey,
            align: c.numeric
                ? ReportLayoutColumnAlign.right
                : ReportLayoutColumnAlign.left,
          ),
        )
        .toList(growable: false);
    return ReportLayout(
      reportId: reportId,
      titleKey: titleKey,
      dense: true,
      columns: cols,
    );
  }

  /// {@template ai_chat_report_pdf_builder_build}
  /// PDF baytları üretir.
  ///
  /// Parametreler:
  /// - [title]: Başlık
  /// - [columns]: Sütunlar
  /// - [rows]: Veri
  /// - [languageCode]: RTL / font
  ///
  /// Dönüş değeri:
  /// - [AiChatReportPdfPayload]
  /// {@endtemplate}
  Future<AiChatReportPdfPayload> build({
    required String title,
    required List<AiReportLayoutColumn> columns,
    required List<Map<String, dynamic>> rows,
    String? languageCode,
  }) async {
    final resolvedTitle =
        title.trim().isEmpty ? 'AI Report' : title.trim();
    final layout = layoutFromColumns(
      reportId: syntheticReport.id,
      titleKey: syntheticReport.titleKey,
      columns: columns,
    );
    final ids = layout.visibleColumns.map((c) => c.id).toList();
    final stringRows = toStringRows(rows: rows, columnIds: ids);
    final bytes = await actions.buildPdfBytes(
      report: syntheticReport,
      title: resolvedTitle,
      snapshot: const MbtReportParamSnapshot(),
      layout: layout,
      rows: stringRows,
      languageCode: languageCode,
    );
    return AiChatReportPdfPayload(
      title: resolvedTitle,
      bytes: bytes,
      rowCount: stringRows.length,
    );
  }
}
