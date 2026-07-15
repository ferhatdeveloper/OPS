import 'package:flutter/foundation.dart';
import 'database_service.dart';

class ForecastingService {
  static final ForecastingService _instance = ForecastingService._internal();
  factory ForecastingService() => _instance;
  ForecastingService._internal();

  /// Returns suggested products for a specific customer
  Future<List<Map<String, dynamic>>> getSuggestions(String customerId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    final results = await db.query(
      'ai_suggestions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );

    if (results.isEmpty) {
      // Fallback: Return top moving products for the region/segment (Mock)
      return [
        {
          'product_id': 'P001',
          'product_name': 'Coca Cola 2.5L',
          'suggested_qty': 10,
          'reason': 'Haftalık ortalama tüketim',
          'confidence': 0.85
        },
        {
          'product_id': 'P002',
          'product_name': 'Fanta 2.5L',
          'suggested_qty': 5,
          'reason': 'Sezonluk talep artışı',
          'confidence': 0.72
        }
      ];
    }

    return results;
  }

  /// In a real production environment, this would call a Python/ML backend
  /// for high-accuracy predictions.
  Future<void> updateLocalModels() async {
    debugPrint('Forecasting: Syncing ML weights from server...');
  }
}
