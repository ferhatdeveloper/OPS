// Dosya Adı: order_pending_store.dart
// Açıklama: Bekleyen siparişler dens SQLite okuma katmanı (ONAY)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../service/database_service.dart';
import '../model/order_pending_record.dart';
import '../model/order_pending_seed.dart';
import 'order_pending_query.dart';

/// {@template order_pending_store}
/// `orders` tablosundan ONAY/status bekleyen dens satırları okur.
///
/// Kullanım örneği:
/// ```dart
/// final store = OrderPendingStore();
/// final rows = await store.loadPending();
/// ```
/// {@endtemplate}
class OrderPendingStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro order_pending_store}
  const OrderPendingStore({this.openDb});

  /// [tableName]: SQLite tablo adı
  static const String tableName = OrderPendingSeed.tableName;

  /// {@template order_pending_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    await svc.ensureOrdersTableSchema();
    return svc.getDatabase();
  }

  /// {@template order_pending_store_ensure}
  /// `orders` tablosunu oluşturur (yoksa).
  /// {@endtemplate}
  Future<void> ensureReady() async {
    final db = await _db();
    await db.execute(SqlQuerys.createOrdersTable);
  }

  /// {@template order_pending_store_load_pending}
  /// Bekleyen siparişleri tarihe göre (yeniden eskiye) döner.
  /// Kriter: ONAY/approval_status = 0 veya status Pending/Proposal.
  ///
  /// Dönüş değeri:
  /// - [List<OrderPendingRecord>]: Bekleyen dens satırlar
  /// {@endtemplate}
  Future<List<OrderPendingRecord>> loadPending() async {
    await ensureReady();
    final db = await _db();
    final maps = await db.rawQuery('''
      SELECT o.*,
             c.code AS customer_code,
             c.name AS customer_name
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      WHERE LOWER(COALESCE(o.status, '')) IN ('pending', 'proposal')
         OR (
           COALESCE(o.approval_status, 0) = 0
           AND LOWER(COALESCE(o.status, '')) NOT IN (
             'approved', 'cancelled', 'shippable', 'notshippable'
           )
         )
      ORDER BY o.order_date DESC, o.id ASC
    ''');
    return OrderPendingQuery.recordsFromMaps(maps);
  }
}
