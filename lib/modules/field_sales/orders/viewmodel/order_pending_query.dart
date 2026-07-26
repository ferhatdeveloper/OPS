// Dosya Adı: order_pending_query.dart
// Açıklama: Bekleyen sipariş dens — ONAY/SQLite filtre + satır üretimi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../model/order_pending_record.dart';

/// {@template order_pending_query}
/// Bekleyen sipariş (ONAY=0) filtre ve dens satır yardımcıları.
///
/// Kullanım örneği:
/// ```dart
/// final pending = OrderPendingQuery.filterPendingMaps(rows);
/// ```
/// {@endtemplate}
class OrderPendingQuery {
  OrderPendingQuery._();

  /// {@template order_pending_query_is_pending_map}
  /// SQLite satırı bekleyen mi?
  /// ONAY/approval_status varsa 0 olmalı; yoksa status Pending/Proposal.
  ///
  /// Parametreler:
  /// - [map]: orders satırı
  ///
  /// Dönüş değeri:
  /// - [bool]: Bekleyen ise true
  /// {@endtemplate}
  static bool isPendingMap(Map<String, dynamic> map) {
    final status = (map['status']?.toString() ?? '').trim().toLowerCase();
    if (status == 'pending' || status == 'proposal') return true;
    if (status == 'approved' ||
        status == 'cancelled' ||
        status == 'shippable' ||
        status == 'notshippable') {
      return false;
    }
    final onay = (map['ONAY'] as num?)?.toInt() ??
        (map['approval_status'] as num?)?.toInt() ??
        0;
    return onay == 0;
  }

  /// {@template order_pending_query_filter_pending_maps}
  /// Map listesinden bekleyenleri süzer.
  /// {@endtemplate}
  static List<Map<String, dynamic>> filterPendingMaps(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.where(isPendingMap).toList(growable: false);
  }

  /// {@template order_pending_query_records_from_maps}
  /// Map → [OrderPendingRecord] (yalnız bekleyenler).
  /// {@endtemplate}
  static List<OrderPendingRecord> recordsFromMaps(
    List<Map<String, dynamic>> rows,
  ) {
    return filterPendingMaps(rows)
        .map(OrderPendingRecord.fromMap)
        .toList(growable: false);
  }
}
