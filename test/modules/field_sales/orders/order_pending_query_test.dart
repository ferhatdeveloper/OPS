// Dosya Adı: order_pending_query_test.dart
// Açıklama: Bekleyen sipariş dens — ONAY/SQLite filtre birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_pending_record.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_pending_query.dart';

void main() {
  group('OrderPendingQuery.isPendingMap', () {
    test('ONAY=0 + status boş → bekleyen', () {
      expect(
        OrderPendingQuery.isPendingMap({'ONAY': 0, 'status': ''}),
        isTrue,
      );
    });

    test('approval_status=0 + Pending bekleyen', () {
      expect(
        OrderPendingQuery.isPendingMap({
          'approval_status': 0,
          'status': 'Pending',
        }),
        isTrue,
      );
    });

    test('ONAY=1 + status Pending → bekleyen (status önceliği)', () {
      expect(
        OrderPendingQuery.isPendingMap({
          'ONAY': 1,
          'status': 'Pending',
        }),
        isTrue,
      );
    });

    test('ONAY=0 + status Approved → bekleyen değil', () {
      expect(
        OrderPendingQuery.isPendingMap({
          'ONAY': 0,
          'status': 'Approved',
        }),
        isFalse,
      );
    });

    test('legacy: kolon yok + status Pending', () {
      expect(
        OrderPendingQuery.isPendingMap({'status': 'Pending'}),
        isTrue,
      );
      expect(
        OrderPendingQuery.isPendingMap({'status': 'Proposal'}),
        isTrue,
      );
      expect(
        OrderPendingQuery.isPendingMap({'status': 'Approved'}),
        isFalse,
      );
    });
  });

  group('OrderPendingRecord', () {
    test('toMap/fromMap ONAY korur', () {
      final row = OrderPendingRecord(
        id: 'ord-p1',
        customerId: 'c1',
        customerCode: 'C001',
        customerName: 'Demo',
        orderDate: DateTime(2026, 7, 26),
        totalAmount: 150.5,
        status: 'Pending',
        orderType: OrderType.sales,
        approvalStatus: 0,
      );
      final map = row.toMap();
      expect(map['ONAY'], 0);
      expect(map['approval_status'], 0);
      expect(map['order_type'], 'sales');
      expect(map['status'], 'Pending');

      final back = OrderPendingRecord.fromMap(map);
      expect(back.id, 'ord-p1');
      expect(back.approvalStatus, 0);
      expect(back.orderType, OrderType.sales);
      expect(back.totalAmount, 150.5);
      expect(back.customerCode, 'C001');
    });

    test('fromMap ONAY yoksa approval_status', () {
      final back = OrderPendingRecord.fromMap({
        'id': 'x',
        'customer_id': 'c',
        'order_date': '2026-07-01T00:00:00.000',
        'total_amount': 10,
        'status': 'Pending',
        'approval_status': 0,
      });
      expect(back.approvalStatus, 0);
      expect(OrderPendingQuery.isPendingMap(back.toMap()), isTrue);
    });
  });

  group('OrderPendingQuery.filterPending', () {
    test('yalnız ONAY=0 / Pending satırları bırakır', () {
      final rows = [
        {
          'id': 'a',
          'customer_id': 'c1',
          'order_date': '2026-07-01T00:00:00.000',
          'total_amount': 1,
          'status': 'Pending',
          'ONAY': 0,
        },
        {
          'id': 'b',
          'customer_id': 'c2',
          'order_date': '2026-07-02T00:00:00.000',
          'total_amount': 2,
          'status': 'Approved',
          'ONAY': 1,
        },
        {
          'id': 'c',
          'customer_id': 'c3',
          'order_date': '2026-07-03T00:00:00.000',
          'total_amount': 3,
          'status': 'Proposal',
        },
      ];
      final pending = OrderPendingQuery.filterPendingMaps(rows);
      expect(pending.map((e) => e['id']), ['a', 'c']);
    });
  });

  group('OrderModel approvalStatus', () {
    test('toMap/fromMap approval_status yazar', () {
      final order = OrderModel(
        id: 'o1',
        customerId: 'c1',
        orderDate: DateTime(2026, 1, 1),
        totalAmount: 10,
        status: 'Pending',
        approvalStatus: 0,
      );
      expect(order.toMap()['approval_status'], 0);
      final back = OrderModel.fromMap(order.toMap(), const []);
      expect(back.approvalStatus, 0);
    });
  });
}
