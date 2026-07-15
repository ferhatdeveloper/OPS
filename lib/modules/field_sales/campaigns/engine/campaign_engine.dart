import '../model/campaign_model.dart';

class CampaignEngine {
  static final CampaignEngine _instance = CampaignEngine._internal();
  factory CampaignEngine() => _instance;
  CampaignEngine._internal();

  /// Validates if a campaign is applicable given the current time and context.
  bool isCampaignValid(CampaignModel campaign) {
    return campaign.isCurrentlyActive;
  }

  /// Calculates the benefits of a campaign for a given set of order items.
  /// Returns a Map containing discounts or free items to be added.
  CampaignResult applyCampaign(CampaignModel campaign, List<OrderItem> items) {
    if (!isCampaignValid(campaign)) {
      return CampaignResult.empty();
    }

    double totalDiscount = 0;
    List<FreeItem> freeItems = [];
    double orderTotal = items.fold(0, (sum, item) => sum + (item.price * item.quantity));

    for (var rule in campaign.rules) {
      if (campaign.type == CampaignType.basketDiscount && rule.basketMinAmount != null) {
        if (orderTotal >= rule.basketMinAmount!) {
          totalDiscount += orderTotal * (rule.discountRate ?? 0) / 100;
        }
      } else if (campaign.type == CampaignType.discount && rule.discountRate != null) {
        if (rule.productId != null) {
          final matchingItems = items.where((i) => i.productId == rule.productId);
          for (var item in matchingItems) {
            if (item.quantity >= rule.minQuantity && (rule.maxQuantity == null || item.quantity <= rule.maxQuantity!)) {
              totalDiscount += (item.price * item.quantity) * (rule.discountRate! / 100);
            }
          }
        }
      } else if (campaign.type == CampaignType.freeProduct && rule.freeProductId != null) {
        final matchingItems = items.where((i) => i.productId == rule.productId);
        double totalQty = matchingItems.fold(0, (sum, item) => sum + item.quantity);
        
        if (totalQty >= rule.minQuantity && (rule.maxQuantity == null || totalQty <= rule.maxQuantity!)) {
          int multiplier = (totalQty / rule.minQuantity).floor();
          freeItems.add(FreeItem(
            productId: rule.freeProductId!,
            quantity: rule.freeQuantity! * multiplier,
          ));
        }
      }
    }

    return CampaignResult(
      campaignId: campaign.id,
      totalDiscount: totalDiscount,
      freeItems: freeItems,
    );
  }
}

// Helper classes for campaign processing
class OrderItem {
  final String productId;
  final double quantity;
  final double price;

  OrderItem({required this.productId, required this.quantity, required this.price});
}

class FreeItem {
  final String productId;
  final String? productName;
  final double quantity;

  FreeItem({required this.productId, this.productName, required this.quantity});
}

class CampaignResult {
  final String campaignId;
  final double totalDiscount;
  final List<FreeItem> freeItems;

  CampaignResult({
    required this.campaignId,
    this.totalDiscount = 0,
    this.freeItems = const [],
  });

  factory CampaignResult.empty() => CampaignResult(campaignId: '');
  
  bool get hasBenefit => totalDiscount > 0 || freeItems.isNotEmpty;
}
