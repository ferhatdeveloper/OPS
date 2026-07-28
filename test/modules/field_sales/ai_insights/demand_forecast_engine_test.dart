// Dosya Adı: demand_forecast_engine_test.dart
// Açıklama: Tüketim aralığı / bitiş tarihi hesap birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/ai_insights/engine/demand_forecast_engine.dart';
import 'package:exfin_ops/modules/field_sales/ai_insights/model/demand_forecast_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemandForecastEngine.compute', () {
    test('boş liste → empty', () {
      final s = DemandForecastEngine.compute(const []);
      expect(s.orderCount, 0);
      expect(s.estimatedDepletionDate, isNull);
    });

    test('tek olay → fallback aralık + bitiş', () {
      final last = DateTime(2026, 7, 1);
      final s = DemandForecastEngine.compute(
        [OrderConsumptionEvent(date: last, quantity: 12)],
        fallbackIntervalDays: 30,
      );
      expect(s.orderCount, 1);
      expect(s.avgQuantity, 12);
      expect(s.avgIntervalDays, 30);
      expect(s.lastOrderDate, last);
      expect(
        s.estimatedDepletionDate,
        DateTime(2026, 7, 31),
      );
    });

    test('üç olay → ortalama aralık 10 gün', () {
      final events = [
        OrderConsumptionEvent(date: DateTime(2026, 1, 1), quantity: 10),
        OrderConsumptionEvent(date: DateTime(2026, 1, 11), quantity: 20),
        OrderConsumptionEvent(date: DateTime(2026, 1, 21), quantity: 30),
      ];
      final s = DemandForecastEngine.compute(events);
      expect(s.avgIntervalDays, 10);
      expect(s.avgQuantity, 20);
      expect(s.estimatedDepletionDate, DateTime(2026, 1, 31));
    });

    test('daysUntilDepletion eşik kontrolü', () {
      final last = DateTime(2026, 7, 20);
      final s = DemandForecastEngine.compute(
        [
          OrderConsumptionEvent(date: DateTime(2026, 7, 1), quantity: 5),
          OrderConsumptionEvent(date: last, quantity: 5),
        ],
      );
      // aralık 19 gün → bitiş 8 Ağustos
      final asOf = DateTime(2026, 8, 1);
      final days = s.daysUntilDepletion(asOf: asOf);
      expect(days, isNotNull);
      expect(days! <= 7, isTrue);
    });

    test('trend artan miktar → pozitif slope', () {
      final events = [
        for (var i = 0; i < 6; i++)
          OrderConsumptionEvent(
            date: DateTime(2026, 1, 1 + i * 10),
            quantity: 5 + i * 5.0,
          ),
      ];
      final s = DemandForecastEngine.compute(events);
      expect(s.trendSlope > 0, isTrue);
      expect(
        DemandForecastEngine.suggestedQty(s) > s.avgQuantity,
        isTrue,
      );
    });
  });

  group('DemandForecastEngine alerts / categories', () {
    CustomerProductForecast row({
      required String id,
      required DateTime last,
      double interval = 10,
      String category = 'A',
    }) {
      final stats = DemandForecastStats(
        orderCount: 2,
        avgIntervalDays: interval,
        avgQuantity: 8,
        trendSlope: 0,
        lastOrderDate: last,
        lastQuantity: 8,
        estimatedDepletionDate: last.add(Duration(days: interval.round())),
      );
      return CustomerProductForecast(
        customerId: 'c$id',
        customerCode: 'C$id',
        customerName: 'Cust $id',
        productId: 'p$id',
        productCode: 'P$id',
        productName: 'Prod $id',
        category: category,
        stats: stats,
      );
    }

    test('eşik içi uyarı üretir', () {
      final asOf = DateTime(2026, 7, 28);
      final rows = [
        row(id: '1', last: DateTime(2026, 7, 20)), // bitiş 30 → 2 gün
        row(id: '2', last: DateTime(2026, 6, 1), interval: 10), // geçmiş
      ];
      final alerts = DemandForecastEngine.buildDepletionAlerts(
        rows,
        thresholdDays: 7,
        asOf: asOf,
      );
      expect(alerts.length, 2);
      expect(alerts.first.kind, 'depletion');
    });

    test('kategori özeti alertCount', () {
      final asOf = DateTime(2026, 7, 28);
      final rows = [
        row(id: '1', last: DateTime(2026, 7, 20), category: 'Süt'),
        row(id: '2', last: DateTime(2026, 1, 1), category: 'Süt'),
        row(id: '3', last: DateTime(2026, 7, 25), category: 'Et'),
      ];
      final cats = DemandForecastEngine.summarizeCategories(
        rows,
        thresholdDays: 14,
        asOf: asOf,
      );
      expect(cats.length, 2);
      final sut = cats.firstWhere((c) => c.category == 'Süt');
      expect(sut.productCount, 2);
    });

    test('AI payload PII: ünvan yok, kod var', () {
      final rows = [
        row(id: '9', last: DateTime(2026, 7, 20)),
      ];
      final payload = DemandForecastEngine.buildAiPromptPayload(rows);
      expect(payload.contains('Cust 9'), isFalse);
      expect(payload.contains('C9'), isTrue);
      expect(payload.contains('P9'), isTrue);
    });

    test('miktar anomali: ortalamadan %50+ sapma', () {
      final normal = DemandForecastStats(
        orderCount: 3,
        avgIntervalDays: 10,
        avgQuantity: 10,
        trendSlope: 0,
        lastQuantity: 11,
      );
      expect(DemandForecastEngine.isQuantityAnomaly(normal), isFalse);

      final anomaly = DemandForecastStats(
        orderCount: 3,
        avgIntervalDays: 10,
        avgQuantity: 10,
        trendSlope: 0,
        lastQuantity: 16,
      );
      expect(DemandForecastEngine.isQuantityAnomaly(anomaly), isTrue);

      final single = DemandForecastStats(
        orderCount: 1,
        avgIntervalDays: 10,
        avgQuantity: 10,
        trendSlope: 0,
        lastQuantity: 100,
      );
      expect(DemandForecastEngine.isQuantityAnomaly(single), isFalse);
    });
  });
}
