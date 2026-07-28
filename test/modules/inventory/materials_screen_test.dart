// Dosya Adı: materials_screen_test.dart
// Açıklama: Malzeme dens kart + uzun basma işlem sheet smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/inventory/view/materials_screen.dart';

import '../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('dens kart ve uzun basma işlemleri görünür', (tester) async {
    await pumpStubWithL10n(
      tester,
      const ProviderScope(child: MaterialsScreen()),
    );

    // MaterialNotifier sample yükleme (~800ms)
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('SİGARA'), findsOneWidget);

    await tester.longPress(find.text('SİGARA'));
    await tester.pumpAndSettle();

    expect(find.text('İşlemler'), findsOneWidget);
    expect(find.text('Detay'), findsOneWidget);
    expect(find.text('Fiyat Gör'), findsOneWidget);
    expect(find.text('Barkod Ekle'), findsOneWidget);
  });
}
