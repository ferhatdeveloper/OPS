// Dosya Adı: compare_matrix_repository.dart
// Açıklama: Esnek karşılaştırma matrisi SQLite agrege okuma
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:sqflite/sqflite.dart';

import '../model/compare_matrix_models.dart';
import '../model/period_comparison_models.dart';
import 'period_comparison_repository.dart';

/// {@template compare_matrix_repository}
/// Wizard state → satır×sütun matris + KPI özet.
///
/// Kullanım örneği:
/// ```dart
/// const repo = CompareMatrixRepository();
/// final r = await repo.fetchMatrix(db, query);
/// ```
/// {@endtemplate}
class CompareMatrixRepository {
  /// {@macro compare_matrix_repository}
  const CompareMatrixRepository();

  /// {@template compare_matrix_repository_fetch}
  /// Matris ve summary metrikleri.
  ///
  /// Parametreler:
  /// - [db]: SQLite
  /// - [query]: Sihirbaz state
  ///
  /// Dönüş değeri:
  /// - [CompareMatrixResult]
  /// {@endtemplate}
  Future<CompareMatrixResult> fetchMatrix(
    Database db,
    ComparisonWizardState query,
  ) async {
    final hints = <String>[];

    // KPI özeti: ilk iki dönem (A/B) — mevcut repo
    final summary = await _summaryMetrics(db, query);

    if (query.rowAxis == CompareAxis.none &&
        query.columnAxis == CompareAxis.period) {
      return _periodOverviewMatrix(query, summary);
    }

    final colAxis = query.columnAxis;
    final rowAxis = query.rowAxis;

    // Sütunlar: dönem listesi
    final colKeys = <String>[];
    final colLabels = <String>[];
    if (colAxis == CompareAxis.period) {
      for (final p in query.periods) {
        colKeys.add(p.id);
        colLabels.add(
          p.label.trim().isEmpty
              ? '${p.range.fromKey}–${p.range.toKey}'
              : p.label,
        );
      }
    } else {
      // Sütun entity ise tek dönem aralığı (periods.first geneli)
      colKeys.addAll(_selectedKeys(query, colAxis));
      colLabels.addAll(colKeys);
      if (colKeys.isEmpty) {
        // TOP-N entity kolonları ilk dönemde
        final top = await _topEntities(
          db,
          query,
          colAxis,
          range: query.periods.isEmpty
              ? null
              : query.periods.first.range,
          limit: query.topN,
        );
        for (final e in top) {
          colKeys.add(e.key);
          colLabels.add(e.label);
        }
        if (colKeys.isEmpty) {
          hints.add(colAxis.name);
        }
      }
    }

    // Satırlar
    List<_Entity> rows;
    final explicit = _selectedKeys(query, rowAxis);
    if (explicit.isNotEmpty) {
      rows = explicit.map((k) => _Entity(key: k, label: k)).toList();
    } else {
      final rangeForTop = query.periods.isNotEmpty
          ? _mergeRange(query.periods)
          : null;
      rows = await _topEntities(
        db,
        query,
        rowAxis,
        range: rangeForTop,
        limit: query.topN,
      );
      if (rows.isEmpty) {
        hints.add(rowAxis.name);
      }
    }

    final cells = <CompareMatrixCell>[];
    for (var ci = 0; ci < colKeys.length; ci++) {
      final colKey = colKeys[ci];
      final range = colAxis == CompareAxis.period
          ? query.periods[ci].range
          : (query.periods.isNotEmpty
              ? query.periods.first.range
              : PeriodDateRange(
                  from: DateTime.now(),
                  to: DateTime.now(),
                ));

      final values = await _valuesForColumn(
        db,
        query: query,
        rowAxis: rowAxis,
        colAxis: colAxis,
        colKey: colKey,
        range: range,
        rowKeys: rows.map((r) => r.key).toList(),
      );
      for (final e in values.entries) {
        cells.add(
          CompareMatrixCell(
            rowKey: e.key,
            colKey: colKey,
            value: e.value,
          ),
        );
      }
    }

    // Satır etiketlerini zenginleştir
    final labels = await _resolveLabels(
      db,
      rowAxis,
      rows.map((r) => r.key).toList(),
      {for (final r in rows) r.key: r.label},
    );

    return CompareMatrixResult(
      query: query,
      rowKeys: rows.map((r) => r.key).toList(),
      rowLabels: rows.map((r) => labels[r.key] ?? r.label).toList(),
      colKeys: colKeys,
      colLabels: colLabels,
      cells: cells,
      summaryMetrics: summary,
      schemaHints: hints,
    );
  }

