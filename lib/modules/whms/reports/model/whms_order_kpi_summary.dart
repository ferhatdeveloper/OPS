// Dosya Adı: whms_order_kpi_summary.dart
// Açıklama: WHMS emir KPI özeti — sayılar, tip dağılımı, sayım fark
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_order_type_count}
/// Emir tipi × adet kırılımı.
///
/// Kullanım örneği:
/// ```dart
/// const row = WhmsOrderTypeCount(typeWire: 'pick', count: 3);
/// ```
/// {@endtemplate}
class WhmsOrderTypeCount {
  /// [typeWire]: `order_type` wire kodu
  final String typeWire;

  /// [count]: Adet
  final int count;

  /// {@macro whms_order_type_count}
  const WhmsOrderTypeCount({
    required this.typeWire,
    required this.count,
  });

  /// AI / rapor map.
  Map<String, String> toInsightMap() {
    return {
      'type': typeWire,
      'count': '$count',
    };
  }
}

/// {@template whms_order_kpi_summary}
/// Emir KPI dashboard özeti — SQLite aggregate.
///
/// Kullanım örneği:
/// ```dart
/// const s = WhmsOrderKpiSummary(totalOrders: 10, openOrders: 4);
/// ```
/// {@endtemplate}
class WhmsOrderKpiSummary {
  /// [totalOrders]: Soft-delete hariç tüm emir
  final int totalOrders;

  /// [openOrders]: draft + assigned + in_progress
  final int openOrders;

  /// [completedOrders]: done / completed
  final int completedOrders;

  /// [draftOrders]: draft
  final int draftOrders;

  /// [inProgressOrders]: in_progress
  final int inProgressOrders;

  /// [typeCounts]: Tip dağılımı (sıralı, azalan)
  final List<WhmsOrderTypeCount> typeCounts;

  /// [countResultRows]: Sayım fark kayıt adedi
  final int countResultRows;

  /// [countVarianceSum]: Net fark miktarı (fiili − sistem)
  final double countVarianceSum;

  /// [countVarianceAbsSum]: Mutlak fark toplamı
  final double countVarianceAbsSum;

  /// {@macro whms_order_kpi_summary}
  const WhmsOrderKpiSummary({
    this.totalOrders = 0,
    this.openOrders = 0,
    this.completedOrders = 0,
    this.draftOrders = 0,
    this.inProgressOrders = 0,
    this.typeCounts = const [],
    this.countResultRows = 0,
    this.countVarianceSum = 0,
    this.countVarianceAbsSum = 0,
  });

  /// [zero]: Boş özet
  static const WhmsOrderKpiSummary zero = WhmsOrderKpiSummary();

  /// AI insight satırları.
  List<Map<String, String>> toInsightRows() {
    final rows = <Map<String, String>>[
      {'metric': 'total_orders', 'value': '$totalOrders'},
      {'metric': 'open_orders', 'value': '$openOrders'},
      {'metric': 'completed_orders', 'value': '$completedOrders'},
      {'metric': 'draft_orders', 'value': '$draftOrders'},
      {'metric': 'in_progress_orders', 'value': '$inProgressOrders'},
      {
        'metric': 'count_results',
        'value': '$countResultRows',
        'variance_sum': countVarianceSum.toStringAsFixed(2),
        'variance_abs': countVarianceAbsSum.toStringAsFixed(2),
      },
    ];
    for (final t in typeCounts) {
      rows.add(t.toInsightMap());
    }
    return rows;
  }
}
