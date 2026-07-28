// Dosya Adı: whms_order_list_source.dart
// Açıklama: Emir listesi kaynağı — WhmsOrderStore adaptörü (DTO)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../model/whms_order_dto.dart';
import '../../model/whms_order_status.dart';
import '../../model/whms_order_type.dart';
import '../../viewmodel/whms_order_store.dart';

/// {@template whms_order_list_source}
/// Dens emir listesi kaynağı — [WhmsOrderDto] döner.
///
/// Kullanım örneği:
/// ```dart
/// final rows = await const WhmsOrderStoreSource().list();
/// ```
/// {@endtemplate}
abstract class WhmsOrderListSource {
  /// Filtrelenmiş emir listesi.
  Future<List<WhmsOrderDto>> list({
    WhmsOrderType? type,
    WhmsOrderStatus? status,
    DateTime? from,
    DateTime? to,
    String query = '',
  });
}

/// {@template whms_order_store_source}
/// [WhmsOrderStore] adaptörü — varsayılan üretim kaynağı.
/// {@endtemplate}
class WhmsOrderStoreSource implements WhmsOrderListSource {
  /// [store]: Emir store
  final WhmsOrderStore store;

  /// {@macro whms_order_store_source}
  const WhmsOrderStoreSource([this.store = const WhmsOrderStore()]);

  @override
  Future<List<WhmsOrderDto>> list({
    WhmsOrderType? type,
    WhmsOrderStatus? status,
    DateTime? from,
    DateTime? to,
    String query = '',
  }) async {
    final rows = await store.list(type: type, status: status);
    final q = query.trim().toLowerCase();
    return rows.where((dto) {
      final parsed = DateTime.tryParse(dto.orderDate);
      if (from != null && parsed != null && parsed.isBefore(from)) {
        return false;
      }
      if (to != null && parsed != null && parsed.isAfter(to)) {
        return false;
      }
      if (q.isEmpty) return true;
      final hay = [
        dto.id,
        dto.referenceNo ?? '',
        dto.warehouseCode ?? '',
        dto.notes ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList(growable: false);
  }
}

/// Boş stub (test).
class WhmsOrderEmptySource implements WhmsOrderListSource {
  /// {@macro whms_order_empty_source}
  const WhmsOrderEmptySource();

  @override
  Future<List<WhmsOrderDto>> list({
    WhmsOrderType? type,
    WhmsOrderStatus? status,
    DateTime? from,
    DateTime? to,
    String query = '',
  }) async =>
      const <WhmsOrderDto>[];
}
