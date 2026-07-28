// Dosya Adı: period_comparison_repository.dart
// Açıklama: Dönem karşılaştırma SQLite metrik okuma katmanı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../model/period_comparison_models.dart';

/// {@template period_comparison_repository}
/// Yerel SQLite’tan A/B dönem metriklerini okur.
///
/// Kullanım örneği:
/// ```dart
/// const repo = PeriodComparisonRepository();
/// final result = await repo.fetch(db, preset: PeriodComparePreset.thisMonthVsLast);
/// ```
/// {@endtemplate}
class PeriodComparisonRepository {
  /// {@macro period_comparison_repository}
  const PeriodComparisonRepository();

  /// {@template period_comparison_repository_fetch}
  /// Preset/özel aralık için metrik satırları.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite
  /// - [preset]: Dens ön ayar
  /// - [customA] / [customB]: custom için aralıklar
  /// - [anchor]: Referans gün
  ///
  /// Dönüş değeri:
  /// - [PeriodComparisonResult]: A/B + metrikler
  /// {@endtemplate}
  Future<PeriodComparisonResult> fetch(
    Database db, {
    required PeriodComparePreset preset,
    PeriodDateRange? customA,
    PeriodDateRange? customB,
    DateTime? anchor,
  }) async {
    final (rangeA, rangeB) = PeriodCompareRangeResolver.resolve(
      preset,
      anchor: anchor,
      customA: customA,
      customB: customB,
    );

    final a = await _metricsForRange(db, rangeA);
    final b = await _metricsForRange(db, rangeB);

    final rows = <PeriodMetricRow>[
      PeriodMetricRow(
        kind: PeriodMetricKind.sales,
        periodA: a.sales,
        periodB: b.sales,
      ),
      PeriodMetricRow(
        kind: PeriodMetricKind.orderCount,
        periodA: a.orderCount.toDouble(),
        periodB: b.orderCount.toDouble(),
      ),
      PeriodMetricRow(
        kind: PeriodMetricKind.collection,
        periodA: a.collection,
        periodB: b.collection,
      ),
      PeriodMetricRow(
        kind: PeriodMetricKind.visit,
        periodA: a.visitCount.toDouble(),
        periodB: b.visitCount.toDouble(),
      ),
      PeriodMetricRow(
        kind: PeriodMetricKind.targetAchievement,
        periodA: a.targetPct,
        periodB: b.targetPct,
      ),
    ];

    return PeriodComparisonResult(
      preset: preset,
      rangeA: rangeA,
      rangeB: rangeB,
      rows: rows,
    );
  }

  Future<_Bucket> _metricsForRange(
    Database db,
    PeriodDateRange range,
  ) async {
    final from = range.fromKey;
    final to = range.toKey;

    final sales = await _scalar(
      db,
      '''
      SELECT COALESCE(SUM(total_amount), 0)
      FROM invoices
      WHERE date(COALESCE(invoice_date, created_at)) >= date(?)
        AND date(COALESCE(invoice_date, created_at)) <= date(?)
        AND COALESCE(status, '') != 'Cancelled'
      ''',
      [from, to],
    );
    final orders = await _scalar(
      db,
      '''
      SELECT COALESCE(COUNT(*), 0)
      FROM orders
      WHERE date(COALESCE(order_date, created_at)) >= date(?)
        AND date(COALESCE(order_date, created_at)) <= date(?)
        AND COALESCE(status, '') != 'Cancelled'
      ''',
      [from, to],
    );
    final collection = await _scalar(
      db,
      '''
      SELECT COALESCE(SUM(amount), 0)
      FROM collections
      WHERE date(COALESCE(collection_date, created_at)) >= date(?)
        AND date(COALESCE(collection_date, created_at)) <= date(?)
        AND COALESCE(status, '') != 'Cancelled'
      ''',
      [from, to],
    );
    final visits = await _scalar(
      db,
      '''
      SELECT COALESCE(COUNT(*), 0)
      FROM visits
      WHERE date(COALESCE(check_in_at, created_at)) >= date(?)
        AND date(COALESCE(check_in_at, created_at)) <= date(?)
      ''',
      [from, to],
    );
    final targetPct = await _targetAchievementPct(
      db,
      fromKey: from,
      salesInPeriod: sales,
    );

    return _Bucket(
      sales: sales,
      orderCount: orders.toInt(),
      collection: collection,
      visitCount: visits.toInt(),
      targetPct: targetPct,
    );
  }

  /// Dönem etiketli targets varsa achieved/target; yoksa satış ÷ toplam hedef.
  Future<double> _targetAchievementPct(
    Database db, {
    required String fromKey,
    required double salesInPeriod,
  }) async {
    final ym = fromKey.length >= 7 ? fromKey.substring(0, 7) : fromKey;
    final ymCompact = ym.replaceAll('-', '');

    final tagged = await _safeQuery(
      db,
      '''
      SELECT
        COALESCE(SUM(achieved_amount), 0) AS achieved,
        COALESCE(SUM(target_amount), 0) AS target
      FROM targets
      WHERE COALESCE(period, '') LIKE '%' || ? || '%'
         OR COALESCE(period, '') LIKE '%' || ? || '%'
      ''',
      [ym, ymCompact],
    );
    if (tagged.isNotEmpty) {
      final target = _asDouble(tagged.first['target']);
      if (target > 0) {
        return (_asDouble(tagged.first['achieved']) * 100.0) / target;
      }
    }

    final allTargets = await _safeQuery(
      db,
      'SELECT COALESCE(SUM(target_amount), 0) AS target FROM targets',
    );
    final target = allTargets.isEmpty
        ? 0.0
        : _asDouble(allTargets.first['target']);
    if (target <= 0) return 0;
    return (salesInPeriod * 100.0) / target;
  }

  Future<double> _scalar(
    Database db,
    String sql,
    List<Object?> args,
  ) async {
    final rows = await _safeQuery(db, sql, args);
    if (rows.isEmpty) return 0;
    return _asDouble(rows.first.values.first);
  }

  Future<List<Map<String, Object?>>> _safeQuery(
    Database db,
    String sql, [
    List<Object?>? args,
  ]) async {
    try {
      return await db.rawQuery(sql, args);
    } catch (_) {
      return const <Map<String, Object?>>[];
    }
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _Bucket {
  final double sales;
  final int orderCount;
  final double collection;
  final int visitCount;
  final double targetPct;

  const _Bucket({
    required this.sales,
    required this.orderCount,
    required this.collection,
    required this.visitCount,
    required this.targetPct,
  });
}
