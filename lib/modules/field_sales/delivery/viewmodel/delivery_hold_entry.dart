// Dosya Adı: delivery_hold_entry.dart
// Açıklama: Sipariş / irsaliye girişinden DeliveryHoldStore.add köprüsü
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../orders/model/order_model.dart';
import '../../waybills/model/waybill_type.dart';
import '../model/delivery_hold_record.dart';
import 'delivery_hold_store.dart';

/// {@template delivery_hold_entry}
/// Fiş giriş ekranlarından beklemeye alma — [DeliveryHoldStore.add] çağırır.
///
/// Kullanım örneği:
/// ```dart
/// await DeliveryHoldEntry.addFromOrder(
///   orderId: draft.id,
///   orderType: OrderType.sales,
///   customerCode: 'C001',
///   customerName: 'Demo',
/// );
/// ```
/// {@endtemplate}
class DeliveryHoldEntry {
  /// {@macro delivery_hold_entry}
  const DeliveryHoldEntry({
    this.store = const DeliveryHoldStore(),
  });

  /// [store]: SharedPreferences kalıcılık
  final DeliveryHoldStore store;

  /// {@template delivery_hold_entry_add_from_order}
  /// Sipariş taslağını beklemeye alır.
  ///
  /// Parametreler:
  /// - [orderId]: Taslak sipariş kimliği
  /// - [orderType]: Satış / alış
  /// - [customerCode]: Cari kod
  /// - [customerName]: Cari ünvan
  /// - [note]: Opsiyonel not
  /// - [heldAt]: Bekleme zamanı (null → now)
  ///
  /// Dönüş değeri:
  /// - [DeliveryHoldRecord]: Kaydedilen özet
  /// {@endtemplate}
  Future<DeliveryHoldRecord> addFromOrder({
    required String orderId,
    required OrderType orderType,
    required String customerCode,
    required String customerName,
    String note = '',
    DateTime? heldAt,
  }) {
    final now = heldAt ?? DateTime.now();
    final side = orderType == OrderType.purchase
        ? DeliveryHoldDocSide.purchase
        : DeliveryHoldDocSide.sales;
    final record = DeliveryHoldRecord(
      id: 'dh-ord-$orderId',
      docNo: _docNo(
        prefix: orderType == OrderType.purchase ? 'ALS' : 'SIP',
        sourceId: orderId,
      ),
      customerCode: customerCode,
      customerName: customerName,
      side: side,
      heldAt: now,
      note: note,
    );
    return _add(record);
  }

  /// {@template delivery_hold_entry_add_from_waybill}
  /// İrsaliye dens sepetini beklemeye alır.
  ///
  /// Parametreler:
  /// - [holdId]: Yerel bekleyen kimliği (uuid)
  /// - [waybillType]: Toptan / satın alma
  /// - [customerCode]: Cari kod
  /// - [customerName]: Cari ünvan
  /// - [note]: Opsiyonel not
  /// - [heldAt]: Bekleme zamanı (null → now)
  ///
  /// Dönüş değeri:
  /// - [DeliveryHoldRecord]: Kaydedilen özet
  /// {@endtemplate}
  Future<DeliveryHoldRecord> addFromWaybill({
    required String holdId,
    required WaybillType waybillType,
    required String customerCode,
    required String customerName,
    String note = '',
    DateTime? heldAt,
  }) {
    final now = heldAt ?? DateTime.now();
    final side = waybillType == WaybillType.purchase
        ? DeliveryHoldDocSide.purchase
        : DeliveryHoldDocSide.sales;
    final record = DeliveryHoldRecord(
      id: 'dh-wb-$holdId',
      docNo: _docNo(
        prefix: waybillType == WaybillType.purchase ? 'IRA' : 'IRS',
        sourceId: holdId,
      ),
      customerCode: customerCode,
      customerName: customerName,
      side: side,
      heldAt: now,
      note: note,
    );
    return _add(record);
  }

  /// {@template delivery_hold_entry_add}
  /// Kaydı [DeliveryHoldStore.add] ile yazar.
  /// {@endtemplate}
  Future<DeliveryHoldRecord> _add(DeliveryHoldRecord record) async {
    await store.add(record);
    return record;
  }

  /// {@template delivery_hold_entry_doc_no}
  /// Kısa fiş no: PREFIX-XXXXXX
  /// {@endtemplate}
  static String _docNo({
    required String prefix,
    required String sourceId,
  }) {
    final compact = sourceId.replaceAll('-', '');
    final tail = compact.length > 6
        ? compact.substring(0, 6).toUpperCase()
        : compact.toUpperCase();
    return '$prefix-$tail';
  }
}
