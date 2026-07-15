// Dosya Adı: performance_service.dart
// Açıklama: Yerel KPI hesaplama ve performans servisi
// Oluşturulma Tarihi: 2024-03-21
// Geliştirici: Ferhat NAS

import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'data_cache_service.dart';

/// {@template performance_service}
/// Yerel KPI hesaplama ve performans servisi.
/// {@endtemplate}
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final _cache = DataCacheService();

  /// Günlük ziyaret tamamlama oranını hesaplar
  Future<double> getDailyVisitCompletionRate() async {
    return _cache.getOrFetch('daily_visit_completion', () async {
      try {
        final dbService = await DatabaseService.getInstance();
        final db = await dbService.getDatabase();
        
        final today = DateTime.now().toIso8601String().split('T')[0];
        
        final totalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM routes WHERE date(scheduled_at) = ?',
          [today],
        );
        final total = totalResult.first['count'] as int? ?? 0;
        
        if (total == 0) return 0.0;
        
        final completedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM visits WHERE date(check_out_time) = ? AND status = "completed"',
          [today],
        );
        final completed = completedResult.first['count'] as int? ?? 0;
        
        return (completed / total) * 100;
      } catch (e) {
        debugPrint('KPI Calculation Error (Visit Completion): $e');
        return 0.0;
      }
    }, ttl: const Duration(minutes: 15));
  }

  /// Ortalama ziyaret süresini hesaplar (dakika)
  Future<double> getAverageVisitDuration() async {
    return _cache.getOrFetch('avg_visit_duration', () async {
      try {
        final dbService = await DatabaseService.getInstance();
        final db = await dbService.getDatabase();
        
        final result = await db.rawQuery('''
          SELECT AVG((strftime('%s', check_out_time) - strftime('%s', check_in_time)) / 60.0) as avg_duration 
          FROM visits 
          WHERE check_in_time IS NOT NULL AND check_out_time IS NOT NULL
        ''');
        
        return (result.first['avg_duration'] as num?)?.toDouble() ?? 0.0;
      } catch (e) {
        debugPrint('KPI Calculation Error (Avg Duration): $e');
        return 0.0;
      }
    }, ttl: const Duration(hours: 1));
  }

  /// Shelf-Share (SOS) trendlerini hesaplar
  Future<List<Map<String, dynamic>>> getShelfShareTrends() async {
    return _cache.getOrFetch('sos_trends', () async {
      try {
        final dbService = await DatabaseService.getInstance();
        final db = await dbService.getDatabase();
        
        // Basit trend sorgusu - son 7 gün
        final results = await db.rawQuery('''
          SELECT date(completed_at) as sync_date, AVG(CAST(answer_value AS FLOAT)) as avg_sos
          FROM visit_audits va
          JOIN audit_answers aa ON va.id = aa.audit_id
          WHERE aa.field_id LIKE '%sos%' OR aa.field_id LIKE '%shelf_share%'
          GROUP BY date(completed_at)
          ORDER BY sync_date DESC
          LIMIT 7
        ''');
        
        return results;
      } catch (e) {
        debugPrint('KPI Calculation Error (SOS Trends): $e');
        return [];
      }
    }, ttl: const Duration(hours: 2));
  }

  /// Performans verilerini temizler
  void invalidateKPIs() {
    _cache.invalidate('daily_visit_completion');
    _cache.invalidate('avg_visit_duration');
    _cache.invalidate('sos_trends');
  }
}