  CompareMatrixResult _periodOverviewMatrix(
    ComparisonWizardState query,
    List<PeriodMetricRow> summary,
  ) {
    final periods = query.periods;
    final colKeys = periods.map((p) => p.id).toList();
    final colLabels = periods.map((p) {
      return p.label.trim().isEmpty
          ? '${p.range.fromKey}–${p.range.toKey}'
          : p.label;
    }).toList();

    final rowKeys = <String>[];
    final rowLabels = <String>[];
    final cells = <CompareMatrixCell>[];

    for (final m in summary) {
      rowKeys.add(m.kind.name);
      rowLabels.add(m.kind.name);
      if (colKeys.isNotEmpty) {
        cells.add(
          CompareMatrixCell(
            rowKey: m.kind.name,
            colKey: colKeys[0],
            value: m.periodA,
          ),
        );
      }
      if (colKeys.length > 1) {
        cells.add(
          CompareMatrixCell(
            rowKey: m.kind.name,
            colKey: colKeys[1],
            value: m.periodB,
          ),
        );
      }
    }

    return CompareMatrixResult(
      query: query,
      rowKeys: rowKeys,
      rowLabels: rowLabels,
      colKeys: colKeys,
      colLabels: colLabels,
      cells: cells,
      summaryMetrics: summary,
    );
  }

  Future<List<PeriodMetricRow>> _summaryMetrics(
    Database db,
    ComparisonWizardState query,
  ) async {
    final periods = query.periods;
    if (periods.length < 2) return const [];
    final a = periods[0].range;
    final b = periods[1].range;
    const abRepo = PeriodComparisonRepository();
    final r = await abRepo.fetch(
      db,
      preset: PeriodComparePreset.custom,
      customA: a,
      customB: b,
    );
    return r.rows;
  }

  List<String> _selectedKeys(ComparisonWizardState q, CompareAxis axis) {
    switch (axis) {
      case CompareAxis.company:
        return q.companyIds;
      case CompareAxis.product:
        return q.productIds;
      case CompareAxis.customer:
        return q.customerIds;
      case CompareAxis.supplier:
        return q.supplierIds;
      case CompareAxis.salesman:
        return q.salesmanIds;
      case CompareAxis.region:
        return q.regionIds;
      case CompareAxis.productGroup:
        return q.productGroupIds;
      case CompareAxis.brand:
        return q.brandIds;
      case CompareAxis.period:
      case CompareAxis.none:
        return const [];
    }
  }

  PeriodDateRange _mergeRange(List<ComparePeriodSlot> periods) {
    var min = periods.first.range.from;
    var max = periods.first.range.to;
    for (final p in periods) {
      if (p.range.from.isBefore(min)) min = p.range.from;
      if (p.range.to.isAfter(max)) max = p.range.to;
    }
    return PeriodDateRange(from: min, to: max);
  }

