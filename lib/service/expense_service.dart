// Dosya Adı: expense_service.dart
// Açıklama: Plasiyer günlük masraf — SQLite expenses CRUD
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/database/migrations/SqlQuerys.dart';
import 'database_service.dart';

/// {@template expense_service}
/// Günlük masraf kaydı (FUEL / FOOD / PARKING / OTHER).
///
/// Kullanım örneği:
/// ```dart
/// await ExpenseService().recordExpense(type: 'FUEL', amount: 100);
/// ```
/// {@endtemplate}
class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();

  /// {@macro expense_service}
  factory ExpenseService() => _instance;

  ExpenseService._internal();

  /// {@template expense_service_record}
  /// Masrafı yerel `expenses` tablosuna yazar.
  ///
  /// Parametreler:
  /// - [type]: FUEL | FOOD | PARKING | OTHER
  /// - [amount]: Tutar (> 0)
  /// - [photoPath]: Opsiyonel fiş foto
  /// - [note]: Açıklama
  /// {@endtemplate}
  Future<void> recordExpense({
    required String type,
    required double amount,
    String? photoPath,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Tutar > 0 olmalı');
    }

    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    await db.execute(SqlQuerys.createExpensesTable);

    await db.insert('expenses', {
      'id': const Uuid().v4(),
      'type': type.trim().toUpperCase(),
      'amount': amount,
      'photo_path': photoPath,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    });

    debugPrint('Expense: Recorded $type expense of $amount');
  }

  /// {@template expense_service_get_daily}
  /// Bugünkü masraf satırlarını döndürür.
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> getDailyExpenses() async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    await db.execute(SqlQuerys.createExpensesTable);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    return db.query(
      'expenses',
      where: 'created_at LIKE ?',
      whereArgs: ['$today%'],
      orderBy: 'created_at DESC',
    );
  }

  /// {@template expense_service_get_total_daily}
  /// Bugünkü masraf toplamı.
  /// {@endtemplate}
  Future<double> getTotalDailyExpense() async {
    final expenses = await getDailyExpenses();
    return expenses.fold<double>(
      0.0,
      (double sum, item) => sum + (item['amount'] as num).toDouble(),
    );
  }
}
