// Dosya Adı: waybill_type.dart
// Açıklama: İrsaliye tipi — Logo dispatch kanalı (≠ fatura TYPE)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/services/logo_payload_mapper.dart';

/// {@template WaybillType}
/// İrsaliye fiş tipi (MBT: Toptan Satış / Satın Alma).
/// Logo `dispatches/sync` kanalı; fatura TYPE 8 / `invoice_type` değil.
/// {@endtemplate}
enum WaybillType {
  /// Sevk / toptan satış irsaliyesi
  wholesale,

  /// Mal alım / satın alma irsaliyesi
  purchase;

  /// Yerel kuyruk anahtarı: `waybill_wholesale` | `waybill_purchase`
  String get localKey => this == WaybillType.purchase
      ? LogoPayloadMapper.dispatchLocalPurchase
      : LogoPayloadMapper.dispatchLocalWholesale;

  /// Logo dispatch kanalı: `wholesale` | `purchase` (≠ invoice TRCODE)
  String get logoDispatchType => this == WaybillType.purchase
      ? LogoPayloadMapper.dispatchChannelPurchase
      : LogoPayloadMapper.dispatchChannelWholesale;

  /// Stok giriş (satın alma irsaliye) yönü
  bool get isStockInbound => this == WaybillType.purchase;

  /// Saklama / route değerinden [WaybillType]
  static WaybillType fromLocalKey(String? raw) {
    final channel = LogoPayloadMapper.resolveDispatchType(raw);
    return channel == LogoPayloadMapper.dispatchChannelPurchase
        ? WaybillType.purchase
        : WaybillType.wholesale;
  }

  /// {@template buildDispatchQueuePayload}
  /// Logo `dispatches/sync` kuyruk gövdesi (fatura TYPE 8 flatten yok).
  /// {@endtemplate}
  static Map<String, dynamic> buildDispatchQueuePayload({
    required String customerCode,
    required WaybillType waybillType,
    List<Map<String, dynamic>> items = const [],
    Map<String, dynamic>? header,
  }) {
    final mappedHeader = LogoPayloadMapper.dispatchHeaderFromLocal(
      customerCode: customerCode,
      header: header,
      dispatchType: waybillType.localKey,
    );
    final mappedItems = LogoPayloadMapper.dispatchItemsFromLocal(items);
    return {
      ...mappedHeader,
      'items': mappedItems,
      'lines': mappedItems,
    };
  }
}
