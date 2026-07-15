class ProductModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? barcode;
  final String unit; // Legacy field, keeping for compatibility
  final double price; // Default price
  final int vatRate;
  final double stockQuantity;
  final String? category;
  final String? unitSetId;
  final String? mainUnit;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.barcode,
    this.unit = 'ADET',
    this.price = 0.0,
    this.vatRate = 20,
    this.stockQuantity = 0.0,
    this.category,
    this.unitSetId,
    this.mainUnit,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      barcode: map['barcode'] as String?,
      unit: map['unit'] as String? ?? 'ADET',
      price: (map['price'] as num? ?? 0.0).toDouble(),
      vatRate: (map['vat_rate'] as num? ?? 20).toInt(),
      stockQuantity: (map['stock_quantity'] as num? ?? 0.0).toDouble(),
      category: map['category'] as String?,
      unitSetId: map['unit_set_id'] as String?,
      mainUnit: map['main_unit'] as String?,
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'barcode': barcode,
      'unit': unit,
      'price': price,
      'vat_rate': vatRate,
      'stock_quantity': stockQuantity,
      'category': category,
      'unit_set_id': unitSetId,
      'main_unit': mainUnit,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