  Future<List<_Entity>> _topEntities(
    Database db,
    ComparisonWizardState query,
    CompareAxis axis, {
    PeriodDateRange? range,
    required int limit,
  }) async {
    final from = range?.fromKey ?? '1970-01-01';
    final to = range?.toKey ?? '2999-12-31';
    final companyFilter = query.companyIds;

    switch (axis) {
      case CompareAxis.product:
        return _queryEntities(
          db,
          '''
          SELECT COALESCE(ii.product_id, 'unknown') AS k,
                 COALESCE(p.name, ii.product_id, '—') AS l,
                 COALESCE(SUM(ii.total_amount), 0) AS v
          FROM invoice_items ii
          JOIN invoices i ON i.id = ii.invoice_id
          LEFT JOIN products p ON p.id = ii.product_id
          WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
            AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
            AND COALESCE(i.status, '') != 'Cancelled'
            ${_inFilter('ii.product_id', query.productIds)}
          GROUP BY k
          ORDER BY v DESC
          LIMIT ?
          ''',
          [from, to, ...query.productIds, limit],
        );
      case CompareAxis.customer:
        return _queryEntities(
          db,
          '''
          SELECT COALESCE(i.customer_id, 'unknown') AS k,
                 COALESCE(c.name, i.customer_id, '—') AS l,
                 COALESCE(SUM(i.total_amount), 0) AS v
          FROM invoices i
          LEFT JOIN customers c ON c.id = i.customer_id
          WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
            AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
            AND COALESCE(i.status, '') != 'Cancelled'
            ${_inFilter('i.customer_id', query.customerIds)}
            ${_companyFilterSql(companyFilter)}
          GROUP BY k
          ORDER BY v DESC
          LIMIT ?
          ''',
          [from, to, ...query.customerIds, ...companyFilter, limit],
        );
      case CompareAxis.company:
        return _queryEntities(
          db,
          '''
          SELECT COALESCE(i.company_id, 'default') AS k,
                 COALESCE(i.company_id, 'default') AS l,
                 COALESCE(SUM(i.total_amount), 0) AS v
          FROM invoices i
          WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
            AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
            AND COALESCE(i.status, '') != 'Cancelled'
            ${_inFilter('i.company_id', companyFilter)}
          GROUP BY k
          ORDER BY v DESC
          LIMIT ?
          ''',
          [from, to, ...companyFilter, limit],
          fallbackOnError: [
            const _Entity(key: 'all', label: 'All'),
          ],
        );
      case CompareAxis.supplier:
        return _queryEntities(
          db,
          '''
          SELECT COALESCE(c.id, 'unknown') AS k,
                 COALESCE(c.name, c.id, '—') AS l,
                 COALESCE(SUM(i.total_amount), 0) AS v
          FROM invoices i
          JOIN customers c ON c.id = i.customer_id
          WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
            AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
            AND COALESCE(i.status, '') != 'Cancelled'
            AND (
              COALESCE(c.card_role, '') = 'supplier'
              OR COALESCE(i.invoice_type, '') LIKE '%Purchase%'
              OR COALESCE(i.invoice_type, '') LIKE '%purchase%'
            )
            ${_inFilter('c.id', query.supplierIds)}
          GROUP BY k
          ORDER BY v DESC
          LIMIT ?
          ''',
          [from, to, ...query.supplierIds, limit],
        );
      case CompareAxis.salesman:
        return _queryEntities(
          db,
          '''
          SELECT COALESCE(i.salesman_code, i.user_id, i.created_by, 'unknown') AS k,
                 COALESCE(i.salesman_code, i.user_id, i.created_by, '—') AS l,
                 COALESCE(SUM(i.total_amount), 0) AS v
          FROM invoices i
          WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
            AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
            AND COALESCE(i.status, '') != 'Cancelled'
            ${_inFilter('i.salesman_code', query.salesmanIds)}
          GROUP BY k
          ORDER BY v DESC
          LIMIT ?
          ''',
          [from, to, ...query.salesmanIds, limit],
        );
      case CompareAxis.region:
        return _queryEntities(
          db,
          '''
          SELECT COALESCE(c.il, c.semt, 'unknown') AS k,
                 COALESCE(c.il, c.semt, '—') AS l,
                 COALESCE(SUM(i.total_amount), 0) AS v
          FROM invoices i
          LEFT JOIN customers c ON c.id = i.customer_id
          WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
            AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
            AND COALESCE(i.status, '') != 'Cancelled'
            ${_inFilter('c.il', query.regionIds)}
          GROUP BY k
          ORDER BY v DESC
          LIMIT ?
          ''',
          [from, to, ...query.regionIds, limit],
        );
      case CompareAxis.productGroup:
      case CompareAxis.brand:
        return _queryEntities(
          db,
          '''
          SELECT COALESCE(p.category, 'unknown') AS k,
                 COALESCE(p.category, '—') AS l,
                 COALESCE(SUM(ii.total_amount), 0) AS v
          FROM invoice_items ii
          JOIN invoices i ON i.id = ii.invoice_id
          LEFT JOIN products p ON p.id = ii.product_id
          WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
            AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
            AND COALESCE(i.status, '') != 'Cancelled'
          GROUP BY k
          ORDER BY v DESC
          LIMIT ?
          ''',
          [from, to, limit],
        );
      case CompareAxis.period:
      case CompareAxis.none:
        return const [];
    }
  }

