// Dosya Adı: waybill_customer_guard_test.dart
// Açıklama: İrsaliye girişinde boş cari + tip l10n anahtarı unit testi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybill_customer_selection_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybill_entry_screen.dart';

void main() {
  group('WaybillCustomerSelectionScreen.isValidCustomerId', () {
    test('boş veya whitespace için false döner', () {
      expect(
        WaybillCustomerSelectionScreen.isValidCustomerId(null),
        isFalse,
      );
      expect(
        WaybillCustomerSelectionScreen.isValidCustomerId(''),
        isFalse,
      );
      expect(
        WaybillCustomerSelectionScreen.isValidCustomerId('   '),
        isFalse,
      );
      expect(
        WaybillCustomerSelectionScreen.isValidCustomerId('cust-1'),
        isTrue,
      );
    });

    test('WaybillEntryScreen aynı guard mantığını paylaşır', () {
      expect(WaybillEntryScreen.isValidCustomerId(null), isFalse);
      expect(WaybillEntryScreen.isValidCustomerId(''), isFalse);
      expect(WaybillEntryScreen.isValidCustomerId('wb-cari'), isTrue);
    });
  });

  group('WaybillCustomerSelectionScreen.emptyMessage', () {
    test('sipariş seçimi ile aynı anahtarları kullanır', () {
      expect(
        WaybillCustomerSelectionScreen.emptyMessage(''),
        'field_sales.no_customer_cards',
      );
      expect(
        WaybillCustomerSelectionScreen.emptyMessage('xyz'),
        'field_sales.customer_not_found',
      );
    });
  });

  group('WaybillType / titleKeyForType', () {
    test('toptan ve satın alma ayrı l10n anahtarları kullanır', () {
      expect(
        WaybillEntryScreen.titleKeyForType(WaybillType.wholesale),
        'field_sales.stubs.waybill_wholesale',
      );
      expect(
        WaybillEntryScreen.titleKeyForType(WaybillType.purchase),
        'field_sales.stubs.waybill_purchase',
      );
    });

    test('route sabitleri seed path ile uyumlu', () {
      expect(
        WaybillEntryScreen.routeWholesale,
        '/field-sales/waybill-wholesale',
      );
      expect(
        WaybillEntryScreen.routePurchase,
        '/field-sales/waybill-purchase',
      );
    });

    test('Logo dispatch TYPE fatura TYPE 8 flatten değil', () {
      expect(WaybillType.wholesale.localKey, 'waybill_wholesale');
      expect(WaybillType.purchase.localKey, 'waybill_purchase');
      expect(WaybillType.wholesale.logoDispatchType, isNot('8'));
      expect(WaybillType.purchase.logoDispatchType, isNot('3'));
    });
  });
}
