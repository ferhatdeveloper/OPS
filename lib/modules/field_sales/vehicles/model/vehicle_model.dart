class VehicleModel {
  final String id;
  final String plate;
  final String? name;
  final String? salespersonId;
  final bool isActive;
  final bool isSynced;

  VehicleModel({
    required this.id,
    required this.plate,
    this.name,
    this.salespersonId,
    this.isActive = true,
    this.isSynced = false,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] as String,
      plate: map['plate'] as String,
      name: map['name'] as String?,
      salespersonId: map['salesperson_id'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plate': plate,
      'name': name,
      'salesperson_id': salespersonId,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}

class VehicleStockModel {
  final String vehicleId;
  final String productId;
  final double quantity;
  final String? productName; // Helper field

  VehicleStockModel({
    required this.vehicleId,
    required this.productId,
    required this.quantity,
    this.productName,
  });

  factory VehicleStockModel.fromMap(Map<String, dynamic> map, {String? productName}) {
    return VehicleStockModel(
      vehicleId: map['vehicle_id'] as String,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      productName: productName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicle_id': vehicleId,
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

class LoadingModel {
  final String id;
  final String vehicleId;
  final String salespersonId;
  final DateTime loadingDate;
  final String status; // 'Pending', 'Approved', 'Completed'
  final bool isSynced;

  LoadingModel({
    required this.id,
    required this.vehicleId,
    required this.salespersonId,
    required this.loadingDate,
    this.status = 'Pending',
    this.isSynced = false,
  });

  factory LoadingModel.fromMap(Map<String, dynamic> map) {
    return LoadingModel(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      salespersonId: map['salesperson_id'] as String,
      loadingDate: DateTime.parse(map['loading_date']),
      status: map['status'] as String,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'salesperson_id': salespersonId,
      'loading_date': loadingDate.toIso8601String(),
      'status': status,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
