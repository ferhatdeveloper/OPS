// Dosya Adı: whms_transfer_order_bridge.dart
// Açıklama: Onaylı transfer → WhmsOrderStore (type=transfer)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../contract/whms_bridge_dto.dart';
import '../model/whms_order_dto.dart';
import '../model/whms_order_status.dart';
import '../viewmodel/whms_order_store.dart';
import 'whms_bridge_order_mapper.dart';

/// {@template whms_transfer_order_bridge}
/// Dens onaylı ambar transferini emir omurgasına yazar.
///
/// Kullanım örneği:
/// ```dart
/// await WhmsTransferOrderBridge.mirrorApproved(
///   dto: transferDto,
///   store: WhmsOrderStore(),
/// );
/// ```
/// {@endtemplate}
class WhmsTransferOrderBridge {
  WhmsTransferOrderBridge._();

  /// {@template whms_transfer_order_bridge_mirror}
  /// ONAY=1 transferi `WhmsOrderType.transfer` olarak upsert eder.
  ///
  /// Parametreler:
  /// - [dto]: Köprü transfer
  /// - [store]: A ajanı [WhmsOrderStore]
  ///
  /// Dönüş değeri:
  /// - [WhmsOrderDto]? : yazılan emir; ONAY≠1 ise null
  /// {@endtemplate}
  static Future<WhmsOrderDto?> mirrorApproved({
    required WhmsWarehouseTransferDto dto,
    WhmsOrderStore store = const WhmsOrderStore(),
  }) async {
    if (dto.approval != WhmsApprovalStatus.approved) {
      return null;
    }
    final order = WhmsBridgeOrderMapper.fromTransfer(
      dto,
      status: WhmsOrderStatus.done,
    );
    return store.upsert(order);
  }
}
