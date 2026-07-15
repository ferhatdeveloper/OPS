

class OrderModel {
  final String id;
  final String customerId;
  final DateTime orderDate;
  final double totalAmount;
  final String status; // 'Pending', 'Approved', 'Cancelled'
  final String? notes;
  final bool isSynced;
  final DateTime? createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    this.notes,
    this.isSynced = false,
    this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, List<OrderItemModel> items) {
    return OrderModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      orderDate: DateTime.parse(map['order_date']),
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: map['status'] as String,
      notes: map['notes'] as String?,
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'order_date': orderDate.toIso8601String(),
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String? unitName;
  final double quantity;
  final double price;
  final double vatAmount;
  final double totalAmount;
  // Join fields
  final String? productName;
  final String? productCode;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    this.unitName,
    required this.quantity,
    required this.price,
    this.vatAmount = 0.0,
    required this.totalAmount,
    this.productName,
    this.productCode,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String,
      unitName: map['unit_name'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      vatAmount: (map['vat_amount'] as num? ?? 0.0).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      productName: map['product_name'] as String?,
      productCode: map['product_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'unit_name': unitName,
      'quantity': quantity,
      'price': price,
      'vat_amount': vatAmount,
      'total_amount': totalAmount,
    };
  }
}
