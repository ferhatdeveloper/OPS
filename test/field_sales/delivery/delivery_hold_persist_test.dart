// Dosya Adı: delivery_hold_persist_test.dart
// Açıklama: Beklemeye alınan dens kuyruk + prefs satır smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:exfin_ops/modules/field_sales/delivery/model/delivery_hold_record.dart';
import 'package:exfin_ops/modules/field_sales/delivery/view/delivery_hold_screen.dart';
import 'package:exfin_ops/modules/field_sales/delivery/viewmodel/delivery_hold_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('prefs kaydı dens satır ve adet gösterir', (tester) async {
    final record = DeliveryHoldRecord(
      id: 'dh-ui-1',
      docNo: 'TSL-042',
      customerCode: 'C042',
      customerName: 'Hold Cari',
      side: DeliveryHoldDocSide.sales,
      heldAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({
      DeliveryHoldStore.prefsKey: jsonEncode([record.toJson()]),
    });

    await pumpStubWithL10n(tester, const DeliveryHoldScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(tester, 'field_sales.stubs.delivery_hold');
    expect(find.text('TSL-042'), findsOneWidget);
    expect(find.text('1 Adet'), findsOneWidget);
  });
}
