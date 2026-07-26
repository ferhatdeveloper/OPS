// Dosya Adı: delivery_hold_entry_test.dart
// Açıklama: Sipariş / irsaliye → DeliveryHoldStore.add köprü testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/delivery/model/delivery_hold_record.dart';
import 'package:exfin_ops/modules/field_sales/delivery/viewmodel/delivery_hold_entry.dart';
import 'package:exfin_ops/modules/field_sales/delivery/viewmodel/delivery_hold_store.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/waybills/model/waybill_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeliveryHoldEntry', () {
    test('addFromOrder → store.add satış kaydı yazar', () async {
      const entry = DeliveryHoldEntry();
      final heldAt = DateTime(2026, 7, 26, 12, 0);
      final record = await entry.addFromOrder(
        orderId: 'ord-abc-123456',
        orderType: OrderType.sales,
        customerCode: 'C001',
        customerName: 'Demo Cari',
        note: 'siparis bekle',
        heldAt: heldAt,
      );

      expect(record.id, 'dh-ord-ord-abc-123456');
      expect(record.docNo, startsWith('SIP-'));
      expect(record.side, DeliveryHoldDocSide.sales);
      expect(record.customerCode, 'C001');
      expect(record.heldAt, heldAt);

      final loaded = await const DeliveryHoldStore().loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, record.id);
      expect(loaded.first.note, 'siparis bekle');
    });

    test('addFromOrder alış → purchase side', () async {
      const entry = DeliveryHoldEntry();
      final record = await entry.addFromOrder(
        orderId: 'p1',
        orderType: OrderType.purchase,
        customerCode: 'S1',
        customerName: 'Tedarikçi',
        heldAt: DateTime(2026, 7, 1),
      );
      expect(record.side, DeliveryHoldDocSide.purchase);
      expect(record.docNo, startsWith('ALS-'));
    });

    test('addFromWaybill → store.add irsaliye kaydı yazar', () async {
      const entry = DeliveryHoldEntry();
      final heldAt = DateTime(2026, 7, 26, 13, 0);
      final record = await entry.addFromWaybill(
        holdId: 'wb-uuid-789012',
        waybillType: WaybillType.wholesale,
        customerCode: 'C009',
        customerName: 'İrsaliye Cari',
        heldAt: heldAt,
      );

      expect(record.id, 'dh-wb-wb-uuid-789012');
      expect(record.docNo, startsWith('IRS-'));
      expect(record.side, DeliveryHoldDocSide.sales);

      final loaded = await const DeliveryHoldStore().loadAll();
      expect(loaded.any((e) => e.id == record.id), isTrue);
    });

    test('addFromWaybill purchase → IRA prefix', () async {
      const entry = DeliveryHoldEntry();
      final record = await entry.addFromWaybill(
        holdId: 'x1',
        waybillType: WaybillType.purchase,
        customerCode: 'T1',
        customerName: 'Alım',
        heldAt: DateTime(2026, 7, 2),
      );
      expect(record.side, DeliveryHoldDocSide.purchase);
      expect(record.docNo, startsWith('IRA-'));
    });
  });
}
