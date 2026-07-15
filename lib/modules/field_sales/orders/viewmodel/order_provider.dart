import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/order_model.dart';
import '../../campaigns/engine/campaign_engine.dart';
import '../../campaigns/model/campaign_model.dart' as cm;
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../../../../core/services/logo_payload_mapper.dart';
import '../engine/price_engine.dart';

class OrderState {
  final OrderModel? draftOrder;
  final List<OrderItemModel> items;
  final double subtotal;
  final double vatTotal;
  final double discountTotal;
  final double grandTotal;
  final List<FreeItem> freeItems;
  final bool isLoading;
  final String? error;

  OrderState({
    this.draftOrder,
    this.items = const [],
    this.subtotal = 0.0,
    this.vatTotal = 0.0,
    this.discountTotal = 0.0,
    this.grandTotal = 0.0,
    this.freeItems = const [],
    this.isLoading = false,
    this.error,
  });

  OrderState copyWith({
    OrderModel? draftOrder,
    List<OrderItemModel>? items,
    double? subtotal,
    double? vatTotal,
    double? discountTotal,
    double? grandTotal,
    List<FreeItem>? freeItems,
    bool? isLoading,
    String? error,
  }) {
    return OrderState(
      draftOrder: draftOrder ?? this.draftOrder,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      vatTotal: vatTotal ?? this.vatTotal,
      discountTotal: discountTotal ?? this.discountTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      freeItems: freeItems ?? this.freeItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final Ref ref;
  OrderNotifier(this.ref) : super(OrderState());

  void startNewOrder(String customerId) {
    state = OrderState(
      draftOrder: OrderModel(
        id: const Uuid().v4(),
        customerId: customerId,
        orderDate: DateTime.now(),
        totalAmount: 0.0,
        status: 'Pending',
      ),
    );
  }

  Future<void> addItem(String productId, String name, double quantity, {String? unitName, double vatRate = 20.0}) async {
    final price = await PriceEngine.getPrice(
      customerId: state.draftOrder!.customerId,
      productId: productId,
      unitName: unitName,
      defaultPrice: 0.0, // We could fetch actual default from DB if needed
    );

    final existingIndex = state.items.indexWhere((i) => i.productId == productId && i.unitName == unitName);
    List<OrderItemModel> newItems = List.from(state.items);

    if (existingIndex != -1) {
      final existing = newItems[existingIndex];
      final newQty = existing.quantity + quantity;
      newItems[existingIndex] = OrderItemModel(
        id: existing.id,
        orderId: existing.orderId,
        productId: productId,
        quantity: newQty,
        price: price,
        vatAmount: (price * newQty) * (vatRate / 100),
        totalAmount: price * newQty,
        productName: name,
      );
    } else {
      newItems.add(OrderItemModel(
        id: const Uuid().v4(),
        orderId: state.draftOrder!.id,
        productId: productId,
        unitName: unitName,
        quantity: quantity,
        price: price,
        vatAmount: (price * quantity) * (vatRate / 100),
        totalAmount: price * quantity,
        productName: name,
      ));
    }

    state = state.copyWith(items: newItems);
    _calculateTotals();
  }

  void removeItem(String productId) {
    state = state.copyWith(items: state.items.where((i) => i.productId != productId).toList());
    _calculateTotals();
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final newItems = state.items.map((i) {
      if (i.productId == productId) {
        return OrderItemModel(
          id: i.id,
          orderId: i.orderId,
          productId: i.productId,
          quantity: quantity,
          price: i.price,
          vatAmount: (i.price * quantity) * 0.2, // Assuming 20% default if not saved
          totalAmount: i.price * quantity,
          productName: i.productName,
        );
      }
      return i;
    }).toList();

    state = state.copyWith(items: newItems);
    _calculateTotals();
  }

  Future<void> _calculateTotals() async {
    double subtotal = state.items.fold(0, (sum, i) => sum + i.totalAmount);
    double vatTotal = state.items.fold(0, (sum, i) => sum + i.vatAmount);
    
    // Campaign Logic
    double discount = 0;
    List<FreeItem> freebies = [];
    
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      
      final campaignResults = await sqliteDb.query('campaigns', where: 'is_active = 1');
      final engine = CampaignEngine();
      
      final engineItems = state.items.map((i) => OrderItem(
        productId: i.productId,
        quantity: i.quantity,
        price: i.price,
      )).toList();

      for (var cMap in campaignResults) {
        // Fetch rules
        final ruleResults = await sqliteDb.query('campaign_rules', where: 'campaign_id = ?', whereArgs: [cMap['id']]);
        final rules = ruleResults.map((r) => cm.CampaignRuleModel.fromMap(r)).toList();
        
        final campaign = cm.CampaignModel.fromMap(cMap, rules);
        final result = engine.applyCampaign(campaign, engineItems);
        
        if (result.hasBenefit) {
          discount += result.totalDiscount;
          freebies.addAll(result.freeItems);
        }
      }
    } catch (e) {
      print('Campaign processing error: $e');
    }

    state = state.copyWith(
      subtotal: subtotal,
      vatTotal: vatTotal,
      discountTotal: discount,
      grandTotal: subtotal + vatTotal - discount,
      freeItems: freebies,
    );
  }

  Future<bool> saveOrder(String? notes) async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Sipariş için en az bir ürün eklemelisiniz.');
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();

      final order = OrderModel(
        id: state.draftOrder!.id,
        customerId: state.draftOrder!.customerId,
        orderDate: DateTime.now(),
        totalAmount: state.grandTotal,
        status: 'Pending',
        notes: notes,
      );

      final savedItems = List<OrderItemModel>.from(state.items);

      await sqliteDb.transaction((txn) async {
        final orderMap = order.toMap();
        orderMap['is_synced'] = 0;
        await txn.insert('orders', orderMap);
        for (var item in savedItems) {
          await txn.insert('order_items', item.toMap());
        }
      });

      // Logo REST aktarım kuyruğu
      final customerRows = await sqliteDb.query(
        'customers',
        where: 'id = ?',
        whereArgs: [order.customerId],
        limit: 1,
      );
      String customerCode = order.customerId;
      if (customerRows.isNotEmpty) {
        final c = customerRows.first;
        customerCode = (c['code'] ?? c['tax_no'] ?? c['id']).toString();
      }

      final lines = <Map<String, dynamic>>[];
      for (final item in savedItems) {
        String productCode = item.productId;
        final products = await sqliteDb.query(
          'products',
          columns: ['code'],
          where: 'id = ?',
          whereArgs: [item.productId],
          limit: 1,
        );
        if (products.isNotEmpty && products.first['code'] != null) {
          productCode = products.first['code'].toString();
        }
        lines.add({
          'product_code': productCode,
          'quantity': item.quantity,
          'price': item.price,
        });
      }

      final logoPayload = LogoPayloadMapper.orderFromLocal(
        order: {
          'id': order.id,
          'order_date': order.orderDate.toIso8601String(),
          'notes': notes,
        },
        items: lines,
        customerCode: customerCode,
      );

      await JobQueueService().enqueue(
        entityType: 'order',
        entityId: order.id,
        payload: logoPayload,
        priority: 1,
      );

      state = state.copyWith(isLoading: false, draftOrder: null, items: []);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref);
});
