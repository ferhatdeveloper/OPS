// Dosya Adı: whms_count_session.dart
// Açıklama: Sayım oturumu — taslak satır persist + tamamla ONAY/kuyruk
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../../service/database_service.dart';
import '../../contract/whms_bridge_dto.dart';
import '../../data/local_warehouse_stock_balance_port.dart';
import '../model/whms_count_order.dart';
import '../model/whms_count_result_line.dart';
import '../queue/whms_count_queue_bridge.dart';
import 'whms_count_order_store.dart';
import 'whms_count_result_store.dart';

/// {@template whms_count_complete_outcome}
/// Tamamla sonucu: sonuç satırı + kuyruk durumu.
/// {@endtemplate}
class WhmsCountCompleteOutcome {
  /// [result]: Onaylı sonuç satırı
  final WhmsCountResultRow result;

  /// [enqueue]: JobQueue sonucu
  final WhmsCountEnqueueOutcome enqueue;

  /// {@macro whms_count_complete_outcome}
  const WhmsCountCompleteOutcome({
    required this.result,
    required this.enqueue,
  });
}

/// {@template whms_count_session}
/// Sayım emri üzerinde satır biriktirme + SQLite taslak + tamamla.
///
/// Kullanım örneği:
/// ```dart
/// final session = WhmsCountSession();
/// await session.saveDraft(order: order, lines: lines);
/// await session.complete(order: order, lines: lines);
/// ```
/// {@endtemplate}
class WhmsCountSession {
  /// Emir store
  final WhmsCountOrderStore orderStore;

  /// Sonuç store
  final WhmsCountResultStore resultStore;

  /// Kuyruk köprüsü
  final WhmsCountQueueBridge bridge;

  /// DB açıcı (test)
  final Future<Database> Function()? openDb;

  /// {@macro whms_count_session}
  WhmsCountSession({
    WhmsCountOrderStore? orderStore,
    WhmsCountResultStore? resultStore,
    WhmsCountQueueBridge? bridge,
    this.openDb,
  })  : orderStore = orderStore ?? const WhmsCountOrderStore(),
        resultStore = resultStore ?? const WhmsCountResultStore(),
        bridge = bridge ?? WhmsCountQueueBridge();

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template whms_count_session_system_qty}
  /// Yerel ambar bakiyesi (sistem miktarı).
  ///
  /// Parametreler:
  /// - [productId]: Ürün id
  /// - [warehouseCode]: Ambar
  ///
  /// Dönüş değeri:
  /// - [double]: Sistem qty (yoksa 0)
  /// {@endtemplate}
  Future<double> systemQtyFor({
    required String productId,
    required String warehouseCode,
  }) async {
    final id = productId.trim();
    final wh = warehouseCode.trim();
    if (id.isEmpty || wh.isEmpty) return 0;
    try {
      final db = await _db();
      final bal = await LocalWarehouseStockBalancePort(db).getBalance(
        productId: id,
        warehouseCode: wh,
      );
      return bal.quantity;
    } catch (_) {
      return 0;
    }
  }

  /// Taslak satırları yükle (yoksa boş).
  Future<({String? resultId, List<WhmsCountResultLine> lines})>
      loadDraftLines(String orderId) async {
    final row = await resultStore.findByOrderId(orderId);
    if (row == null) {
      return (resultId: null, lines: <WhmsCountResultLine>[]);
    }
    return (
      resultId: row.id,
      lines: WhmsCountResultStore.parseLines(row.linesJson),
    );
  }

  /// {@template whms_count_session_save_draft}
  /// Devam eden sayımı SQLite’a yazar; emri inProgress yapar.
  /// {@endtemplate}
  Future<WhmsCountResultRow> saveDraft({
    required WhmsCountOrder order,
    required List<WhmsCountResultLine> lines,
    String? existingResultId,
  }) async {
    if (order.status == WhmsCountOrderStatus.draft ||
        order.status == WhmsCountOrderStatus.assigned) {
      await orderStore.updateStatus(
        id: order.id,
        status: WhmsCountOrderStatus.inProgress,
      );
    }
    return resultStore.upsertDraft(
      order: order,
      lines: lines,
      existingId: existingResultId,
    );
  }

  /// {@template whms_count_session_complete}
  /// Fiili satırları kaydet → ONAY=1 → stock_count JobQueue.
  ///
  /// Parametreler:
  /// - [order]: Emir
  /// - [lines]: Sayım satırları
  /// - [existingResultId]: Taslak sonuç id
  ///
  /// Dönüş değeri:
  /// - [WhmsCountCompleteOutcome]
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: Satır yok / emir tamamlanmış
  /// {@endtemplate}
  Future<WhmsCountCompleteOutcome> complete({
    required WhmsCountOrder order,
    required List<WhmsCountResultLine> lines,
    String? existingResultId,
  }) async {
    if (order.status == WhmsCountOrderStatus.completed ||
        order.status == WhmsCountOrderStatus.cancelled) {
      throw StateError('whms.count.already_done');
    }
    if (lines.isEmpty) {
      throw StateError('whms.count.lines_required');
    }

    final draft = await resultStore.upsertDraft(
      order: order,
      lines: lines,
      existingId: existingResultId,
    );
    await resultStore.setApproval(
      id: draft.id,
      approval: WhmsApprovalStatus.approved,
    );
    await orderStore.updateStatus(
      id: order.id,
      status: WhmsCountOrderStatus.completed,
      approval: WhmsApprovalStatus.approved,
    );

    final approved = WhmsCountResultRow(
      id: draft.id,
      orderId: draft.orderId,
      warehouseCode: draft.warehouseCode,
      locationCode: draft.locationCode,
      countDate: draft.countDate,
      varianceQty: draft.varianceQty,
      approval: WhmsApprovalStatus.approved,
      linesJson: draft.linesJson,
    );

    final dto = WhmsCountResultDto(
      id: approved.id,
      orderId: order.id,
      warehouseCode: order.warehouseCode,
      locationCode: order.locationCode,
      date: DateTime.tryParse(approved.countDate) ?? DateTime.now(),
      lines: lines.map((l) => l.toBridgeLine()).toList(growable: false),
      approval: WhmsApprovalStatus.approved,
    );

    final enqueue = await bridge.enqueueIfApproved(
      dto,
      varianceLines: lines,
    );
    return WhmsCountCompleteOutcome(result: approved, enqueue: enqueue);
  }
}
