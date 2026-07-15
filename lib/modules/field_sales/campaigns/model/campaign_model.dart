

enum CampaignType { discount, freeProduct, bundle, basketDiscount }

class CampaignModel {
  final String id;
  final String name;
  final CampaignType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<CampaignRuleModel> rules;

  CampaignModel({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.rules = const [],
  });

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  factory CampaignModel.fromMap(Map<String, dynamic> map, List<CampaignRuleModel> rules) {
    return CampaignModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CampaignType.values.firstWhere((e) => e.name == map['campaign_type']),
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      isActive: (map['is_active'] as int?) == 1,
      rules: rules,
    );
  }
}

class CampaignRuleModel {
  final String id;
  final String? productId;
  final double minQuantity;
  final double? maxQuantity;
  final double? discountRate;
  final String? freeProductId;
  final double? freeQuantity;
  final double? basketMinAmount;

  CampaignRuleModel({
    required this.id,
    this.productId,
    this.minQuantity = 0,
    this.maxQuantity,
    this.discountRate,
    this.freeProductId,
    this.freeQuantity,
    this.basketMinAmount,
  });

  factory CampaignRuleModel.fromMap(Map<String, dynamic> map) {
    return CampaignRuleModel(
      id: map['id'] as String,
      productId: map['product_id'] as String?,
      minQuantity: (map['min_quantity'] as num?)?.toDouble() ?? 0.0,
      maxQuantity: (map['max_quantity'] as num?)?.toDouble(),
      discountRate: (map['discount_rate'] as num?)?.toDouble(),
      freeProductId: map['free_product_id'] as String?,
      freeQuantity: (map['free_quantity'] as num?)?.toDouble(),
      basketMinAmount: (map['basket_min_amount'] as num?)?.toDouble(),
    );
  }
}
