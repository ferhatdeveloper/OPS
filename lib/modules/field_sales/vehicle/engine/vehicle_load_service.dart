// Dosya Adı: vehicle_load_service.dart
// Açıklama: Araç yükleme — merkez (products.stock_quantity) düşümü + vehicle_stocks artışı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

/// {@template vehicle_load_service}
/// Merkez ambardan araç deposuna stok yüklemesi uygular.
///
/// Kullanım örneği:
/// ```dart
/// await VehicleLoadService.applyLoad(
///   db: txn,
///   vehicleId: 'veh-1',
///   items: [{'productId': 'prd-1', 'quantity': 10.0}],
/// );
/// ```
/// {@endtemplate}
class VehicleLoadService {
  /// {@template apply_load}
  /// [products.stock_quantity] düşer; [vehicle_stocks] artar.
  ///
  /// Parametreler:
  /// - [db]: Transaction veya Database
  /// - [vehicleId]: Hedef araç
  /// - [items]: `{productId, quantity}` listesi
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: Ürün yok veya merkez stok yetersiz
  /// {@endtemplate}
  static Future<void> applyLoad({
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

      if (centerQty < qty) {
        throw StateError(
          'Merkez stok yetersiz: $productId ($centerQty < $qty)',
        );
      }

      await db.update(
        'products',
        {
          'stock_quantity': centerQty - qty,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      final existing = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: [vehicleId, productId],
      );

      if (existing.isNotEmpty) {
        final currentQty = (existing.first['quantity'] as num).toDouble();
        await db.update(
          'vehicle_stocks',
          {
            'quantity': currentQty + qty,
            'updated_at': now,
          },
          where: 'vehicle_id = ? AND product_id = ?',
          whereArgs: [vehicleId, productId],
        );
      } else {
        await db.insert('vehicle_stocks', {
          'vehicle_id': vehicleId,
          'product_id': productId,
          'quantity': qty,
          'updated_at': now,
        });
      }
    }
  }
}