  String _inFilter(String col, List<String> ids) {
    if (ids.isEmpty) return '';
    final ph = List.filled(ids.length, '?').join(',');
    return 'AND $col IN ($ph)';
  }

  /// Opsiyonel company_id filtresi (kolon yoksa sorgu catch'e düşer).
  String _companyFilterSql(List<String> companyFilter) {
    if (companyFilter.isEmpty) return '';
    final ph = List.filled(companyFilter.length, '?').join(',');
    return 'AND i.company_id IN ($ph)';
  }

  Future<List<_Entity>> _queryEntities(
    Database db,
    String sql,
    List<Object?> args, {
    List<_Entity> fallbackOnError = const [],
  }) async {
    try {
      final rows = await db.rawQuery(sql, args);
      return rows
          .map(
            (r) => _Entity(
              key: '${r['k'] ?? ''}',
              label: '${r['l'] ?? r['k'] ?? '—'}',
            ),
          )
          .where((e) => e.key.isNotEmpty)
          .toList();
    } catch (_) {
      return fallbackOnError;
    }
  }

  Future<Map<String, double>> _valuesForColumn(
    Database db, {
    required ComparisonWizardState query,
    required CompareAxis rowAxis,
    required CompareAxis colAxis,
    required String colKey,
    required PeriodDateRange range,
    required List<String> rowKeys,
  }) async {
    if (rowKeys.isEmpty) return {};
    final from = range.fromKey;
    final to = range.toKey;
    final metric = query.primaryMetric;

    // Dönem özeti dışı: satış tutarı agregasyon
    if (metric == PeriodMetricKind.orderCount) {
      return _orderCounts(db, from, to, rowAxis, rowKeys, query);
    }
    if (metric == PeriodMetricKind.collection) {
      return _collectionSums(db, from, to, rowAxis, rowKeys, query);
    }
    if (metric == PeriodMetricKind.visit) {
      return _visitCounts(db, from, to, rowAxis, rowKeys, query);
    }

    // Default sales
    return _salesSums(
      db,
      from: from,
      to: to,
      rowAxis: rowAxis,
      rowKeys: rowKeys,
      query: query,
      colAxis: colAxis,
      colKey: colKey,
    );
  }

