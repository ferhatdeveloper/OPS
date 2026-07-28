// Dosya Adı: gamification_service.dart
// Açıklama: Plasiyer puan / seviye — plasiyer_profile CRUD
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/migrations/SqlQuerys.dart';
import 'database_service.dart';

/// {@template gamification_service}
/// Ziyaret / fatura vb. olaylarda plasiyer puanı yazar.
///
/// Tablo yoksa oluşturur; puan yazımı başarısız olsa ziyaret akışını
/// bozmamak için hataları yutar.
///
/// Kullanım örneği:
/// ```dart
/// await GamificationService().addPoints(userId, 10, 'Ziyaret Başlatıldı');
/// ```
/// {@endtemplate}
class GamificationService {
  static final GamificationService _instance = GamificationService._internal();

  /// {@macro gamification_service}
  factory GamificationService() => _instance;

  GamificationService._internal();

  /// Constants for point values
  static const int pointsPerVisit = 10;
  static const int pointsPerInvoice = 50;
  static const int pointsPerNewCustomer = 100;
  static const int pointsPerAudit = 30;

  /// {@template gamification_ensure_schema}
  /// `plasiyer_profile` tablosunu oluşturur; [userId] için satır yoksa seed.
  ///
  /// Parametreler:
  /// - [db]: Açık SQLite bağlantısı
  /// - [userId]: Opsiyonel plasiyer id (seed)
  /// - [displayName]: Opsiyonel görünen ad
  /// {@endtemplate}
  Future<void> ensureSchema(
    Database db, {
    String? userId,
    String? displayName,
  }) async {
    try {
      await db.execute(SqlQuerys.createPlasiyerProfileTable);
      await _ensurePlasiyerProfileColumns(db);
      final id = (userId ?? '').trim();
      if (id.isEmpty) return;

      final existing = await db.query(
        'plasiyer_profile',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isNotEmpty) return;

      await db.insert(
        'plasiyer_profile',
        {
          'id': id,
          'name': (displayName ?? '').trim().isEmpty
              ? id
              : displayName!.trim(),
          'total_points': 0,
          'level': 1,
          'last_achievement': null,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e, st) {
      // Check-in / puan yolu asla şema hatasıyla düşmesin
      debugPrint('Gamification ensureSchema failed (non-blocking): $e\n$st');
    }
  }

  /// {@template gamification_add_points}
  /// Puan ekler; tablo/satır yoksa create+upsert. Hata fırlatmaz.
  ///
  /// Parametreler:
  /// - [userId]: Plasiyer id
  /// - [amount]: Eklenecek puan
  /// - [reason]: last_achievement metni
  /// - [database]: Opsiyonel test DB (yoksa DatabaseService)
  ///
  /// Dönüş değeri:
  /// - [bool]: true = yazıldı; false = atlandı / hata
  /// {@endtemplate}
  Future<bool> addPoints(
    String userId,
    int amount,
    String reason, {
    Database? database,
  }) async {
    try {
      final db = database ??
          await (await DatabaseService.getInstance()).getDatabase();
      await ensureSchema(db, userId: userId);

      final updated = await db.rawUpdate(
        '''
        UPDATE plasiyer_profile
        SET total_points = total_points + ?,
            last_achievement = ?
        WHERE id = ?
        ''',
        [amount, reason, userId],
      );

      if (updated == 0) {
        await db.insert(
          'plasiyer_profile',
          {
            'id': userId,
            'name': userId,
            'total_points': amount,
            'level': 1,
            'last_achievement': reason,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      debugPrint('Gamification: Added $amount points for $userId ($reason)');
      _checkLevelUp();
      return true;
    } catch (e, st) {
      debugPrint('Gamification addPoints failed (non-blocking): $e\n$st');
      return false;
    }
  }

  /// {@template gamification_get_player_stats}
  /// Plasiyer puan / seviye özeti.
  /// {@endtemplate}
  Future<Map<String, dynamic>> getPlayerStats(String userId) async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await ensureSchema(db, userId: userId);

      final result = await db.query(
        'plasiyer_profile',
        where: 'id = ?',
        whereArgs: [userId],
      );
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
    } catch (e) {
      debugPrint('Gamification getPlayerStats failed: $e');
    }
    return {'points': 0, 'level': 1, 'last_achievement': 'Yok'};
  }

  /// {@template gamification_get_stats}
  /// current_user satırı (eski API).
  /// {@endtemplate}
  Future<Map<String, dynamic>> getStats() async {
    try {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await ensureSchema(db, userId: 'current_user');

      final result = await db.query(
        'plasiyer_profile',
        where: "id = 'current_user'",
      );
      if (result.isNotEmpty) {
        return result.first;
      }
    } catch (e) {
      debugPrint('Gamification getStats failed: $e');
    }
    return {'total_points': 0, 'last_achievement': 'Yok'};
  }

  void _checkLevelUp() {
    // Logic to trigger a notification when milestones are reached
  }

  /// PRAGMA ile eksik kolonları ekler (CREATE IF NOT EXISTS yetmez).
  Future<void> _ensurePlasiyerProfileColumns(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(plasiyer_profile)');
      if (columns.isEmpty) return;
      final names = columns
          .map((c) => c['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
      Future<void> add(String sql, String col) async {
        if (names.contains(col)) return;
        try {
          await db.execute(sql);
          names.add(col);
        } catch (_) {}
      }

      await add(
        SqlQuerys.addPlasiyerProfileTotalPointsColumn,
        'total_points',
      );
      await add(SqlQuerys.addPlasiyerProfileLevelColumn, 'level');
      await add(
        SqlQuerys.addPlasiyerProfileLastAchievementColumn,
        'last_achievement',
      );
      await add(SqlQuerys.addPlasiyerProfileCreatedAtColumn, 'created_at');
    } catch (e) {
      debugPrint('Gamification column migrate skipped: $e');
    }
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
