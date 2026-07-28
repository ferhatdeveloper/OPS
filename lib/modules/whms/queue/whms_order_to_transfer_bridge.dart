// Dosya Adı: whms_order_to_transfer_bridge.dart
// Açıklama: Emir (transfer) → WhmsWarehouseTransferDto → TransferQueueBridge
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../contract/whms_bridge_dto.dart';
import '../mapper/whms_payload_mapper.dart';
import 'whms_transfer_queue_bridge.dart';

/// {@template whms_order_to_transfer_bridge}
/// `order_type=transfer` emrini onaylıysa ambar transfer kuyruğuna yazar.
///
/// Model [WhmsOrderDto] zorunlu değil; named params veya emir map yeter.
///
/// Kullanım örneği:
/// ```dart
/// final r = await WhmsOrderToTransferBridge().enqueueFromParams(
///   orderId: 'wo1',
///   fromWh: 'MRK',
///   toWh: 'IAD',
///   date: DateTime(2026, 7, 28),
///   lines: const [],
///   approval: WhmsApprovalStatus.approved,
/// );
/// ```
/// {@endtemplate}
class WhmsOrderToTransferBridge {
  /// SQLite / JSON emir tipi kodu
  static const String orderTypeTransfer = 'transfer';

  /// [transferBridge]: Test için enjekte edilebilir kuyruk köprüsü
  final WhmsTransferQueueBridge transferBridge;

  /// {@macro whms_order_to_transfer_bridge}
  WhmsOrderToTransferBridge({
    WhmsTransferQueueBridge? transferBridge,
  }) : transferBridge = transferBridge ??
            WhmsTransferQueueBridge(
              // Emir zaten store’da — dens mirror tekrarlanmaz
              mirrorOrder: false,
            );

  /// {@template whms_order_to_transfer_bridge_enqueue_from_params}
  /// Named params ile transfer DTO üretip [enqueueIfApproved] çağırır.
  ///
  /// Parametreler:
  /// - [orderId]: Emir / batch id
  /// - [fromWh]: Kaynak ambar
  /// - [toWh]: Hedef ambar
  /// - [date]: Emir tarihi
  /// - [lines]: Köprü satırları
  /// - [approval]: ONAY durumu
  /// - [transferIds]: Yerel transfer id listesi (opsiyonel)
  /// - [priority]: Kuyruk önceliği
  ///
  /// Dönüş değeri:
  /// - [WhmsTransferEnqueueOutcome]: enqueued / skipped / failed
  /// {@endtemplate}
  Future<WhmsTransferEnqueueOutcome> enqueueFromParams({
    required String orderId,
    required String fromWh,
    required String toWh,
    required DateTime date,
    required List<WhmsBridgeLine> lines,
    WhmsApprovalStatus approval = WhmsApprovalStatus.pending,
    List<String> transferIds = const [],
    int priority = 1,
  }) {
    if (approval != WhmsApprovalStatus.approved) {
      return Future.value(
        WhmsTransferEnqueueOutcome(
          status: WhmsTransferEnqueueStatus.skipped,
          entityId: orderId,
        ),
      );
    }

    final dto = WhmsWarehouseTransferDto(
      id: orderId,
      fromWarehouseCode: fromWh,
      toWarehouseCode: toWh,
      date: date,
      lines: lines,
      transferIds: transferIds,
      approval: approval,
    );
    return transferBridge.enqueueIfApproved(dto, priority: priority);
  }

