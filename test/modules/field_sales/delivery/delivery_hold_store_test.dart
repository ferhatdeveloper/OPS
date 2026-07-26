// Dosya Adı: delivery_hold_store_test.dart
// Açıklama: Beklemeye alınan teslimat SharedPreferences kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/delivery/model/delivery_hold_record.dart';
import 'package:exfin_ops/modules/field_sales/delivery/viewmodel/delivery_hold_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeliveryHoldStore', () {
    test('boş prefs yüklenince boş liste döner', () async {
      const store = DeliveryHoldStore();
      final list = await store.loadAll();
      expect(list, isEmpty);
    });

    test('add / loadAll / remove turu kalıcıdır', () async {
      const store = DeliveryHoldStore();
      final heldAt = DateTime(2026, 7, 26, 10, 30);
      await store.add(
        DeliveryHoldRecord(
          id: 'dh-1',
          docNo: 'TSL-001',
          customerCode: 'C001',
          customerName: 'Demo',
          side: DeliveryHoldDocSide.sales,
          heldAt: heldAt,
          note: 'not',
        ),
      );

      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'dh-1');
      expect(loaded.first.docNo, 'TSL-001');
      expect(loaded.first.side, DeliveryHoldDocSide.sales);
      expect(loaded.first.heldAt, heldAt);

      await store.remove('dh-1');
      expect(await store.loadAll(), isEmpty);
    });

    test('aynı id ile add günceller', () async {
      const store = DeliveryHoldStore();
      await store.add(
        DeliveryHoldRecord(
          id: 'dh-2',
          docNo: 'A',
          customerCode: 'C',
          customerName: 'N',
          side: DeliveryHoldDocSide.purchase,
          heldAt: DateTime(2026, 7, 1),
        ),
      );
      await store.add(
        DeliveryHoldRecord(
          id: 'dh-2',
          docNo: 'B',
          customerCode: 'C',
          customerName: 'N',
          side: DeliveryHoldDocSide.purchase,
          heldAt: DateTime(2026, 7, 2),
        ),
      );
      final loaded = await store.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.docNo, 'B');
    });
  });
}
