// Dosya Adı: order_dens_store.dart
// Açıklama: Sipariş dens listeleri — SQLite sorgu + soft-delete/cancel
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../../../../service/job_queue_service.dart';
import '../model/order_dens_row.dart';
import '../model/order_dens_scope.dart';

/// {@template order_dens_store}
/// `orders` tablosundan dens kapsamına göre satır okur (cari join);
/// aktarılmamış sipariş soft-delete / iptal + sync_queue stub.
///
/// Kullanım örneği:
/// ```dart
/// final store = OrderDensStore();
/// final rows = await store.query(OrderDensScope.tracking);
/// ```
/// {@endtemplate}
class OrderDensStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro order_dens_store}
  const OrderDensStore({this.openDb});

  /// {@template order_dens_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template order_dens_store_query}
  /// Kapsama göre sipariş dens satırlarını yükler.
  /// {@endtemplate}
  Future<List<OrderDensRow>> query(OrderDensScope scope) async {
    final db = await _db();
    final where = _whereFor(scope);
    final maps = await db.rawQuery(
      '''
      SELECT
        o.id,
        o.customer_id,
        o.order_date,
        o.total_amount,
        o.status,
        o.is_synced,
        o.order_type,
        c.code AS customer_code,
        c.name AS customer_name,
        sq.id AS queue_job_id,
        sq.retry_count AS retry_count,
        sq.last_error AS last_error
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      LEFT JOIN sync_queue sq
        ON sq.entity_id = o.id
        AND LOWER(sq.entity_type) IN ('order', 'orders')
      WHERE $where
      ORDER BY o.order_date DESC
      ''',
    );
    return maps.map(OrderDensRow.fromJoinedMap).toList();
  }

  /// {@template order_dens_store_where_for}
  /// Kapsam → SQL WHERE parçası.
  /// {@endtemplate}
  String _whereFor(OrderDensScope scope) {
    const notDeleted = 'COALESCE(o.is_deleted, 0) = 0';
    switch (scope) {
      case OrderDensScope.tracking:
        return notDeleted;
      case OrderDensScope.transferred:
        return '$notDeleted AND COALESCE(o.is_synced, 0) = 1';
      case OrderDensScope.untransferred:
        return '$notDeleted AND COALESCE(o.is_synced, 0) = 0';
      case OrderDensScope.pending:
        return "$notDeleted AND LOWER(COALESCE(o.status, '')) IN "
            "('pending', 'proposal')";
    }
  }

  /// {@template order_dens_store_soft_delete_local}
  /// Aktarılmamış yerel siparişi soft-delete + sync_queue.
  /// {@endtemplate}
  Future<bool> softDeleteLocal(String orderId) async {
    final id = orderId.trim();
    if (id.isEmpty) return false;
    final db = await _db();
    await db.execute(SqlQuerys.createSyncQueueTable);
    final now = DateTime.now().toIso8601String();
    var updated = 0;
    await db.transaction((txn) async {
      updated = await txn.update(
        'orders',
        {
          'is_deleted': 1,
          'is_synced': 0,
          'updated_at': now,
        },
        where: 'id = ? AND COALESCE(is_synced, 0) = 0 '
            'AND COALESCE(is_deleted, 0) = 0',
        whereArgs: [id],
      );
      if (updated > 0) {
        await txn.insert('sync_queue', {
          'id': const Uuid().v4(),
          'entity_type': 'order',
          'entity_id': id,
          'payload': jsonEncode({
            'id': id,
            'op': 'delete',
            'updated_at': now,
          }),
          'priority': 0,
          'retry_count': 0,
          'created_at': now,
        });
      }
    });
    if (updated > 0 && openDb == null) {
      JobQueueService().processQueue();
    }
    return updated > 0;
  }

  /// {@template order_dens_store_cancel_local}
  /// Aktarılmamış siparişi Cancelled yapar + sync_queue.
  /// {@endtemplate}
  Future<bool> cancelLocal(String orderId) async {
    final id = orderId.trim();
    if (id.isEmpty) return false;
    final db = await _db();
    await db.execute(SqlQuerys.createSyncQueueTable);
    final now = DateTime.now().toIso8601String();
    var updated = 0;
    await db.transaction((txn) async {
      updated = await txn.update(
        'orders',
        {
          'status': 'Cancelled',
          'is_synced': 0,
          'updated_at': now,
        },
        where: 'id = ? AND COALESCE(is_synced, 0) = 0 '
            'AND COALESCE(is_deleted, 0) = 0',
        whereArgs: [id],
      );
      if (updated > 0) {
        await txn.insert('sync_queue', {
          'id': const Uuid().v4(),
          'entity_type': 'order',
          'entity_id': id,
          'payload': jsonEncode({
            'id': id,
            'op': 'cancel',
            'status': 'Cancelled',
            'updated_at': now,
          }),
          'priority': 0,
          'retry_count': 0,
          'created_at': now,
        });
      }
    });
    if (updated > 0 && openDb == null) {
      JobQueueService().processQueue();
    }
    return updated > 0;
  }

  /// {@template order_dens_store_fetch_header}
  /// Sipariş üst bilgisi (silinmemiş).
  /// {@endtemplate}
  Future<Map<String, dynamic>?> fetchOrderHeader(String orderId) async {
    final db = await _db();
    final rows = await db.query(
      'orders',
      where: 'id = ? AND COALESCE(is_deleted, 0) = 0',
      whereArgs: [orderId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// {@template order_dens_store_fetch_items}
  /// Sipariş kalemleri.
  /// {@endtemplate}
  Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    final db = await _db();
    return db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }
}