  /// {@template whms_order_to_transfer_bridge_enqueue_from_order_map}
  /// Emir map veya satır listesinden köprü.
  /// `order_type` ≠ transfer veya ONAY≠1 → skipped.
  ///
  /// Parametreler:
  /// - [order]: Emir header map (`id`, `order_type`, `from_warehouse_code`…)
  /// - [lines]: Açık satır listesi; yoksa `order['lines']` parse edilir
  /// - [priority]: Kuyruk önceliği
  ///
  /// Dönüş değeri:
  /// - [WhmsTransferEnqueueOutcome]
  /// {@endtemplate}
  Future<WhmsTransferEnqueueOutcome> enqueueFromOrderMap(
    Map<String, dynamic> order, {
    List<WhmsBridgeLine>? lines,
    int priority = 1,
  }) {
    final orderId = order['id']?.toString() ?? '';
    final orderType = (order['order_type'] ?? order['orderType'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (orderType != orderTypeTransfer) {
      return Future.value(
        WhmsTransferEnqueueOutcome(
          status: WhmsTransferEnqueueStatus.skipped,
          entityId: orderId.isEmpty ? null : orderId,
          error: 'order_type must be transfer',
        ),
      );
    }

    final approval = _approvalFromOrderMap(order);
    final resolvedLines = lines ?? _linesFromRaw(order['lines']);
    final fromWh = (order['from_warehouse_code'] ??
            order['fromWarehouseCode'] ??
            order['warehouse_code'] ??
            order['warehouseCode'] ??
            '')
        .toString();
    final toWh = (order['to_warehouse_code'] ??
            order['toWarehouseCode'] ??
            '')
        .toString();
    final date = _parseDate(
          order['order_date'] ?? order['orderDate'] ?? order['date'],
        ) ??
        DateTime.now();
    final transferIds = _stringListFromRaw(
      order['transfer_ids'] ?? order['transferIds'],
    );

    return enqueueFromParams(
      orderId: orderId,
      fromWh: fromWh,
      toWh: toWh,
      date: date,
      lines: resolvedLines,
      approval: approval,
      transferIds: transferIds,
      priority: priority,
    );
  }

  /// {@template whms_order_to_transfer_bridge_enqueue_if_transfer_dto}
  /// Hazır [WhmsWarehouseTransferDto] ile kuyruk (onay kontrolü içeride).
  ///
  /// Parametreler:
  /// - [dto]: Ambar transfer DTO
  /// - [priority]: Kuyruk önceliği
  ///
  /// Dönüş değeri:
  /// - [WhmsTransferEnqueueOutcome]
  /// {@endtemplate}
  Future<WhmsTransferEnqueueOutcome> enqueueIfTransferDto(
    WhmsWarehouseTransferDto dto, {
    int priority = 1,
  }) {
    if (dto.approval != WhmsApprovalStatus.approved) {
      return Future.value(
        WhmsTransferEnqueueOutcome(
          status: WhmsTransferEnqueueStatus.skipped,
          entityId: dto.id,
        ),
      );
    }
    return transferBridge.enqueueIfApproved(dto, priority: priority);
  }

  static WhmsApprovalStatus _approvalFromOrderMap(Map<String, dynamic> order) {
    final rawOnay = order['ONAY'] ?? order['approval'];
    if (rawOnay is WhmsApprovalStatus) return rawOnay;
    if (rawOnay is num) {
      return WhmsPayloadMapper.approvalFromInt(rawOnay.toInt());
    }
    if (rawOnay is String) {
      final asInt = int.tryParse(rawOnay.trim());
      if (asInt != null) {
        return WhmsPayloadMapper.approvalFromInt(asInt);
      }
      final v = rawOnay.trim().toLowerCase();
      if (v == 'approved') return WhmsApprovalStatus.approved;
      if (v == 'synced') return WhmsApprovalStatus.synced;
      if (v == 'rejected') return WhmsApprovalStatus.rejected;
      if (v == 'error') return WhmsApprovalStatus.error;
    }
    return WhmsApprovalStatus.pending;
  }

  static List<WhmsBridgeLine> _linesFromRaw(Object? raw) {
    if (raw is! List) return const [];
    final out = <WhmsBridgeLine>[];
    for (final e in raw) {
      if (e is WhmsBridgeLine) {
        out.add(e);
        continue;
      }
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      out.add(
        WhmsBridgeLine(
          productId: (m['product_id'] ?? m['productId'] ?? '').toString(),
          productCode: (m['product_code'] ??
                  m['productCode'] ??
                  m['MASTER_CODE'] ??
                  '')
              .toString(),
          quantity: (m['quantity'] as num?)?.toDouble() ??
              (m['QUANTITY'] as num?)?.toDouble() ??
              0,
          unitName: (m['unit_name'] ?? m['unitName'])?.toString(),
        ),
      );
    }
    return out;
  }

  static List<String> _stringListFromRaw(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}
