// Dosya Adı: period_comparison_models.dart
// Açıklama: Dönem karşılaştırma preset / metrik / sonuç modelleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template period_compare_preset}
/// Dens dönem karşılaştırma ön ayarları.
///
/// Kullanım örneği:
/// ```dart
/// final p = PeriodComparePreset.thisMonthVsLast;
/// ```
/// {@endtemplate}
enum PeriodComparePreset {
  /// Bu ay × geçen ay
  thisMonthVsLast,

  /// Bu hafta × geçen hafta
  thisWeekVsLast,

  /// Bu ay × geçen yıl aynı ay (YoY)
  yearOverYear,

  /// Kullanıcı seçimli iki aralık
  custom,
}

/// {@template period_metric_kind}
/// Karşılaştırılan yerel SQLite metrikleri.
/// {@endtemplate}
enum PeriodMetricKind {
  /// Fatura satış tutarı
  sales,

  /// Sipariş adedi
  orderCount,

  /// Tahsilat tutarı
  collection,

  /// Ziyaret adedi
  visit,

  /// Hedef gerçekleşme % (targets)
  targetAchievement,
}

/// {@template period_date_range}
/// Kapalı tarih aralığı (gün bazlı).
///
/// Kullanım örneği:
/// ```dart
/// final r = PeriodDateRange(
///   from: DateTime(2026, 7, 1),
///   to: DateTime(2026, 7, 28),
/// );
/// ```
/// {@endtemplate}
class PeriodDateRange {
  /// [from]: Başlangıç (dahil)
  final DateTime from;

  /// [to]: Bitiş (dahil)
  final DateTime to;

  /// {@macro period_date_range}
  const PeriodDateRange({required this.from, required this.to});

  /// Gün sayısı (dahil).
  int get dayCount {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays.abs() + 1;
  }

  /// `yyyy-MM-dd` başlangıç.
  String get fromKey => _key(from);

  /// `yyyy-MM-dd` bitiş.
  String get toKey => _key(to);

  static String _key(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

/// {@template period_metric_row}
/// Tek metrik için A/B değer + fark / %.
///
/// Kullanım örneği:
/// ```dart
/// final row = PeriodMetricRow(
///   kind: PeriodMetricKind.sales,
///   periodA: 100,
///   periodB: 120,
/// );
/// ```
/// {@endtemplate}
class PeriodMetricRow {
  /// [kind]: Metrik türü
  final PeriodMetricKind kind;

  /// [periodA]: Önceki / baz dönem değeri
  final double periodA;

  /// [periodB]: Güncel / karşılaştırılan dönem değeri
  final double periodB;

  /// {@macro period_metric_row}
  const PeriodMetricRow({
    required this.kind,
    required this.periodA,
    required this.periodB,
  });

  /// Mutlak fark (B − A).
  double get diff => periodB - periodA;

  /// Yüzde değişim; A=0 → B>0 ise 100, ikisi 0 ise 0.
  double get pctChange {
    if (periodA == 0) {
      return periodB == 0 ? 0 : 100;
    }
    return (diff / periodA) * 100;
  }

  /// AI / satır özeti için string map.
  Map<String, String> toInsightMap(String title) {
    return {
      'code': kind.name,
      'title': title,
      'previous': periodA.toStringAsFixed(2),
      'current': periodB.toStringAsFixed(2),
      'diff': diff.toStringAsFixed(2),
      'growth': pctChange.toStringAsFixed(2),
    };
  }
}

/// {@template period_comparison_result}
/// İki dönem + metrik satırları.
/// {@endtemplate}
class PeriodComparisonResult {
  /// [preset]: Seçili ön ayar
  final PeriodComparePreset preset;

  /// [rangeA]: Dönem A (baz)
  final PeriodDateRange rangeA;

  /// [rangeB]: Dönem B (karşılaştırılan)
  final PeriodDateRange rangeB;

  /// [rows]: Metrik satırları
  final List<PeriodMetricRow> rows;

  /// {@macro period_comparison_result}
  const PeriodComparisonResult({
    required this.preset,
    required this.rangeA,
    required this.rangeB,
    required this.rows,
  });

  /// Boş sonuç.
  static PeriodComparisonResult empty({
    PeriodComparePreset preset = PeriodComparePreset.thisMonthVsLast,
    PeriodDateRange? rangeA,
    PeriodDateRange? rangeB,
  }) {
    final now = DateTime.now();
    final fallback = PeriodDateRange(from: now, to: now);
    return PeriodComparisonResult(
      preset: preset,
      rangeA: rangeA ?? fallback,
      rangeB: rangeB ?? fallback,
      rows: const [],
    );
  }
}

/// {@template period_compare_range_resolver}
/// Preset → A/B tarih aralıkları.
///
/// Kullanım örneği:
/// ```dart
/// final pair = PeriodCompareRangeResolver.resolve(
///   PeriodComparePreset.thisMonthVsLast,
/// );
/// ```
/// {@endtemplate}
class PeriodCompareRangeResolver {
  /// {@macro period_compare_range_resolver}
  const PeriodCompareRangeResolver._();

  /// Preset veya özel aralıkları çözer.
  ///
  /// Parametreler:
  /// - [preset]: Ön ayar
  /// - [anchor]: Referans gün (varsayılan bugün)
  /// - [customA] / [customB]: custom preset için zorunlu
  ///
  /// Dönüş değeri:
  /// - `(PeriodDateRange, PeriodDateRange)`: (A, B)
  static (PeriodDateRange, PeriodDateRange) resolve(
    PeriodComparePreset preset, {
    DateTime? anchor,
    PeriodDateRange? customA,
    PeriodDateRange? customB,
  }) {
    final now = _dateOnly(anchor ?? DateTime.now());
    switch (preset) {
      case PeriodComparePreset.thisMonthVsLast:
        final bFrom = DateTime(now.year, now.month, 1);
        final bTo = now;
        final aTo = bFrom.subtract(const Duration(days: 1));
        final aFrom = DateTime(aTo.year, aTo.month, 1);
        return (
          PeriodDateRange(from: aFrom, to: aTo),
          PeriodDateRange(from: bFrom, to: bTo),
        );
      case PeriodComparePreset.thisWeekVsLast:
        final weekday = now.weekday;
        final bFrom = now.subtract(Duration(days: weekday - 1));
        final bTo = now;
        final aTo = bFrom.subtract(const Duration(days: 1));
        final aFrom = aTo.subtract(const Duration(days: 6));
        return (
          PeriodDateRange(from: aFrom, to: aTo),
          PeriodDateRange(from: bFrom, to: bTo),
        );
      case PeriodComparePreset.yearOverYear:
        final bFrom = DateTime(now.year, now.month, 1);
        final bTo = now;
        final aFrom = DateTime(now.year - 1, now.month, 1);
        final lastDayPrev = DateTime(now.year - 1, now.month + 1, 0).day;
        final aDay = now.day.clamp(1, lastDayPrev);
        final aTo = DateTime(now.year - 1, now.month, aDay);
        return (
          PeriodDateRange(from: aFrom, to: aTo),
          PeriodDateRange(from: bFrom, to: bTo),
        );
      case PeriodComparePreset.custom:
        final fallback = PeriodDateRange(from: now, to: now);
        return (customA ?? fallback, customB ?? fallback);
    }
  }

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
