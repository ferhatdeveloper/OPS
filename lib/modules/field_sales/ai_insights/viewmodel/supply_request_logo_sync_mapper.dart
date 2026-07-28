// Dosya Adı: supply_request_logo_sync_mapper.dart
// Açıklama: Tedarik talebi → Logo satın alma siparişi sync_queue + enqueue
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/services/logo_payload_mapper.dart';
import '../model/supplier_purchase_request.dart';

/// {@template supply_request_logo_sync_mapper}
/// Onaylı tedarik talebini `sync_queue`’ya yazar.
/// Payload: [LogoPayloadMapper.orderFromLocal] satın alma kanalı
/// (`type`/`order_type` = `purchase`) — JobQueue `createOrder` işler.
///
/// Feature flag: [useRealLogoPurchasePath] false → yalnızca yerel kuyruk
/// işaretleme (eski stub). Varsayılan: gerçek path.
///
/// Kullanım örneği:
/// ```dart
/// await SupplyRequestLogoSyncMapper.enqueueApproved(
///   db: db,
///   row: request,
/// );
/// ```
/// {@endtemplate}
class SupplyRequestLogoSyncMapper {
  /// {@macro supply_request_logo_sync_mapper}
  const SupplyRequestLogoSyncMapper._();

  /// JobQueue / sync_queue entity_type
  static const String entityType = 'supplier_purchase_request';

  /// true → JobQueue Logo `POST /orders` (purchase); false → stub ok
  static bool useRealLogoPurchasePath = true;

  /// {@template supply_request_logo_sync_mapper_payload}
  /// Logo satın alma siparişi payload (Objects / ExfinApi orders).
  /// {@endtemplate}
  static Map<String, dynamic> payload({
    required SupplierPurchaseRequest row,
    String operation = 'upsert',
  }) {
    final supplierCode = row.supplierCode.trim().isNotEmpty
        ? row.supplierCode.trim()
        : (row.supplierId ?? '').trim();
    final productCode = row.productCode.trim().isNotEmpty
        ? row.productCode.trim()
        : row.productId.trim();

    final mapped = LogoPayloadMapper.orderFromLocal(
      order: {
        'id': row.id,
        'fiche_no': 'SPR-${row.id}',
        'order_number': 'SPR-${row.id}',
        'date': row.updatedAt ?? row.createdAt,
        'notes': row.notes,
        'order_type': 'purchase',
        'type': 'purchase',
        if (row.warehouseCode.trim().isNotEmpty)
          'warehouse_code': row.warehouseCode,
      },
      items: [
        {
          'product_code': productCode,
          'product_id': row.productId,
          'quantity': row.quantity,
          'price': 0,
          'unit_name': '',
        },
      ],
      customerCode: supplierCode.isEmpty ? 'SUPPLIER' : supplierCode,
      orderType: 'purchase',
    );

    return {
      ...mapped,
      'entity': entityType,
      'operation': operation,
      'id': row.id,
      'product_id': row.productId,
      'product_code': productCode,
      'product_name': row.productName,
      'quantity': row.quantity,
      'supplier_id': row.supplierId,
      'supplier_code': row.supplierCode,
      'supplier_name': row.supplierName,
      'warehouse_code': row.warehouseCode,
      'notes': row.notes,
      'ONAY': row.onay,
      'status': row.status.storageValue,
      // Gerçek path: stub false; flag kapalıysa worker stub ok döner
      'stub': !useRealLogoPurchasePath,
      'logo_channel': 'purchase_order',
    };
  }

  /// {@template supply_request_logo_sync_mapper_enqueue}
  /// sync_queue satırı yazar.
  /// {@endtemplate}
  static Future<String> enqueue({
    required DatabaseExecutor db,
    required SupplierPurchaseRequest row,
    String operation = 'upsert',
  }) async {
    if (db is Database) {
      await db.execute(SqlQuerys.createSyncQueueTable);
    }
    final jobId = const Uuid().v4();
    await db.insert('sync_queue', {
      'id': jobId,
      'entity_type': entityType,
      'entity_id': row.id,
      'payload': jsonEncode(payload(row: row, operation: operation)),
      'priority': 0,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    return jobId;
  }

  /// Onaylı talep enqueue (ONAY=1 beklenir).
  static Future<String> enqueueApproved({
    required DatabaseExecutor db,
    required SupplierPurchaseRequest row,
  }) {
    return enqueue(db: db, row: row, operation: 'upsert');
  }
}
