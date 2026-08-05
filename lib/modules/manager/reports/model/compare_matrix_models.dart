// Dosya Adı: compare_matrix_models.dart
// Açıklama: Esnek karşılaştırma matrisi eksen / şablon / sihirbaz modelleri
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'period_comparison_models.dart';

/// {@template compare_axis}
/// Matris satır/sütun boyutları.
///
/// Kullanım örneği:
/// ```dart
/// final a = CompareAxis.product;
/// ```
/// {@endtemplate}
enum CompareAxis {
  /// Global özet (satır yok / KPI)
  none,

  /// Dönem dilimleri
  period,

  /// Firma
  company,

  /// Ürün
  product,

  /// Müşteri
  customer,

  /// Tedarikçi
  supplier,

  /// Plasiyer / satış elemanı
  salesman,

  /// Bölge
  region,

  /// Ürün grubu
  productGroup,

  /// Marka
  brand,
}

/// {@template compare_template}
/// Hazır matris şablonları.
/// {@endtemplate}
enum CompareTemplate {
  /// Mevcut A/B dönem özeti
  periodOverview,

  /// Firma × dönem
  companyPeriod,

  /// Ürün × dönem
  productPeriod,

  /// Müşteri × dönem
  customerPeriod,

  /// Tedarikçi × dönem
  supplierPeriod,

  /// Plasiyer × dönem
  salesmanPeriod,

  /// Marka/kategori × dönem
  brandCategory,

  /// Bölge × dönem
  regionPeriod,

  /// Kullanıcı seçimli
  custom,
}

/// {@template compare_period_slot}
/// Tek dönem dilimi (sütun).
///
/// Kullanım örneği:
/// ```dart
/// final s = ComparePeriodSlot(
///   id: '1',
///   label: 'Bu Ay',
///   range: PeriodDateRange(from: a, to: b),
/// );
/// ```
/// {@endtemplate}
class ComparePeriodSlot {
  /// [id]: Yerel kimlik
  final String id;

  /// [label]: Görünen ad
  final String label;

  /// [range]: Tarih aralığı
  final PeriodDateRange range;

  /// {@macro compare_period_slot}
  const ComparePeriodSlot({
    required this.id,
    required this.label,
    required this.range,
  });

  /// Kopya.
  ComparePeriodSlot copyWith({
    String? id,
    String? label,
    PeriodDateRange? range,
  }) {
    return ComparePeriodSlot(
      id: id ?? this.id,
      label: label ?? this.label,
      range: range ?? this.range,
    );
  }

  /// JSON serileştirme.
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'from': range.fromKey,
        'to': range.toKey,
      };

  /// JSON'dan dönem dilimi.
  static ComparePeriodSlot? fromJson(Map<String, dynamic>? map) {
    if (map == null) return null;
    final id = map['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    final from = DateTime.tryParse(map['from']?.toString() ?? '');
    final to = DateTime.tryParse(map['to']?.toString() ?? '');
    if (from == null || to == null) return null;
    return ComparePeriodSlot(
      id: id,
      label: map['label']?.toString() ?? id,
      range: PeriodDateRange(from: from, to: to),
    );
  }
}

/// {@template comparison_wizard_state}
/// 4 adımlı sihirbaz state.
///
/// Kullanım örneği:
/// ```dart
/// final s = ComparisonWizardState.fromTemplate(
///   CompareTemplate.productPeriod,
/// );
/// ```
/// {@endtemplate}
class ComparisonWizardState {
  /// Max sütun/dönem
  static const int maxPeriods = 6;

  /// [step]: 0 şablon, 1 eksen, 2 filtre, 3 sonuç
  final int step;

  /// [template]: Seçili şablon
  final CompareTemplate template;

  /// [rowAxis]: Satır boyutu
  final CompareAxis rowAxis;

  /// [columnAxis]: Sütun boyutu
  final CompareAxis columnAxis;

  /// [periods]: Dönem dilimleri (≤6)
  final List<ComparePeriodSlot> periods;

  /// [companyIds]: Firma filtresi / satır
  final List<String> companyIds;

  /// [productIds]: Ürün filtresi
  final List<String> productIds;

  /// [customerIds]: Müşteri filtresi
  final List<String> customerIds;

  /// [supplierIds]: Tedarikçi filtresi
  final List<String> supplierIds;

  /// [salesmanIds]: Plasiyer filtresi
  final List<String> salesmanIds;

