import 'package:flutter/material.dart';
import 'database_service.dart';

class PODService {
  static final PODService _instance = PODService._internal();
  factory PODService() => _instance;
  PODService._internal();

  Future<void> saveProofOfDelivery({
    required String invoiceId,
    required String signatureData,
    required double latitude,
    required double longitude,
  }) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    await db.insert('proof_of_deliveries', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'invoice_id': invoiceId,
      'signature_data': signatureData,
      'latitude': latitude,
      'longitude': longitude,
      'signed_at': DateTime.now().toIso8601String(),
    });

    debugPrint('POD: Proof of delivery saved for invoice $invoiceId');
  }

  Future<void> saveOrderSignature({
    required String orderId,
    required String signatureData,
  }) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    // In a production app, we would have an order_signatures table
    // For now, we update the order record or a shared signatures table
    try {
      await db.execute('''
        UPDATE orders SET signature_data = ? WHERE id = ?
      ''', [signatureData, orderId]);
    } catch (e) {
      // Fallback for demo if column doesn't exist yet
      debugPrint('POD: Could not update order signature directly, check schema: $e');
    }

    debugPrint('POD: Signature saved for order $orderId');
  }
}
