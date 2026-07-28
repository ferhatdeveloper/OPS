// Dosya Adı: demand_forecast_models.dart
// Açıklama: Talep tahmin / tüketim bitiş modelleri (deterministic)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template order_consumption_event}
/// Tek sipariş / fatura satırı tüketim olayı.
///
/// Kullanım örneği:
/// ```dart
/// final e = OrderConsumptionEvent(
///   date: DateTime(2026, 1, 1),
///   quantity: 10,
/// );
/// ```
/// {@endtemplate}
class OrderConsumptionEvent {
  /// [date]: Sipariş / fatura tarihi
  final DateTime date;

  /// [quantity]: Miktar
  final double quantity;

  /// {@macro order_consumption_event}
  const OrderConsumptionEvent({
    required this.date,
    required this.quantity,
  });
}

/// {@template demand_forecast_stats}
/// Ortalama aralık / miktar / trend / tahmini bitiş.
/// {@endtemplate}
class DemandForecastStats {
  /// [orderCount]: Geçmiş olay sayısı
  final int orderCount;

  /// [avgIntervalDays]: Ortalama sipariş aralığı (gün)
  final double avgIntervalDays;

  /// [avgQuantity]: Ortalama miktar
  final double avgQuantity;

  /// [trendSlope]: Son yarı − ilk yarı / ilk yarı (0 = düz)
  final double trendSlope;

  /// [lastOrderDate]: Son sipariş
  final DateTime? lastOrderDate;

  /// [lastQuantity]: Son miktar
  final double lastQuantity;

  /// [estimatedDepletionDate]: Tahmini bitiş
  final DateTime? estimatedDepletionDate;

  /// {@macro demand_forecast_stats}
  const DemandForecastStats({
    required this.orderCount,
    required this.avgIntervalDays,
    required this.avgQuantity,
    required this.trendSlope,
    this.lastOrderDate,
    this.lastQuantity = 0,
    this.estimatedDepletionDate,
  });

  /// Yetersiz veri
  static const DemandForecastStats empty = DemandForecastStats(
    orderCount: 0,
    avgIntervalDays: 0,
    avgQuantity: 0,
    trendSlope: 0,
  );

  /// [asOf] itibarıyla bitişe kalan gün (negatif = geçmiş)
  int? daysUntilDepletion({DateTime? asOf}) {
    final end = estimatedDepletionDate;
    if (end == null) return null;
    final now = asOf ?? DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(end.year, end.month, end.day);
    return b.difference(a).inDays;
  }
}

/// {@template customer_product_forecast}
/// Cari + ürün bazlı forecast satırı (UI / uyarı).
/// {@endtemplate}
class CustomerProductForecast {
  /// [customerId]: Cari id
  final String customerId;

  /// [customerCode]: Cari kod (PII minimize)
  final String customerCode;

  /// [customerName]: Ünvan (yerel liste; AI’ya gönderilmez)
  final String customerName;

  /// [productId]: Ürün id
  final String productId;

  /// [productCode]: Ürün kod
  final String productCode;

  /// [productName]: Ürün ad
  final String productName;

  /// [category]: Ürün grubu / kategori
  final String category;

  /// [stats]: Hesaplanan istatistik
  final DemandForecastStats stats;

  /// {@macro customer_product_forecast}
  const CustomerProductForecast({
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.category,
    required this.stats,
  });

  /// Uyarı eşiği içinde mi?
  bool isWithinAlertWindow({
    required int thresholdDays,
    DateTime? asOf,
  }) {
    final days = stats.daysUntilDepletion(asOf: asOf);
    if (days == null) return false;
    return days <= thresholdDays;
  }

  /// Son miktar ortalamadan %50+ sapma (dens rozet)
  bool get isQuantityAnomaly {
    if (stats.orderCount < 2 || stats.avgQuantity <= 0) return false;
    final deviation =
        (stats.lastQuantity - stats.avgQuantity).abs() / stats.avgQuantity;
    return deviation >= 0.5;
  }
}

/// {@template category_demand_summary}
/// Kategori / ürün grubu özeti.
/// {@endtemplate}
class CategoryDemandSummary {
  /// [category]: Grup adı
  final String category;

  /// [productCount]: Ürün sayısı
  final int productCount;

  /// [avgIntervalDays]: Ortalama aralık
  final double avgIntervalDays;

  /// [avgQuantity]: Ortalama miktar
  final double avgQuantity;

  /// [alertCount]: Eşik altı uyarı sayısı
  final int alertCount;

  /// {@macro category_demand_summary}
  const CategoryDemandSummary({
    required this.category,
    required this.productCount,
    required this.avgIntervalDays,
    required this.avgQuantity,
    required this.alertCount,
  });
}

/// {@template ai_insight_alert}
/// In-app dens uyarı satırı.
/// {@endtemplate}
class AiInsightAlert {
  /// [id]: Stabil id
  final String id;

  /// [kind]: depletion | stock_low | visit_suggest | supply
  final String kind;

  /// [titleKey]: l10n başlık
  final String titleKey;

  /// [bodyKey]: l10n gövde
  final String bodyKey;

  /// [params]: Çeviri parametreleri
  final Map<String, String> params;

  /// [priority]: 0 yüksek
  final int priority;

  /// [route]: Opsiyonel hedef route
  final String? route;

  /// [customerId]: Filtre / navigasyon
  final String? customerId;

  /// [productId]: Filtre
  final String? productId;

  /// [daysUntil]: Bitişe gün
  final int? daysUntil;

  /// {@macro ai_insight_alert}
  const AiInsightAlert({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.bodyKey,
    this.params = const {},
    this.priority = 50,
    this.route,
    this.customerId,
    this.productId,
    this.daysUntil,
  });
}
