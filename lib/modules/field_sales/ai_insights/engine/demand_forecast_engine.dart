// Dosya Adı: demand_forecast_engine.dart
// Açıklama: Deterministik talep / tüketim aralığı ve bitiş tarihi motoru
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../../../core/ai/ai_prompt_sanitizer.dart';
import '../model/demand_forecast_models.dart';

/// {@template demand_forecast_engine}
/// Sipariş geçmişinden ortalama aralık, miktar, trend ve tahmini bitiş.
///
/// Varsayım: plasiyer siparişi ürün bitimine yakın verir →
/// ortalama sipariş aralığı ≈ tüketim süresi.
///
/// Kullanım örneği:
/// ```dart
/// final stats = DemandForecastEngine.compute(events);
/// print(stats.estimatedDepletionDate);
/// ```
/// {@endtemplate}
class DemandForecastEngine {
  DemandForecastEngine._();

  /// Minimum olay sayısı (aralık için ≥2)
  static const int minEventsForInterval = 2;

  /// Varsayılan uyarı eşiği (gün)
  static const int defaultAlertThresholdDays = 7;

  /// {@template demand_forecast_engine_compute}
  /// Olay listesinden istatistik üretir.
  ///
  /// Parametreler:
  /// - [events]: Tarih + miktar
  /// - [asOf]: Referans gün (test)
  /// - [fallbackIntervalDays]: Tek olayda varsayılan aralık
  ///
  /// Dönüş değeri:
  /// - [DemandForecastStats]
  /// {@endtemplate}
  static DemandForecastStats compute(
    List<OrderConsumptionEvent> events, {
    DateTime? asOf,
    double fallbackIntervalDays = 30,
  }) {
    if (events.isEmpty) return DemandForecastStats.empty;

    final sorted = List<OrderConsumptionEvent>.from(events)
      ..sort((a, b) => a.date.compareTo(b.date));

    final qtySum = sorted.fold<double>(0, (s, e) => s + e.quantity);
    final avgQty = qtySum / sorted.length;
    final last = sorted.last;

    double avgInterval = fallbackIntervalDays;
    if (sorted.length >= minEventsForInterval) {
      final gaps = <double>[];
      for (var i = 1; i < sorted.length; i++) {
        final days = sorted[i]
            .date
            .difference(sorted[i - 1].date)
            .inDays
            .toDouble();
        if (days > 0) gaps.add(days);
      }
      if (gaps.isNotEmpty) {
        avgInterval = gaps.reduce((a, b) => a + b) / gaps.length;
      }
    }

    final trend = _trendSlope(sorted);
    final depletion = last.date.add(
      Duration(days: avgInterval.round().clamp(1, 3650)),
    );

    return DemandForecastStats(
      orderCount: sorted.length,
      avgIntervalDays: avgInterval,
      avgQuantity: avgQty,
      trendSlope: trend,
      lastOrderDate: last.date,
      lastQuantity: last.quantity,
      estimatedDepletionDate: depletion,
    );
  }

  /// Son yarı ortalama − ilk yarı / ilk yarı.
  static double _trendSlope(List<OrderConsumptionEvent> sorted) {
    if (sorted.length < 4) return 0;
    final mid = sorted.length ~/ 2;
    final first = sorted.sublist(0, mid);
    final second = sorted.sublist(mid);
    final a = first.fold<double>(0, (s, e) => s + e.quantity) / first.length;
    final b = second.fold<double>(0, (s, e) => s + e.quantity) / second.length;
    if (a.abs() < 0.0001) return b > a ? 1 : 0;
    return (b - a) / a;
  }

  /// {@template demand_forecast_engine_suggested_qty}
  /// Önerilen sipariş miktarı (trend ile ayarlanmış ortalama).
  /// Otomatik sipariş kesmez — yalnızca öneri.
  /// {@endtemplate}
  static double suggestedQty(DemandForecastStats stats) {
    if (stats.orderCount == 0) return 0;
    final factor = (1 + (stats.trendSlope.clamp(-0.5, 0.5))).clamp(0.5, 1.5);
    return (stats.avgQuantity * factor);
  }

  /// Varsayılan anomali eşiği (ortalamadan sapma oranı)
  static const double defaultAnomalyDeviationRatio = 0.5;

  /// {@template demand_forecast_engine_is_quantity_anomaly}
  /// Son miktar ortalamadan [ratio] (%50 varsayılan) veya daha fazla sapıyorsa.
  /// AI zorunlu değil — dens satır rozeti için.
  /// {@endtemplate}
  static bool isQuantityAnomaly(
    DemandForecastStats stats, {
    double ratio = defaultAnomalyDeviationRatio,
  }) {
    if (stats.orderCount < 2) return false;
    if (stats.avgQuantity <= 0) return false;
    final deviation =
        (stats.lastQuantity - stats.avgQuantity).abs() / stats.avgQuantity;
    return deviation >= ratio;
  }

