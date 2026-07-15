class PriceListModel {
  final String id;
  final String name;
  final String currency;
  final bool isActive;
  final bool isSynced;
  final List<PriceListItemModel> items;

  PriceListModel({
    required this.id,
    required this.name,
    this.currency = 'TRY',
    this.isActive = true,
    this.isSynced = false,
    this.items = const [],
  });

  factory PriceListModel.fromMap(Map<String, dynamic> map, List<PriceListItemModel> items) {
    return PriceListModel(
      id: map['id'] as String,
      name: map['name'] as String,
      currency: map['currency'] as String? ?? 'TRY',
      isActive: (map['is_active'] as int?) == 1,
      isSynced: (map['is_synced'] as int?) == 1,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currency': currency,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}

class PriceListItemModel {
  final String id;
  final String priceListId;
  final String productId;
  final String? unitName;
  final double price;
  final double minQuantity;

  PriceListItemModel({
    required this.id,
    required this.priceListId,
    required this.productId,
    this.unitName,
    required this.price,
    this.minQuantity = 0.0,
  });

  factory PriceListItemModel.fromMap(Map<String, dynamic> map) {
    return PriceListItemModel(
      id: map['id'] as String,
      priceListId: map['price_list_id'] as String,
      productId: map['product_id'] as String,
      unitName: map['unit_name'] as String?,
      price: (map['price'] as num).toDouble(),
      minQuantity: (map['min_quantity'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'price_list_id': priceListId,
      'product_id': productId,
      'unit_name': unitName,
      'price': price,
      'min_quantity': minQuantity,
    };
  }
}

class CustomerPriceMapModel {
  final String id;
  final String customerId;
  final String priceListId;
  final bool isActive;
  final bool isSynced;
  final DateTime? createdAt;

  CustomerPriceMapModel({
    required this.id,
    required this.customerId,
    required this.priceListId,
    this.isActive = true,
    this.isSynced = false,
    this.createdAt,
  });

  factory CustomerPriceMapModel.fromMap(Map<String, dynamic> map) {
    return CustomerPriceMapModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      priceListId: map['price_list_id'] as String,
      isActive: (map['is_active'] as int?) == 1,
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'price_list_id': priceListId,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
