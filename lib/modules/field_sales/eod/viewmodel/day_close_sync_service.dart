// Dosya Adı: day_close_sync_service.dart
// Açıklama: Gün sonu plaka/km kaydını sync_queue + audit_log'a yazar
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:uuid/uuid.dart';

import '../../other/model/day_status_record.dart';

/// {@template day_close_enqueue}
/// Sync kuyruğuna gün sonu kaydı ekleme imzası.
/// {@endtemplate}
typedef DayCloseEnqueue = Future<void> Function({
  required String entityType,
  required String entityId,
  Map<String, dynamic>? payload,
  int priority,
});

/// {@template day_close_write_audit}
/// Audit log yazma imzası.
/// {@endtemplate}
typedef DayCloseWriteAudit = Future<void> Function({
  required String action,
  String? tableName,
  String? recordId,
  Map<String, dynamic>? oldValues,
  Map<String, dynamic>? newValues,
  String? userId,
});

/// {@template day_close_resolve_user_id}
/// Aktif oturumdan kullanıcı id çözümleme imzası.
/// {@endtemplate}
typedef DayCloseResolveUserId = Future<String?> Function();

/// {@template day_close_sync_service}
/// Gün bitirme sonrası plaka/km bilgisini offline sync + denetim kaydına alır.
///
/// Kullanım örneği:
/// ```dart
/// await DayCloseSyncService(
///   enqueue: myEnqueue,
///   writeAudit: myAudit,
///   resolveUserId: () async => session?['id'] as String?,
/// ).recordClose(record: closed, previous: open);
/// ```
/// {@endtemplate}
class DayCloseSyncService {
  /// [entityType]: sync_queue entity_type
  static const String entityType = 'day_close';

  /// [auditAction]: audit_log action
  static const String auditAction = 'day_close';

  /// [auditTable]: audit_log table_name
  static const String auditTable = 'day_status';

  /// [enqueue]: Sync kuyruğu yazıcı (zorunlu)
  final DayCloseEnqueue enqueue;

  /// [writeAudit]: Audit log yazıcı (zorunlu)
  final DayCloseWriteAudit writeAudit;

  /// [resolveUserId]: Oturumdan kullanıcı id (üretimde getUserSession)
  final DayCloseResolveUserId? resolveUserId;

  /// {@macro day_close_sync_service}
  const DayCloseSyncService({
    required this.enqueue,
    required this.writeAudit,
    this.resolveUserId,
  });

  /// {@template day_close_sync_service_record_close}
  /// Plaka/km ile gün kapanışını kuyruk + audit olarak kaydeder.
  ///
  /// Parametreler:
  /// - [record]: Kapanmış gün kaydı
  /// - [previous]: Önceki durum (audit old_values)
  /// - [userId]: Override; verilmezse [resolveUserId] / oturum kullanılır
  ///
  /// Dönüş değeri:
  /// - [String]: sync/audit entity id
  /// {@endtemplate}
  Future<String> recordClose({
    required DayStatusRecord record,
    DayStatusRecord? previous,
    String? userId,
  }) async {
    final entityId = const Uuid().v4();
    final payload = record.toSyncPayload();
    final resolvedUserId = userId ??
        (resolveUserId != null ? await resolveUserId!() : null);

    await enqueue(
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      priority: 1,
    );

    await writeAudit(
      action: auditAction,
      tableName: auditTable,
      recordId: entityId,
      oldValues: previous?.toSyncPayload(),
      newValues: payload,
      userId: resolvedUserId,
    );

    return entityId;
  }
}
