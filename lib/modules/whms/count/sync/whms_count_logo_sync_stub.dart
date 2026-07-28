// Dosya Adı: whms_count_logo_sync_stub.dart
// Açıklama: Merkez sayım → Logo REST sync stub (P0; canlı fiş yok)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../contract/whms_bridge_dto.dart';
import '../queue/whms_count_queue_bridge.dart';

/// {@template whms_count_logo_sync_status}
/// Logo sayım sync sonucu (stub).
/// {@endtemplate}
enum WhmsCountLogoSyncStatus {
  /// [queued]: ONAY=1 → JobQueue’ya yazıldı
  queued,

  /// [skipped]: ONAY≠1
  skipped,

  /// [stubOnly]: Canlı Logo fiş çağrısı yok (iskelet)
  stubOnly,

  /// [failed]: Hata
  failed,
}

/// {@template whms_count_logo_sync_result}
/// Stub sync çağrı sonucu.
/// {@endtemplate}
class WhmsCountLogoSyncResult {
  /// [status]: Sonuç
  final WhmsCountLogoSyncStatus status;

  /// [message]: Açıklama
  final String message;

  /// [entityId]: Sayım id
  final String? entityId;

  /// {@macro whms_count_logo_sync_result}
  const WhmsCountLogoSyncResult({
    required this.status,
    required this.message,
    this.entityId,
  });
}

/// {@template whms_count_logo_sync_stub}
/// Logo sayım fazla/eksik fişi henüz REST’e bağlı değil.
/// Onaylı sonuçları [WhmsCountQueueBridge] ile offline kuyruğa bırakır.
///
/// Kullanım örneği:
/// ```dart
/// final r = await WhmsCountLogoSyncStub().syncIfApproved(dto);
/// ```
/// {@endtemplate}
class WhmsCountLogoSyncStub {
  /// [bridge]: Enjekte edilebilir kuyruk köprüsü
  final WhmsCountQueueBridge bridge;

  /// {@macro whms_count_logo_sync_stub}
  WhmsCountLogoSyncStub({WhmsCountQueueBridge? bridge})
      : bridge = bridge ?? WhmsCountQueueBridge();

  /// {@template whms_count_logo_sync_stub_sync}
  /// ONAY=1 ise kuyruğa yazar; Logo REST çağrısı yapmaz (stub).
  ///
  /// Parametreler:
  /// - [dto]: Merkez sayım sonucu
  ///
  /// Dönüş değeri:
  /// - [WhmsCountLogoSyncResult]
  /// {@endtemplate}
  Future<WhmsCountLogoSyncResult> syncIfApproved(
    WhmsCountResultDto dto,
  ) async {
    final outcome = await bridge.enqueueIfApproved(dto);
    switch (outcome.status) {
      case WhmsCountEnqueueStatus.skipped:
        return WhmsCountLogoSyncResult(
          status: WhmsCountLogoSyncStatus.skipped,
          message: 'ONAY≠1 — sayım kuyruğa alınmadı',
          entityId: dto.id,
        );
      case WhmsCountEnqueueStatus.failed:
        return WhmsCountLogoSyncResult(
          status: WhmsCountLogoSyncStatus.failed,
          message: outcome.error ?? 'enqueue failed',
          entityId: dto.id,
        );
      case WhmsCountEnqueueStatus.enqueued:
        return WhmsCountLogoSyncResult(
          status: WhmsCountLogoSyncStatus.stubOnly,
          message:
              'stock_count kuyruğa yazıldı; Logo sayım fişi REST stub',
          entityId: dto.id,
        );
    }
  }
}
