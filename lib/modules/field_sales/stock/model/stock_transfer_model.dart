class StockTransferModel {
  final String id;
  final String fromWarehouse;
  final String toWarehouse;
  final String productId;
  final double quantity;
  final String? unitName;
  final DateTime transferDate;
  final String status; // 'Pending', 'Approved', 'Completed'
  final bool isSynced;
  final DateTime? createdAt;
  // Join fields
  final String? productName;
  final String? productCode;

  StockTransferModel({
    required this.id,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.productId,
    required this.quantity,
    this.unitName,
    required this.transferDate,
    this.status = 'Pending',
    this.isSynced = false,
    this.createdAt,
    this.productName,
    this.productCode,
  });

  factory StockTransferModel.fromMap(Map<String, dynamic> map) {
    return StockTransferModel(
      id: map['id'] as String,
      fromWarehouse: map['from_warehouse'] as String,
      toWarehouse: map['to_warehouse'] as String,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitName: map['unit_name'] as String?,
      transferDate: DateTime.parse(map['transfer_date']),
      status: map['status'] as String? ?? 'Pending',
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      productName: map['product_name'] as String?,
      productCode: map['product_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_warehouse': fromWarehouse,
      'to_warehouse': toWarehouse,
      'product_id': productId,
      'quantity': quantity,
      'unit_name': unitName,
      'transfer_date': transferDate.toIso8601String(),
      'status': status,
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
