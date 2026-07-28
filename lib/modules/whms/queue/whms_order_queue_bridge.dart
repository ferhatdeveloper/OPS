// Dosya Adı: whms_order_queue_bridge.dart
// Açıklama: Emir ONAY=1 tüm tipler → tip bazlı JobQueue
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../../service/job_queue_service.dart';
import '../contract/whms_bridge_dto.dart';
import '../mapper/whms_payload_mapper.dart';
import '../model/whms_order_dto.dart';
import '../model/whms_order_type.dart';
import '../viewmodel/whms_order_store.dart';
import 'whms_order_to_transfer_bridge.dart';
import 'whms_transfer_queue_bridge.dart';

/// {@template whms_order_enqueue_status}
/// Emir kuyruk sonucu: enqueued / skipped / failed.
/// {@endtemplate}
enum WhmsOrderEnqueueStatus {
  /// [enqueued]: ONAY=1 ve kuyruğa yazıldı
  enqueued,

  /// [skipped]: ONAY≠1
  skipped,

  /// [failed]: enqueue hatası
  failed,
}

/// {@template whms_order_enqueue_outcome}
/// Emir kuyruk çağrı sonucu.
/// {@endtemplate}
class WhmsOrderEnqueueOutcome {
  /// [status]: Sonuç durumu
  final WhmsOrderEnqueueStatus status;

  /// [entityId]: Kuyruk entity id
  final String? entityId;

  /// [entityType]: JobQueue entity_type
  final String? entityType;

  /// [error]: Hata metni (opsiyonel)
  final String? error;

  /// {@macro whms_order_enqueue_outcome}
  const WhmsOrderEnqueueOutcome({
    required this.status,
    this.entityId,
    this.entityType,
    this.error,
  });
}

/// {@template whms_order_queue_bridge}
/// **Tüm** emir tiplerinde ONAY=1 → tip bazlı JobQueue.
///
/// Entity:
/// - transfer → `stock_transfer`
/// - sayim → `stock_count`
/// - load → `whms_load_order`
/// - diğer → `whms_order_{wire}`
///
/// Kullanım örneği:
/// ```dart
/// final r = await WhmsOrderQueueBridge().enqueueIfApproved(order);
/// ```
/// {@endtemplate}
class WhmsOrderQueueBridge {
  /// [enqueueFn]: Test için enjekte edilebilir kuyruk
  final Future<void> Function({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int priority,
  }) enqueueFn;

  /// [orderStore]: approveAndEnqueue için (opsiyonel)
  final WhmsOrderStore orderStore;

