// Dosya Adı: warehouse_transfer_stock_txn.dart
// Açıklama: Ambar transferi sonrası yerel stok txn (WHMS prep R3 / B2-27)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../../whms/data/warehouse_stocks_table.dart';
import '../../../whms/mapper/whms_payload_mapper.dart';
import '../model/warehouse_master_seed.dart';

/// {@template transfer_stock_bucket}
/// Yerel stok kovası: merkez ürün stoğu veya araç stoğu.
/// {@endtemplate}
enum TransferStockBucket {
  /// [product]: `products.stock_quantity` (merkez / iade)
  product,

  /// [vehicle]: `vehicle_stocks` (araç deposu)
  vehicle,
}

/// {@template warehouse_transfer_stock_txn}
/// Transfer satırı için kaynak düşüm + hedef artış (aynı SQLite txn).
///
/// Kullanım örneği:
/// ```dart
/// await WarehouseTransferStockTxn.applyLine(
///   db: txn,
///   fromWarehouse: 'MRK',
///   toWarehouse: 'ARC',
///   productId: 'prd-1',
///   quantity: 10,
///   vehicleId: 'veh-1',
/// );
/// ```
/// {@endtemplate}
class WarehouseTransferStockTxn {
  WarehouseTransferStockTxn._();

  /// {@template warehouse_transfer_stock_txn_apply_line}
  /// Kaynak −qty, hedef +qty. Hata → StateError (txn rollback).
  ///
  /// Parametreler:
  /// - [db]: Transaction veya Database
  /// - [fromWarehouse]: Kod, seed adı veya l10n görünen ad
  /// - [toWarehouse]: Hedef ambar referansı
  /// - [productId]: Ürün id
  /// - [quantity]: Ana birim miktar (> 0)
  /// - [vehicleId]: Araç deposu için zorunlu (yoksa aktif araç aranır)
  ///
  /// Fırlatılan hatalar:
  /// - [StateError]: Bilinmeyen ambar, yetersiz stok, araç yok
  /// {@endtemplate}
  static Future<void> applyLine({
    required DatabaseExecutor db,
    required String fromWarehouse,
    required String toWarehouse,
    required String productId,
    required double quantity,
    String? vehicleId,
  }) async {
    if (quantity <= 0) {
      throw StateError('transfer_qty_invalid');
    }

    final fromCode =
        WhmsPayloadMapper.normalizeWarehouseCode(fromWarehouse);
    final toCode = WhmsPayloadMapper.normalizeWarehouseCode(toWarehouse);
    final fromBucket = await _resolveBucket(db, fromWarehouse);
    final toBucket = await _resolveBucket(db, toWarehouse);

    String? resolvedVehicleId = vehicleId?.trim();
    if (fromBucket == TransferStockBucket.vehicle ||
        toBucket == TransferStockBucket.vehicle) {
      resolvedVehicleId ??= await _resolveActiveVehicleId(db);
      if (resolvedVehicleId == null || resolvedVehicleId.isEmpty) {
        throw StateError('transfer_vehicle_required');
      }
    }

    // Merkez↔merkez: yalnız warehouse_stocks (R1); products aggregate atlanır.
    if (fromBucket == TransferStockBucket.product &&
        toBucket == TransferStockBucket.product) {
      double? bootstrap;
      try {
        final products = await db.query(
          'products',
          columns: ['stock_quantity'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (products.isNotEmpty) {
          bootstrap =
              (products.first['stock_quantity'] as num?)?.toDouble() ?? 0;
        }
      } catch (_) {}
      await _adjustWarehouseStock(
        db: db,
        warehouseCode: fromCode,
        productId: productId,
        delta: -quantity,
        bootstrapQuantity: bootstrap,
      );
      await _adjustWarehouseStock(
        db: db,
        warehouseCode: toCode,
        productId: productId,
        delta: quantity,
      );
      return;
    }

    await _adjust(
      db: db,
      bucket: fromBucket,
      productId: productId,
      delta: -quantity,
      vehicleId: resolvedVehicleId,
      warehouseCode: fromCode,
    );
    await _adjust(
      db: db,
      bucket: toBucket,
      productId: productId,
      delta: quantity,
      vehicleId: resolvedVehicleId,
      warehouseCode: toCode,
    );
  }

  /// Ambar metnini stok kovasına çevirir (kod / ad / tip).
  static Future<TransferStockBucket> _resolveBucket(
    DatabaseExecutor db,
    String raw,
  ) async {
    final ref = raw.trim();
    if (ref.isEmpty) {
      throw StateError('transfer_unknown_warehouse');
    }

    final bySeed = WarehouseMasterSeed.byCode(ref);
    if (bySeed != null) {
      return bySeed.type == WarehouseMasterSeed.typeVehicle
          ? TransferStockBucket.vehicle
          : TransferStockBucket.product;
    }

    for (final row in WarehouseMasterSeed.defaultRows) {
      if (row.seedName.toLowerCase() == ref.toLowerCase()) {
        return row.type == WarehouseMasterSeed.typeVehicle
            ? TransferStockBucket.vehicle
            : TransferStockBucket.product;
      }
    }

    try {
      final rows = await db.query(
        WarehouseMasterSeed.tableName,
        columns: ['type', 'code', 'name'],
        where: 'code = ? OR name = ? OR id = ?',
        whereArgs: [ref, ref, ref],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final type = rows.first['type']?.toString() ?? '';
        return type == WarehouseMasterSeed.typeVehicle
            ? TransferStockBucket.vehicle
            : TransferStockBucket.product;
      }
    } catch (_) {
      // warehouses tablosu yoksa seed ile devam
    }

    final lower = ref.toLowerCase();
    if (lower.contains('araç') ||
        lower.contains('arac') ||
        lower.contains('vehicle') ||
        lower.startsWith('vehicle:')) {
      return TransferStockBucket.vehicle;
    }
    if (lower.contains('merkez') ||
        lower.contains('center') ||
        lower.contains('iade') ||
        lower.contains('return')) {
      return TransferStockBucket.product;
    }

    throw StateError('transfer_unknown_warehouse');
  }

  static Future<String?> _resolveActiveVehicleId(DatabaseExecutor db) async {
    try {
      final rows = await db.query(
        'vehicles',
        columns: ['id'],
        where: 'is_active = 1',
        limit: 1,
      );
      if (rows.isNotEmpty && rows.first['id'] != null) {
        return rows.first['id'].toString();
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _adjust({
    required DatabaseExecutor db,
    required TransferStockBucket bucket,
    required String productId,
    required double delta,
    String? vehicleId,
    String? warehouseCode,
  }) async {
    final now = DateTime.now().toIso8601String();

    if (bucket == TransferStockBucket.product) {
      final products = await db.query(
        'products',
        columns: ['stock_quantity'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (products.isEmpty) {
        throw StateError('transfer_product_missing');
      }
      final current =
          (products.first['stock_quantity'] as num?)?.toDouble() ?? 0.0;
      final next = current + delta;
      if (next < -0.0001) {
        throw StateError('transfer_insufficient_stock');
      }
      if (warehouseCode != null && warehouseCode.isNotEmpty) {
        await _adjustWarehouseStock(
          db: db,
          warehouseCode: warehouseCode,
          productId: productId,
          delta: delta,
          bootstrapQuantity: current,
        );
      }
      await db.update(
        'products',
        {
          'stock_quantity': next < 0 ? 0.0 : next,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
      return;
    }

    final vid = vehicleId;
    if (vid == null || vid.isEmpty) {
      throw StateError('transfer_vehicle_required');
    }

    final existing = await db.query(
      'vehicle_stocks',
      where: 'vehicle_id = ? AND product_id = ?',
      whereArgs: [vid, productId],
      limit: 1,
    );

    if (existing.isEmpty) {
      if (delta < 0) {
        throw StateError('transfer_insufficient_stock');
      }
      await db.insert('vehicle_stocks', {
        'vehicle_id': vid,
        'product_id': productId,
        'quantity': delta,
        'updated_at': now,
      });
      return;
    }

    final current = (existing.first['quantity'] as num).toDouble();
    final next = current + delta;
    if (next < -0.0001) {
      throw StateError('transfer_insufficient_stock');
    }
    await db.update(
      'vehicle_stocks',
      {
        'quantity': next < 0 ? 0.0 : next,
        'updated_at': now,
      },
      where: 'vehicle_id = ? AND product_id = ?',
      whereArgs: [vid, productId],
    );
  }

  /// Merkez ambar bakiyesi (`warehouse_stocks`) — WHMS Faz 1 / R1.
  static Future<void> _adjustWarehouseStock({
    required DatabaseExecutor db,
    required String warehouseCode,
    required String productId,
    required double delta,
    double? bootstrapQuantity,
  }) async {
    final code = WhmsPayloadMapper.normalizeWarehouseCode(warehouseCode);
    if (code.isEmpty) {
      throw StateError('transfer_unknown_warehouse');
    }
    final now = DateTime.now().toIso8601String();

    try {
      final existing = await db.query(
        WarehouseStocksTable.name,
        where:
            '${WarehouseStocksTable.colWarehouseCode} = ? AND '
            '${WarehouseStocksTable.colProductId} = ?',
        whereArgs: [code, productId],
        limit: 1,
      );

      if (existing.isEmpty) {
        final base = bootstrapQuantity ?? 0.0;
        final next = base + delta;
        if (next < -0.0001) {
          throw StateError('transfer_insufficient_stock');
        }
        if (delta < 0 && bootstrapQuantity == null) {
          throw StateError('transfer_insufficient_stock');
        }
        await db.insert(WarehouseStocksTable.name, {
          WarehouseStocksTable.colWarehouseCode: code,
          WarehouseStocksTable.colProductId: productId,
          WarehouseStocksTable.colQuantity: next < 0 ? 0.0 : next,
          'is_synced': 0,
          'created_at': now,
          'updated_at': now,
        });
        return;
      }

      final current =
          (existing.first[WarehouseStocksTable.colQuantity] as num)
              .toDouble();
      final next = current + delta;
      if (next < -0.0001) {
        throw StateError('transfer_insufficient_stock');
      }
      await db.update(
        WarehouseStocksTable.name,
        {
          WarehouseStocksTable.colQuantity: next < 0 ? 0.0 : next,
          'updated_at': now,
        },
        where:
            '${WarehouseStocksTable.colWarehouseCode} = ? AND '
            '${WarehouseStocksTable.colProductId} = ?',
        whereArgs: [code, productId],
      );
    } catch (e) {
      if (e is StateError) rethrow;
      // Tablo yoksa sessizce atla (eski DB); products yolu kalır.
    }
  }
}
