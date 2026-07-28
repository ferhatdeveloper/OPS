// Dosya Adı: company_general_overview_test.dart
// Açıklama: Firma Genel Görünüm model — Kar % hesabı ve sample
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/model/company_general_overview.dart';

void main() {
  test('Kar % = (Satışlar − Maliyet) / Satışlar', () {
    const o = CompanyGeneralOverview(
      salesExVat: 1000,
      salesCost: 720,
    );
    expect(o.salesProfitAmount, 280);
    expect(o.salesProfitPct, closeTo(28, 0.01));
  });

  test('sample: 12 aylık çift + isSample', () {
    final s = CompanyGeneralOverview.sample;
    expect(s.isSample, isTrue);
    expect(s.monthlyPairs, hasLength(12));
    expect(s.designFileName, 'GenelAnaliz.repx');
    expect(s.salesProfitPct, greaterThan(0));
  });
}
