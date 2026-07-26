// Dosya Adı: day_close_sync_service_test.dart
// Açıklama: Gün sonu plaka/km → sync_queue + audit_log kayıt testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/eod/viewmodel/day_close_sync_service.dart';
import 'package:exfin_ops/modules/field_sales/other/model/day_status_record.dart';

void main() {
  group('DayStatusRecord.toSyncPayload', () {
    test('plaka / km / tamamlandı alanlarını taşır', () {
      final end = DateTime(2026, 7, 26, 18, 0);
      final record = DayStatusRecord(
        plate: '34 MBT 01',
        startKm: 1000,
        endKm: 1125,
        completed: true,
        isDayStarted: false,
        startTime: DateTime(2026, 7, 26, 8, 0),
        endTime: end,
      );

      final payload = record.toSyncPayload();
      expect(payload['entity_type'], DayCloseSyncService.entityType);
      expect(payload['plate'], '34 MBT 01');
      expect(payload['start_km'], 1000);
      expect(payload['end_km'], 1125);
      expect(payload['completed'], true);
      expect(payload['end_time'], end.toIso8601String());
    });
  });

  group('DayCloseSyncService.recordClose', () {
    DayStatusRecord previous() => DayStatusRecord(
          plate: '34 MBT 01',
          startKm: 1000,
          completed: false,
          isDayStarted: true,
          startTime: DateTime(2026, 7, 26, 8, 0),
        );

    DayStatusRecord closed(DayStatusRecord prev) => DayStatusRecord(
          plate: '34 MBT 01',
          startKm: 1000,
          endKm: 1125,
          completed: true,
          isDayStarted: false,
          startTime: prev.startTime,
          endTime: DateTime(2026, 7, 26, 18, 0),
        );

    DayCloseSyncService buildService({
      required void Function(Map<String, dynamic>) onEnqueue,
      required void Function(Map<String, dynamic>) onAudit,
      DayCloseResolveUserId? resolveUserId,
    }) {
      return DayCloseSyncService(
        enqueue: ({
          required String entityType,
          required String entityId,
          Map<String, dynamic>? payload,
          int priority = 0,
        }) async {
          onEnqueue({
            'entity_type': entityType,
            'entity_id': entityId,
            'payload': payload,
            'priority': priority,
          });
        },
        writeAudit: ({
          required String action,
          String? tableName,
          String? recordId,
          Map<String, dynamic>? oldValues,
          Map<String, dynamic>? newValues,
          String? userId,
        }) async {
          onAudit({
            'action': action,
            'table_name': tableName,
            'record_id': recordId,
            'old_values': oldValues,
            'new_values': newValues,
            'user_id': userId,
          });
        },
        resolveUserId: resolveUserId,
      );
    }

    test('sync_queue enqueue + audit_log yazar', () async {
      Map<String, dynamic>? enqueued;
      Map<String, dynamic>? audited;
      final prev = previous();
      final next = closed(prev);

      final service = buildService(
        onEnqueue: (m) => enqueued = m,
        onAudit: (m) => audited = m,
        resolveUserId: () async => 'plasiyer-1',
      );

      final id = await service.recordClose(
        record: next,
        previous: prev,
      );

      expect(id, isNotEmpty);
      expect(enqueued!['entity_type'], DayCloseSyncService.entityType);
      expect(enqueued!['entity_id'], id);
      expect(enqueued!['payload']['plate'], '34 MBT 01');
      expect(enqueued!['payload']['end_km'], 1125);
      expect(enqueued!['priority'], 1);

      expect(audited!['action'], DayCloseSyncService.auditAction);
      expect(audited!['table_name'], DayCloseSyncService.auditTable);
      expect(audited!['record_id'], id);
      expect(audited!['user_id'], 'plasiyer-1');
      expect(audited!['old_values']['plate'], '34 MBT 01');
      expect(audited!['old_values']['end_km'], isNull);
      expect(audited!['new_values']['end_km'], 1125);
      expect(audited!['new_values']['completed'], true);
    });

    test('userId oturumdan (resolveUserId) gelir', () async {
      Map<String, dynamic>? audited;
      final prev = previous();

      final service = buildService(
        onEnqueue: (_) {},
        onAudit: (m) => audited = m,
        resolveUserId: () async => 'session-user-42',
      );

      await service.recordClose(record: closed(prev), previous: prev);

      expect(audited!['user_id'], 'session-user-42');
    });

    test('açık userId override, oturumu ezer', () async {
      Map<String, dynamic>? audited;
      final prev = previous();

      final service = buildService(
        onEnqueue: (_) {},
        onAudit: (m) => audited = m,
        resolveUserId: () async => 'session-user-42',
      );

      await service.recordClose(
        record: closed(prev),
        previous: prev,
        userId: 'explicit-override',
      );

      expect(audited!['user_id'], 'explicit-override');
    });
  });
}
