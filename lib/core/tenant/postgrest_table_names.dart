// Dosya Adı: postgrest_table_names.dart
// Açıklama: RetailEX rex_{FF}_ / rex_{FF}_{DD}_ tablo adı üreticisi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template postgrest_table_names}
/// RetailEX PostgREST tablo adları (`rex_001_customers`, `rex_001_01_sales`).
/// OPS yerel `exfin_*` önekinden bağımsızdır.
///
/// Kullanım örneği:
/// ```dart
/// print(PostgrestTableNames.firmTable('001', 'customers'));
/// // rex_001_customers
/// ```
/// {@endtemplate}
class PostgrestTableNames {
  /// {@macro postgrest_table_names}
  const PostgrestTableNames._();

  /// Firma no: 3 haneli (`001`).
  static String padFirm(String firmNr) {
    final t = firmNr.trim();
    if (t.isEmpty) return '001';
    return t.padLeft(3, '0');
  }

  /// Dönem no: 2 haneli (`01`).
  static String padPeriod(String periodNr) {
    final t = periodNr.trim();
    if (t.isEmpty) return '01';
    return t.padLeft(2, '0');
  }

  /// Firma düzeyi tablo: `rex_{FF}_{base}`.
  static String firmTable(String firmNr, String baseTable) {
    final base = baseTable.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    return 'rex_${padFirm(firmNr)}_$base';
  }

  /// Dönem düzeyi tablo: `rex_{FF}_{DD}_{base}`.
  static String periodTable(
    String firmNr,
    String periodNr,
    String baseTable,
  ) {
    final base = baseTable.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    return 'rex_${padFirm(firmNr)}_${padPeriod(periodNr)}_$base';
  }
}
