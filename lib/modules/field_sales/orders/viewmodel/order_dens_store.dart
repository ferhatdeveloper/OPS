// Dosya Adı: order_dens_store.dart
// Açıklama: Sipariş dens listeleri için SQLite sorgu katmanı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../service/database_service.dart';
import '../model/order_dens_row.dart';
import '../model/order_dens_scope.dart';

/// {@template order_dens_store}
/// `orders` tablosundan dens kapsamına göre satır okur (cari join).
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
  ///
  /// Parametreler:
  /// - [scope]: Takip / transfer edilen / edilmeyen / bekleyen
  ///
  /// Dönüş değeri:
  /// - [List<OrderDensRow>]: Tarih azalan dens satırlar
  ///
  /// Fırlatılan hatalar:
  /// - [DatabaseException]: SQLite okuma hatası
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
    switch (scope) {
      case OrderDensScope.tracking:
        return '1 = 1';
      case OrderDensScope.transferred:
        return 'COALESCE(o.is_synced, 0) = 1';
      case OrderDensScope.untransferred:
        return 'COALESCE(o.is_synced, 0) = 0';
      case OrderDensScope.pending:
        return "LOWER(COALESCE(o.status, '')) IN "
            "('pending', 'proposal')";
    }
  }
}
