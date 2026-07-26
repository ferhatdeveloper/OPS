// Dosya Adı: day_close_sync_defaults.dart
// Açıklama: Gün sonu sync/audit için JobQueue + SQLite varsayılan bağları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import 'day_close_sync_service.dart';

/// {@template create_default_day_close_sync_service}
/// Üretim ortamı DayCloseSyncService (sync_queue + audit_log).
///
/// Kullanım örneği:
/// ```dart
/// final svc = createDefaultDayCloseSyncService();
/// await svc.recordClose(record: closed);
/// ```
/// {@endtemplate}
DayCloseSyncService createDefaultDayCloseSyncService() {
  return DayCloseSyncService(
    enqueue: ({
      required String entityType,
      required String entityId,
      Map<String, dynamic>? payload,
      int priority = 0,
    }) {
      return JobQueueService().enqueue(
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        priority: priority,
      );
    },
    resolveUserId: () async {
      final dbService = await DatabaseService.getInstance();
      final session = await dbService.getUserSession();
      final raw = session?['id'];
      if (raw == null) return null;
      final id = raw.toString().trim();
      return id.isEmpty ? null : id;
    },
    writeAudit: ({
      required String action,
      String? tableName,
      String? recordId,
      Map<String, dynamic>? oldValues,
      Map<String, dynamic>? newValues,
      String? userId,
    }) async {
      final dbService = await DatabaseService.getInstance();
      final db = await dbService.getDatabase();
      await db.execute(SqlQuerys.createAuditLogTable);
      await db.insert('audit_log', {
        'user_id': userId,
        'action': action,
        'table_name': tableName,
        'record_id': recordId,
        'old_values': oldValues != null ? jsonEncode(oldValues) : null,
        'new_values': newValues != null ? jsonEncode(newValues) : null,
        'created_at': DateTime.now().toIso8601String(),
      });
    },
  );
}
