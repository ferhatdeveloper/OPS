// Dosya Adı: order_line_discount_persist_test.dart
// Açıklama: Sipariş satır iskonto % provider + SQLite kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/orders/model/order_model.dart';
import 'package:exfin_ops/modules/field_sales/orders/viewmodel/order_provider.dart';

/// Test için kalem tohumlayan OrderNotifier.
class _HarnessOrderNotifier extends OrderNotifier {
  _HarnessOrderNotifier(super.ref);

  /// {@template seedItems}
  /// Taslak kalemlerini doğrudan state'e yazar (fiyat motoru atlanır).
  /// {@endtemplate}
  void seedItems(List<OrderItemModel> items) {
    state = state.copyWith(items: List<OrderItemModel>.from(items));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrderItemModel discount_percent map', () {
    test('toMap / fromMap iskonto % taşır', () {
      final item = OrderItemModel(
        id: 'oi-1',
        orderId: 'ord-1',
        productId: 'prd-1',
        quantity: 10,
        price: 100,
        vatAmount: 180,
        totalAmount: 900,
        discountPercent: 10,
      );

      final map = item.toMap();
      expect(map['discount_percent'], 10);

      final loaded = OrderItemModel.fromMap(map);
      expect(loaded.discountPercent, 10);
      expect(loaded.totalAmount, 900);
      expect(loaded.vatAmount, 180);
    });

    test('fromMap eksik discount_percent → 0', () {
      final loaded = OrderItemModel.fromMap({
        'id': 'oi-2',
        'order_id': 'ord-2',
        'product_id': 'prd-2',
        'quantity': 1,
        'price': 50,
        'total_amount': 50,
      });
      expect(loaded.discountPercent, 0);
    });
  });

  group('OrderNotifier.updateDiscount', () {
    late ProviderContainer container;
    late _HarnessOrderNotifier harness;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          orderProvider.overrideWith((ref) => _HarnessOrderNotifier(ref)),
        ],
      );
      harness =
          container.read(orderProvider.notifier) as _HarnessOrderNotifier;
    });

    tearDown(() async {
      // Kampanya _calculateTotals async tamamlanana kadar bekle
      await Future<void>.delayed(Duration.zero);
      container.dispose();
    });

    OrderItemModel lineOf({
      required String orderId,
      double discountPercent = 0,
    }) {
      return OrderItemModel(
        id: 'line-1',
        orderId: orderId,
        productId: 'prd-a',
        quantity: 10,
        price: 100,
        vatAmount: 200,
        totalAmount: 1000,
        discountPercent: discountPercent,
        productName: 'Ürün A',
      );
    }

    test('%10 iskonto net + KDV yeniden hesaplar', () {
      harness.startNewOrder('cust-1');
      final orderId = container.read(orderProvider).draftOrder!.id;
      harness.seedItems([lineOf(orderId: orderId)]);

      harness.updateDiscount('prd-a', 10);

      final item = container.read(orderProvider).items.single;
      expect(item.discountPercent, 10);
      expect(item.totalAmount, 900);
      expect(item.vatAmount, 180);
      expect(item.toMap()['discount_percent'], 10);
    });

    test('iskonto 0–100 aralığına sıkıştırılır', () {
      harness.startNewOrder('cust-1');
      final orderId = container.read(orderProvider).draftOrder!.id;
      harness.seedItems([lineOf(orderId: orderId)]);

      harness.updateDiscount('prd-a', 150);
      expect(container.read(orderProvider).items.single.discountPercent, 100);
      expect(container.read(orderProvider).items.single.totalAmount, 0);

      harness.updateDiscount('prd-a', -5);
      expect(container.read(orderProvider).items.single.discountPercent, 0);
      expect(container.read(orderProvider).items.single.totalAmount, 1000);
    });

    test('miktar güncellemesi satır iskontosunu korur', () {
      harness.startNewOrder('cust-1');
      final orderId = container.read(orderProvider).draftOrder!.id;
      harness.seedItems([lineOf(orderId: orderId)]);
      harness.updateDiscount('prd-a', 20);

      harness.updateQuantity('prd-a', 5);

      final item = container.read(orderProvider).items.single;
      expect(item.discountPercent, 20);
      expect(item.quantity, 5);
      expect(item.totalAmount, 400); // 100*5*0.8
      expect(item.vatAmount, 80);
    });
  });

  group('SQLite order_items discount_percent persist', () {
    late Database db;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(SqlQuerys.createOrderItemsTable);
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('insert + query iskonto % geri okur', () async {
      final item = OrderItemModel(
        id: 'oi-persist-1',
        orderId: 'ord-persist-1',
        productId: 'prd-persist-1',
        unitName: 'Adet',
        quantity: 4,
        price: 250,
        vatAmount: 170,
        totalAmount: 850,
        discountPercent: 15,
      );

      await db.insert('order_items', item.toMap());

      final rows = await db.query(
        'order_items',
        where: 'id = ?',
        whereArgs: [item.id],
      );
      expect(rows, hasLength(1));
      expect(rows.first['discount_percent'], 15);

      final loaded = OrderItemModel.fromMap(rows.first);
      expect(loaded.discountPercent, 15);
      expect(loaded.totalAmount, 850);
      expect(loaded.vatAmount, 170);
    });

    test('provider updateDiscount sonrası toMap SQLite’a yazılır', () async {
      final container = ProviderContainer(
        overrides: [
          orderProvider.overrideWith((ref) => _HarnessOrderNotifier(ref)),
        ],
      );
      addTearDown(() async {
        await Future<void>.delayed(Duration.zero);
        container.dispose();
      });

      final harness =
          container.read(orderProvider.notifier) as _HarnessOrderNotifier;
      harness.startNewOrder('cust-persist');
      final orderId = container.read(orderProvider).draftOrder!.id;
      harness.seedItems([
        OrderItemModel(
          id: 'oi-p2',
          orderId: orderId,
          productId: 'prd-p2',
          quantity: 2,
          price: 500,
          vatAmount: 200,
          totalAmount: 1000,
        ),
      ]);
      harness.updateDiscount('prd-p2', 12.5);

      final mapped = container.read(orderProvider).items.single.toMap();
      await db.insert('order_items', mapped);

      final rows = await db.query(
        'order_items',
        where: 'id = ?',
        whereArgs: ['oi-p2'],
      );
      final loaded = OrderItemModel.fromMap(rows.single);
      expect(loaded.discountPercent, 12.5);
      expect(loaded.totalAmount, closeTo(875, 0.001)); // 500*2*0.875
      expect(loaded.vatAmount, closeTo(175, 0.001));
    });
  });
}
