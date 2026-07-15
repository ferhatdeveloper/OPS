import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/invoice_model.dart';
import '../../campaigns/engine/campaign_engine.dart';
import '../../campaigns/model/campaign_model.dart' as cm;
import '../../../../service/database_service.dart';
import '../../../../service/notification_service.dart';
import '../../../../service/job_queue_service.dart';
import '../../../../service/gamification_service.dart';
import '../../vehicles/viewmodel/vehicle_provider.dart';

class InvoiceState {
  final InvoiceModel? draftInvoice;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double vatTotal;
  final double discountTotal;
  final double grandTotal;
  final List<FreeItem> freeItems;
  final bool isLoading;
  final String? error;

  InvoiceState({
    this.draftInvoice,
    this.items = const [],
    this.subtotal = 0.0,
    this.vatTotal = 0.0,
    this.discountTotal = 0.0,
    this.grandTotal = 0.0,
    this.freeItems = const [],
    this.isLoading = false,
    this.error,
  });

  InvoiceState copyWith({
    InvoiceModel? draftInvoice,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? vatTotal,
    double? discountTotal,
    double? grandTotal,
    List<FreeItem>? freeItems,
    bool? isLoading,
    String? error,
  }) {
    return InvoiceState(
      draftInvoice: draftInvoice ?? this.draftInvoice,
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

class InvoiceNotifier extends StateNotifier<InvoiceState> {
  final Ref ref;
  InvoiceNotifier(this.ref) : super(InvoiceState());

  void startNewInvoice(String customerId, {String invoiceType = 'field_sales.van_sales'}) {
    state = InvoiceState(
      draftInvoice: InvoiceModel(
        id: const Uuid().v4(),
        customerId: customerId,
        invoiceDate: DateTime.now(),
        totalAmount: 0.0,
        invoiceType: invoiceType,
        isEInvoice: true,
      ),
    );
  }

  void updateInvoiceSettings({String? type, bool? isEInvoice}) {
    if (state.draftInvoice == null) return;
    
    state = state.copyWith(
      draftInvoice: InvoiceModel(
        id: state.draftInvoice!.id,
        customerId: state.draftInvoice!.customerId,
        invoiceDate: state.draftInvoice!.invoiceDate,
        totalAmount: state.draftInvoice!.totalAmount,
        invoiceType: type ?? state.draftInvoice!.invoiceType,
        isEInvoice: isEInvoice ?? state.draftInvoice!.isEInvoice,
        status: state.draftInvoice!.status,
        notes: state.draftInvoice!.notes,
      ),
    );
  }

  Future<void> addItem(String productId, String name, double price, double quantity, {double vatRate = 20.0}) async {
    final existingIndex = state.items.indexWhere((i) => i.productId == productId);
    List<InvoiceItemModel> newItems = List.from(state.items);

    if (existingIndex != -1) {
      final existing = newItems[existingIndex];
      final newQty = existing.quantity + quantity;
      newItems[existingIndex] = InvoiceItemModel(
        id: existing.id,
        invoiceId: existing.invoiceId,
        productId: productId,
        quantity: newQty,
        price: price,
        vatAmount: (price * newQty) * (vatRate / 100),
        totalAmount: price * newQty,
        productName: name,
      );
    } else {
      newItems.add(InvoiceItemModel(
        id: const Uuid().v4(),
        invoiceId: state.draftInvoice!.id,
        productId: productId,
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

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      state = state.copyWith(items: state.items.where((i) => i.productId != productId).toList());
      _calculateTotals();
      return;
    }

    final newItems = state.items.map((i) {
      if (i.productId == productId) {
        return InvoiceItemModel(
          id: i.id,
          invoiceId: i.invoiceId,
          productId: i.productId,
          quantity: quantity,
          price: i.price,
          vatAmount: (i.price * quantity) * 0.2, 
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

  Future<bool> saveInvoice(String? notes) async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Fatura için en az bir ürün eklemelisiniz.');
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final db = await DatabaseService.getInstance();
      final sqliteDb = await db.getDatabase();

      final invoice = InvoiceModel(
        id: state.draftInvoice!.id,
        customerId: state.draftInvoice!.customerId,
        invoiceDate: DateTime.now(),
        totalAmount: state.grandTotal,
        status: 'Completed',
        notes: notes,
        invoiceType: state.draftInvoice!.invoiceType,
        isEInvoice: state.draftInvoice!.isEInvoice,
        isSynced: 0,
      );

      final now = DateTime.now().toIso8601String();
      final invoiceMap = invoice.toMap();
      invoiceMap['approval_status'] = 1; // Approved (ready for sync)
      invoiceMap['created_at'] = now;
      invoiceMap['updated_at'] = now;

      final vehicleState = ref.read(vehicleProvider);
      final selectedVehicleId = vehicleState.selectedVehicle?.id;

      await sqliteDb.transaction((txn) async {
        await txn.insert('invoices', invoiceMap);
        
        for (var item in state.items) {
          final itemMap = item.toMap();
          itemMap['updated_at'] = now;
          await txn.insert('invoice_items', itemMap);

          // Deduct from vehicle stock if a vehicle is selected
          if (selectedVehicleId != null) {
            final existingStock = await txn.query('vehicle_stocks', 
              where: 'vehicle_id = ? AND product_id = ?',
              whereArgs: [selectedVehicleId, item.productId]);
            
            if (existingStock.isNotEmpty) {
              final currentQty = (existingStock.first['quantity'] as num).toDouble();
              await txn.update('vehicle_stocks', 
                {'quantity': currentQty - item.quantity},
                where: 'vehicle_id = ? AND product_id = ?',
                whereArgs: [selectedVehicleId, item.productId]);
            }
          }
        }
      });

      state = state.copyWith(isLoading: false, draftInvoice: null, items: []);

      // Logo REST kuyruğu — satırlı payload hazırla
      String customerCode = invoice.customerId;
      final cust = await sqliteDb.query(
        'customers',
        where: 'id = ?',
        whereArgs: [invoice.customerId],
        limit: 1,
      );
      if (cust.isNotEmpty) {
        customerCode =
            (cust.first['code'] ?? cust.first['tax_no'] ?? cust.first['id'])
                .toString();
      }
      final lines = <Map<String, dynamic>>[];
      // items already cleared from state — rebuild from DB
      final itemRows = await sqliteDb.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );
      for (final row in itemRows) {
        String productCode = row['product_id']?.toString() ?? '';
        final products = await sqliteDb.query(
          'products',
          columns: ['code'],
          where: 'id = ?',
          whereArgs: [row['product_id']],
          limit: 1,
        );
        if (products.isNotEmpty && products.first['code'] != null) {
          productCode = products.first['code'].toString();
        }
        lines.add({
          'product_code': productCode,
          'quantity': row['quantity'],
          'price': row['price'],
        });
      }

      await JobQueueService().enqueue(
        entityType: 'invoice',
        entityId: invoice.id,
        payload: {
          ...invoice.toMap(),
          'customer_code': customerCode,
          'arp_code': customerCode,
          'type': 'wholesale',
          'lines': lines,
        },
        priority: 2,
      );

      // Phase 9: Reward Points
      final session = await db.getUserSession();
      final userId = session?['id'] as String? ?? 'current_user';
      await GamificationService().addPoints(
        userId,
        GamificationService.pointsPerInvoice, 
        'Yeni Fatura Kesildi: ${invoice.id}'
      );

      // Notify
      await NotificationService().showNotification(
        id: 200,
        title: 'Fatura Kesildi',
        body: 'Toplam ${invoice.totalAmount.toStringAsFixed(2)}  tutarındaki fatura başarıyla kaydedildi.',
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final invoiceProvider = StateNotifierProvider<InvoiceNotifier, InvoiceState>((ref) {
  return InvoiceNotifier(ref);
});
