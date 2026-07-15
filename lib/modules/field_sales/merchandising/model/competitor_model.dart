class CompetitorProductModel {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final double? priceReference;

  CompetitorProductModel({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    this.priceReference,
  });

  factory CompetitorProductModel.fromMap(Map<String, dynamic> map) {
    return CompetitorProductModel(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      category: map['category'] as String?,
      priceReference: (map['price_reference'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'price_reference': priceReference,
    };
  }
}

class CompetitorObservationModel {
  final String id;
  final String visitId;
  final String competitorProductId;
  final double? observedPrice;
  final bool hasStock;
  final bool onPromotion;
  final String? notes;
  final String? photoUrl;
  final DateTime createdAt;

  CompetitorObservationModel({
    required this.id,
    required this.visitId,
    required this.competitorProductId,
    this.observedPrice,
    this.hasStock = true,
    this.onPromotion = false,
    this.notes,
    this.photoUrl,
    required this.createdAt,
  });

  factory CompetitorObservationModel.fromMap(Map<String, dynamic> map) {
    return CompetitorObservationModel(
      id: map['id'] as String,
      visitId: map['visit_id'] as String,
      competitorProductId: map['competitor_product_id'] as String,
      observedPrice: (map['observed_price'] as num?)?.toDouble(),
      hasStock: (map['has_stock'] as int?) == 1,
      onPromotion: (map['on_promotion'] as int?) == 1,
      notes: map['notes'] as String?,
      photoUrl: map['photo_url'] as String?,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_id': visitId,
      'competitor_product_id': competitorProductId,
      'observed_price': observedPrice,
      'has_stock': hasStock ? 1 : 0,
      'on_promotion': onPromotion ? 1 : 0,
      'notes': notes,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
