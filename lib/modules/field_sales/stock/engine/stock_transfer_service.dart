import 'package:uuid/uuid.dart';
import '../../../../service/database_service.dart';
import '../model/stock_transfer_model.dart';

class StockTransferService {
  static Future<bool> createTransfer(StockTransferModel transfer) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();

      await db.transaction((txn) async {
        // 1. Insert transfer record
        await txn.insert('warehouse_transfers', transfer.toMap());

        // 2. Adjust stocks (If it's a direct movement between vehicles/warehouses)
        // Note: In many ERPs, this happens on the server after approval.
        // For local SFA, we might want to deduct immediately for better local tracking.
      });

      return true;
    } catch (e) {
      print('StockTransferService Error: $e');
      return false;
    }
  }

  static Future<List<StockTransferModel>> getTransfers() async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      
      final results = await db.rawQuery('''
        SELECT t.*, p.name as product_name, p.code as product_code 
        FROM warehouse_transfers t
        LEFT JOIN products p ON t.product_id = p.id
        ORDER BY t.transfer_date DESC
      ''');
      
      return results.map((r) => StockTransferModel.fromMap(r)).toList();
    } catch (e) {
      print('StockTransferService Error: $e');
      return [];
    }
  }
}
