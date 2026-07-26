// Dosya Adı: partial_delivery_dens_form_test.dart
// Açıklama: Kısmi teslimat dens form Ambar/Tarih/Satırlar/Kaydet smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exfin_ops/modules/field_sales/delivery/view/partial_delivery_screen.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('MBT kısmi teslimat dens form', () {
    testWidgets('Ambar, Tarih, Satırlar ve Kaydet görünür', (tester) async {
      await pumpStubWithL10n(
        tester,
        const ProviderScope(child: PartialDeliveryScreen()),
      );
      expect(find.text('Kısmi Teslimat'), findsOneWidget);
      expect(find.text('İşyeri'), findsWidgets);
      expect(find.text('Fabrika'), findsWidgets);
      expect(find.text('Ambar'), findsWidgets);
      expect(find.text('Tarih'), findsWidgets);
      expect(find.text('Satırlar'), findsOneWidget);
      expect(find.text('Henüz satır eklenmedi.'), findsOneWidget);
      expect(find.text('Araç Depo'), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
    });
  });
}