  /// [regionIds]: Bölge filtresi
  final List<String> regionIds;

  /// [productGroupIds]: Ürün grubu
  final List<String> productGroupIds;

  /// [brandIds]: Marka
  final List<String> brandIds;

  /// [topN]: Boş filtrede TOP-N satır
  final int topN;

  /// [primaryMetric]: Grafik metrik
  final PeriodMetricKind primaryMetric;

  /// {@macro comparison_wizard_state}
  ComparisonWizardState({
    required this.step,
    required this.template,
    required this.rowAxis,
    required this.columnAxis,
    required List<ComparePeriodSlot> periods,
    this.companyIds = const [],
    this.productIds = const [],
    this.customerIds = const [],
    this.supplierIds = const [],
    this.salesmanIds = const [],
    this.regionIds = const [],
    this.productGroupIds = const [],
    this.brandIds = const [],
    this.topN = 15,
    this.primaryMetric = PeriodMetricKind.sales,
  }) : periods = _clampPeriods(periods);

  /// Şablondan başlangıç state.
  factory ComparisonWizardState.fromTemplate(
    CompareTemplate template, {
    DateTime? anchor,
  }) {
    final now = anchor ?? DateTime.now();
    final slots = _defaultPeriods(now);
    switch (template) {
      case CompareTemplate.periodOverview:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.none,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
      case CompareTemplate.companyPeriod:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.company,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
      case CompareTemplate.productPeriod:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.product,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
      case CompareTemplate.customerPeriod:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.customer,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
      case CompareTemplate.supplierPeriod:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.supplier,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
      case CompareTemplate.salesmanPeriod:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.salesman,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
      case CompareTemplate.brandCategory:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.brand,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
      case CompareTemplate.regionPeriod:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.region,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
      case CompareTemplate.custom:
        return ComparisonWizardState(
          step: 0,
          template: template,
          rowAxis: CompareAxis.product,
          columnAxis: CompareAxis.period,
          periods: slots,
        );
    }
  }

  /// Satır/sütun aynı boyuta sahip olmamalı.
  bool get isAxesValid {
    if (rowAxis == CompareAxis.none && columnAxis == CompareAxis.period) {
      return true;
    }
    if (rowAxis == CompareAxis.none) return false;
    return rowAxis != columnAxis;
  }

  /// Filtre adımına geçilebilir mi (min dönem sayısı).
  bool get canProceedFromFilters {
    if (columnAxis == CompareAxis.period || rowAxis == CompareAxis.period) {
      return periods.length >= 2 && periods.length <= maxPeriods;
    }
    return periods.isNotEmpty && periods.length <= maxPeriods;
  }

  /// Kopya (periods max 6 clamp).
  ComparisonWizardState copyWith({
    int? step,
    CompareTemplate? template,
    CompareAxis? rowAxis,
    CompareAxis? columnAxis,
    List<ComparePeriodSlot>? periods,
    List<String>? companyIds,
    List<String>? productIds,
    List<String>? customerIds,
    List<String>? supplierIds,
    List<String>? salesmanIds,
    List<String>? regionIds,
    List<String>? productGroupIds,
    List<String>? brandIds,
    int? topN,
    PeriodMetricKind? primaryMetric,
  }) {
    return ComparisonWizardState(
      step: step ?? this.step,
      template: template ?? this.template,
      rowAxis: rowAxis ?? this.rowAxis,
      columnAxis: columnAxis ?? this.columnAxis,
      periods: periods ?? this.periods,
      companyIds: companyIds ?? this.companyIds,
      productIds: productIds ?? this.productIds,
      customerIds: customerIds ?? this.customerIds,
      supplierIds: supplierIds ?? this.supplierIds,
      salesmanIds: salesmanIds ?? this.salesmanIds,
      regionIds: regionIds ?? this.regionIds,
      productGroupIds: productGroupIds ?? this.productGroupIds,
      brandIds: brandIds ?? this.brandIds,
      topN: topN ?? this.topN,
      primaryMetric: primaryMetric ?? this.primaryMetric,
    );
  }

