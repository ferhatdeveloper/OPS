// Dosya Adı: report_pivot_aggregator.dart
// Açıklama: Rapor satırlarından dens pivot tablo toplama (sum)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../model/report_layout.dart';
import '../model/report_layout_column.dart';

/// {@template report_pivot_result}
/// Pivot hücre matrisi + satır/sütun/genel toplamlar.
///
/// Kullanım örneği:
/// ```dart
/// final pivot = ReportPivotAggregator.aggregate(
///   rows: rows,
///   rowFieldId: 'code',
///   columnFieldId: 'txn_type',
///   valueFieldId: 'amount',
/// );
/// ```
/// {@endtemplate}
class ReportPivotResult {
  /// [rowKeys]: Satır boyut değerleri (sıralı)
  final List<String> rowKeys;

  /// [columnKeys]: Sütun boyut değerleri (sıralı; boş = tek ölçü)
  final List<String> columnKeys;

  /// [cells]: rowKey → columnKey → toplam
  final Map<String, Map<String, double>> cells;

  /// [rowTotals]: Satır toplamları
  final Map<String, double> rowTotals;

  /// [columnTotals]: Sütun toplamları
  final Map<String, double> columnTotals;

  /// [grandTotal]: Genel toplam
  final double grandTotal;

  /// {@macro report_pivot_result}
  const ReportPivotResult({
    required this.rowKeys,
    required this.columnKeys,
    required this.cells,
    required this.rowTotals,
    required this.columnTotals,
    required this.grandTotal,
  });

  /// {@template report_pivot_result_cell}
  /// Hücre değeri (yoksa 0).
  /// {@endtemplate}
  double cell(String rowKey, String columnKey) {
    return cells[rowKey]?[columnKey] ?? 0;
  }
}

/// {@template report_pivot_field_guess}
/// Layout’tan satır / sütun / ölçü varsayılanları.
/// {@endtemplate}
class ReportPivotFieldGuess {
  /// [rowFieldId]: Satır boyutu
  final String? rowFieldId;

  /// [columnFieldId]: Sütun boyutu (opsiyonel)
  final String? columnFieldId;

  /// [valueFieldId]: Ölçü (sum)
  final String? valueFieldId;

  /// {@macro report_pivot_field_guess}
  const ReportPivotFieldGuess({
    this.rowFieldId,
    this.columnFieldId,
    this.valueFieldId,
  });
}

/// {@template report_pivot_aggregator}
/// Rapor satırlarını pivot matrise toplar (sum).
///
/// Kullanım örneği:
/// ```dart
/// final r = ReportPivotAggregator.aggregate(
///   rows: [
///     {'code': 'A', 'type': 'Nakit', 'amount': '10'},
///     {'code': 'A', 'type': 'Nakit', 'amount': '5'},
///   ],
///   rowFieldId: 'code',
///   columnFieldId: 'type',
///   valueFieldId: 'amount',
/// );
/// // r.cell('A', 'Nakit') == 15
/// ```
/// {@endtemplate}
class ReportPivotAggregator {
  /// {@macro report_pivot_aggregator}
  const ReportPivotAggregator._();

  /// Boş boyut etiketi
  static const String emptyLabel = '(boş)';

  /// Tek ölçü sütunu anahtarı (columnFieldId null iken)
  static const String singleMeasureKey = '_';

  /// {@template report_pivot_aggregator_parse_number}
  /// TR/EN sayı dizgesini double’a çevirir.
  ///
  /// Parametreler:
  /// - [raw]: Ham metin (`1.234,56` / `1,234.56` / `1234`)
  ///
  /// Dönüş değeri:
  /// - [double?]: Sayı veya null
  /// {@endtemplate}
  static double? parseNumber(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (s.isEmpty || s == '-' || s == '.' || s == ',') return null;

    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }

  /// {@template report_pivot_aggregator_guess_fields}
  /// Görünür sütunlardan satır / sütun / ölçü tahmini.
  ///
  /// Parametreler:
  /// - [layout]: ReportLayout
  ///
  /// Dönüş değeri:
  /// - [ReportPivotFieldGuess]: Varsayılan alanlar
  /// {@endtemplate}
  static ReportPivotFieldGuess guessFields(ReportLayout layout) {
    final cols = layout.visibleColumns;
    if (cols.isEmpty) {
      return const ReportPivotFieldGuess();
    }

    ReportLayoutColumn? valueCol;
    for (final c in cols) {
      if (c.includeInTotals) {
        valueCol = c;
        break;
      }
    }
    if (valueCol == null) {
      for (final c in cols) {
        if (c.align == ReportLayoutColumnAlign.right) {
          valueCol = c;
          break;
        }
      }
    }
    valueCol ??= cols.last;

    final dimCols = cols.where((c) => c.id != valueCol!.id).toList();
    final rowCol = dimCols.isNotEmpty ? dimCols.first : cols.first;
    final colCol = dimCols.length > 1 ? dimCols[1] : null;

    return ReportPivotFieldGuess(
      rowFieldId: rowCol.id,
      columnFieldId: colCol?.id,
      valueFieldId: valueCol.id,
    );
  }

  /// {@template report_pivot_aggregator_aggregate}
  /// Satırları pivot matrise toplar (sum).
  ///
  /// Parametreler:
  /// - [rows]: columnId → değer
  /// - [rowFieldId]: Satır boyutu
  /// - [columnFieldId]: Sütun boyutu (null → tek ölçü sütunu)
  /// - [valueFieldId]: Toplanacak alan
  ///
  /// Dönüş değeri:
  /// - [ReportPivotResult]: Matris + toplamlar
  /// {@endtemplate}
  static ReportPivotResult aggregate({
    required List<Map<String, String>> rows,
    required String rowFieldId,
    String? columnFieldId,
    required String valueFieldId,
  }) {
    final cells = <String, Map<String, double>>{};
    final rowOrder = <String>[];
    final colOrder = <String>[];
    final rowSeen = <String>{};
    final colSeen = <String>{};

    for (final row in rows) {
      final rk = _label(row[rowFieldId]);
      final ck = columnFieldId == null
          ? singleMeasureKey
          : _label(row[columnFieldId]);
      final v = parseNumber(row[valueFieldId]) ?? 0;

      if (rowSeen.add(rk)) rowOrder.add(rk);
      if (colSeen.add(ck)) colOrder.add(ck);

      final rowMap = cells.putIfAbsent(rk, () => <String, double>{});
      rowMap[ck] = (rowMap[ck] ?? 0) + v;
    }

    final rowTotals = <String, double>{};
    final columnTotals = <String, double>{};
    var grand = 0.0;
    for (final rk in rowOrder) {
      var rt = 0.0;
      final rowMap = cells[rk] ?? const {};
      for (final ck in colOrder) {
        final v = rowMap[ck] ?? 0;
        rt += v;
        columnTotals[ck] = (columnTotals[ck] ?? 0) + v;
      }
      rowTotals[rk] = rt;
      grand += rt;
    }

    return ReportPivotResult(
      rowKeys: rowOrder,
      columnKeys: colOrder,
      cells: cells,
      rowTotals: rowTotals,
      columnTotals: columnTotals,
      grandTotal: grand,
    );
  }

  static String _label(String? raw) {
    final t = raw?.trim() ?? '';
    return t.isEmpty ? emptyLabel : t;
  }
}