  /// {@macro whms_order_queue_bridge}
  WhmsOrderQueueBridge({
    Future<void> Function({
      required String entityType,
      required String entityId,
      required Map<String, dynamic> payload,
      int priority,
    })? enqueueFn,
    WhmsOrderStore? orderStore,
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

  /// {@template whms_order_queue_bridge_enqueue_if_approved}
  /// ONAY=1 ise tip bazlı payload + JobQueue.
  ///
  /// Parametreler:
  /// - [order]: Emir DTO
  /// - [priority]: Kuyruk önceliği
  ///
  /// Dönüş değeri:
  /// - [WhmsOrderEnqueueOutcome]
  /// {@endtemplate}
  Future<WhmsOrderEnqueueOutcome> enqueueIfApproved(
    WhmsOrderDto order, {
    int priority = 1,
  }) async {
    if (order.approval != WhmsApprovalStatus.approved) {
      return WhmsOrderEnqueueOutcome(
        status: WhmsOrderEnqueueStatus.skipped,
        entityId: order.id,
        entityType: WhmsPayloadMapper.entityTypeForOrder(order.orderType),
      );
    }

    final entityType =
        WhmsPayloadMapper.entityTypeForOrder(order.orderType);
    try {
      final payload = orderToPayload(order);
      payload['entity'] = entityType;
      await enqueueFn(
        entityType: entityType,
        entityId: order.id,
        payload: payload,
        priority: priority,
      );
      return WhmsOrderEnqueueOutcome(
        status: WhmsOrderEnqueueStatus.enqueued,
        entityId: order.id,
        entityType: entityType,
      );
    } catch (e) {
      return WhmsOrderEnqueueOutcome(
        status: WhmsOrderEnqueueStatus.failed,
        entityId: order.id,
        entityType: entityType,
        error: e.toString(),
      );
    }
  }

  /// {@template whms_order_queue_bridge_order_to_payload}
  /// Tip bazlı JobQueue gövdesi (mapper uzman payload + genel fallback).
  /// {@endtemplate}
  static Map<String, dynamic> orderToPayload(WhmsOrderDto order) {
    final entity = WhmsPayloadMapper.entityTypeForOrder(order.orderType);

    if (order.orderType == WhmsOrderType.transfer) {
      final transfer = order.toTransferDto();
      if (transfer != null) {
        final payload =
            WhmsPayloadMapper.warehouseTransferToPayload(transfer);
        payload['entity'] = entity;
        return payload;
      }
    }
    if (order.orderType == WhmsOrderType.load) {
      final load = order.toLoadOrderDto();
      if (load != null) {
        final payload = WhmsPayloadMapper.loadOrderToPayload(load);
        payload['entity'] = entity;
        return payload;
      }
    }
    if (order.orderType == WhmsOrderType.sayim) {
      final count = order.toCountResultDto();
      if (count != null) {
        final payload = WhmsPayloadMapper.countResultToPayload(count);
        payload['entity'] = entity;
        return payload;
      }
    }

    final lines =
        order.lines.map((l) => l.toMap()).toList(growable: false);
    final header = order.toMap();
    return <String, dynamic>{
      ...header,
      'entity': entity,
      'type': entity,
      'order_type': order.orderType.wireName,
      'warehouse': order.warehouseCode,
      'SOURCE_WH': order.fromWarehouseCode ?? order.warehouseCode,
      'TARGET_WH': order.toWarehouseCode,
      'date': order.orderDate,
      'lines': lines,
      'items': lines,
    };
  }

  /// {@template whms_order_queue_bridge_approve_and_enqueue}
  /// Store ONAY=1 + hemen kuyruk.
  ///
  /// Parametreler:
  /// - [orderId]: Emir id
  /// - [priority]: Kuyruk önceliği
  ///
  /// Dönüş değeri:
  /// - [WhmsOrderEnqueueOutcome]
  /// {@endtemplate}
  Future<WhmsOrderEnqueueOutcome> approveAndEnqueue(
    String orderId, {
    int priority = 1,
  }) async {
    final updated = await orderStore.setApproval(
      orderId,
      WhmsApprovalStatus.approved,
    );
    if (updated == null) {
      return WhmsOrderEnqueueOutcome(
        status: WhmsOrderEnqueueStatus.failed,
        entityId: orderId,
        error: 'order not found',
      );
    }
    return enqueueIfApproved(updated, priority: priority);
  }

  /// {@template whms_order_queue_bridge_from_order_map}
  /// Emir map → DTO parse değil; transfer tipi için mevcut köprüye delege.
  /// Genel tiplerde minimal DTO + enqueue.
  ///
  /// Not: transfer için [WhmsOrderToTransferBridge] tercih edilebilir;
  /// bu metot tek giriş noktası sağlar.
  /// {@endtemplate}
  Future<WhmsOrderEnqueueOutcome> enqueueFromOrderMap(
    Map<String, dynamic> order, {
    int priority = 1,
  }) async {
    final orderType = (order['order_type'] ?? order['orderType'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (orderType == WhmsOrderToTransferBridge.orderTypeTransfer) {
      final transferOutcome =
          await WhmsOrderToTransferBridge(
        transferBridge: WhmsTransferQueueBridge(
          mirrorOrder: false,
          enqueueFn: enqueueFn,
        ),
      ).enqueueFromOrderMap(order, priority: priority);
      return _fromTransferOutcome(transferOutcome);
    }

    final dto = WhmsOrderDto.fromMap(
      order,
      lines: const [],
    );
    return enqueueIfApproved(dto, priority: priority);
  }

  static WhmsOrderEnqueueOutcome _fromTransferOutcome(
    WhmsTransferEnqueueOutcome o,
  ) {
    switch (o.status) {
      case WhmsTransferEnqueueStatus.enqueued:
        return WhmsOrderEnqueueOutcome(
          status: WhmsOrderEnqueueStatus.enqueued,
          entityId: o.entityId,
          entityType: WhmsPayloadMapper.stockTransferEntityType,
        );
      case WhmsTransferEnqueueStatus.skipped:
        return WhmsOrderEnqueueOutcome(
          status: WhmsOrderEnqueueStatus.skipped,
          entityId: o.entityId,
          entityType: WhmsPayloadMapper.stockTransferEntityType,
        );
      case WhmsTransferEnqueueStatus.failed:
        return WhmsOrderEnqueueOutcome(
          status: WhmsOrderEnqueueStatus.failed,
          entityId: o.entityId,
          entityType: WhmsPayloadMapper.stockTransferEntityType,
          error: o.error,
        );
    }
  }
}
