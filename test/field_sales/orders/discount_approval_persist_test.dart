// Dosya Adı: discount_approval_persist_test.dart
// Açıklama: İskonto onay dens kuyruk + prefs satır smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:exfin_ops/modules/field_sales/orders/model/discount_approval_record.dart';
import 'package:exfin_ops/modules/field_sales/orders/view/discount_approval_screen.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/discount_approval_store.dart';
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
    final record = DiscountApprovalRecord(
      id: 'da-ui-1',
      docNo: 'SIP-042',
      customerCode: 'C042',
      customerName: 'İskonto Cari',
      discountPercent: 15,
      amount: 4200,
      side: DiscountApprovalDocSide.sales,
      requestedAt: DateTime.now(),
    );
    SharedPreferences.setMockInitialValues({
      DiscountApprovalStore.prefsKey: jsonEncode([record.toJson()]),
    });

    await pumpStubWithL10n(tester, const DiscountApprovalScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(tester, 'field_sales.stubs.discount_approval');
    expect(find.text('SIP-042'), findsOneWidget);
    expect(find.text('1 Adet'), findsOneWidget);
  });
}
