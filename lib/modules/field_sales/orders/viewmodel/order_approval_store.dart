// Dosya Adı: order_approval_store.dart
// Açıklama: Sipariş onaylama dens — Öneri/Sevk SQLite sorgu + durum güncelleme
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../../service/database_service.dart';
import '../model/order_dens_row.dart';
import '../model/order_model.dart';

/// {@template order_approval_dens_tab}
/// Sipariş onaylama dens sekmesi (Öneri / Sevk).
///
/// Kullanım örneği:
/// ```dart
/// OrderApprovalDensTab.proposal
/// ```
/// {@endtemplate}
enum OrderApprovalDensTab {
  /// Öneri: Pending / Proposal
  proposal,

  /// Sevk: Shippable veya NotShippable
  dispatch,
}

/// {@template order_approval_store}
/// `orders` + `customers` join ile Öneri/Sevk dens satırlarını okur;
/// onay / sevk durumunu SQLite’a yazar.
///
/// Kullanım örneği:
/// ```dart
/// final store = OrderApprovalStore();
/// final rows = await store.query(
///   tab: OrderApprovalDensTab.proposal,
///   periodFrom: DateTime(2026, 7, 1),
///   periodTo: DateTime(2026, 7, 26),
/// );
/// ```
/// {@endtemplate}
class OrderApprovalStore {
  /// [openDb]: Test için enjekte edilebilir DB açıcı
  final Future<Database> Function()? openDb;

  /// {@macro order_approval_store}
  const OrderApprovalStore({this.openDb});

  /// {@template order_approval_store_db}
  /// Veritabanı bağlantısını döner.
  /// {@endtemplate}
  Future<Database> _db() async {
    if (openDb != null) return openDb!();
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template order_approval_store_query}
  /// Dönem / tip / sekme / sevk moduna göre dens satırlarını yükler.
  ///
  /// Parametreler:
  /// - [tab]: Öneri veya Sevk
  /// - [sevkShippable]: Sevk sekmesinde Edilebilir / Edilemez
  /// - [orderType]: null = hepsi; sales / purchase
  /// - [periodFrom]: Başlangıç (dahil)
  /// - [periodTo]: Bitiş (dahil)
  ///
  /// Dönüş değeri:
  /// - [List<OrderDensRow>]: Tarih azalan dens satırlar
  /// {@endtemplate}
  Future<List<OrderDensRow>> query({
    required OrderApprovalDensTab tab,
    bool sevkShippable = true,
    OrderType? orderType,
    required DateTime periodFrom,
    required DateTime periodTo,
  }) async {
    final db = await _db();
    final where = <String>['1 = 1'];
    final args = <Object?>[];

    final from = _toDateOnly(periodFrom);
    final toExclusive = _toDateOnly(
      periodTo.add(const Duration(days: 1)),
    );
    where.add('o.order_date >= ?');
    args.add(from);
    where.add('o.order_date < ?');
    args.add(toExclusive);

    if (orderType != null) {
      where.add('LOWER(COALESCE(o.order_type, \'sales\')) = ?');
      args.add(orderType.storageValue);
    }

    where.add(_statusClause(tab, sevkShippable));

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
        c.name AS customer_name
      FROM orders o
      LEFT JOIN customers c ON c.id = o.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY o.order_date DESC
      ''',
      args,
    );
    return maps.map(OrderDensRow.fromJoinedMap).toList();
  }

  /// {@template order_approval_store_update_status}
  /// Sipariş durumunu SQLite’ta günceller (tip korunur).
  ///
  /// Parametreler:
  /// - [id]: Sipariş kimliği
  /// - [status]: Yeni durum (örn. Shippable, NotShippable, Approved)
  ///
  /// Dönüş değeri:
  /// - [int]: Etkilenen satır sayısı
  /// {@endtemplate}
  Future<int> updateStatus({
    required String id,
    required String status,
  }) async {
    final trimmedId = id.trim();
    final trimmedStatus = status.trim();
    if (trimmedId.isEmpty || trimmedStatus.isEmpty) return 0;
    final db = await _db();
    return db.update(
      'orders',
      {
        'status': trimmedStatus,
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [trimmedId],
    );
  }

  /// {@template order_approval_store_status_clause}
  /// Sekme / sevk modu → SQL status filtresi.
  /// {@endtemplate}
  String _statusClause(OrderApprovalDensTab tab, bool sevkShippable) {
    final s = "LOWER(REPLACE(COALESCE(o.status, ''), '_', ''))";
    switch (tab) {
      case OrderApprovalDensTab.proposal:
        return "$s IN ('pending', 'proposal')";
      case OrderApprovalDensTab.dispatch:
        if (sevkShippable) {
          return "$s IN ('approved', 'shippable')";
        }
        return "$s IN ('notshippable', 'cancelled', 'canceled')";
    }
  }

  /// {@template order_approval_store_to_date_only}
  /// SQLite string karşılaştırma için `yyyy-MM-dd`.
  /// {@endtemplate}
  static String _toDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// {@template order_approval_store_status_l10n_key}
  /// Durum kodunu çeviri anahtarına çevirir (order_list_dens ile ortak).
  /// {@endtemplate}
  static String statusL10nKey(String status) {
    switch (status.trim().toLowerCase().replaceAll('_', '')) {
      case 'approved':
        return 'field_sales.order_list_dens.status_approved';
      case 'cancelled':
      case 'canceled':
        return 'field_sales.order_list_dens.status_cancelled';
      case 'proposal':
        return 'field_sales.order_list_dens.status_proposal';
      case 'shippable':
        return 'field_sales.order_list_dens.status_shippable';
      case 'notshippable':
        return 'field_sales.order_list_dens.status_not_shippable';
      case 'pending':
      default:
        return 'field_sales.order_list_dens.status_pending';
    }
  }
}
