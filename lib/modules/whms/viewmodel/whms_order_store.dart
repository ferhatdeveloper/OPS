// Dosya Adı: whms_order_store.dart
// Açıklama: whms_orders / whms_order_lines SQLite CRUD + ONAY / yaşam döngüsü
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/migrations/SqlQuerys.dart';
import '../../../service/database_service.dart';
import '../contract/whms_bridge_dto.dart';
import '../devices/viewmodel/whms_terminal_session.dart';
import '../model/whms_order_dto.dart';
import '../model/whms_order_line_dto.dart';
import '../model/whms_order_status.dart';
import '../model/whms_order_type.dart';
import '../model/whms_orders_table.dart';
import '../pick/engine/whms_pick_serial_rule.dart';
import '../pick/viewmodel/whms_product_serial_rule_store.dart';

/// {@template whms_order_store}
/// Emir header + satır persist; UI yazmaz.
///
/// Kullanım örneği:
/// ```dart
/// final store = WhmsOrderStore();
/// await store.ensureReady();
/// final rows = await store.list(type: WhmsOrderType.malKabul);
/// ```
/// {@endtemplate}
class WhmsOrderStore {
  /// [openDb]: Test için DB açıcı
  final Future<Database> Function()? openDb;

  /// [productSerialStore]: Pick seri ürün kuralı
  final WhmsProductSerialRuleStore productSerialStore;

  /// {@macro whms_order_store}
  const WhmsOrderStore({
    this.openDb,
    this.productSerialStore = const WhmsProductSerialRuleStore(),
  });

  /// [ordersTable]: Header tablo
  static const String ordersTable = WhmsOrdersTable.name;

