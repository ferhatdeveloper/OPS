// Dosya Adı: discount_approval_store_test.dart
// Açıklama: İskonto onay SharedPreferences kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/orders/model/discount_approval_record.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/discount_approval_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DiscountApprovalStore', () {
    test('boş prefs yüklenince boş liste döner', () async {
      const store = DiscountApprovalStore();
      final list = await store.loadAll();
      expect(list, isEmpty);
    });

    test('add / loadAll / remove turu kalıcıdır', () async {
      const store = DiscountApprovalStore();
      final requestedAt = DateTime(2026, 7, 26, 10, 30);
      await store.add(
        DiscountApprovalRecord(
          id: 'da-1',
          docNo: 'SIP-001',
          customerCode: 'C001',
          customerName: 'Demo',
          discountPercent: 12.5,
          amount: 2500,
          side: DiscountApprovalDocSide.sales,
          requestedAt: requestedAt,
          note: 'not',
        ),
      );

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'da-1');
      expect(loaded.first.docNo, 'SIP-001');
      expect(loaded.first.discountPercent, 12.5);
      expect(loaded.first.side, DiscountApprovalDocSide.sales);
      expect(loaded.first.requestedAt, requestedAt);

      await store.remove('da-1');
      expect(await store.loadAll(), isEmpty);
    });

    test('aynı id ile add günceller', () async {
      const store = DiscountApprovalStore();
      await store.add(
        DiscountApprovalRecord(
          id: 'da-2',
          docNo: 'A',
          customerCode: 'C',
          customerName: 'N',
          discountPercent: 5,
          side: DiscountApprovalDocSide.purchase,
          requestedAt: DateTime(2026, 7, 1),
        ),
      );
      await store.add(
        DiscountApprovalRecord(
          id: 'da-2',
          docNo: 'B',
          customerCode: 'C',
          customerName: 'N',
          discountPercent: 20,
          side: DiscountApprovalDocSide.purchase,
          requestedAt: DateTime(2026, 7, 2),
        ),
      );
      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.docNo, 'B');
      expect(loaded.first.discountPercent, 20);
    });
  });
}
