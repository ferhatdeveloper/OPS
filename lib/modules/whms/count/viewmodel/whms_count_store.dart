// Dosya Adı: whms_count_store.dart
// Açıklama: Merkez sayım emir/sonuç bellek içi store iskeleti (P0)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/foundation.dart';

import '../../contract/whms_bridge_dto.dart';
import '../model/whms_count_order.dart';

/// {@template whms_count_store}
/// Sayım emirleri + sonuçlar — bellek iskeleti (UI smoke / test).
/// Kalıcı CRUD: [WhmsCountOrderStore].
///
/// Kullanım örneği:
/// ```dart
/// final store = WhmsCountStore();
/// store.upsertOrder(order);
/// ```
/// {@endtemplate}
class WhmsCountStore extends ChangeNotifier {
  final List<WhmsCountOrder> _orders = [];
  final List<WhmsCountResultDto> _results = [];

  /// [orders]: Emir listesi (yeniden)
  List<WhmsCountOrder> get orders => List.unmodifiable(_orders);

  /// [results]: Sonuç listesi (yeniden)
  List<WhmsCountResultDto> get results => List.unmodifiable(_results);

  /// {@template whms_count_store_upsert_order}
  /// Emir ekle veya id ile güncelle.
  /// {@endtemplate}
  void upsertOrder(WhmsCountOrder order) {
    final i = _orders.indexWhere((o) => o.id == order.id);
    if (i >= 0) {
      _orders[i] = order;
    } else {
      _orders.add(order);
    }
    notifyListeners();
  }

  /// {@template whms_count_store_upsert_result}
  /// Sonuç ekle veya id ile güncelle.
  /// {@endtemplate}
  void upsertResult(WhmsCountResultDto result) {
    final i = _results.indexWhere((r) => r.id == result.id);
    if (i >= 0) {
      _results[i] = result;
    } else {
      _results.add(result);
    }
    notifyListeners();
  }

  /// {@template whms_count_store_seed_demo}
  /// Dens liste için tek taslak emir (UI smoke).
  /// {@endtemplate}
  void seedDemoIfEmpty() {
    if (_orders.isNotEmpty) return;
    final now = DateTime.now();
    upsertOrder(
      WhmsCountOrder(
        id: 'whms-count-demo-1',
        warehouseCode: 'MRK',
        orderDate: now,
        status: WhmsCountOrderStatus.draft,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