  Future<Map<String, double>> _salesSums(
    Database db, {
    required String from,
    required String to,
    required CompareAxis rowAxis,
    required List<String> rowKeys,
    required ComparisonWizardState query,
    required CompareAxis colAxis,
    required String colKey,
  }) async {
    final result = <String, double>{for (final k in rowKeys) k: 0};
    final ph = List.filled(rowKeys.length, '?').join(',');

    String? groupExpr;
    String? joinExtra = '';
    switch (rowAxis) {
      case CompareAxis.product:
        groupExpr = 'COALESCE(ii.product_id, \'unknown\')';
        joinExtra = 'JOIN invoice_items ii ON ii.invoice_id = i.id';
        break;
      case CompareAxis.customer:
        groupExpr = 'i.customer_id';
        break;
      case CompareAxis.company:
        groupExpr = "COALESCE(i.company_id, 'default')";
        break;
      case CompareAxis.supplier:
        groupExpr = 'i.customer_id';
        break;
      case CompareAxis.salesman:
        groupExpr =
            "COALESCE(i.salesman_code, i.user_id, i.created_by, 'unknown')";
        break;
      case CompareAxis.region:
        groupExpr = "COALESCE(c.il, c.semt, 'unknown')";
        joinExtra = 'LEFT JOIN customers c ON c.id = i.customer_id';
        break;
      case CompareAxis.productGroup:
      case CompareAxis.brand:
        groupExpr = "COALESCE(p.category, 'unknown')";
        joinExtra = '''
          JOIN invoice_items ii ON ii.invoice_id = i.id
          LEFT JOIN products p ON p.id = ii.product_id
        ''';
        break;
      case CompareAxis.period:
      case CompareAxis.none:
        return result;
    }

    final amountExpr = joinExtra.contains('invoice_items')
        ? 'COALESCE(SUM(ii.total_amount), 0)'
        : 'COALESCE(SUM(i.total_amount), 0)';

    final sql = '''
      SELECT $groupExpr AS k, $amountExpr AS v
      FROM invoices i
      $joinExtra
      WHERE date(COALESCE(i.invoice_date, i.created_at)) >= date(?)
        AND date(COALESCE(i.invoice_date, i.created_at)) <= date(?)
        AND COALESCE(i.status, '') != 'Cancelled'
        AND $groupExpr IN ($ph)
      GROUP BY k
    ''';

    try {
      final rows = await db.rawQuery(sql, [from, to, ...rowKeys]);
      for (final r in rows) {
        final k = '${r['k'] ?? ''}';
        if (result.containsKey(k)) {
          result[k] = _asDouble(r['v']);
        }
      }
    } catch (_) {
      // invoices.company_id yoksa: dönem toplamını seçili satırlara yaz
      // (tek firma DB / ActiveCompany senaryosu).
      if (rowAxis == CompareAxis.company) {
        try {
          final totalRows = await db.rawQuery(
            '''
            SELECT COALESCE(SUM(total_amount), 0) AS v
            FROM invoices
            WHERE date(COALESCE(invoice_date, created_at)) >= date(?)
              AND date(COALESCE(invoice_date, created_at)) <= date(?)
              AND COALESCE(status, '') != 'Cancelled'
            ''',
            [from, to],
          );
          final total = totalRows.isEmpty
              ? 0.0
              : _asDouble(totalRows.first['v']);
          if (rowKeys.length == 1) {
            result[rowKeys.first] = total;
          } else if (rowKeys.isNotEmpty) {
            // Çoklu seçimde yalnızca ilk satıra (aktif) yaz; diğerleri 0.
            result[rowKeys.first] = total;
          }
        } catch (_) {}
      }
    }
    return result;
  }

  Future<Map<String, double>> _orderCounts(
    Database db,
    String from,
    String to,
    CompareAxis rowAxis,
    List<String> rowKeys,
    ComparisonWizardState query,
  ) async {
    final result = <String, double>{for (final k in rowKeys) k: 0};
    if (rowAxis != CompareAxis.customer && rowAxis != CompareAxis.company) {
      // basit: toplam sipariş sayısı / satır sayısı dağıtılmaz — customer grubu
      try {
        final rows = await db.rawQuery(
          '''
          SELECT COALESCE(customer_id, 'unknown') AS k, COUNT(*) AS v
          FROM orders
          WHERE date(COALESCE(order_date, created_at)) >= date(?)
            AND date(COALESCE(order_date, created_at)) <= date(?)
            AND COALESCE(status, '') != 'Cancelled'
          GROUP BY k
          ''',
          [from, to],
        );
        for (final r in rows) {
          final k = '${r['k'] ?? ''}';
          if (result.containsKey(k)) result[k] = _asDouble(r['v']);
        }
      } catch (_) {}
      return result;
    }
    try {
      final ph = List.filled(rowKeys.length, '?').join(',');
      final col = rowAxis == CompareAxis.customer
          ? 'customer_id'
          : "COALESCE(company_id, firm_nr, 'default')";
      final rows = await db.rawQuery(
        '''
        SELECT $col AS k, COUNT(*) AS v
        FROM orders
        WHERE date(COALESCE(order_date, created_at)) >= date(?)
          AND date(COALESCE(order_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled'
          AND $col IN ($ph)
        GROUP BY k
        ''',
        [from, to, ...rowKeys],
      );
      for (final r in rows) {
        final k = '${r['k'] ?? ''}';
        if (result.containsKey(k)) result[k] = _asDouble(r['v']);
      }
    } catch (_) {}
    return result;
  }

