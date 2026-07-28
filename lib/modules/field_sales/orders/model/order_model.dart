// Dosya Adı: order_model.dart
// Açıklama: Sipariş ve kalem modelleri (satış/alış tip desteği)
// Oluşturulma Tarihi: 2024-01-01
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../customers/model/customer_model.dart';

/// {@template order_type}
/// MBT sipariş tipi: Satış veya Alış.
///
/// Kullanım örneği:
/// ```dart
/// final t = OrderType.fromStorage('purchase');
/// ```
/// {@endtemplate}
enum OrderType {
  /// Satış siparişi
  sales,

  /// Alış siparişi
  purchase;

  /// {@template order_type_storage}
  /// SQLite / JSON saklama değeri.
  /// {@endtemplate}
  String get storageValue => this == OrderType.purchase ? 'purchase' : 'sales';

  /// {@template order_type_from_storage}
  /// Saklama değerinden [OrderType] üretir; bilinmeyen → sales.
  /// {@endtemplate}
  static OrderType fromStorage(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'purchase' || v == 'alis' || v == 'alış' || v == 'buy') {
      return OrderType.purchase;
    }
    return OrderType.sales;
  }

  /// {@template order_type_l10n}
  /// Başlık çeviri anahtarı.
  /// {@endtemplate}
  String get titleL10nKey => this == OrderType.purchase
      ? 'field_sales.order_type_purchase'
      : 'field_sales.order_type_sales';
}

/// {@template order_model}
/// Sipariş üst bilgisi (cari, tip, tutar, durum).
/// {@endtemplate}
class OrderModel {
  /// [id]: Sipariş kimliği
  final String id;

  /// [customerId]: Cari kart kimliği
  final String customerId;

  /// [orderDate]: Sipariş tarihi
  final DateTime orderDate;

  /// [totalAmount]: Genel toplam
  final double totalAmount;

  /// [status]: 'Pending', 'Approved', 'Cancelled', 'Proposal', 'Shippable', 'NotShippable'
  final String status;

  /// [notes]: Not
  final String? notes;

  /// [isSynced]: Senkron durumu
  final bool isSynced;

  /// [approvalStatus]: ONAY (0 bekliyor, 1 onaylı, 2 sync, 3 red, 4 hata)
  final int approvalStatus;

  /// [createdAt]: Oluşturulma
  final DateTime? createdAt;

  /// [items]: Kalemler
  final List<OrderItemModel> items;

  /// [orderType]: Satış / Alış
  final OrderType orderType;

  /// [cariCardRole]: Taslak cari rolü (alış tedarikçi guard; SQLite orders'a yazılmaz)
  final CariCardRole? cariCardRole;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    this.notes,
    this.isSynced = false,
    this.approvalStatus = 0,
    this.createdAt,
    this.items = const [],
    this.orderType = OrderType.sales,
    this.cariCardRole,
  });

  factory OrderModel.fromMap(
    Map<String, dynamic> map,
    List<OrderItemModel> items,
  ) {
    final onay = (map['ONAY'] as num?)?.toInt() ??
        (map['approval_status'] as num?)?.toInt() ??
        0;
    return OrderModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      orderDate: DateTime.parse(map['order_date']),
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: map['status'] as String,
      notes: map['notes'] as String?,
      isSynced: (map['is_synced'] as int?) == 1,
      approvalStatus: onay,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      items: items,
      orderType: OrderType.fromStorage(map['order_type'] as String?),
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
      'is_deleted': 0,
      'approval_status': approvalStatus,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'order_type': orderType.storageValue,
    };
  }
}

/// {@template order_item_model}
/// Sipariş kalem satırı.
/// {@endtemplate}
class OrderItemModel {
  /// [id]: Kalem kimliği
  final String id;

  /// [orderId]: Üst sipariş
  final String orderId;

  /// [productId]: Ürün kimliği
  final String productId;

  /// [unitName]: Birim adı
  final String? unitName;

  /// [quantity]: Miktar
  final double quantity;

  /// [price]: Birim fiyat
  final double price;

  /// [vatAmount]: KDV tutarı
  final double vatAmount;

  /// [totalAmount]: Satır toplamı
  final double totalAmount;

  /// [discountPercent]: Satır iskonto %
  final double discountPercent;

  /// [productName]: Ürün adı (join)
  final String? productName;

  /// [productCode]: Ürün kodu (join)
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
    this.discountPercent = 0.0,
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
      discountPercent: (map['discount_percent'] as num? ?? 0.0).toDouble(),
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
      'discount_percent': discountPercent,
    };
  }
}
