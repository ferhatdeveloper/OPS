import 'package:flutter/foundation.dart';
import 'database_service.dart';

class AssetTrackingService {
  static final AssetTrackingService _instance = AssetTrackingService._internal();
  factory AssetTrackingService() => _instance;
  AssetTrackingService._internal();

  Future<void> logAssetCheck({
    required String assetId,
    required String customerId,
    required String status, // 'OK', 'DAMAGED', 'MISSING'
    String? note,
  }) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    await db.insert('asset_tracking_logs', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'asset_id': assetId,
      'customer_id': customerId,
      'status': status,
      'note': note,
      'checked_at': DateTime.now().toIso8601String(),
    });

    debugPrint('Asset: Checked \$assetId at customer \$customerId - Status: \$status');
  }

  /// Returns list of assets assigned to a customer
  Future<List<Map<String, dynamic>>> getCustomerAssets(String customerId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    // In a real app, there would be an 'assets' table
    return [
      {'id': 'REF-001', 'type': 'Soğutucu', 'model': 'Vestel V-300'},
      {'id': 'ST-005', 'type': 'Stand', 'model': 'Promosyon Standı'},
    ];
  }
}
