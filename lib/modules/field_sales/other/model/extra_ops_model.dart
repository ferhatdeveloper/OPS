class VisitTaskModel {
  final String id;
  final String? visitId;
  final String? customerId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;

  VisitTaskModel({
    required this.id,
    this.visitId,
    this.customerId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
  });

  factory VisitTaskModel.fromMap(Map<String, dynamic> map) {
    return VisitTaskModel(
      id: map['id'] as String,
      visitId: map['visit_id'] as String?,
      customerId: map['customer_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_id': visitId,
      'customer_id': customerId,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
    };
  }
}

class WastageLogModel {
  final String id;
  final String productId;
  final double quantity;
  final String type; // 'Wastage' or 'Sample'
  final String? reason;
  final DateTime createdAt;

  WastageLogModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.type,
    this.reason,
    required this.createdAt,
  });

  factory WastageLogModel.fromMap(Map<String, dynamic> map) {
    return WastageLogModel(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      type: map['type'] as String,
      reason: map['reason'] as String?,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'type': type,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