  /// {@template demand_forecast_engine_summarize_categories}
  /// Forecast satırlarını kategoriye toplar.
  /// {@endtemplate}
  static List<CategoryDemandSummary> summarizeCategories(
    List<CustomerProductForecast> rows, {
    int thresholdDays = defaultAlertThresholdDays,
    DateTime? asOf,
  }) {
    final map = <String, List<CustomerProductForecast>>{};
    for (final r in rows) {
      final key = r.category.trim().isEmpty ? '_' : r.category.trim();
      (map[key] ??= []).add(r);
    }
    final out = <CategoryDemandSummary>[];
    for (final entry in map.entries) {
      final list = entry.value;
      final avgInt = list.fold<double>(
            0,
            (s, e) => s + e.stats.avgIntervalDays,
          ) /
          list.length;
      final avgQty = list.fold<double>(
            0,
            (s, e) => s + e.stats.avgQuantity,
          ) /
          list.length;
      final alerts = list
          .where(
            (e) => e.isWithinAlertWindow(
              thresholdDays: thresholdDays,
              asOf: asOf,
            ),
          )
          .length;
      out.add(
        CategoryDemandSummary(
          category: entry.key == '_' ? '' : entry.key,
          productCount: list.length,
          avgIntervalDays: avgInt,
          avgQuantity: avgQty,
          alertCount: alerts,
        ),
      );
    }
    out.sort((a, b) => b.alertCount.compareTo(a.alertCount));
    return out;
  }

  /// {@template demand_forecast_engine_build_alerts}
  /// Eşik içi satırlardan dens uyarı listesi.
  /// {@endtemplate}
  static List<AiInsightAlert> buildDepletionAlerts(
    List<CustomerProductForecast> rows, {
    int thresholdDays = defaultAlertThresholdDays,
    DateTime? asOf,
    String insightsRoute = '/field-sales/ai-insights',
  }) {
    final alerts = <AiInsightAlert>[];
    for (final r in rows) {
      if (!r.isWithinAlertWindow(thresholdDays: thresholdDays, asOf: asOf)) {
        continue;
      }
      final days = r.stats.daysUntilDepletion(asOf: asOf) ?? thresholdDays;
      alerts.add(
        AiInsightAlert(
          id: 'deplete_${r.customerId}_${r.productId}',
          kind: 'depletion',
          titleKey: 'field_sales.ai_insights.alert_depletion_title',
          bodyKey: 'field_sales.ai_insights.alert_depletion_body',
          params: {
            'customer': r.customerCode.isNotEmpty
                ? r.customerCode
                : r.customerName,
            'product': r.productCode.isNotEmpty
                ? r.productCode
                : r.productName,
            'days': '$days',
          },
          priority: days <= 0 ? 0 : days,
          route: insightsRoute,
          customerId: r.customerId,
          productId: r.productId,
          daysUntil: days,
        ),
      );
    }
    alerts.sort((a, b) => a.priority.compareTo(b.priority));
    return alerts;
  }

  /// {@template demand_forecast_engine_ai_prompt_payload}
  /// AI için PII minimize özet (kod + gün + miktar; ünvan yok).
  /// {@endtemplate}
  static String buildAiPromptPayload(
    List<CustomerProductForecast> alertRows, {
    int maxRows = 20,
  }) {
    final buf = StringBuffer();
    buf.writeln('demand_alerts:');
    final take = alertRows.take(maxRows);
    for (final r in take) {
      final days = r.stats.daysUntilDepletion() ?? -1;
      final code = r.customerCode.isEmpty ? r.customerId : r.customerCode;
      final prod = r.productCode.isEmpty ? r.productId : r.productCode;
      // Ünvan / telefon asla eklenmez; kodlar sanitize edilir
      buf.writeln(
        '- c=${AiPromptSanitizer.sanitize(code)}'
        ' p=${AiPromptSanitizer.sanitize(prod)}'
        ' cat=${AiPromptSanitizer.sanitize(r.category)}'
        ' days=$days'
        ' avgQty=${r.stats.avgQuantity.toStringAsFixed(1)}'
        ' avgDays=${r.stats.avgIntervalDays.toStringAsFixed(1)}'
        ' trend=${r.stats.trendSlope.toStringAsFixed(2)}',
      );
    }
    return buf.toString();
  }
}