  Future<Map<String, double>> _collectionSums(
    Database db,
    String from,
    String to,
    CompareAxis rowAxis,
    List<String> rowKeys,
    ComparisonWizardState query,
  ) async {
    final result = <String, double>{for (final k in rowKeys) k: 0};
    try {
      final ph = List.filled(rowKeys.length, '?').join(',');
      final rows = await db.rawQuery(
        '''
        SELECT COALESCE(customer_id, 'unknown') AS k,
               COALESCE(SUM(amount), 0) AS v
        FROM collections
        WHERE date(COALESCE(collection_date, created_at)) >= date(?)
          AND date(COALESCE(collection_date, created_at)) <= date(?)
          AND COALESCE(status, '') != 'Cancelled'
          AND COALESCE(customer_id, 'unknown') IN ($ph)
        GROUP BY k
        ''',
        [from, to, ...rowKeys],
      );
      for (final r in rows) {
        final k = '${r['k'] ?? ''}';
        if (result.containsKey(k)) result[k] = _asDouble(r['v']);
      }
    } catch (_) {}
    return result;
  }

  Future<Map<String, double>> _visitCounts(
    Database db,
    String from,
    String to,
    CompareAxis rowAxis,
    List<String> rowKeys,
    ComparisonWizardState query,
  ) async {
    final result = <String, double>{for (final k in rowKeys) k: 0};
    try {
      final ph = List.filled(rowKeys.length, '?').join(',');
      final rows = await db.rawQuery(
        '''
        SELECT COALESCE(customer_id, 'unknown') AS k, COUNT(*) AS v
        FROM visits
        WHERE date(COALESCE(check_in_at, created_at)) >= date(?)
          AND date(COALESCE(check_in_at, created_at)) <= date(?)
          AND COALESCE(customer_id, 'unknown') IN ($ph)
        GROUP BY k
        ''',
        [from, to, ...rowKeys],
      );
      for (final r in rows) {
        final k = '${r['k'] ?? ''}';
        if (result.containsKey(k)) result[k] = _asDouble(r['v']);
      }
    } catch (_) {}
    return result;
  }

  Future<Map<String, String>> _resolveLabels(
    Database db,
    CompareAxis axis,
    List<String> keys,
    Map<String, String> fallback,
  ) async {
    if (keys.isEmpty) return fallback;
    final out = Map<String, String>.from(fallback);
    try {
      final ph = List.filled(keys.length, '?').join(',');
      if (axis == CompareAxis.product) {
        final rows = await db.rawQuery(
          'SELECT id, name FROM products WHERE id IN ($ph)',
          keys,
        );
        for (final r in rows) {
          out['${r['id']}'] = '${r['name'] ?? r['id']}';
        }
      } else if (axis == CompareAxis.customer ||
          axis == CompareAxis.supplier) {
        final rows = await db.rawQuery(
          'SELECT id, name FROM customers WHERE id IN ($ph)',
          keys,
        );
        for (final r in rows) {
          out['${r['id']}'] = '${r['name'] ?? r['id']}';
        }
      }
    } catch (_) {}
    return out;
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _Entity {
  final String key;
  final String label;

  const _Entity({required this.key, required this.label});
}
