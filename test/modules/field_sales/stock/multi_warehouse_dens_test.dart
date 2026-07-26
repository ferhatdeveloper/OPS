// Dosya Adı: multi_warehouse_dens_test.dart
// Açıklama: Çoklu ambar dens ekranı — seed satır + l10n smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/warehouse_dens_row.dart';
import 'package:exfin_ops/modules/field_sales/stock/view/multi_warehouse_screen.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('seed dens satırları Kod/Ad/Tip ile görünür', (tester) async {
    await pumpStubWithL10n(
      tester,
      MultiWarehouseScreen(rows: WarehouseDensRow.fromSeed()),
    );
    await tester.pump();

    expectStubL10nSmoke(tester, 'field_sales.stubs.multi_warehouse');
    expect(find.text('MRK'), findsOneWidget);
    expect(find.text('ARC'), findsOneWidget);
    expect(find.text('IAD'), findsOneWidget);
    expect(find.text('Merkez Depo'), findsWidgets);
    expect(find.textContaining('3 ambar'), findsOneWidget);
  });

  test('applyDensCacheFromMaps densCount eşler', () {
    final n = MultiWarehouseScreen.applyDensCacheFromMaps(
      WarehouseDensRow.fromSeed()
          .map(
            (r) => <String, dynamic>{
              'id': r.id,
              'code': r.code,
              'name': r.name,
              'type': r.type,
              'is_active': 1,
            },
          )
          .toList(),
    );
    expect(n, 3);
    expect(MultiWarehouseScreen.densCount, 3);
    expect(MultiWarehouseScreen.densRows.length, 3);
  });
}
