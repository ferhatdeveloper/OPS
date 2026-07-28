// Dosya Adı: whms_count_queue_bridge.dart
// Açıklama: Onaylı merkez sayım sonucu → JobQueue (stock_count)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../../../service/job_queue_service.dart';
import '../../contract/whms_bridge_dto.dart';
import '../../mapper/whms_payload_mapper.dart';
import '../model/whms_count_result_line.dart';

/// {@template whms_count_enqueue_status}
/// Sayım kuyruk sonucu: enqueued / skipped / failed.
/// {@endtemplate}
enum WhmsCountEnqueueStatus {
  /// [enqueued]: ONAY=1 ve kuyruğa yazıldı
  enqueued,

  /// [skipped]: ONAY≠1
  skipped,

  /// [failed]: enqueue hatası
  failed,
}

/// {@template whms_count_enqueue_outcome}
/// Sayım köprü çağrı sonucu.
/// {@endtemplate}
class WhmsCountEnqueueOutcome {
  /// [status]: Sonuç durumu
  final WhmsCountEnqueueStatus status;

  /// [entityId]: Kuyruk entity id
  final String? entityId;

  /// [error]: Hata metni (opsiyonel)
  final String? error;

  /// {@macro whms_count_enqueue_outcome}
  const WhmsCountEnqueueOutcome({
    required this.status,
    this.entityId,
    this.error,
  });
}

/// {@template whms_count_result_queue_wrapper}
/// `WhmsCountResultDto` genişletilmez — kuyruk payload sarmalayıcı.
///
/// Kullanım örneği:
/// ```dart
/// final w = WhmsCountResultQueueWrapper(dto);
/// final payload = w.toPayload();
/// ```
/// {@endtemplate}
class WhmsCountResultQueueWrapper {
  /// [dto]: Merkez sayım sonucu (contract; genişletilmez)
  final WhmsCountResultDto dto;

  /// [varianceLines]: Opsiyonel fark satırları (count klasörü modeli)
  final List<WhmsCountResultLine> varianceLines;

  /// {@macro whms_count_result_queue_wrapper}
  const WhmsCountResultQueueWrapper(
    this.dto, {
    this.varianceLines = const [],
  });

  /// JobQueue entity — LogoPayloadMapper’da sayım sabiti yok
  static const String entityType = 'stock_count';

  /// Yerel fiş tipi
  static const String slipType = 'stock_count';

  /// {@template whms_count_result_queue_wrapper_to_payload}
  /// Minimal stock_count queue gövdesi (Logo sayım mapper yok).
  ///
  /// Dönüş değeri:
  /// - [Map]: JobQueue payload
  /// {@endtemplate}
  Map<String, dynamic> toPayload() {
    final lineMaps = varianceLines.isNotEmpty
        ? varianceLines.map((l) => l.toMap()).toList(growable: false)
        : dto.lines.map((l) => l.toMap()).toList(growable: false);
    final base = WhmsPayloadMapper.countResultToPayload(dto);
    return <String, dynamic>{
      ...base,
      'lines': lineMaps,
      'items': lineMaps,
    };
  }
}

/// {@template whms_count_queue_bridge}
/// Yalnız **approved** sayım sonuçlarını Logo/WHMS sync kuyruğuna yazar.
///
/// Entity: `stock_count` (OPS plasiyer sayım ile aynı tip; merkez DTO ayrı).
/// LogoPayloadMapper’da sayım sabiti yok → wrapper minimal payload.
///
/// Kullanım örneği:
/// ```dart
/// final r = await WhmsCountQueueBridge().enqueueIfApproved(dto);
/// ```
/// {@endtemplate}
class WhmsCountQueueBridge {
  /// JobQueue entity — merkez / plasiyer sayım
  static const String entityType = WhmsCountResultQueueWrapper.entityType;

  /// [enqueueFn]: Test için enjekte edilebilir kuyruk
  final Future<void> Function({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int priority,
  }) enqueueFn;

  /// {@macro whms_count_queue_bridge}
  WhmsCountQueueBridge({
    Future<void> Function({
      required String entityType,
      required String entityId,
      required Map<String, dynamic> payload,
      int priority,
    })? enqueueFn,
  }) : enqueueFn = enqueueFn ??
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

  /// {@template whms_count_queue_bridge_enqueue_if_approved}
  /// ONAY=1 ise sayım payload + stock_count kuyruğu.
  ///
  /// Parametreler:
  /// - [dto]: Merkez sayım sonucu
  /// - [varianceLines]: Opsiyonel fark satırları
  /// - [priority]: Kuyruk önceliği
  ///
  /// Dönüş değeri:
  /// - [WhmsCountEnqueueOutcome]: enqueued / skipped / failed
  /// {@endtemplate}
  Future<WhmsCountEnqueueOutcome> enqueueIfApproved(
    WhmsCountResultDto dto, {
    List<WhmsCountResultLine> varianceLines = const [],
    int priority = 1,
  }) {
    return enqueueWrapperIfApproved(
      WhmsCountResultQueueWrapper(dto, varianceLines: varianceLines),
      priority: priority,
    );
  }

  /// {@template whms_count_queue_bridge_enqueue_wrapper}
  /// Wrapper üzerinden ONAY=1 kuyruk yazımı.
  /// {@endtemplate}
  Future<WhmsCountEnqueueOutcome> enqueueWrapperIfApproved(
    WhmsCountResultQueueWrapper wrapper, {
    int priority = 1,
  }) async {
    final dto = wrapper.dto;
    if (dto.approval != WhmsApprovalStatus.approved) {
      return WhmsCountEnqueueOutcome(
        status: WhmsCountEnqueueStatus.skipped,
        entityId: dto.id,
      );
    }

    try {
      final payload = wrapper.toPayload();
      await enqueueFn(
        entityType: entityType,
        entityId: dto.id,
        payload: payload,
        priority: priority,
      );
      return WhmsCountEnqueueOutcome(
        status: WhmsCountEnqueueStatus.enqueued,
        entityId: dto.id,
      );
    } catch (e) {
      return WhmsCountEnqueueOutcome(
        status: WhmsCountEnqueueStatus.failed,
        entityId: dto.id,
        error: e.toString(),
      );
    }
  }
}