  /// SQLite geçmiş için JSON.
  Map<String, dynamic> toJson() => {
        'step': step,
        'template': template.name,
        'row_axis': rowAxis.name,
        'column_axis': columnAxis.name,
        'periods': periods.map((p) => p.toJson()).toList(),
        'company_ids': companyIds,
        'product_ids': productIds,
        'customer_ids': customerIds,
        'supplier_ids': supplierIds,
        'salesman_ids': salesmanIds,
        'region_ids': regionIds,
        'product_group_ids': productGroupIds,
        'brand_ids': brandIds,
        'top_n': topN,
        'primary_metric': primaryMetric.name,
      };

  /// JSON → sihirbaz state.
  static ComparisonWizardState? fromJson(Map<String, dynamic>? map) {
    if (map == null) return null;
    CompareTemplate template;
    try {
      template = CompareTemplate.values.byName(
        map['template']?.toString() ?? '',
      );
    } catch (_) {
      template = CompareTemplate.periodOverview;
    }
    CompareAxis rowAxis;
    CompareAxis columnAxis;
    try {
      rowAxis = CompareAxis.values.byName(map['row_axis']?.toString() ?? '');
    } catch (_) {
      rowAxis = CompareAxis.none;
    }
    try {
      columnAxis =
          CompareAxis.values.byName(map['column_axis']?.toString() ?? '');
    } catch (_) {
      columnAxis = CompareAxis.period;
    }
    PeriodMetricKind metric;
    try {
      metric = PeriodMetricKind.values.byName(
        map['primary_metric']?.toString() ?? '',
      );
    } catch (_) {
      metric = PeriodMetricKind.sales;
    }
    final rawPeriods = map['periods'];
    final periods = <ComparePeriodSlot>[];
    if (rawPeriods is List) {
      for (final item in rawPeriods) {
        if (item is Map<String, dynamic>) {
          final slot = ComparePeriodSlot.fromJson(item);
          if (slot != null) periods.add(slot);
        } else if (item is Map) {
          final slot = ComparePeriodSlot.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (slot != null) periods.add(slot);
        }
      }
    }
    if (periods.length < 2) {
      return ComparisonWizardState.fromTemplate(template).copyWith(
        step: (map['step'] as num?)?.toInt() ?? 0,
        rowAxis: rowAxis,
        columnAxis: columnAxis,
        companyIds: _strList(map['company_ids']),
        productIds: _strList(map['product_ids']),
        customerIds: _strList(map['customer_ids']),
        supplierIds: _strList(map['supplier_ids']),
        salesmanIds: _strList(map['salesman_ids']),
        regionIds: _strList(map['region_ids']),
        productGroupIds: _strList(map['product_group_ids']),
        brandIds: _strList(map['brand_ids']),
        topN: (map['top_n'] as num?)?.toInt() ?? 15,
        primaryMetric: metric,
      );
    }
    return ComparisonWizardState(
      step: (map['step'] as num?)?.toInt() ?? 0,
      template: template,
      rowAxis: rowAxis,
      columnAxis: columnAxis,
      periods: periods,
      companyIds: _strList(map['company_ids']),
      productIds: _strList(map['product_ids']),
      customerIds: _strList(map['customer_ids']),
      supplierIds: _strList(map['supplier_ids']),
      salesmanIds: _strList(map['salesman_ids']),
      regionIds: _strList(map['region_ids']),
      productGroupIds: _strList(map['product_group_ids']),
      brandIds: _strList(map['brand_ids']),
      topN: (map['top_n'] as num?)?.toInt() ?? 15,
      primaryMetric: metric,
    );
  }

  static List<String> _strList(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  static List<ComparePeriodSlot> _clampPeriods(
    List<ComparePeriodSlot> list,
  ) {
    if (list.length <= maxPeriods) return List.unmodifiable(list);
    return List.unmodifiable(list.take(maxPeriods));
  }

  /// Bu ay + geçen ay varsayılan dilimler.
  static List<ComparePeriodSlot> _defaultPeriods(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final bFrom = DateTime(today.year, today.month, 1);
    final aTo = bFrom.subtract(const Duration(days: 1));
    final aFrom = DateTime(aTo.year, aTo.month, 1);
    return [
      ComparePeriodSlot(
        id: 'a',
        label: 'A',
        range: PeriodDateRange(from: aFrom, to: aTo),
      ),
      ComparePeriodSlot(
        id: 'b',
        label: 'B',
        range: PeriodDateRange(from: bFrom, to: today),
      ),
    ];
  }
}

/// {@template compare_matrix_cell}
/// Matris hücresi.
/// {@endtemplate}
class CompareMatrixCell {
  /// [rowKey]: Satır anahtarı
  final String rowKey;

