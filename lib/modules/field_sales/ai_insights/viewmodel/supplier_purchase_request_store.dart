// Dosya Adı: supplier_purchase_request_store.dart
// Açıklama: supplier_purchase_requests SQLite CRUD + onay + sync_queue
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../service/database_service.dart';
import '../model/supplier_purchase_request.dart';
import 'supply_request_logo_sync_mapper.dart';

/// {@template supplier_purchase_request_store}
/// Depocu tedarik talep kuyruğu — ONAY + is_synced + sync_queue.
///
/// Kullanım örneği:
/// ```dart
/// final store = SupplierPurchaseRequestStore();
/// await store.ensureReady();
/// final list = await store.listActive();
/// ```
/// {@endtemplate}
class SupplierPurchaseRequestStore {
  /// [uuid]: Id üretici
  final Uuid _uuid;

  /// {@macro supplier_purchase_request_store}
  const SupplierPurchaseRequestStore({Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  static const String tableName = 'supplier_purchase_requests';

  /// Tabloyu oluştur
  Future<void> ensureReady() async {
    final dbService = await DatabaseService.getInstance();
    await dbService.ensureSupplierPurchaseRequestsSchema();
  }

  Future<Database> _db() async {
    final dbService = await DatabaseService.getInstance();
    return dbService.getDatabase();
  }

  /// Aktif (silinmemiş) talepler
  ///
  /// [unsyncedOnly]: true → ONAY=1 ve is_synced=0 (aktarılmayan)
  Future<List<SupplierPurchaseRequest>> listActive({
    String? query,
    bool unsyncedOnly = false,
  }) async {
    await ensureReady();
    final db = await _db();
    final where = StringBuffer('COALESCE(is_deleted, 0) = 0');
    if (unsyncedOnly) {
      where.write(' AND COALESCE(ONAY, 0) = 1 AND COALESCE(is_synced, 0) = 0');
    }
    final rows = await db.query(
      tableName,
      where: where.toString(),
      orderBy: 'updated_at DESC',
    );
    var list = rows
        .map((m) => SupplierPurchaseRequest.fromMap(m))
        .toList(growable: false);
    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (r) =>
                r.productCode.toLowerCase().contains(q) ||
                r.productName.toLowerCase().contains(q) ||
                r.supplierCode.toLowerCase().contains(q) ||
                r.supplierName.toLowerCase().contains(q),
          )
          .toList(growable: false);
    }
    return list;
  }

  /// Onaylı + sync edilmemiş (transfer edilmeyen listesi)
  Future<List<SupplierPurchaseRequest>> listUnsynced() {
    return listActive(unsyncedOnly: true);
  }

  /// Yeni draft talep
  Future<SupplierPurchaseRequest> create({
    required String productId,
    String productCode = '',
    String productName = '',
    required double quantity,
    String? supplierId,
    String supplierCode = '',
    String supplierName = '',
    String warehouseCode = '',
    String notes = '',
    String? createdBy,
  }) async {
    await ensureReady();
    final now = DateTime.now().toIso8601String();
    final row = SupplierPurchaseRequest(
      id: _uuid.v4(),
      productId: productId,
      productCode: productCode,
      productName: productName,
      quantity: quantity,
      supplierId: supplierId,
      supplierCode: supplierCode,
      supplierName: supplierName,
      warehouseCode: warehouseCode,
      status: SupplierPurchaseRequestStatus.draft,
      notes: notes,
      onay: 0,
      isSynced: false,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _db();
    await db.insert(
      tableName,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return row;
  }

  /// Güncelle
  Future<void> update(SupplierPurchaseRequest row) async {
    await ensureReady();
    final db = await _db();
    final next = row.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    await db.update(
      tableName,
      next.toMap(),
      where: 'id = ?',
      whereArgs: [row.id],
    );
  }

  /// Onaya gönder (draft → pending, ONAY=0)
  Future<void> submitForApproval(String id) async {
    await ensureReady();
    final db = await _db();
    await db.update(
      tableName,
      {
        'status':
            SupplierPurchaseRequestStatus.pendingApproval.storageValue,
        'ONAY': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Onayla (ONAY=1, is_synced=0) + sync_queue enqueue
  Future<void> approve(String id) async {
    await ensureReady();
    final db = await _db();
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.update(
        tableName,
        {
          'status': SupplierPurchaseRequestStatus.approved.storageValue,
          'ONAY': 1,
          'is_synced': 0,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      final rows = await txn.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final row = SupplierPurchaseRequest.fromMap(rows.first);
      await SupplyRequestLogoSyncMapper.enqueueApproved(db: txn, row: row);
    });
  }

  /// Reddet (ONAY=3)
  Future<void> reject(String id) async {
    await ensureReady();
    final db = await _db();
    await db.update(
      tableName,
      {
        'status': SupplierPurchaseRequestStatus.rejected.storageValue,
        'ONAY': 3,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soft delete
  Future<void> softDelete(String id) async {
    await ensureReady();
    final db = await _db();
    await db.update(
      tableName,
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Düşük stok satırlarından öneri üret (warehouse_stocks)
  Future<List<Map<String, dynamic>>> suggestFromLowStock({
    double threshold = 10,
  }) async {
    final db = await _db();
    try {
      return await db.rawQuery('''
        SELECT
          ws.product_id AS product_id,
          COALESCE(p.code, '') AS product_code,
          COALESCE(p.name, '') AS product_name,
          ws.warehouse_code AS warehouse_code,
          ws.quantity AS quantity
        FROM warehouse_stocks ws
        LEFT JOIN products p ON p.id = ws.product_id
        WHERE ws.quantity <= ?
        ORDER BY ws.quantity ASC
        LIMIT 50
      ''', [threshold]);
    } catch (_) {
      return const [];
    }
  }

  /// Tedarikçi cariler (card_role)
  Future<List<Map<String, dynamic>>> listSuppliers({
    String? query,
  }) async {
    final db = await _db();
    try {
      final rows = await db.rawQuery('''
        SELECT id, COALESCE(code,'') AS code, COALESCE(name,'') AS name
        FROM customers
        WHERE COALESCE(is_active, 1) = 1
          AND (
            LOWER(COALESCE(card_role,'')) IN ('supplier','both')
            OR LOWER(COALESCE(card_role,'')) LIKE '%supplier%'
          )
        ORDER BY name ASC
        LIMIT 200
      ''');
      final q = (query ?? '').trim().toLowerCase();
      if (q.isEmpty) return rows;
      return rows
          .where(
            (r) =>
                (r['code']?.toString() ?? '')
                    .toLowerCase()
                    .contains(q) ||
                (r['name']?.toString() ?? '')
                    .toLowerCase()
                    .contains(q),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