  /// [linesTable]: Satır tablo
  static const String linesTable = WhmsOrderLinesTable.name;

  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template whms_order_store_ensure}
  /// Tabloları oluşturur; eksik kolonları ekler.
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createWhmsOrdersTable);
    await db.execute(SqlQuerys.createWhmsOrderLinesTable);
    await _ensureOrderColumns(db);
    await _ensureLineColumns(db);
  }

  /// {@template whms_order_store_list}
  /// Soft-delete edilmemiş emirler (satırlarla).
  ///
  /// Parametreler:
  /// - [type]: Tip filtresi
  /// - [status]: Durum filtresi
  /// - [includeLines]: Satırları yükle
  ///
  /// Dönüş değeri:
  /// - [List<WhmsOrderDto>]: Emirler
  /// {@endtemplate}
  Future<List<WhmsOrderDto>> list({
    WhmsOrderType? type,
    WhmsOrderStatus? status,
    bool includeLines = true,
  }) async {
    await ensureReady();
    final db = await _db();
    final where = <String>['COALESCE(is_deleted, 0) = 0'];
    final args = <Object?>[];
    if (type != null) {
      where.add('order_type = ?');
      args.add(type.wireName);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.wireName);
    }
    final maps = await db.query(
      ordersTable,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'order_date DESC, updated_at DESC, id ASC',
    );
    if (!includeLines) {
      return maps
          .map((m) => WhmsOrderDto.fromMap(m))
          .toList(growable: false);
    }
    final out = <WhmsOrderDto>[];
    for (final m in maps) {
      final id = m['id']?.toString() ?? '';
      final lines = await loadLines(id);
      out.add(WhmsOrderDto.fromMap(m, lines: lines));
    }
    return out;
  }

  /// {@template whms_order_store_get_by_id}
  /// Tek emir + satırlar; yoksa null.
  /// {@endtemplate}
  Future<WhmsOrderDto?> getById(String id) async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      ordersTable,
      where: 'id = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final lines = await loadLines(id);
    return WhmsOrderDto.fromMap(maps.first, lines: lines);
  }

  /// {@template whms_order_store_load_lines}
  /// Emir satırlarını yükler.
  /// {@endtemplate}
  Future<List<WhmsOrderLineDto>> loadLines(String orderId) async {
    await ensureReady();
    final db = await _db();
    final maps = await db.query(
      linesTable,
      where: 'order_id = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: <Object?>[orderId],
      orderBy: 'line_no ASC, id ASC',
    );
    return maps
        .map(WhmsOrderLineDto.fromMap)
        .toList(growable: false);
  }

  /// {@template whms_order_store_upsert}
  /// Header + satırları txn ile yazar (replace).
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: mal_kabul satırında lokasyon eksik
  /// - [StateError]: pick tamamlanırken seri eksik
  /// {@endtemplate}
  Future<WhmsOrderDto> upsert(WhmsOrderDto order) async {
    await ensureReady();
    if (!order.linesSatisfyLocation) {
      throw StateError(
        'whms.order_error.location_required',
      );
    }
    if (order.status == WhmsOrderStatus.done &&
        order.orderType == WhmsOrderType.pick) {
      await _assertPickSerialComplete(order);
    }
    final now = DateTime.now().toIso8601String();
    final header = order.copyWith(
      createdAt: order.createdAt.isEmpty ? now : order.createdAt,
      updatedAt: now,
    );
    final db = await _db();
    await db.transaction((txn) async {
      await txn.insert(
        ordersTable,
        header.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        linesTable,
        where: 'order_id = ?',
        whereArgs: <Object?>[header.id],
      );
      var lineNo = 0;
      for (final raw in header.lines) {
        lineNo = raw.lineNo > 0 ? raw.lineNo : lineNo + 1;
        final line = raw.copyWith(
          orderId: header.id,
          lineNo: lineNo,
          createdAt: raw.createdAt ?? now,
          updatedAt: now,
        );
        await txn.insert(
          linesTable,
          line.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    return (await getById(header.id)) ?? header;
  }

  /// {@template whms_order_store_create_draft}
  /// Yeni taslak emir oluşturur.
  /// {@endtemplate}
  Future<WhmsOrderDto> createDraft({
    required WhmsOrderType orderType,
    String? warehouseCode,
    String? fromWarehouseCode,
    String? toWarehouseCode,
    String? toVehicleId,
    String? assignedUserId,
    String? deviceId,
    String? referenceNo,
    String? notes,
    bool requireSerial = false,
    String? orderDate,
    List<WhmsOrderLineDto> lines = const [],
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final iso = now.toIso8601String();
    final day = orderDate ?? iso.substring(0, 10);
    final numbered = <WhmsOrderLineDto>[];
    for (var i = 0; i < lines.length; i++) {
      numbered.add(
        lines[i].copyWith(
          id: lines[i].id.isEmpty ? const Uuid().v4() : lines[i].id,
          orderId: id,
          lineNo: lines[i].lineNo > 0 ? lines[i].lineNo : i + 1,
        ),
      );
    }
    return upsert(
      WhmsOrderDto(
        id: id,
        orderType: orderType,
        status: WhmsOrderStatus.draft,
        warehouseCode: warehouseCode,
        fromWarehouseCode: fromWarehouseCode,
        toWarehouseCode: toWarehouseCode,
        toVehicleId: toVehicleId,
        assignedUserId: assignedUserId,
        deviceId: deviceId,
        referenceNo: referenceNo,
        notes: notes,
        requireSerial: requireSerial,
        orderDate: day,
        createdAt: iso,
        updatedAt: iso,
        lines: numbered,
      ),
    );
  }

  /// {@template whms_order_store_update_line_pick}
  /// Pick satırında seri / miktar günceller.
  /// {@endtemplate}
  Future<WhmsOrderDto?> updateLinePickScan({
    required String orderId,
    required String lineId,
    String? serialNo,
    double? quantityDone,
  }) async {
    final current = await getById(orderId);
    if (current == null) return null;
    final now = DateTime.now().toIso8601String();
    final lines = current.lines.map((l) {
      if (l.id != lineId) return l;
      final nextQty = quantityDone ?? l.quantityDone;
      return l.copyWith(
        serialNo: serialNo ?? l.serialNo,
        quantityDone: nextQty,
        updatedAt: now,
      );
    }).toList(growable: false);
    final status = current.status == WhmsOrderStatus.draft ||
            current.status == WhmsOrderStatus.assigned
        ? WhmsOrderStatus.inProgress
        : current.status;
    return upsert(
      current.copyWith(
        status: status,
        updatedAt: now,
        lines: lines,
      ),
    );
  }

  /// {@template whms_order_store_complete_pick}
  /// Pick emrini tamamlar — seri zorunlu satırlar dolu olmalı.
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: [WhmsPickSerialRule.errorSerialRequired]
  /// {@endtemplate}
  Future<WhmsOrderDto?> completePick(String id) async {
    final current = await getById(id);
    if (current == null) return null;
    if (current.orderType != WhmsOrderType.pick) {
      return setStatus(id, WhmsOrderStatus.done);
    }
    await _assertPickSerialComplete(current);
    return setStatus(id, WhmsOrderStatus.done);
  }

  Future<void> _assertPickSerialComplete(WhmsOrderDto order) async {
    final productIds = await productSerialStore.productIdsRequiringSerial(
      order.lines.map((l) => l.productId),
    );
    if (!WhmsPickSerialRule.canCompleteOrder(
      order,
      productIdsRequiringSerial: productIds,
    )) {
      throw StateError(WhmsPickSerialRule.errorSerialRequired);
    }
  }

  /// {@template whms_order_store_advance_status}
  /// Bir sonraki yaşam durumuna geçer (done=completed).
  /// Backoffice; terminal gate yok.
  /// {@endtemplate}
  Future<WhmsOrderDto?> advanceStatus(String id) async {
    final current = await getById(id);
    if (current == null) return null;
    final next = current.status.next;
    if (next == null) return current;
    final now = DateTime.now().toIso8601String();
    return upsert(
      current.copyWith(
        status: next,
        completedAt: next.isTerminal ? now : current.completedAt,
        updatedAt: now,
      ),
    );
  }

  /// {@template whms_order_store_advance_as_terminal}
  /// Terminal yürütme adımı: MAC/rol gate sonra status advance.
  /// `assigned→in_progress` ve `in_progress→done` için zorunlu.
  ///
  /// Parametreler:
  /// - [id]: Emir id
  /// - [session]: Bağlı [WhmsTerminalSession]
  ///
  /// Dönüş değeri:
  /// - [WhmsOrderDto?]: Güncel emir
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: `whms.terminal.*` messageKey
  /// {@endtemplate}
  Future<WhmsOrderDto?> advanceAsTerminal(
    String id,
    WhmsTerminalSession session,
  ) async {
    session.assertReady();
    final current = await getById(id);
    if (current == null) return null;
    final next = current.status.next;
    if (next == null) return current;

    final enteringOrLeavingExecution =
        next == WhmsOrderStatus.inProgress ||
            current.status == WhmsOrderStatus.inProgress;
    if (enteringOrLeavingExecution) {
      session.assertCanExecute(current.orderType);
    }

    final now = DateTime.now().toIso8601String();
    return upsert(
      current.copyWith(
        status: next,
        deviceId: session.deviceId,
        completedAt: next.isTerminal ? now : current.completedAt,
        updatedAt: now,
      ),
    );
  }

  /// {@template whms_order_store_set_status}
  /// Durumu doğrudan set eder.
  /// {@endtemplate}
  Future<WhmsOrderDto?> setStatus(
    String id,
    WhmsOrderStatus status,
  ) async {
    final current = await getById(id);
    if (current == null) return null;
    final now = DateTime.now().toIso8601String();
    return upsert(
      current.copyWith(
        status: status,
        completedAt: status.isTerminal ? now : current.completedAt,
        updatedAt: now,
      ),
    );
  }

  /// {@template whms_order_store_set_approval}
  /// Header ONAY + satır ONAY hizası; ONAY=2 → is_synced.
  /// {@endtemplate}
  Future<WhmsOrderDto?> setApproval(
    String id,
    WhmsApprovalStatus approval,
  ) async {
    final current = await getById(id);
    if (current == null) return null;
    final now = DateTime.now().toIso8601String();
    final synced = approval == WhmsApprovalStatus.synced;
    final lines = current.lines
        .map(
          (l) => l.copyWith(
            approval: approval,
            isSynced: synced,
            updatedAt: now,
          ),
        )
        .toList(growable: false);
    return upsert(
      current.copyWith(
        approval: approval,
        isSynced: synced,
        updatedAt: now,
        lines: lines,
      ),
    );
  }

  /// {@template whms_order_store_apply_receipt_lines}
  /// Mal kabul / putaway satır ilerlemesi (lokasyon + miktar_done).
  /// Durum en az [WhmsOrderStatus.inProgress] olur.
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: emir yok / tip uyumsuz / terminal / lokasyon eksik
  /// {@endtemplate}
  Future<WhmsOrderDto> applyReceiptLines({
    required String orderId,
    required List<WhmsOrderLineDto> lines,
  }) async {
    final current = await _requireReceiptOrder(orderId);
    final now = DateTime.now().toIso8601String();
    final nextStatus = current.status == WhmsOrderStatus.draft ||
            current.status == WhmsOrderStatus.assigned
        ? WhmsOrderStatus.inProgress
        : current.status;
    return upsert(
      current.copyWith(
        status: nextStatus,
        updatedAt: now,
        lines: _normalizeReceiptLines(
          orderId: current.id,
          lines: lines,
          now: now,
        ),
      ),
    );
  }

  /// {@template whms_order_store_confirm_receipt_putaway}
  /// Putaway onayı: tüm satır lokasyon zorunlu → ONAY=1 + status=done.
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: emir yok / tip uyumsuz / terminal / lokasyon eksik
  /// {@endtemplate}
  Future<WhmsOrderDto> confirmReceiptPutaway({
    required String orderId,
    required List<WhmsOrderLineDto> lines,
  }) async {
    final current = await _requireReceiptOrder(orderId);
    final now = DateTime.now().toIso8601String();
    final normalized = _normalizeReceiptLines(
      orderId: current.id,
      lines: lines,
      now: now,
      approval: WhmsApprovalStatus.approved,
    );
    for (final line in normalized) {
      if (!line.hasRequiredLocation(current.orderType)) {
        throw StateError('whms.order_error.location_required');
      }
    }
    if (normalized.isEmpty) {
      throw StateError('whms.order_error.location_required');
    }
    return upsert(
      current.copyWith(
        status: WhmsOrderStatus.done,
        approval: WhmsApprovalStatus.approved,
        completedAt: now,
        updatedAt: now,
        lines: normalized,
      ),
    );
  }

  /// Mal kabul / putaway emri; yoksa / uyumsuzsa hata.
  Future<WhmsOrderDto> _requireReceiptOrder(String orderId) async {
    final current = await getById(orderId);
    if (current == null) {
      throw StateError('whms.order_error.not_found');
    }
    if (current.orderType != WhmsOrderType.malKabul &&
        current.orderType != WhmsOrderType.putaway) {
      throw StateError('whms.order_error.invalid_type');
    }
    if (current.status.isTerminal) {
      throw StateError('whms.order_error.terminal');
    }
    return current;
  }

  List<WhmsOrderLineDto> _normalizeReceiptLines({
    required String orderId,
    required List<WhmsOrderLineDto> lines,
    required String now,
    WhmsApprovalStatus? approval,
  }) {
    final out = <WhmsOrderLineDto>[];
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final loc = (raw.locationCode ?? '').trim();
      out.add(
        WhmsOrderLineDto(
          id: raw.id.isEmpty ? const Uuid().v4() : raw.id,
          orderId: orderId,
          lineNo: raw.lineNo > 0 ? raw.lineNo : i + 1,
          productId: raw.productId,
          productCode: raw.productCode,
          productName: raw.productName,
          quantity: raw.quantity,
          quantityDone: raw.quantityDone,
          unitName: raw.unitName,
          locationCode: loc.isEmpty ? null : loc,
          lotNo: raw.lotNo,
          serialNo: raw.serialNo,
          expiryDate: raw.expiryDate,
          routeSeq: raw.routeSeq,
          approval: approval ?? raw.approval,
          isSynced: raw.isSynced,
          isDeleted: raw.isDeleted,
          createdAt: raw.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }
    return out;
  }

  /// {@template whms_order_store_soft_delete}
  /// Soft delete header (+ satırlar).
  /// {@endtemplate}
  Future<void> softDelete(String id) async {
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        ordersTable,
        <String, Object?>{
          'is_deleted': 1,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      await txn.update(
        linesTable,
        <String, Object?>{
          'is_deleted': 1,
          'updated_at': now,
        },
        where: 'order_id = ?',
        whereArgs: <Object?>[id],
      );
    });
  }

  Future<void> _ensureOrderColumns(Database db) async {
    final cols = await _columnNames(db, ordersTable);
    if (cols.isEmpty) return;
    await _addColIfMissing(
      db,
      ordersTable,
      cols,
      'from_warehouse_code',
      'TEXT',
    );
    await _addColIfMissing(
      db,
      ordersTable,
      cols,
      'reference_no',
      'TEXT',
    );
    await _addColIfMissing(
      db,
      ordersTable,
      cols,
      'completed_at',
      'TEXT',
    );
    await _addColIfMissing(
      db,
      ordersTable,
      cols,
      'require_serial',
      'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _ensureLineColumns(Database db) async {
    final cols = await _columnNames(db, linesTable);
    if (cols.isEmpty) return;
    await _addColIfMissing(
      db,
      linesTable,
      cols,
      'quantity_done',
      'REAL NOT NULL DEFAULT 0',
    );
    await _addColIfMissing(
      db,
      linesTable,
      cols,
      'serial_no',
      'TEXT',
    );
    await _addColIfMissing(
      db,
      linesTable,
      cols,
      'ONAY',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColIfMissing(
      db,
      linesTable,
      cols,
      'is_synced',
      'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<Set<String>> _columnNames(
    Database db,
    String table,
  ) async {
    try {
      final rows = await db.rawQuery('PRAGMA table_info($table)');
      return rows
          .map((r) => r['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _addColIfMissing(
    Database db,
    String table,
    Set<String> cols,
    String name,
    String typeSql,
  ) async {
    if (cols.contains(name)) return;
    try {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN $name $typeSql',
      );
      cols.add(name);
    } catch (_) {
      // Kolon yarış / mevcut — yoksay
    }
  }
}