  /// [colKey]: Sütun anahtarı
  final String colKey;

  /// [value]: Değer
  final double value;

  /// {@macro compare_matrix_cell}
  const CompareMatrixCell({
    required this.rowKey,
    required this.colKey,
    required this.value,
  });
}

/// {@template compare_matrix_result}
/// Matris sorgu sonucu + özet metrikler.
/// {@endtemplate}
class CompareMatrixResult {
  /// [query]: Sihirbaz sorgu
  final ComparisonWizardState query;

  /// [rowKeys]: Satır id
  final List<String> rowKeys;

  /// [rowLabels]: Satır etiket
  final List<String> rowLabels;

  /// [colKeys]: Sütun id
  final List<String> colKeys;

  /// [colLabels]: Sütun etiket
  final List<String> colLabels;

  /// [cells]: Hücreler
  final List<CompareMatrixCell> cells;

  /// [summaryMetrics]: KPI A/B (ilk iki dönem veya global)
  final List<PeriodMetricRow> summaryMetrics;

  /// [schemaHints]: Eksik şema uyarıları
  final List<String> schemaHints;

  /// {@macro compare_matrix_result}
  const CompareMatrixResult({
    required this.query,
    required this.rowKeys,
    required this.rowLabels,
    required this.colKeys,
    required this.colLabels,
    required this.cells,
    this.summaryMetrics = const [],
    this.schemaHints = const [],
  });

  /// Hücre değeri.
  double valueAt(String rowKey, String colKey) {
    for (final c in cells) {
      if (c.rowKey == rowKey && c.colKey == colKey) return c.value;
    }
    return 0;
  }

  /// Boş sonuç.
  static CompareMatrixResult empty(ComparisonWizardState query) {
    return CompareMatrixResult(
      query: query,
      rowKeys: const [],
      rowLabels: const [],
      colKeys: query.periods.map((p) => p.id).toList(),
      colLabels: query.periods.map((p) => p.label).toList(),
      cells: const [],
    );
  }

  /// Snapshot JSON (geçmiş).
  Map<String, dynamic> toJson() => {
        'query': query.toJson(),
        'row_keys': rowKeys,
        'row_labels': rowLabels,
        'col_keys': colKeys,
        'col_labels': colLabels,
        'cells': [
          for (final c in cells)
            {
              'row_key': c.rowKey,
              'col_key': c.colKey,
              'value': c.value,
            },
        ],
        'summary': [
          for (final m in summaryMetrics)
            {
              'kind': m.kind.name,
              'period_a': m.periodA,
              'period_b': m.periodB,
            },
        ],
        'schema_hints': schemaHints,
      };

  /// Snapshot → sonuç.
  static CompareMatrixResult? fromJson(Map<String, dynamic>? map) {
    if (map == null) return null;
    final queryRaw = map['query'];
    final query = ComparisonWizardState.fromJson(
      queryRaw is Map<String, dynamic>
          ? queryRaw
          : (queryRaw is Map
              ? Map<String, dynamic>.from(queryRaw)
              : null),
    );
    if (query == null) return null;
    final cells = <CompareMatrixCell>[];
    final rawCells = map['cells'];
    if (rawCells is List) {
      for (final item in rawCells) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        cells.add(
          CompareMatrixCell(
            rowKey: m['row_key']?.toString() ?? '',
            colKey: m['col_key']?.toString() ?? '',
            value: (m['value'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }
    final summary = <PeriodMetricRow>[];
    final rawSummary = map['summary'];
    if (rawSummary is List) {
      for (final item in rawSummary) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        PeriodMetricKind kind;
        try {
          kind = PeriodMetricKind.values.byName(m['kind']?.toString() ?? '');
        } catch (_) {
          continue;
        }
        summary.add(
          PeriodMetricRow(
            kind: kind,
            periodA: (m['period_a'] as num?)?.toDouble() ?? 0,
            periodB: (m['period_b'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }
    List<String> asStrList(Object? raw) {
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).toList();
    }

    return CompareMatrixResult(
      query: query,
      rowKeys: asStrList(map['row_keys']),
      rowLabels: asStrList(map['row_labels']),
      colKeys: asStrList(map['col_keys']),
      colLabels: asStrList(map['col_labels']),
      cells: cells,
      summaryMetrics: summary,
      schemaHints: asStrList(map['schema_hints']),
    );
  }
}
