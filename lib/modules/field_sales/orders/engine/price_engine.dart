import '../../../../service/database_service.dart';
import '../model/price_list_model.dart';

class PriceEngine {
  static Future<double> getPrice({
    required String customerId,
    required String productId,
    String? unitName,
    required double defaultPrice,
  }) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      // 1. Find active price list for customer
      final maps = await db.query(
        'customer_price_maps',
        where: 'customer_id = ? AND is_active = 1',
        whereArgs: [customerId],
        limit: 1,
      );

      if (maps.isEmpty) return defaultPrice;

      final priceListId = maps.first['price_list_id'] as String;

      // 2. Find price for specific product and unit in that list
      String where = 'price_list_id = ? AND product_id = ?';
      List<dynamic> whereArgs = [priceListId, productId];
      
      if (unitName != null) {
        where += ' AND unit_name = ?';
        whereArgs.add(unitName);
      }

      final items = await db.query(
        'price_list_items',
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );

      if (items.isNotEmpty) {
        return (items.first['price'] as num).toDouble();
      }

      // 3. Fallback: If unit was specified but not found, try without unit (main list price)
      if (unitName != null) {
        final mainUnitPrices = await db.query(
          'price_list_items',
          where: 'price_list_id = ? AND product_id = ? AND unit_name IS NULL',
          whereArgs: [priceListId, productId],
          limit: 1,
        );
        if (mainUnitPrices.isNotEmpty) {
          return (mainUnitPrices.first['price'] as num).toDouble();
        }
      }

      return defaultPrice;
    } catch (e) {
      print('PriceEngine Error: $e');
      return defaultPrice;
    }
  }
}
