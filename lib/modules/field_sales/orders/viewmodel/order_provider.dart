import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:uuid/uuid.dart';
import '../model/order_model.dart';
import '../../campaigns/engine/campaign_engine.dart';
import '../../campaigns/model/campaign_model.dart' as cm;
import '../../customers/model/customer_model.dart';
import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../../../../core/services/gps_service.dart';
import '../../../../core/services/logo_payload_mapper.dart';
import '../../gps/engine/order_geofence_gate.dart';
import '../../gps/viewmodel/geofence_settings_store.dart';
import '../engine/price_engine.dart';
import 'order_dens_store.dart';

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

  /// {@template isValidCustomerId}
  /// Cari kart kimliğinin sipariş için geçerli olup olmadığını kontrol eder.
  ///
  /// Parametreler:
  /// - [customerId]: Kontrol edilecek cari kimliği
  ///
  /// Dönüş değeri:
  /// - [bool]: Boş/whitespace değilse true
  /// {@endtemplate}
  static bool isValidCustomerId(String? customerId) {
    return customerId != null && customerId.trim().isNotEmpty;
  }

  /// {@template isValidPartyForOrder}
  /// Sipariş tipi ile cari rolünün uyumunu doğrular.
  ///
  /// Alış → tedarikçi/both zorunlu (null fail-closed).
  /// Satış → null geriye uyumlu (customer varsayılır); salt supplier engelli.
  ///
  /// Parametreler:
  /// - [customerId]: Cari kimliği
  /// - [orderType]: Satış / Alış
  /// - [cardRole]: Cari kart rolü
  ///
  /// Dönüş değeri:
  /// - [bool]: Uyumluysa true
  /// {@endtemplate}
  static bool isValidPartyForOrder({
    required String? customerId,
    required OrderType orderType,
    CariCardRole? cardRole,
  }) {
    if (!isValidCustomerId(customerId)) return false;
    if (orderType == OrderType.purchase) {
      if (cardRole == null) return false;
      return cardRole.allowsPurchaseOrder;
    }
    final role = cardRole ?? CariCardRole.customer;
    return role.allowsSalesOrder;
  }

  /// {@template filterForOrderType}
  /// Cari listesini sipariş tipine göre süzer.
  ///
  /// Parametreler:
  /// - [customers]: Ham cari listesi
  /// - [orderType]: Satış / Alış
  ///
  /// Dönüş değeri:
  /// - [List]: Tip ile uyumlu cariler
  /// {@endtemplate}
  static List<CustomerModel> filterForOrderType(
    List<CustomerModel> customers,
    OrderType orderType,
  ) {
    return customers
        .where((c) {
          if (!isValidCustomerId(c.id)) return false;
          return orderType == OrderType.purchase
              ? c.cardRole.allowsPurchaseOrder
              : c.cardRole.allowsSalesOrder;
        })
        .toList();
  }

  /// {@template resolveQueueType}
  /// Sipariş tipi → Logo / job queue `type` anahtarı.
  ///
  /// Parametreler:
  /// - [orderType]: [OrderType], saklama string veya null
  ///
  /// Dönüş değeri:
  /// - [String]: `sales` | `purchase`
  /// {@endtemplate}
  static String resolveQueueType(Object? orderType) {
    if (orderType is OrderType) {
      return orderType.storageValue;
    }
    return OrderType.fromStorage(orderType?.toString()).storageValue;
  }

  /// {@template startNewOrder}
  /// Yeni sipariş taslağı başlatır (cari + tip + rol).
  ///
  /// Parametreler:
  /// - [customerId]: Cari kart kimliği
  /// - [orderType]: Satış / Alış (varsayılan satış)
  /// - [cardRole]: Tedarikçi/müşteri rolü (alış guard)
  /// {@endtemplate}
  void startNewOrder(
    String customerId, {
    OrderType orderType = OrderType.sales,
    CariCardRole? cardRole,
  }) {
    state = OrderState(
      draftOrder: OrderModel(
        id: const Uuid().v4(),
        customerId: customerId.trim(),
        orderDate: DateTime.now(),
        totalAmount: 0.0,
        status: 'Pending',
        orderType: orderType,
        cariCardRole: cardRole,
      ),
    );
  }

  /// {@template discardDraft}
  /// Kaydedilmemiş sipariş taslağını siler (MBT Sil aksiyonu).
  /// {@endtemplate}
  void discardDraft() {
    state = OrderState();
  }

  /// {@template loadDraftFromOrderId}
  /// Aktarılmamış yerel siparişi düzenleme taslağına yükler.
  /// {@endtemplate}
  Future<bool> loadDraftFromOrderId(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final store = const OrderDensStore();
      final header = await store.fetchOrderHeader(orderId);
      if (header == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'field_sales.order_edit_not_found',
        );
        return false;
      }
      if ((header['is_synced'] as num?)?.toInt() == 1) {
        state = state.copyWith(
          isLoading: false,
          error: 'field_sales.order_edit_synced_blocked',
        );
        return false;
      }
      final itemMaps = await store.fetchOrderItems(orderId);
      final orderType = OrderType.fromStorage(header['order_type']?.toString());
      final draft = OrderModel(
        id: orderId,
        customerId: header['customer_id']?.toString() ?? '',
        orderDate: DateTime.tryParse(header['order_date']?.toString() ?? '') ??
            DateTime.now(),
        totalAmount: (header['total_amount'] as num?)?.toDouble() ?? 0,
        status: header['status']?.toString() ?? 'Pending',
        notes: header['notes']?.toString(),
        orderType: orderType,
      );
      final items = itemMaps.map((m) => OrderItemModel.fromMap(m)).toList();
      state = OrderState(
        draftOrder: draft,
        items: items,
        isLoading: false,
      );
      await _calculateTotals();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// {@template softDeleteLocalOrder}
  /// Aktarılmamış yerel sipariş soft-delete.
  /// {@endtemplate}
  Future<bool> softDeleteLocalOrder(String orderId) async {
    try {
      return await const OrderDensStore().softDeleteLocal(orderId);
    } catch (_) {
      return false;
    }
  }

  /// {@template cancelLocalOrder}
  /// Aktarılmamış siparişi iptal (Cancelled) + sync_queue stub.
  /// {@endtemplate}
  Future<bool> cancelLocalOrder(String orderId) async {
    try {
      final ok = await const OrderDensStore().cancelLocal(orderId);
      if (ok && state.draftOrder?.id == orderId.trim()) {
        state = OrderState();
      }
      return ok;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// {@template updateLocalOrder}
  /// Mevcut aktarılmamış siparişi günceller (üst + kalemler).
  /// {@endtemplate}
  Future<bool> updateLocalOrder(String? notes) async {
    final orderId = state.draftOrder?.id;
    if (orderId == null || orderId.isEmpty) {
      state = state.copyWith(error: 'field_sales.order_edit_not_found');
      return false;
    }
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'field_sales.order_min_products');
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      final store = const OrderDensStore();
      final header = await store.fetchOrderHeader(orderId);
      if (header == null ||
          (header['is_synced'] as num?)?.toInt() == 1) {
        state = state.copyWith(
          isLoading: false,
          error: 'field_sales.order_edit_synced_blocked',
        );
        return false;
      }
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      await sqliteDb.execute(SqlQuerys.createSyncQueueTable);
      final now = DateTime.now().toIso8601String();
      final savedItems = List<OrderItemModel>.from(state.items);

      await sqliteDb.transaction((txn) async {
        await txn.update(
          'orders',
          {
            'total_amount': state.grandTotal,
            'notes': notes,
            'updated_at': now,
            'is_synced': 0,
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );
        await txn.delete('order_items', where: 'order_id = ?', whereArgs: [
          orderId,
        ]);
        for (final item in savedItems) {
          await txn.insert('order_items', item.toMap());
        }
        await txn.insert('sync_queue', {
          'id': const Uuid().v4(),
          'entity_type': 'order',
          'entity_id': orderId,
          'payload': jsonEncode({
            'id': orderId,
            'op': 'update',
            'total_amount': state.grandTotal,
            'notes': notes,
            'updated_at': now,
          }),
          'priority': 0,
          'retry_count': 0,
          'created_at': now,
        });
      });

      JobQueueService().processQueue();
      state = state.copyWith(isLoading: false, draftOrder: null, items: []);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
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
        unitName: unitName ?? existing.unitName,
        quantity: newQty,
        price: price,
        discountPercent: existing.discountPercent,
        vatAmount: (price * newQty) *
            (1 - existing.discountPercent / 100) *
            (vatRate / 100),
        totalAmount:
            price * newQty * (1 - existing.discountPercent / 100),
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
        return _recalcLine(i, quantity: quantity);
      }
      return i;
    }).toList();

    state = state.copyWith(items: newItems);
    _calculateTotals();
  }

  /// {@template updateDiscount}
  /// Satır iskonto yüzdesini günceller (0–100).
  ///
  /// Parametreler:
  /// - [productId]: Kalem ürün kimliği
  /// - [discountPercent]: İskonto %
  /// {@endtemplate}
  void updateDiscount(String productId, double discountPercent) {
    final clamped = discountPercent.clamp(0.0, 100.0).toDouble();
    final newItems = state.items.map((i) {
      if (i.productId == productId) {
        return _recalcLine(i, discountPercent: clamped);
      }
      return i;
    }).toList();
    state = state.copyWith(items: newItems);
    _calculateTotals();
  }

  /// {@template _recalcLine}
  /// Miktar / iskonto sonrası satır tutarlarını yeniden hesaplar.
  /// {@endtemplate}
  OrderItemModel _recalcLine(
    OrderItemModel i, {
    double? quantity,
    double? discountPercent,
  }) {
    final qty = quantity ?? i.quantity;
    final disc = discountPercent ?? i.discountPercent;
    final net = i.price * qty * (1 - disc / 100);
    return OrderItemModel(
      id: i.id,
      orderId: i.orderId,
      productId: i.productId,
      unitName: i.unitName,
      quantity: qty,
      price: i.price,
      discountPercent: disc,
      vatAmount: net * 0.2,
      totalAmount: net,
      productName: i.productName,
      productCode: i.productCode,
    );
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

    if (!mounted) return;
    state = state.copyWith(
      subtotal: subtotal,
      vatTotal: vatTotal,
      discountTotal: discount,
      grandTotal: subtotal + vatTotal - discount,
      freeItems: freebies,
    );
  }

  Future<bool> saveOrder(String? notes) async {
    final customerId = state.draftOrder?.customerId;
    final orderType = state.draftOrder?.orderType ?? OrderType.sales;
    final cardRole = state.draftOrder?.cariCardRole;

    if (!isValidCustomerId(customerId)) {
      state = state.copyWith(
        error: orderType == OrderType.purchase
            ? 'field_sales.order_save_requires_supplier'
            : 'field_sales.order_save_requires_customer',
      );
      return false;
    }

    if (!isValidPartyForOrder(
      customerId: customerId,
      orderType: orderType,
      cardRole: cardRole,
    )) {
      state = state.copyWith(
        error: orderType == OrderType.purchase
            ? 'field_sales.order_save_requires_supplier'
            : 'field_sales.order_save_requires_customer',
      );
      return false;
    }

    if (state.items.isEmpty) {
      state = state.copyWith(error: 'field_sales.order_min_products');
      return false;
    }

    final geofenceOk = await _ensureOrderGeofence(customerId!);
    if (!geofenceOk) return false;

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
        orderType: state.draftOrder!.orderType,
      );

      final savedItems = List<OrderItemModel>.from(state.items);

      await sqliteDb.transaction((txn) async {
        final orderMap = order.toMap();
        orderMap['is_synced'] = 0;
        orderMap['is_deleted'] = 0;
        orderMap['approval_status'] = order.approvalStatus;
        orderMap['updated_at'] = DateTime.now().toIso8601String();
        await txn.insert(
          'orders',
          orderMap,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
        await txn.delete(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [order.id],
        );
        for (var item in savedItems) {
          await txn.insert(
            'order_items',
            item.toMap(),
            conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
          );
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
          'discount_percent': item.discountPercent,
        });
      }

      final queueType = resolveQueueType(order.orderType);
      final logoPayload = LogoPayloadMapper.orderFromLocal(
        order: {
          'id': order.id,
          'order_date': order.orderDate.toIso8601String(),
          'notes': notes,
          'order_type': queueType,
        },
        items: lines,
        customerCode: customerCode,
        orderType: queueType,
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

  /// {@template order_notifier_ensure_order_geofence}
  /// Parametre açıksa müşteri GPS yarıçapında değilse siparişi engeller.
  /// Check-in geofence [enabled] bayrağına dokunmaz.
  /// {@endtemplate}
  Future<bool> _ensureOrderGeofence(String customerId) async {
    final settings = await const GeofenceSettingsStore().load();
    if (!settings.orderRequireGeofence) return true;

    double? custLat;
    double? custLng;
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();
      final rows = await sqliteDb.query(
        'customers',
        columns: ['latitude', 'longitude'],
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        custLat = (rows.first['latitude'] as num?)?.toDouble();
        custLng = (rows.first['longitude'] as num?)?.toDouble();
      }
    } catch (_) {
      // DB okunamazsa failClosed kurallarına bırak
    }

    final pos = await GpsService().getCurrentPosition();
    final decision = OrderGeofenceGate.evaluate(
      orderRequireGeofence: true,
      radiusMeters: settings.radiusMeters,
      failClosed: settings.failClosed,
      customerLat: custLat,
      customerLng: custLng,
      deviceLat: pos?.latitude,
      deviceLng: pos?.longitude,
    );
    if (!decision.allowed) {
      state = state.copyWith(
        error: decision.errorKey ?? 'field_sales.order_geofence_outside',
      );
      return false;
    }
    return true;
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref);
});
