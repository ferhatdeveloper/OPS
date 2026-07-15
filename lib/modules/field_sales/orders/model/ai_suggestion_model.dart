class AISuggestionModel {
  final String id;
  final String customerId;
  final String productId;
  final double suggestedQty;
  final String? reason;
  final double confidence; // 0.0 to 1.0
  final DateTime updatedAt;

  AISuggestionModel({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.suggestedQty,
    this.reason,
    required this.confidence,
    required this.updatedAt,
  });

  factory AISuggestionModel.fromMap(Map<String, dynamic> map) {
    return AISuggestionModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      productId: map['product_id'] as String,
      suggestedQty: (map['suggested_qty'] as num).toDouble(),
      reason: map['reason'] as String?,
      confidence: (map['confidence'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'product_id': productId,
      'suggested_qty': suggestedQty,
      'reason': reason,
      'confidence': confidence,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
