import 'package:flutter/foundation.dart';
import 'database_service.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  /// Constants for point values
  static const int pointsPerVisit = 10;
  static const int pointsPerInvoice = 50;
  static const int pointsPerNewCustomer = 100;
  static const int pointsPerAudit = 30;

  Future<void> addPoints(String userId, int amount, String reason) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();

    await db.execute('''
      UPDATE plasiyer_profile 
      SET total_points = total_points + ?, 
          last_achievement = ? 
      WHERE id = ?
    ''', [amount, reason, userId]);

    debugPrint('Gamification: Added $amount points for $userId ($reason)');
    _checkLevelUp();
  }

  Future<Map<String, dynamic>> getPlayerStats(String userId) async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    final result = await db.query('plasiyer_profile', where: "id = ?", whereArgs: [userId]);
    if (result.isNotEmpty) {
      final data = result.first;
      final points = (data['total_points'] as num?)?.toInt() ?? 0;
      // Simple level calculation: 1000 points per level
      final level = (points / 1000).floor() + 1;
      
      return {
        'points': points,
        'level': level,
        'last_achievement': data['last_achievement'] ?? 'Yok',
      };
    }
    return {'points': 0, 'level': 1, 'last_achievement': 'Yok'};
  }

  Future<Map<String, dynamic>> getStats() async {
    final dbService = await DatabaseService.getInstance();
    final db = await dbService.getDatabase();
    
    final result = await db.query('plasiyer_profile', where: "id = 'current_user'");
    if (result.isNotEmpty) {
      return result.first;
    }
    return {'total_points': 0, 'last_achievement': 'Yok'};
  }

  void _checkLevelUp() {
    // Logic to trigger a notification when milestones are reached
  }

  /// Returns a mock leaderboard for the dashboard
  List<Map<String, dynamic>> getMockLeaderboard() {
    return [
      {'name': 'Ahmet Yılmaz', 'points': 2450, 'rank': 1},
      {'name': 'Caner Aksoy', 'points': 2100, 'rank': 2},
      {'name': 'Sen (EXFINOPS)', 'points': 1850, 'rank': 3},
      {'name': 'Mehmet Demir', 'points': 1400, 'rank': 4},
    ];
  }
}
