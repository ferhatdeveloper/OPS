// Dosya Adı: vehicle_unload_service.dart
// Açıklama: Araç boşaltma — vehicle_stocks düşümü + merkez (products.stock_quantity) artışı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

/// {@template vehicle_unload_service}
/// Araç deposundan merkez ambara stok iadesi uygular.
///
/// Kullanım örneği:
/// ```dart
/// await VehicleUnloadService.applyUnload(
///   db: txn,
///   vehicleId: 'veh-1',
///   items: [{'productId': 'prd-1', 'quantity': 10.0}],
/// );
/// ```
/// {@endtemplate}
class VehicleUnloadService {
  /// {@template apply_unload}
  /// [vehicle_stocks] miktarını düşer; [products.stock_quantity] artırır.
  ///
  /// Parametreler:
  /// - [db]: Transaction veya Database
  /// - [vehicleId]: Kaynak araç
  /// - [items]: `{productId, quantity}` listesi
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: Araç stoğu yok veya yetersiz
  /// {@endtemplate}
  static Future<void> applyUnload({
    required DatabaseExecutor db,
    required String vehicleId,
    required List<Map<String, dynamic>> items,
  }) async {
    final now = DateTime.now().toIso8601String();

    for (final item in items) {
      final productId = item['productId']?.toString();
      if (productId == null || productId.isEmpty) continue;

      final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      if (qty <= 0) continue;

      final existing = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: [vehicleId, productId],
      );

      if (existing.isEmpty) {
        throw StateError('Araç stoğu bulunamadı: $productId');
      }

      final currentQty = (existing.first['quantity'] as num).toDouble();
      if (currentQty < qty) {
        throw StateError(
          'Araç stoğu yetersiz: $productId ($currentQty < $qty)',
        );
      }

      await db.update(
        'vehicle_stocks',
        {
          'quantity': currentQty - qty,
          'updated_at': now,
        },
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: [vehicleId, productId],
      );

      final products = await db.query(
        'products',
        columns: ['stock_quantity'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (products.isEmpty) {
        throw StateError('Ürün bulunamadı: $productId');
      }

      final centerQty =
          (products.first['stock_quantity'] as num?)?.toDouble() ?? 0.0;

      await db.update(
        'products',
        {
          'stock_quantity': centerQty + qty,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
  }
}
