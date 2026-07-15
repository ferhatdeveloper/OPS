import 'package:flutter/foundation.dart';
import 'database_service.dart';

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  Future<void> recordExpense({
    required String type, // 'FUEL', 'FOOD', 'PARKING', 'OTHER'
    required double amount,
    String? photoPath,
    String? note,
  }) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    await db.insert('expenses', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'amount': amount,
      'photo_path': photoPath,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    });

    debugPrint('Expense: Recorded \$type expense of \$amount ');
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses() async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await db.query(
      'expenses',
      where: "created_at LIKE ?",
      whereArgs: ['\$today%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<double> getTotalDailyExpense() async {
    final expenses = await getDailyExpenses();
    return expenses.fold<double>(0.0, (double sum, item) => sum + (item['amount'] as num).toDouble());
  }
}
