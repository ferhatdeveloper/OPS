// Dosya Adı: mbt_report_definition.dart
// Açıklama: Tek MBT rapor tanımı (id · kategori · dizayn · parametreler)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'mbt_report_category.dart';
import 'mbt_report_param_field.dart';

/// {@template mbt_report_definition}
/// Katalog satırı — Parametreler ekranına gider.
///
/// Kullanım örneği:
/// ```dart
/// MbtReportDefinition(
///   id: 'cari_extre',
///   category: MbtReportCategory.cari,
///   titleKey: 'field_sales.mbt_reports.cari_extre',
///   designFile: 'CariExtre.repx',
///   fields: MbtReportParamProfiles.cariExtre,
/// );
/// ```
/// {@endtemplate}
class MbtReportDefinition {
  /// [id]: Stabil kimlik (route arg)
  final String id;

  /// [category]: Hub kategori
  final MbtReportCategory category;

  /// [titleKey]: Rapor başlık l10n
  final String titleKey;

  /// [designFile]: MBT Dizayn Dosya (.repx)
  final String designFile;

  /// [fields]: Parametre alan profili
  final List<MbtReportParamField> fields;

  /// {@macro mbt_report_definition}
  const MbtReportDefinition({
    required this.id,
    required this.category,
    required this.titleKey,
    required this.designFile,
    required this.fields,
  });
}
