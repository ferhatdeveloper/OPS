// Dosya Adı: company_general_overview_screen_test.dart
// Açıklama: Firma Genel Görünüm dens smoke — Liste + Grafik sekmeleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/view/company_general_overview_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('MBT dens: iki sütun · aylık · dizayn · Liste/Grafik', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(
      tester,
      const CompanyGeneralOverviewScreen(),
    );

    expect(find.text('FİRMA GENEL ANALİZ'), findsOneWidget);
    expect(find.text('Liste'), findsOneWidget);
    expect(find.text('Grafik'), findsOneWidget);
    expect(find.text('Firma Genel Görünüm'), findsOneWidget);
    expect(find.text('Borç / Alacak'), findsOneWidget);
    expect(find.text('Müşteri Borcu'), findsOneWidget);
    expect(find.text('Kendi'), findsOneWidget);
    expect(find.text('Kasa / Banka'), findsOneWidget);
    expect(find.text('Satışlar (KDV Hariç)'), findsOneWidget);
    expect(find.text('Maliyet'), findsWidgets);
    expect(find.text('Kar %'), findsWidgets);
    expect(find.text('Envanter'), findsOneWidget);
    expect(find.text('Envanter (+/-)'), findsOneWidget);
    expect(find.text('Demirbaş'), findsOneWidget);
    expect(find.text('Firma/Müşteri Çek Riski'), findsOneWidget);
    expect(find.text('Firma Çek Riski'), findsOneWidget);
    expect(find.text('Müşteri Çek Riski'), findsOneWidget);
    expect(find.text('Alışlar'), findsWidgets);
    expect(find.text('Giderler'), findsWidgets);
    expect(find.text('Firma Aylık Görünüm'), findsOneWidget);
    expect(find.textContaining('GenelAnaliz.repx'), findsOneWidget);
    expect(find.textContaining('Dizayn Dosya'), findsOneWidget);

    await tester.tap(find.text('Grafik'));
    await tester.pumpAndSettle();

    expect(find.text('Satış vs Maliyet'), findsOneWidget);
    expect(find.text('Aylık Kar'), findsOneWidget);
  });

  testWidgets(
    'Aylık: aynı ay N üstte N-1 altta; yatay kaydırma ay sütunu',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpStubWithL10n(
        tester,
        const CompanyGeneralOverviewScreen(),
      );

      final year = DateTime.now().year;
      final prev = year - 1;

      final janCol = find.byKey(ValueKey('month_col_1_$year'));
      expect(janCol, findsOneWidget);

      final janCurrent = find.text('Ocak $year');
      final janPrev = find.text('Ocak $prev');
      expect(janCurrent, findsOneWidget);
      expect(janPrev, findsOneWidget);

      // Aynı sütunda N üstte, N−1 altta
      final currentY = tester.getTopLeft(janCurrent).dy;
      final prevY = tester.getTopLeft(janPrev).dy;
      expect(currentY < prevY, isTrue);

      // Aynı ay kartları aynı x (bir sütun)
      final currentX = tester.getTopLeft(janCurrent).dx;
      final prevX = tester.getTopLeft(janPrev).dx;
      expect((currentX - prevX).abs() < 1.0, isTrue);

      // Yatay kaydırınca Ocak sütunu (her iki yıl) birlikte kayar
      final beforeX = tester.getTopLeft(janCol).dx;
      await tester.drag(janCol, const Offset(-180, 0));
      await tester.pumpAndSettle();
      final afterX = tester.getTopLeft(janCol).dx;
      expect(afterX < beforeX, isTrue);
      expect(find.byKey(ValueKey('month_col_1_$year')), findsOneWidget);
      expect(find.text('Ocak $year'), findsOneWidget);
      expect(find.text('Ocak $prev'), findsOneWidget);
    },
  );
}
