// Dosya Adı: period_comparison_models_test.dart
// Açıklama: Dönem karşılaştırma preset / % değişim unit testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/manager/reports/model/period_comparison_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodCompareRangeResolver', () {
    test('thisMonthVsLast — Temmuz 28 → A Haziran, B Temmuz 1–28', () {
      final anchor = DateTime(2026, 7, 28);
      final (a, b) = PeriodCompareRangeResolver.resolve(
        PeriodComparePreset.thisMonthVsLast,
        anchor: anchor,
      );
      expect(a.from, DateTime(2026, 6, 1));
      expect(a.to, DateTime(2026, 6, 30));
      expect(b.from, DateTime(2026, 7, 1));
      expect(b.to, DateTime(2026, 7, 28));
    });

    test('yearOverYear — aynı ay geçen yıl', () {
      final anchor = DateTime(2026, 7, 28);
      final (a, b) = PeriodCompareRangeResolver.resolve(
        PeriodComparePreset.yearOverYear,
        anchor: anchor,
      );
      expect(a.from, DateTime(2025, 7, 1));
      expect(a.to, DateTime(2025, 7, 28));
      expect(b.from, DateTime(2026, 7, 1));
      expect(b.to, DateTime(2026, 7, 28));
    });

    test('thisWeekVsLast — Pazartesi başlangıç', () {
      // 2026-07-28 Salı
      final anchor = DateTime(2026, 7, 28);
      final (a, b) = PeriodCompareRangeResolver.resolve(
        PeriodComparePreset.thisWeekVsLast,
        anchor: anchor,
      );
      expect(b.from, DateTime(2026, 7, 27)); // Pazartesi
      expect(b.to, DateTime(2026, 7, 28));
      expect(a.to, DateTime(2026, 7, 26));
      expect(a.from, DateTime(2026, 7, 20));
    });

    test('custom — verilen aralıklar korunur', () {
      final customA = PeriodDateRange(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 31),
      );
      final customB = PeriodDateRange(
        from: DateTime(2026, 2, 1),
        to: DateTime(2026, 2, 28),
      );
      final (a, b) = PeriodCompareRangeResolver.resolve(
        PeriodComparePreset.custom,
        customA: customA,
        customB: customB,
      );
      expect(a.fromKey, '2026-01-01');
      expect(b.toKey, '2026-02-28');
    });
  });

  group('PeriodMetricRow', () {
    test('pctChange — artış / düşüş / sıfır baz', () {
      expect(
        const PeriodMetricRow(
          kind: PeriodMetricKind.sales,
          periodA: 100,
          periodB: 150,
        ).pctChange,
        50,
      );
      expect(
        const PeriodMetricRow(
          kind: PeriodMetricKind.sales,
          periodA: 100,
          periodB: 80,
        ).pctChange,
        -20,
      );
      expect(
        const PeriodMetricRow(
          kind: PeriodMetricKind.sales,
          periodA: 0,
          periodB: 10,
        ).pctChange,
        100,
      );
      expect(
        const PeriodMetricRow(
          kind: PeriodMetricKind.sales,
          periodA: 0,
          periodB: 0,
        ).pctChange,
        0,
      );
    });
  });
}
