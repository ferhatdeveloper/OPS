

class RouteModel {
  final String id;
  final String name;
  final String? salespersonId;
  final int dayOfWeek; // 1-7 (Monday to Sunday)
  final bool isActive;
  final List<RouteCustomerModel> customers;

  RouteModel({
    required this.id,
    required this.name,
    this.salespersonId,
    required this.dayOfWeek,
    this.isActive = true,
    this.customers = const [],
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, List<RouteCustomerModel> customers) {
    return RouteModel(
      id: map['id'] as String,
      name: map['name'] as String,
      salespersonId: map['salesperson_id'] as String?,
      dayOfWeek: (map['day_of_week'] as num).toInt(),
      isActive: (map['is_active'] as int?) == 1,
      customers: customers,
    );
  }
}

class RouteCustomerModel {
  final String id;
  final String routeId;
  final String customerId;
  final int visitOrder;
  final bool isMandatory;
  // Join fields
  final String? customerName;
  final String? customerAddress;
  final double? latitude;
  final double? longitude;

  RouteCustomerModel({
    required this.id,
    required this.routeId,
    required this.customerId,
    required this.visitOrder,
    this.isMandatory = true,
    this.customerName,
    this.customerAddress,
    this.latitude,
    this.longitude,
  });

  factory RouteCustomerModel.fromMap(Map<String, dynamic> map) {
    return RouteCustomerModel(
      id: map['id'] as String,
      routeId: map['route_id'] as String,
      customerId: map['customer_id'] as String,
      visitOrder: (map['visit_order'] as num).toInt(),
      isMandatory: (map['is_mandatory'] as int?) == 1,
      customerName: map['customer_name'] as String?,
      customerAddress: map['customer_address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class VisitModel {
  final String id;
  final String customerId;
  final String? userId;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final double? checkInLat;
  final double? checkInLong;
  final double? checkOutLat;
  final double? checkOutLong;
  final String? notes;
  final String status; // 'Open', 'Completed'
  final int? durationMinutes;
  final bool isSynced;
  final String? signatureData;

  VisitModel({
    required this.id,
    required this.customerId,
    this.userId,
    required this.checkInAt,
    this.checkOutAt,
    this.checkInLat,
    this.checkInLong,
    this.checkOutLat,
    this.checkOutLong,
    this.notes,
    this.status = 'Open',
    this.durationMinutes,
    this.isSynced = false,
    this.signatureData,
  });

  bool get isCompleted => status == 'Completed';

  factory VisitModel.fromMap(Map<String, dynamic> map) {
    return VisitModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      userId: map['user_id'] as String?,
      checkInAt: DateTime.parse(map['check_in_at']),
      checkOutAt: map['check_out_at'] != null ? DateTime.parse(map['check_out_at']) : null,
      checkInLat: (map['check_in_lat'] as num?)?.toDouble(),
      checkInLong: (map['check_in_long'] as num?)?.toDouble(),
      checkOutLat: (map['check_out_lat'] as num?)?.toDouble(),
      checkOutLong: (map['check_out_long'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'Open',
      durationMinutes: map['duration_minutes'] as int?,
      isSynced: (map['is_synced'] as int?) == 1,
      signatureData: map['signature_data'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'user_id': userId,
      'check_in_at': checkInAt.toIso8601String(),
      'check_out_at': checkOutAt?.toIso8601String(),
      'check_in_lat': checkInLat,
      'check_in_long': checkInLong,
      'check_out_lat': checkOutLat,
      'check_out_long': checkOutLong,
      'notes': notes,
      'status': status,
      'duration_minutes': durationMinutes,
      'is_synced': isSynced ? 1 : 0,
      'signature_data': signatureData,
    };
  }
}
