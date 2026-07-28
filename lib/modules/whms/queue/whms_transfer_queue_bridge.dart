// Dosya Adı: whms_transfer_queue_bridge.dart
// Açıklama: Onaylı ambar fişi → emir store + JobQueue (WHMS Faz 2.2 / P0 E)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../../core/services/logo_payload_mapper.dart';
import '../../../service/job_queue_service.dart';
import '../bridge/whms_transfer_order_bridge.dart';
import '../contract/whms_bridge_dto.dart';
import '../mapper/whms_payload_mapper.dart';
import '../viewmodel/whms_order_store.dart';

/// {@template whms_transfer_enqueue_result}
/// Kuyruk sonucu: enqueued / skipped / failed.
/// {@endtemplate}
enum WhmsTransferEnqueueStatus {
  /// [enqueued]: ONAY=1 ve kuyruğa yazıldı
  enqueued,

  /// [skipped]: ONAY≠1 (pending/reject…)
  skipped,

  /// [failed]: enqueue hatası
  failed,
}

/// {@template whms_transfer_enqueue_outcome}
/// Köprü çağrı sonucu.
/// {@endtemplate}
class WhmsTransferEnqueueOutcome {
  /// [status]: Sonuç durumu
  final WhmsTransferEnqueueStatus status;

  /// [entityId]: Kuyruk entity id (batch)
  final String? entityId;

  /// [error]: Hata metni (opsiyonel)
  final String? error;

  /// {@macro whms_transfer_enqueue_outcome}
  const WhmsTransferEnqueueOutcome({
    required this.status,
    this.entityId,
    this.error,
  });
}

/// {@template whms_transfer_queue_bridge}
/// Yalnız **approved** transferleri Logo/WHMS sync kuyruğuna yazar.
///
/// Kullanım örneği:
/// ```dart
/// final r = await WhmsTransferQueueBridge.enqueueIfApproved(dto);
/// ```
/// {@endtemplate}
class WhmsTransferQueueBridge {
  /// [enqueueFn]: Test için enjekte edilebilir kuyruk
  final Future<void> Function({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int priority,
  }) enqueueFn;

  /// [orderStore]: Emir omurgası (A API); null → varsayılan store
  final WhmsOrderStore orderStore;

  /// [mirrorOrder]: false ise yalnız JobQueue (regresyon / test)
  final bool mirrorOrder;

  /// {@macro whms_transfer_queue_bridge}
  WhmsTransferQueueBridge({
    Future<void> Function({
      required String entityType,
      required String entityId,
      required Map<String, dynamic> payload,
      int priority,
    })? enqueueFn,
    WhmsOrderStore? orderStore,
    this.mirrorOrder = true,
  })  : orderStore = orderStore ?? const WhmsOrderStore(),
        enqueueFn = enqueueFn ??
            (({
              required entityType,
              required entityId,
              required payload,
              priority = 1,
            }) =>
                JobQueueService().enqueue(
                  entityType: entityType,
                  entityId: entityId,
                  payload: payload,
                  priority: priority,
                ));

  /// {@template whms_transfer_queue_bridge_enqueue_if_approved}
  /// ONAY=1 ise mapper payload + stock_transfer kuyruğu.
  ///
  /// Parametreler:
  /// - [dto]: Ambar transfer DTO
  /// - [priority]: Kuyruk önceliği
  ///
  /// Dönüş değeri:
  /// - [WhmsTransferEnqueueOutcome]: enqueued / skipped / failed
  /// {@endtemplate}
  Future<WhmsTransferEnqueueOutcome> enqueueIfApproved(
    WhmsWarehouseTransferDto dto, {
    int priority = 1,
  }) async {
    if (dto.approval != WhmsApprovalStatus.approved) {
      return WhmsTransferEnqueueOutcome(
        status: WhmsTransferEnqueueStatus.skipped,
        entityId: dto.id,
      );
    }

    try {
      // P0 E: önce emir omurgası (type=transfer), sonra Logo kuyruk
      if (mirrorOrder) {
        await WhmsTransferOrderBridge.mirrorApproved(
          dto: dto,
          store: orderStore,
        );
      }
      final payload = WhmsPayloadMapper.warehouseTransferToPayload(dto);
      // Logo mapper entity sabiti ile uyum
      payload['entity'] = LogoPayloadMapper.stockTransferEntityType;
      await enqueueFn(
        entityType: LogoPayloadMapper.stockTransferEntityType,
        entityId: dto.id,
        payload: payload,
        priority: priority,
      );
      return WhmsTransferEnqueueOutcome(
        status: WhmsTransferEnqueueStatus.enqueued,
        entityId: dto.id,
      );
    } catch (e) {
      return WhmsTransferEnqueueOutcome(
        status: WhmsTransferEnqueueStatus.failed,
        entityId: dto.id,
        error: e.toString(),
      );
    }
  }

  /// {@template whms_transfer_queue_bridge_from_dens}
  /// Dens submit alanlarından approved DTO üretip kuyruğa yazar.
  ///
  /// Parametreler:
  /// - [batchId]: Batch id
  /// - [fromWarehouse]: Kaynak
  /// - [toWarehouse]: Hedef
  /// - [date]: Tarih
  /// - [transferIds]: Yerel id listesi
  /// - [lines]: Köprü satırları
  ///
  /// Dönüş değeri:
  /// - [WhmsTransferEnqueueOutcome]
  /// {@endtemplate}
  Future<WhmsTransferEnqueueOutcome> enqueueApprovedFromDens({
    required String batchId,
    required String fromWarehouse,
    required String toWarehouse,
    required DateTime date,
    required List<String> transferIds,
    required List<WhmsBridgeLine> lines,
  }) {
    final dto = WhmsWarehouseTransferDto(
      id: batchId,
      fromWarehouseCode: fromWarehouse,
      toWarehouseCode: toWarehouse,
      date: date,
      lines: lines,
      transferIds: transferIds,
      approval: WhmsApprovalStatus.approved,
    );
    return enqueueIfApproved(dto);
  }
}
